#' Check the docker logs of a container
#' 
#' @param instance The instance running docker
#' @param container A running container to get logs of
#' 
#' @return logs
#' @export
gce_check_container <- function(instance, container){
  
  gce_ssh(instance, paste0("sudo journalctl -u ", container))
  
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
                            image_family = "gci-stable",
                            name,
                            ...){
  
  dots <- list(...)
  dots$name <- NULL
  
  template <- match.arg(template)
  
  cloud_init <- get_template_file(template)
  
  cloud_init_file <- readChar(cloud_init, nchars = 32768)
  
  upload_meta <- list(template = template)
  

  if(template %in% c("rstudio","rstudio-hadleyverse")){
    
    if(any(is.null(username), is.null(password))){
      stop("Must supply a username and password for RStudio Server templates", call. = FALSE)
    }
    
    image <- get_image("rocker/rstudio", dynamic_image = dynamic_image)
    
    ## Add the username and password to the config file
    cloud_init_file <- sprintf(cloud_init_file, username, password, image)
    upload_meta$rstudio_users <- username
    
  } else if(template == "dynamic"){
    if(is.null(dynamic_image)){
      stop("Must supply a docker image to download for template = 'dynamic'")
      cloud_init_file <- sprintf(cloud_init_file, name, dynamic_image, dynamic_image)
    }
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
  
  job <- do.call(gce_vm_container,
                 c(dots, list(
                   name = name,
                   cloud_init = cloud_init_file,
                   image_family = image_family,
                   tags = list(items = list("http-server")),
                   metadata = upload_meta
                 )))
  
  gce_wait(job, wait = 10)
  
  ins <- gce_get_instance(name)
  ip <- gce_get_external_ip(name)
  
  ## where to find application
  ip_suffix <- ""
  ip_suffix <- switch(template,
                    rstudio = "",
                    shiny   = "",
                    opencpu = "/ocpu/"         
                    )
  
  myMessage("## ", paste0(template, " running at ", ip,ip_suffix), level = 3)
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

#' Launch a container-VM image
#' 
#' This lets you specify docker images when creating the VM
#' 
#' @inheritParams Instance
#' @inheritParams gce_make_machinetype_url
#' @param file file location of a cloud-init file. One of \code{file} or \code{cloud_init} must be supplied
#' @param cloud_init contents of a cloud-init file, for example read via \code{readChar(file, nchars = 32768)}
#' @param image_family An image-family.  It must come from the \code{google-containers} family.
#' @param ... Other arguments passed to \link{gce_vm_create}
#' 
#'  
#' \code{file} expects a filepath to a \href{cloud-init}{https://cloudinit.readthedocs.io/en/latest/topics/format.html} configuration file. 
#' 
#' A configuration file must be less than 32768 characters.
#' 
#' \code{image_project} will be ignored if set, overriden to \code{google-containers}
#' 
#' @return A zone operation
#' @export
gce_vm_container <- function(file = NULL,
                             cloud_init = NULL, 
                             image_family = "gci-stable", 
                             ...){
  
  if(is.null(file)){
    stopifnot(!is.null(cloud_init))
  }
  
  if(is.null(cloud_init)){
    stopifnot(!is.null(file))
    testthat::expect_type(file, "character")
    testthat::expect_gt(nchar(file), 0)
    cloud_init <-  readChar(file, nchars = 32768)
    
    if(!grepl("^#cloud-config\n",cloud_init)){
      stop("file contents does not start with #cloud-config.  Must be a valid cloud-init file.
           Got: ", cloud_init, call. = FALSE)
    }
  }
  
  dots <- list(...)
  
  ## add to any existing metadata
  metadata_new <- c(dots$metadata, 
                    `user-data` = cloud_init)
  
  dots$metadata <- NULL
  
  do.call(gce_vm_create, c(list(image_family = image_family,
                                image_project = "google-containers",
                                metadata = metadata_new), dots)
          )
  
}

#' Push to Google Container Registry
#' 
#' Commit and save a running container or docker image to the Google Container Registry
#' 
#' @param instance The VM to run within
#' @param save_name The new name for the saved image
#' @param container_name A running docker container. Can't be set if \code{image_name} is too.
#' @param image_name A docker image on the instance. Can't be set if \code{container_name} is too.
#' @param wait Will wait for operation to finish on the instance if TRUE 
#' @param container_url The URL of where to save container
#' @param project Project ID for this request, default as set by \link{gce_get_global_project}
#' 
#' This will only work on the Google Container optimised containers of image_family google_containers.
#' Otherwise you will need to get a container authentication yourself (for now)
#' 
#' It will start the push but it may take a long time to finish, espeically the first time, 
#'   this function will return whilst waiting but don't turn off the VM until its finished.
#' @return The tag the image was tagged with on GCE
#' @export
gce_push_registry <- function(instance,
                               save_name,
                               container_name = NULL,
                               image_name = NULL,
                               container_url = "gcr.io",
                               project = gce_get_global_project(), 
                               wait = FALSE){
  
  if(all(!is.null(container_name), !is.null(image_name))){
    stop("Can't set container_name and image_name at same time", call. = FALSE)
  }
  
  build_tag <- gce_tag_container(container_url = container_url,
                                 project = project,
                                 container_name = save_name
                                 )
  
  if(!is.null(container_name)){
    ## commits the current version of running docker container image_name and renames it 
    ## so it can be registered to Google Container Registry
    cmd <- "commit"
    obj <- container_name
  } else if(!is.null(image_name)){
    ## or tags an image for upload
    cmd <- "tag"
    obj <- image_name
  } else {
    stop("Set one of container_name or image_name", call. = FALSE)
  }

  ## tagging
  docker_cmd(instance, cmd = cmd, args = c(obj, build_tag))
  ## authenticatation
  gce_ssh(instance, "/usr/share/google/dockercfg_update.sh")
  
  myMessage("Uploading to Google Container Registry: ", 
            paste0("https://console.cloud.google.com/kubernetes/images/list?project=",project), level = 3)
  
  docker_cmd(instance, cmd = "push", args = build_tag, wait = wait)
  
  build_tag
  
}

#' Return a container tag for Google Container Registry
#' 
#' 
#' @inheritParams gce_push_registry
#' @return A tag for use in Google Container Registry
#' @export
gce_tag_container <- function(container_name,
                              project = gce_get_global_project(),
                              container_url = "gcr.io"
                              ){
  
  paste0(container_url, "/", project, "/", container_name)
  
}

#' Load a previously saved private Google Container
#' 
#' @param instance The VM to run within
#' @param container_name The name of the saved container
#' @param container_url The URL of where the container was saved
#' @param project Project ID for this request, default as set by \link{gce_get_global_project}
#' @param pull_only If TRUE, will not run the container, only pull to the VM
#' @param ... Other arguments passed to \link{docker_run} or \link{docker_pull}
#' 
#' After starting a VM, you can load the container again using this command.
#' 
#' \itemize{
#'   \item For Shiny based containers, pass \code{"-p 80:3838"} to run it at the IP URL
#'   \item For RStudio based containers, pass \code{"-p 80:8787"} to run it at the IP URL
#'  }
#' 
#' @return The instance
#' @export
gce_pull_registry <- function(instance,
                               container_name,
                               container_url = "gcr.io",
                               pull_only = FALSE,
                               project = gce_get_global_project(),
                               ...){
  
  build_tag <- gce_tag_container(container_name = container_name,
                                 project = project,
                                 container_url = container_url)
  
  gce_ssh(instance, "/usr/share/google/dockercfg_update.sh")
  
  if(pull_only){
    docker_pull(instance, image = build_tag, ...)
  } else {
    ## this needs to specify ports etc. 
    docker_run(instance, image = build_tag, detach = TRUE, ...)
  }

  
  instance
}




