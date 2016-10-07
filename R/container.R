#' Create a template container VM
#' 
#' This lets you specify templates for the VM you wnat to launch
#' It passes the template on to \link{gce_vm_container}
#' 
#' @param template The template available
#' @param username username if needed (RStudio)
#' @param password password if needed (RStudio)
#' @param image_family An image-family.  It must come from the \code{google-containers} family.
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
#'   \item r_base Latest version of R stable
#'   \item example A non-R test container running busybox
#'  }
#'  
#' @return The VM object
#' @importFrom utils browseURL
#' 
#' @examples 
#' 
#' \dontrun{
#' 
#'  library(googleComputeEngineR)
#'  library(harbor)
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
gce_vm_template <- function(template = c("rstudio","shiny","opencpu","r-base", "example"),
                            username=NULL,
                            password=NULL,
                            image_family = "gci-stable",
                            ...){
  
  dots <- list(...)
  
  template <- match.arg(template)
  
  cloud_init <- switch(template,
                       rstudio  = system.file("cloudconfig", "rstudio.yaml", package = "googleComputeEngineR"),
                       shiny    = system.file("cloudconfig", "shiny.yaml",   package = "googleComputeEngineR"),
                       opencpu  = system.file("cloudconfig", "opencpu.yaml", package = "googleComputeEngineR"),
                       `r-base` = system.file("cloudconfig", "r-base.yaml",  package = "googleComputeEngineR"),
                       example  = system.file("cloudconfig", "example.yaml", package = "googleComputeEngineR")
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
                          tags = list(items = list("http-server")),
                          ...)
  
  gce_check_zone_op(job$name, wait = 10)
  
  ins <- gce_get_instance(dots$name)
  ip <- gce_get_external_ip(dots$name)
  
  ## where to find application
  ip_suffix <- ""
  ip_suffix <- switch(template,
                    rstudio = "",
                    shiny   = "",
                    opencpu = "/ocpu/"         
                    )
  
  cat("\n## ", paste0(template, " running at ", ip,ip_suffix),"\n")
  cat("\n You may need to wait a few minutes for the inital docker container to download and install before logging in.\n")
  
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
#' A configuration file must be less than 32768 characters.
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
    cloud_init <-  readChar(file, nchars = 32768)
    
    if(!grepl("^#cloud-config\n",cloud_init)){
      stop("file contents does not start with #cloud-config.  Must be a valid cloud-init file.
           Got: ", cloud_init)
    }
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


