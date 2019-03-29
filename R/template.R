#' Create a template container VM
#' 
#' This lets you specify templates for the VM you want to launch
#' It passes the template on to \link{gce_vm_container}
#' 
#' @inheritParams Instance
#' @inheritParams gce_make_machinetype_url
#' @inheritParams gce_ssh_setup
#' @param template The template available
#' @param username username if needed (RStudio)
#' @param password password if needed (RStudio)
#' @param image_family An image-family.  It must come from the \code{cos-cloud} family.
#' @param dynamic_image Supply an alternative to the default Docker image for the template
#' @param wait Whether to wait for the VM to launch before returning. Default \code{TRUE}.
#' @inheritDotParams gce_vm_container
#' 
#' @details 
#' 
#' Templates available are:
#' 
#' \itemize{
#'   \item rstudio An RStudio server docker image with tidyverse and devtools
#'   \item rstudio-gpu An RStudio server with popular R machine learning libraries and GPU driver.  Will launch a GPU enabled VM.
#'   \item rstudio-shiny An RStudio server with Shiny also installed, proxied to /shiny
#'   \item shiny A Shiny docker image
#'   \item opencpu An OpenCPU docker image
#'   \item r_base Latest version of R stable
#'   \item dynamic Supply your own docker image within dynamic_image
#'  }
#'  
#' For \code{dynamic} templates you will need to launch the docker image with any ports you want opened, 
#'    other settings etc. via \link{docker_run}.
#' 
#' Use \code{dynamic_image} to override the default rocker images e.g. \code{rocker/shiny} for shiny, etc. 
#'  
#' @return The VM object, or the VM startup operation if \code{wait=FALSE}
#' 
#' @examples 
#' 
#' \dontrun{
#' 
#'  library(googleComputeEngineR)
#'  
#'  ## make instance using R-base
#'  vm <- gce_vm_template("r-base", predefined_type = "f1-micro", name = "rbase")
#'  
#'  ## run an R function on the instance within the R-base docker image
#'  docker_run(vm, "rocker/r-base", c("Rscript", "-e", "1+1"), user = "mark")
#'  #> [1] 2
#'  
#' 
#' }
#' 
#' 
#' @export
#' @import assertthat
gce_vm_template <- function(template = c("rstudio",
                                         "shiny",
                                         "opencpu",
                                         "r-base",
                                         "dynamic",
                                         "rstudio-gpu", 
                                         "rstudio-shiny"),
                            username=NULL,
                            password=NULL,
                            dynamic_image=NULL,
                            image_family = "cos-stable",
                            wait = TRUE,
                            ...){
  
  template <- match.arg(template)
  assert_that(is.flag(wait),
              is.string(image_family))
  dots <- list(...)
  
  if(is.null(dots$name)){
    message("No VM name specified, defaulting to ", template)
    dots$name <- template
  }
  if(is.null(dots$zone)){
    dots$zone <- gce_get_global_zone()
  }
  if(is.null(dots$project)){
    dots$project <- gce_get_global_project()
  }
  
  # hack for gpu until nvidia-docker is supported on cos-cloud images
  if(grepl("gpu$", template)){
    # setup GPU specific options
    dots            <- set_gpu_template(dots)
    ss_file         <- get_template_file(template, "startupscripts")
    startup_script  <- readChar(ss_file, nchars = file.info(ss_file)$size)
    cloud_init_file <- NULL
    image_family    <- "tf-latest-cu92"
    image_project   <- "deeplearning-platform-release"
  } else {
    # creates cloud-config file that will call the startup script
    cloud_init_file <- read_cloud_init_file(template)
    startup_script  <- NULL
    image_project   <-  "cos-cloud"
  }

  # adds metadata startup script will read
  dots <- setup_shell_metadata(dots,
                               template = template,
                               username = username, 
                               password = password, 
                               dynamic_image = dynamic_image)

  ## metadata
  dots <- modify_metadata(dots, list(template = template,
                                     "google-logging-enabled" = "true"))
  
  ## tag for http, shiny etc.
  dots$tags <- template_tags(template)

  ## build VM
  job <- do.call(gce_vm_container,
                 args = c(list(
                     cloud_init = cloud_init_file,
                     shell_script = startup_script,
                     image_family = image_family,
                     image_project = image_project
                   ), 
                   dots)
                 )
  
  if(wait){
    gce_wait(job, wait = 10)
  } else {
    myMessage("Returning the VM startup job, not the VM instance.", level = 2)
    return(job)
  }

  ins <- gce_get_instance(dots$name, project = dots$project, zone = dots$zone)
  ip  <- gce_get_external_ip(ins, verbose = FALSE)
  
  ## where to find application
  ip_suffix <- ""
  if(grepl("opencpu", template)){
    ip_suffix <- "/ocpu/"
  }

  myMessage("## VM Template: '", paste0(template, "' running at http://", ip,ip_suffix), level = 3)
  myMessage("On first boot, wait a few minutes for docker container to install before logging in.", level = 3)
  
  print(ins)
  ins
  
}

template_tags <- function(template){
  switch(template,
         "rstudio" = list(items = list("http-server", "rstudio")),
         "rstudio-gpu" = list(items = list("http-server","rstudio")),
         "rstudio-shiny" = list(items = list("http-server","rstudio","shiny")),
         "shiny" = list(items = list("http-server","shiny")),
         "opencpu" = list(items = list("http-server","opencpu")),
         "r-base" = list(items = list("r-base"))
  )
}

#' Show the cloud-config template files
#' 
#' @param template The template for the file to fetch
#' @param folder Which folder within the package to fetch it for
#' 
#' This returns the file location of template files for use in \link{gce_vm_template}
#' 
#' @details 
#' 
#' Templates available are:
#' 
#' \itemize{
#'   \item rstudio An RStudio server docker image with the tidyverse installed
#'   \item shiny A Shiny docker image
#'   \item opencpu An OpenCPU docker image
#'   \item r_base Latest version of R stable
#'   \item example A non-R test container running busybox
#'   \item dynamic Supply your own docker image to download such as \code{rocker/verse}
#'  }
#' 
#' @return file location
#' @noRd
get_template_file <- function(template, type = c("cloudconfig", "startupscripts")){
  type <- match.arg(type)
  ext <- if(type == "cloudconfig") ".yaml" else ".sh"
  
  system.file(type, paste0(template, ext), package = "googleComputeEngineR")
  
}

#' Get Dockerfolder of templates
#' 
#' This gets the folder location of available Dockerfile examples
#' 
#' @param dockerfile_folder The folder containing \code{Dockerfile}
#' 
#' @return file location
#' @export
get_dockerfolder <- function(dockerfile_folder){
  
  system.file("dockerfiles", dockerfile_folder, package = "googleComputeEngineR")
  
}