#' create the cloud_init file to upload
#' @keywords internal
#' @import assertthat
get_cloud_init_file <- function(template,
                                username = NULL, 
                                password = NULL, 
                                dynamic_image = NULL) {
  
  
  if(template == "rstudio"){
    assert_that(
      is.string(username),
      is.string(password)
    )
    
  } else if(template == "dynamic"){
    assert_that(
      is.string(dynamic_image)
    )
  }
  
  switch(template,
         rstudio = build_cloud_init_file_rstudio(template_file = template, 
                                                 docker_image = "rocker/tidyverse", 
                                                 dynamic_image = dynamic_image,
                                                 username = username, 
                                                 password = password),
         dynamic = build_cloud_init_file(template_file = template, 
                                         docker_image = dynamic_image, 
                                         dynamic_image = dynamic_image),
         shiny = build_cloud_init_file(template_file = template, 
                                       docker_image = "rocker/shiny", 
                                       dynamic_image = dynamic_image),
         opencpu = build_cloud_init_file(template_file = template, 
                                         docker_image = "opencpu/base", 
                                         dynamic_image = dynamic_image),
         "r-base" = build_cloud_init_file(template_file = template, 
                                          docker_image = "rocker/r-base", 
                                          dynamic_image = dynamic_image),
         ropensci = build_cloud_init_file_rstudio(template_file = template, 
                                                  docker_image = "rocker/ropensci:dev", 
                                                  dynamic_image = dynamic_image,
                                                  username = username,
                                                  password = password))
}

# build a cloud init file for all non-rstudio 
build_cloud_init_file <- function(template_file, docker_image, dynamic_image){
  cloud_init <- get_template_file(template_file)
  cloud_init_file <- readChar(cloud_init, nchars = file.info(cloud_init)$size)
  image <- get_image(docker_image, dynamic_image = dynamic_image)
  sprintf(cloud_init_file, image)
}

# build the cloud-init file with a username and password
build_cloud_init_file_rstudio <- function(template_file, docker_image, dynamic_image, username, password){
  cloud_init <- get_template_file(template_file)
  cloud_init_file <- readChar(cloud_init, nchars = file.info(cloud_init)$size)
  image <- get_image(docker_image, dynamic_image = dynamic_image)
  sprintf(cloud_init_file, username, password, username, image)
}


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
#' @param dynamic_image Supply an alternative to the default Docker image here to download
#' @inheritDotParams gce_vm_container
#' 
#' @details 
#' 
#' Templates available are:
#' 
#' \itemize{
#'   \item rstudio An RStudio server docker image with tidyverse and devtools
#'   \item shiny A Shiny docker image
#'   \item opencpu An OpenCPU docker image
#'   \item r_base Latest version of R stable
#'   \item ropensci RStudio and tidyverse with all ropensci packages on CRAN and Github
#'   \item example A non-R test container running busybox
#'   \item dynamic Supply your own docker image to download such as \code{rocker/verse}
#'  }
#'  
#'  For \code{dynamic} templates you will need to launch the docker image with any ports you want opened, 
#'    other settings etc. via \link{docker_run}.
#' 
#' Use \code{dynamic_image} to override the default rocker images e.g. \code{rocker/shiny} for shiny, etc. 
#'  
#' @return The VM object
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
gce_vm_template <- function(template = c("rstudio","shiny","opencpu",
                                         "r-base", "example",
                                         "dynamic", "ropensci"),
                            username=NULL,
                            password=NULL,
                            dynamic_image=NULL,
                            image_family = "cos-stable",
                            ...){
  
  dots <- list(...)
  
  if(is.null(dots$name)){
    message("No VM name specified, defaulting to ", template)
    dots$name <- template
  }
  
  template <- match.arg(template)

  cloud_init_file <- get_cloud_init_file(template,
                                         username = username, 
                                         password = password, 
                                         dynamic_image = dynamic_image)
  
  ## metadata
  upload_meta <- list(template = template)
  if(grepl("rstudio", template)){
    upload_meta$rstudio_users <- username
  }
  
  ## build VM
  job <- do.call(gce_vm_container,
                 c(dots, list(
                   cloud_init = cloud_init_file,
                   image_family = image_family,
                   tags = list(items = list("http-server")), # no use now
                   metadata = upload_meta
                 )))
  
  gce_wait(job, wait = 10)
  
  ins <- gce_get_instance(dots$name)
  ip <- gce_get_external_ip(dots$name)
  
  ## where to find application
  ip_suffix <- ""
  if(grepl("opencpu", template)){
    ip_suffix <- "/ocpu/"
  }

  myMessage("## VM ", paste0(template, " running at ", ip,ip_suffix), level = 3)
  myMessage("Wait a few minutes for inital docker container to 
            download and install before logging in.", level = 3)
  
  ins
  
}

get_image <- function(default_image, dynamic_image = NULL){
  ## override default rocker image
  if(is.null(dynamic_image)){
    image <- default_image
  } else {
    image <- dynamic_image
  }
  image
}

#' Show the cloud-config template files
#' 
#' @param template
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
#' @export
get_template_file <- function(template){
  
  system.file("cloudconfig", paste0(template,".yaml"), package = "googleComputeEngineR")
  
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