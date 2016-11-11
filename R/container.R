#' Check the docker logs of a container
#' 
#' @param instance The instance running docker
#' @param container A running container to get logs of
#' 
#' @return logs
#' @export
gce_check_docker <- function(instance, container){
  
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
gce_vm_template <- function(template = c("rstudio","shiny","opencpu",
                                         "r-base", "example", "rstudio-hadleyverse"),
                            username=NULL,
                            password=NULL,
                            image_family = "gci-stable",
                            name,
                            ...){
  
  dots <- list(...)
  dots$name <- NULL
  
  template <- match.arg(template)
  
  cloud_init <- get_template_file(template)
  
  cloud_init_file <- readChar(cloud_init, nchars = 32768)
  
  ## Add the username and password to the config file
  if(template %in% c("rstudio","rstudio-hadleyverse")){
    if(any(is.null(username), is.null(password))){
      stop("Must supply a username and password for RStudio Server templates")
    }
    cloud_init_file <- sprintf(cloud_init_file, username, password)
  }
  
  job <- do.call(gce_vm_container,
                 c(dots, list(
                   name = name,
                   cloud_init = cloud_init_file,
                   image_family = image_family,
                   tags = list(items = list("http-server")),
                   metadata = list(template = template)
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

get_template_file <- function(template){
  
  switch(template,
         rstudio  = system.file("cloudconfig", "rstudio.yaml", package = "googleComputeEngineR"),
         `rstudio-hadleyverse`  = system.file("cloudconfig", "rstudio-hadleyverse.yaml", package = "googleComputeEngineR"),
         shiny    = system.file("cloudconfig", "shiny.yaml",   package = "googleComputeEngineR"),
         opencpu  = system.file("cloudconfig", "opencpu.yaml", package = "googleComputeEngineR"),
         `r-base` = system.file("cloudconfig", "r-base.yaml",  package = "googleComputeEngineR"),
         example  = system.file("cloudconfig", "example.yaml", package = "googleComputeEngineR")
  )
  
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
           Got: ", cloud_init)
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

#' Commit and save a running docker container to the private Google Container Registry
#' 
#' Saves a running docker container to your projects Google Cloud Storage.
#' 
#' @param instance The VM to run within
#' @param container_name The name for the saved container
#' @param image_name The running docker container you are saving.
#' @param wait Will wait for operation to finish on the instance if TRUE 
#' @param container_url The URL of where to save container
#' @param project Project ID for this request, default as set by \link{gce_get_global_project}
#' 
#' This will only work on the Google Container optimised containers of image_family google_containers.
#' Otherwise you will need to get a container authentication yourself (for now)
#' 
#' It will start the push but it may take a long time to finish, espeically the first time, 
#'   this function will return whilst waiting but don't turn off the VM until its finished.
#' @return TRUE if commands finish
#' @importFrom harbor docker_cmd
#' @export
gce_save_container <- function(instance,
                               container_name,
                               image_name = "rstudio",
                               container_url = "gcr.io",
                               project = gce_get_global_project(), 
                               wait = FALSE){
  
  build_tag <- paste0(container_url, "/", project, "/", container_name)
  
  ## commits the current version of running docker container image_name and renames it 
  ## so it can be registered to Google Container Registry
  harbor::docker_cmd(instance, cmd = "commit", args = c(image_name, build_tag))
  
  ## authenticatation
  gce_ssh(instance, "/usr/share/google/dockercfg_update.sh")
  
  harbor::docker_cmd(instance, cmd = "push", args = build_tag, wait = wait)
  
  TRUE
  
}

#' Load a previously saved private Google Container
#' 
#' @param instance The VM to run within
#' @param container_name The name of the saved container
#' @param container_url The URL of where the container was saved
#' @param project Project ID for this request, default as set by \link{gce_get_global_project}
#' @param pull_only If TRUE, will not run the container, only pull to the VM
#' @param ... Other arguments passed to docker_run or docker_pull
#' 
#' After starting a VM, you can load the container again using this command.
#' 
#' \itemize{
#'   \item For Shiny based containers, pass "-p 80:3838" to run it at the URL
#'   \item For RStudio based containers, pass "-p 80:8787" to run it at the URL
#'  }
#' 
#' @return TRUE if successful
#' @import harbor
#' @export
gce_load_container <- function(instance,
                               container_name,
                               container_url = "gcr.io",
                               pull_only = FALSE,
                               project = gce_get_global_project(),
                               ...){
  
  build_tag <- paste0(container_url, "/", project, "/", container_name)
  
  gce_ssh(instance, "/usr/share/google/dockercfg_update.sh")
  
  if(pull_only){
    harbor::docker_pull(instance, image = build_tag, ...)
  } else {
    ## this needs to specify ports etc. 
    harbor::docker_run(instance, image = build_tag, detach = TRUE, ...)
  }

  
  TRUE
}

#' Install R packages onto an instance's stopped docker image
#' 
#' @param instance The instance running the container
#' @param docker_image A docker image to install packages within.
#' @param cran_packages A character vector of CRAN packages to be installed
#' @param github_packages A character vector of devtools packages to be installed
#' 
#' @details 
#' 
#' See the images on the instance via \code{harbor::docker_cmd(instance, "images")}
#' 
#' If using devtools github, will look for an auth token via \code{devtools::github_pat()}.  
#'   This is an environment variable called \code{GITHUB_PAT} 
#' 
#'  Will start a container, install packages and then commit 
#'    the container to an image of the same name via \code{docker commit -m "installed packages via gceR"}
#' 
#' @return TRUE if successful
#' @import harbor
#' @import future
#' @importFrom utils install.packages
#' @importFrom devtools install_github
#' @export
gce_install_packages_docker <- function(instance,
                                        docker_image,
                                        cran_packages = NULL,
                                        github_packages = NULL){
  
  if(!check_ssh_set(instance)){
    stop("SSH settings not setup. Run gce_ssh_addkeys().")
  }
  

  
  ## set up future cluster
  temp_name <- paste0("gceR-install-",idempotency())
  clus <- as.cluster(instance, 
                     docker_image = docker_image,
                     rscript = c("docker", "run",paste0("--name=",temp_name),"--net=host", docker_image, "Rscript"))
  
  future::plan(future::cluster, workers = clus)
  
  if(!is.null(cran_packages)){
    cran <- NULL
    cran %<-% utils::install.packages(cran_packages)
    cran
  }
  
  if(!is.null(github_packages)){
    devt <- NULL
    devt %<-% devtools::install_github(github_packages, auth_token = devtools::github_pat())
    devt
  }
  
  harbor::docker_cmd(instance, 
                     cmd = "commit", 
                     args = c("-a 'googleComputeEngineR'" ,
                              paste("-m 'Installed packages:", 
                                    paste(collapse = " ", cran_packages), 
                                    paste(collapse = " ", github_packages),
                                    "'"),
                              temp_name, 
                              docker_image))
  
  ## stop the container
  harbor::docker_cmd(instance, "stop", temp_name)
  
  TRUE
  
}

