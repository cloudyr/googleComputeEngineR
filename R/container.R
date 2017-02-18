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
#' \code{image_project} will be ignored if set, overriden to \code{cos-cloud}
#' 
#' @seealso \url{https://cloud.google.com/container-optimized-os/docs/how-to/create-configure-instance}
#' 
#' @return A zone operation
#' @export
gce_vm_container <- function(file = NULL,
                             cloud_init = NULL, 
                             image_family = "cos-stable", 
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
                                image_project = "cos-cloud",
                                metadata = metadata_new), dots)
          )
  
}

