#' create the cloud_init file to upload
#' @keywords internal
get_cloud_init_file <- function(template, 
                                cloud_init,
                                username = NULL, 
                                password = NULL, 
                                dynamic_image = NULL, 
                                build_name = NULL, 
                                dockerfile = NULL) {
  
  cloud_init_file <- readChar(cloud_init, nchars = file.info(cloud_init)$size)
  
  # cloud_init_file <- switch(template,
  #       rstudio = sprintf(cloud_init_file, username, password, get_image("rocker/rstudio", 
  #                                                                        dynamic_image = dynamic_image)),
  #       "rstudio-hadleyverse" = sprintf(cloud_init_file, username, password, get_image("rocker/rstudio", 
  #                                                                        dynamic_image = dynamic_image)),
  #       dynamic = sprintf(cloud_init_file, build_name, dynamic_image, dynamic_image),
  #       shiny = sprintf(cloud_init_file, get_image("rocker/shiny", dynamic_image = dynamic_image)),
  #       opencpu = sprintf(cloud_init_file, get_image("opencpu/base", dynamic_image = dynamic_image)),
  #       "r-base" = sprintf(cloud_init_file, get_image("rocker/r-base", dynamic_image = dynamic_image))
  #                           )
  
  if(template %in% c("rstudio","rstudio-hadleyverse")){
    
    if(any(is.null(username), is.null(password))){
      stop("Must supply a username and password for RStudio Server templates", call. = FALSE)
    }
    
    image <- get_image("rocker/rstudio", dynamic_image = dynamic_image)
    
    ## Add the username and password to the config file
    cloud_init_file <- sprintf(cloud_init_file, username, password, image)
    
  } else if(template == "dynamic"){
    if(is.null(dynamic_image)){
      stop("Must supply a docker image to download for template = 'dynamic'")
    }
    cloud_init_file <- sprintf(cloud_init_file, build_name, dynamic_image, dynamic_image)
  } else if(template == "shiny"){
    
    image <- get_image("rocker/shiny", dynamic_image = dynamic_image)
    
    cloud_init_file <- sprintf(cloud_init_file, image)
  } else if(template == "opencpu"){
    
    image <- get_image("opencpu/base", dynamic_image = dynamic_image)
    cloud_init_file <- sprintf(cloud_init_file, image)
    
  } else if(template == "r-base"){
    
    image <- get_image("rocker/r-base", dynamic_image = dynamic_image)
    cloud_init_file <- sprintf(cloud_init_file, image)
    
  } else {
    warning("No template settings found for ", template)
  }
  
  cloud_init_file
}

#' Create a template container VM
#' 
#' This lets you specify templates for the VM you wnat to launch
#' It passes the template on to \link{gce_vm_container}
#' 
#' @inheritParams Instance
#' @inheritParams gce_make_machinetype_url
#' @param template The template available
#' @param username username if needed (RStudio)
#' @param password password if needed (RStudio)
#' @param image_family An image-family.  It must come from the \code{google-containers} family.
#' @param dynamic_image Supply an alternative to the default Docker image here to download
#' @param dockerfile If template is \code{builder} the Dockerfile to run on startup
#' @param image_name If template is \code{builder} or \code{dynamic}, the name of Docker image
#' @param build_name The name of the build
#' @param ... Other arguments passed to \link{gce_vm_create}
#' 
#' @details 
#' 
#' Templates available are:
#' 
#' \itemize{
#'   \item rstudio An RStudio server docker image
#'   \item rstudio-hadleyverse RStudio with the tidyverse installed
#'   \item shiny A Shiny docker image
#'   \item opencpu An OpenCPU docker image
#'   \item r_base Latest version of R stable
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
#' @importFrom utils browseURL
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
                                         "r-base", "example", "rstudio-hadleyverse",
                                         "dynamic"),
                            username=NULL,
                            password=NULL,
                            dynamic_image=NULL,
                            dockerfile = NULL,
                            build_name = NULL,
                            image_family = "cos-stable",
                            ...){
  
  dots <- list(...)
  
  if(is.null(dots$name)){
    message("No VM name specified, defaulting to ", template)
    dots$name <- template
  }
  
  template <- match.arg(template)

  cloud_init_file <- get_cloud_init_file(template, 
                                         cloud_init = get_template_file(template),
                                         username = username, 
                                         password = password, 
                                         dynamic_image = dynamic_image, 
                                         build_name = build_name, 
                                         dockerfile = dockerfile)
  
  ## metadata
  upload_meta <- list(template = template)
  if(template %in% c("rstudio","rstudio-hadleyverse")){
    upload_meta$rstudio_users <- username
  }
  
  ## build VM
  job <- do.call(gce_vm_container,
                 c(dots, list(
                   cloud_init = cloud_init_file,
                   image_family = image_family,
                   tags = list(items = list("http-server")),
                   metadata = upload_meta
                 )))
  
  gce_wait(job, wait = 10)
  
  ins <- gce_get_instance(dots$name)
  ip <- gce_get_external_ip(dots$name)
  
  ## where to find application
  ip_suffix <- ""
  ip_suffix <- switch(template,
                      rstudio = "",
                      shiny   = "",
                      opencpu = "/ocpu/"         
  )
  
  myMessage("## VM ", paste0(template, " running at ", ip,ip_suffix), level = 3)
  myMessage("You may need to wait a few minutes for the inital docker container to 
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
#'   \item rstudio An RStudio server docker image
#'   \item rstudio-hadleyverse RStudio with the tidyverse installed
#'   \item shiny A Shiny docker image
#'   \item opencpu An OpenCPU docker image
#'   \item r_base Latest version of R stable
#'   \item example A non-R test container running busybox
#'   \item dynamic Supply your own docker image to download such as \code{rocker/verse}
#'   \item builder A VM that can build a supplied Dockerfile
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