# from https://github.com/HenrikBengtsson/future/issues/101#issuecomment-253725603
#' @importFrom future makeClusterPSOCK
#' @author Henrik Bengtsson \email{henrikb@@braju.com}
makeDockerClusterPSOCK <- function(workers, 
                                   docker_image = "rocker/r-base", 
                                   rscript = c("docker", "run", "--net=host", docker_image, "Rscript"), 
                                   rscript_args = NULL, install_future = TRUE, ..., verbose = FALSE) {
  ## Should 'future' package be installed, if not already done?
  if (install_future) {
    rscript_args <- c("-e", 
                      shQuote(sprintf("if (!requireNamespace('future', quietly = TRUE)) install.packages('future', quiet = %s)", 
                                      !verbose)), 
                      rscript_args)
  }
  
  future::makeClusterPSOCK(workers, rscript = rscript, rscript_args = rscript_args, ..., verbose = verbose)
}


#' Create a future cluster for GCE objects
#' 
#' S3 method for \code{\link[future:as.cluster]{as.cluster}()} in the \pkg{future} package.
#' 
#' @details 
#' 
#' Only works for r-base containers created via \code{gce_vm_template("r-base")} or for 
#'   docker containers created using the \code{--net=host} argument flag
#' 
#' @param x The instance to make a future cluster
#' @param project The GCE project
#' @param zone The GCE zone
#' @param rshopts Options for the SSH
#' @param ... Other arguments passed to makeDockerClusterPSOCK
#' @param recursive Not used.
#'
#' @return A \code{cluster} object.
#'
#' @examples
#' \donttest{\dontrun{
#' vm <- gce_vm("r-base", name = "future", predefined_type = "f1-micro")
#' plan(cluster, workers = vm)  ## equivalent to workers = as.cluster(vm)
#' x %<-% { Sys.getinfo() }
#' print(x)
#' }}
#'
#' @importFrom future as.cluster
#' @export
as.cluster.gce_instance <- function(x, 
                                    project = gce_get_global_project(), 
                                    zone = gce_get_global_zone(), 
                                    rshopts = ssh_options(x), 
                                    ..., 
                                    recursive = FALSE) {
  stopifnot(check_ssh_set(x))
  
  if (is.null(x$kind)) {
    ips <- vapply(x, FUN = gce_get_external_ip, FUN.VALUE = character(1L))
  } else {
    ips <- gce_get_external_ip(x)
  }
  stopifnot(!is.null(ips))
  
  makeDockerClusterPSOCK(ips, user = x$ssh$username, rshopts = rshopts, ...)
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
#' See the images on the instance via \code{docker_cmd(instance, "images")}
#' 
#' If using devtools github, will look for an auth token via \code{devtools::github_pat()}.  
#'   This is an environment variable called \code{GITHUB_PAT} 
#' 
#'  Will start a container, install packages and then commit 
#'    the container to an image of the same name via \code{docker commit -m "installed packages via gceR"}
#' 
#' @return TRUE if successful
#' @import future
#' @importFrom utils install.packages
#' @export
gce_future_install_packages <- function(instance,
                                        docker_image,
                                        cran_packages = NULL,
                                        github_packages = NULL){
  
  ## set up future cluster
  temp_name <- paste0("gceR-install-",idempotency())
  clus <- future::as.cluster(instance, 
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
  
  docker_cmd(instance, 
                     cmd = "commit", 
                     args = c("-a 'googleComputeEngineR'" ,
                              paste("-m 'Installed packages:", 
                                    paste(collapse = " ", cran_packages), 
                                    paste(collapse = " ", github_packages),
                                    "'"),
                              temp_name, 
                              docker_image))
  
  ## stop the container
  docker_cmd(instance, "stop", temp_name)
  
  TRUE
  
}

