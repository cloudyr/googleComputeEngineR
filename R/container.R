#' Launch a container-VM image
#' 
#' This lets you specify docker images when creating the VM
#' 
#' @param cloud_init template name or filepath to a cloud-init configuration file
#' @param image_family An image-family.  It must come from the \code{google-containers} family.
#' @param ... Other arguments passed to \link{gce_vm_create}
#' 
#' Templates available are:
#' 
#' \itemize{
#'   \item rstudio An RStudio server docker image
#'   \item shiny A Shiny docker image
#'   \item opencpu An OpenCPU docker image
#'  }
#'  
#'  If not one of the above, then the function expects a filepath to a \href{cloud-init}{https://cloudinit.readthedocs.io/en/latest/topics/format.html} configuration file. 
#' 
#' \code{image_project} will be ignored if set, overriden to \code{google-containers}
#' 
#' @return A zone operation
#' @export
gce_containervm_create <- function(cloud_init, 
                                   image_family = "gci-stable", 
                                   ...){
  
  testthat::expect_type(cloud_init, "character")
  testthat::expect_gt(nchar(cloud_init), 0)
  
  dots <- list(...)
  
  templates <- c("rstudio","shiny","opencpu")
  
  if(cloud_init %in% templates){
    
    cloud_init <- switch(cloud_init,
          rstudio = system.file("cloudconfig", "rstudio.yml", package = "googleComputeEngineR"),
          shiny   = system.file("cloudconfig", "shiny.yml",   package = "googleComputeEngineR"),
          opencpu = system.file("cloudconfig", "opencpu.yml", package = "googleComputeEngineR")
                              )
    cloud_init_file <- readChar(system.file("cloudconfig", 
                                            cloud_init, 
                                            package = "googleComputeEngineR"), 
                                nchars = 32768)
    
  } else {
    cloud_init_file <- readChar(cloud_init, nchars = 32768)
  }
  
  ## add to any existing metadata
  metadata <- c(dots$metadata, 
                `user-data` = cloud_init_file)
  
  
  gce_vm_create(..., 
                image_family = image_family,
                image_project = "google-containers",
                metadata = metadata)
  
}

#' Container images
#' 
#' https://cloud.google.com/container-registry/docs/advanced-authentication
#' 
#' Upload project JSON auth file for login
#' docker login -e 1234@5678.com -u _json_key -p "$(cat keyfile.json)" https://gcr.io
#' 
#' https://cloud.google.com/container-registry/docs/using-with-google-cloud-platform
#' 
#' https://cloudinit.readthedocs.io/en/latest/topics/examples.html#yaml-examples
#' 
#' https://coreos.com/docs/launching-containers/launching/getting-started-with-systemd/
#' 
#' https://cloud.google.com/compute/docs/storing-retrieving-metadata
#' 



