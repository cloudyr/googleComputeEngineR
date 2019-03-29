#' Check the docker logs of a container
#' 
#' @param instance The instance running docker
#' @param container A running container to get logs of
#' 
#' @return logs
#' @export
gce_container_logs <- function(instance, container){
  gce_ssh(instance, paste0("sudo journalctl -u ", container))
}

#' @rdname gce_container_logs
#' @param ... Arguments passed to \link{gce_container_logs}
#' @export
gce_check_container <- function(...){
  .Deprecated("gce_container_logs", package = "googleComputeEngineR")
  gce_container_logs(...)
}



#' Launch a container-VM image
#' 
#' This lets you specify docker images when creating the VM.  These are a special class of Google instances that are setup for running Docker containers. 
#' 
#' @inheritParams Instance
#' @inheritParams gce_make_machinetype_url
#' @param file file location of a valid cloud-init or shell_script file. 
#'   One of \code{file} or \code{cloud_init} or \code{shell_script} must be supplied
#' @param cloud_init contents of a cloud-init file, for example read via \code{readChar(file, nchars = 32768)}
#' @param shell_script contents of a shell_script file, for example read via \code{readChar(file, nchars = 32768)}
#' @param image_family An image-family.  It must come from the \code{image_project} family.
#' @param image_project An image-project, where the image-family resides.
#' @param ... Other arguments passed to \link{gce_vm_create}
#' 
#' @details 
#'  
#' \code{file} expects a filepath to a \href{cloud-init}{https://cloudinit.readthedocs.io/en/latest/topics/format.html} configuration file or a valid bash script e.g. has \code{!#/bin/} or \code{#cloud-config} at top of file.
#' 
#' \code{image_project} will be ignored if set, overriden to \code{cos-cloud}.  
#' If you want to set it then use the \link{gce_vm_create} function directly that this function wraps with some defaults.
#' 
#' @seealso \url{https://cloud.google.com/container-optimized-os/docs/how-to/create-configure-instance} - \href{https://www.freedesktop.org/software/systemd/man/systemd.service.html}{help using cloud-init files}
#' 
#' @return A zone operation
#' @export
#' @import assertthat
gce_vm_container <- function(file = NULL,
                             cloud_init = NULL, 
                             shell_script = NULL,
                             image_family = "cos-stable", 
                             image_project = "cos-cloud",
                             ...){
  
  startup_type <- discern_startup_type(file, cloud_init, shell_script)
  
  file_type     <- startup_type$file_type
  file_contents <- startup_type$file_contents
  
  dots <- list(...)
  
  if(file_type == "cloud-config"){
    
    dots <- modify_metadata(dots, list(`user-data` = file_contents))
    
  } else if(file_type == "shell"){
    
    dots <- modify_metadata(dots, list(`startup-script` = file_contents))

  } else {
    stop("Unknown file_type", call. = FALSE)
  }

  myMessage(sprintf("Run gce_startup_logs(your-instance, '%s') to track startup script logs", 
                    file_type), 
            level = 2)
  
  do.call(gce_vm_create, c(list(image_family = image_family,
                                image_project = image_project), 
                           dots)
          )
  
}

#' Get startup script logs
#' 
#' @param instance The instance to get startup script logs from
#' @param type The type of log to run
#' 
#' Will use SSH so that needs to be setup
#' @export
gce_startup_logs <- function(instance, type = c("shell","cloud-config","nginx")){
  type <- match.arg(type)
  
  cmd <- switch(type,
         shell = "google-startup-scripts.service",
         "cloud-config" = "gcer.service",
         nginx = "nginx.service")
  
  gce_ssh(instance, sprintf("sudo journalctl -u %s", cmd))

}

discern_startup_type <- function(file, cloud_init, shell_script){

  if(all(is.null(file), is.null(cloud_init), is.null(shell_script))){
    stop("No template file found: file, cloud_init and shell_script were all NULL", call. = FALSE)
  }
  
  if(!is.null(file)){
    assert_that(
      is.null(cloud_init),
      is.null(shell_script),
      is.readable(file)
    )
    file_contents <- readChar(file, nchars = file.info(file)$size)
    file_type <- detect_startup_filetype(file_contents)
  }
  
  if(!is.null(cloud_init)){
    assert_that(
      is.null(file),
      is.null(shell_script),
      detect_startup_filetype(cloud_init) == "cloud-config"
    )
    file_contents <- cloud_init
    file_type = "cloud-config"
  }
  
  if(!is.null(shell_script)){
    assert_that(
      is.null(file),
      is.null(cloud_init),
      detect_startup_filetype(shell_script) == "shell"
    )
    file_contents <- shell_script
    file_type <- "shell"
  }
  
  list(file_contents = file_contents,
       file_type = file_type)
}

detect_startup_filetype <- function(x){
  if(grepl("^#cloud-config", x)){
    return("cloud-config")
  } else if(grepl("^#!/bin/", x)){
    return("shell")
  } else {
    stop("Text does not start with #cloud-config or #!/bin.  Invalid file.
           Got: ", x, call. = FALSE)
  }

}
