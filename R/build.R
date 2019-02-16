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
#' It will start the push but it may take a long time to finish, especially the first time, 
#'   this function will return whilst waiting but don't turn off the VM until its finished.
#' @return The tag the image was tagged with on GCE
#' @export
#' @family container registry functions
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
            paste0("https://console.cloud.google.com/gcr/images/list?project=",project), level = 3)
  
  docker_cmd(instance, cmd = "push", args = build_tag, wait = wait)
  
  gce_list_registry(instance,
                    container_url = container_url,
                    project = project)
  build_tag
  
}

#' Return a container tag for Google Container Registry
#' 
#' 
#' @inheritParams gce_push_registry
#' @return A tag for use in Google Container Registry
#' @export
#' @family container registry functions
gce_tag_container <- function(container_name,
                              project = gce_get_global_project(),
                              container_url = "gcr.io"){
  
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
#' @family container registry functions
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

#' List the docker images you have on Google Container Registry
#' 
#' @param instance The VM to run within
#' @param container_url The URL of where the container was saved
#' @param project Project ID for this request, default as set by \link{gce_get_global_project}
#' 
#' @details 
#' Currently needs to run on a Google VM, not locally
#' 
#' @examples 
#' 
#' \dontrun{
#' 
#'   vm <- gce_vm("my_instance")
#'   gce_list_registry(vm)
#' 
#' }
#' 
#' @export
#' @family container registry functions
gce_list_registry <- function(instance,
                              container_url = "gcr.io",
                              project = gce_get_global_project()){
  
  search_string <- paste0(container_url, "/", project)
  
  gce_ssh(instance, "/usr/share/google/dockercfg_update.sh")
  
  out <- docker_cmd(instance, cmd = "search", search_string, capture_text = TRUE)
  
  out 
  
}




