#' Create a template container VM
#' 
#' This lets you specify templates for the VM you wnat to launch
#' It passes the template on to \link{gce_containervm_create}
#' 
#' @param template The template available
#' @param username username if needed (RStudio)
#' @param password password if needed (RStudio)
#' @param image_family An image-family.  It must come from the \code{google-containers} family.
#' @param browse If TRUE will attempt to open browser to server once deployed
#' @param ... Other arguments passed to \link{gce_vm_create}
#' 
#' @details 
#' 
#' Templates available are:
#' 
#' \itemize{
#'   \item rstudio An RStudio server docker image
#'   \item shiny A Shiny docker image
#'   \item opencpu An OpenCPU docker image
#'  }
#'  
#' @return The VM object
#' @export  
gce_vm_template <- function(template = c("rstudio","shiny","opencpu"),
                            username=NULL,
                            password=NULL,
                            image_family = "gci-stable",
                            browse = TRUE,
                            ...){
  
  dots <- list(...)
  
  template <- match.arg(template)
  
  cloud_init <- switch(template,
                       rstudio = system.file("cloudconfig", "rstudio.yaml", package = "googleComputeEngineR"),
                       shiny   = system.file("cloudconfig", "shiny.yaml",   package = "googleComputeEngineR"),
                       opencpu = system.file("cloudconfig", "opencpu.yaml", package = "googleComputeEngineR")
  )
  
  cloud_init_file <- readChar(cloud_init, nchars = 32768)
  
  ## Add the username and password to the config file
  if(template == "rstudio"){
    if(any(is.null(username), is.null(password))){
      stop("Must supply a username and password for RStudio Server templates")
    }
    cloud_init_file <- sprintf(cloud_init_file, username, password)
  }
  
  job <- gce_vm_container(cloud_init = cloud_init_file,
                          image_family = image_family,
                          ...)
  
  done <- gce_check_zone_op(job$name, wait = 20)
  testthat::expect_equal(done$status, "DONE")
  
  ins <- gce_get_instance(dots$name)
  expect_equal(ins$kind, "compute#instance")
  expect_equal(ins$status, "RUNNING")
  
  ip <- gce_get_external_ip(dots$name)
  
  ip_suffix <- switch(template,
                    rstudio = ":8787",
                    shiny   = ":3838",
                    opencpu = "/ocpu/"         
                    )
  
  cat("\n## ", paste0(template, " running at ", ip,ip_suffix),"\n")
  
  if(browse){
    browseURL(paste0("http://",ip,ip_suffix))
  }
  
  ins

}

#' Launch a container-VM image
#' 
#' This lets you specify docker images when creating the VM
#' 
#' @param file file location of a cloud-init file. One of \code{file} or \code{cloud_init} must be supplied
#' @param cloud_init contents of a cloud-init file, for example read via \code{readChar(file, nchars = 32768)}
#' @param image_family An image-family.  It must come from the \code{google-containers} family.
#' @param ... Other arguments passed to \link{gce_vm_create}
#' 
#'  
#' \code{file} expects a filepath to a \href{cloud-init}{https://cloudinit.readthedocs.io/en/latest/topics/format.html} configuration file. 
#' 
#' \code{image_project} will be ignored if set, overriden to \code{google-containers}
#' 
#' @return A zone operation
#' @export
gce_vm_container <- function(file,
                             cloud_init, 
                             image_family = "gci-stable", 
                             ...){
  
  if(missing(file)){
    stopifnot(!missing(cloud_init))
  }
  
  if(missing(cloud_init)){
    stopifnot(!missing(file))
    testthat::expect_type(file, "character")
    testthat::expect_gt(nchar(file), 0)
    cloud_init <-  readChar(cloud_init, nchars = 32768)
  }
  
  dots <- list(...)
  
  ## add to any existing metadata
  metadata <- c(dots$metadata, 
                `user-data` = cloud_init)
  
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



