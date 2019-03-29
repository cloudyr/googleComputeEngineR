#' Make a VM cluster suitable for running parallel workloads
#' 
#' This wraps the commands for creating a cluster suitable for \link[future]{future} workloads.
#' 
#' @param vm_prefix The prefix of the VMs you want to make. Will be appended the cluster number
#' @param cluster_size The number of VMs in your cluster
#' @param docker_image The docker image the jobs on the cluster will run on. Recommend this is derived from \code{rocker/r-parallel}
#' @param ... Passed to \link{gce_vm_template}
#' @param ssh_args A list of optional arguments that will be passed to \link{gce_ssh_setup}
#' @param project The project to launch the cluster in
#' @param zone The zone to launch the cluster in
#' 
#' @export
#' @import assertthat
#' @examples 
#' 
#' \dontrun{
#' library(future)
#' library(googleComputeEngineR)
#' 
#' vms <- gce_vm_cluster()
#' 
#' ## make a future cluster
#' plan(cluster, workers = as.cluster(vms))
#' 
#' }
gce_vm_cluster <- function(vm_prefix = "r-cluster-",
                           cluster_size = 3,
                           docker_image = "rocker/r-parallel",
                           ...,
                           ssh_args = NULL,
                           project = gce_get_global_project(), 
                           zone = gce_get_global_zone()){
  
  assert_that(
    is.string(vm_prefix),
    is.scalar(cluster_size)
  )
  
  ## names for your cluster
  vm_names <- paste0(vm_prefix, 1:cluster_size)
  
  vm_check <- lapply(vm_names, check_vm_exists, project = project, zone = zone)
  
  if(all(unlist(lapply(vm_check, is.gce_instance)))){
    myMessage("VMs already exisits with the cluster names", level = 3)
    return(vm_check)
  }
  
  dots <- list(...)
  
  # defaults
  dots$name <- NULL
  dots$template <- "r-base"
  dots$dynamic_image <- docker_image
  dots$wait <- FALSE
  
  if(is.null(dots$predefined_type)){
    dots$predefined_type <- "n1-standard-1"
  }
  
  myMessage("# Creating cluster with settings: ", 
            paste(names(dots), "=", dots, collapse = ", "),
            level = 3)
  
  ## create the cluster using default template for r-base
  ## creates jobs that are creating VMs in background
  jobs <- lapply(vm_names, function(x) {
    dots$name <- x
    do.call(gce_vm_template, args = dots)
  })
  
  ## wait for all the jobs to complete and VMs are ready
  jobs <- lapply(jobs, gce_wait)
  
  ## get the VM objects
  vms <- lapply(vm_names, gce_vm)
  
  if(!is.null(ssh_args)){
    assert_that(is.list(ssh_args))
    myMessage("# Setting up SSH:", paste(names(ssh_args), "=", ssh_args, collapse = ","),
              level = 3)
  } else {
    ssh_args <- list()
  }
  
  vms <- lapply(vms, function(x){
    ssh_args$instance <- x
    do.call(gce_ssh_setup, args = ssh_args)
  }) 
  
  myMessage("# Testing cluster:", level = 3)
  lapply(vms, function(x){
    gce_ssh(x, paste("echo", x$name, "ssh working"))
  })
  
  vms
  
}



#' Make the Docker cluster on Google Compute Engine
#' 
#' Called by \link{as.cluster}
#' 
#' @param workers The VMs being called upon
#' @param docker_image The docker image to use on the cluster
#' @param rscript The Rscript command to run on the cluster
#' @param rscript_args Arguments to the RScript
#' @param install_future Whether to check if future is installed first (not needed if using docker derived from rocker/r-parallel which is recommended)
#' @param ... Other arguments passed to \link[future]{makeClusterPSOCK}
#' @param verbose How much feedback to show
#' 
#' @importFrom future makeClusterPSOCK
#' @author Henrik Bengtsson \email{henrikb@@braju.com}
#' @export
makeDockerClusterPSOCK <- function(workers, 
                                   docker_image = "rocker/r-parallel", 
                                   rscript = c("docker", "run", "--net=host", docker_image, "Rscript"), 
                                   rscript_args = NULL, install_future = FALSE, ..., verbose = FALSE) {
  ## Should 'future' package be installed, if not already done?
  if (install_future) {
    rscript_args <- c("-e", 
      shQuote(sprintf("if (!requireNamespace('future', quietly = TRUE)) install.packages('future', quiet = %s)", 
                                      !verbose)), 
      rscript_args)
  }
  
  makeClusterPSOCK(workers, 
                   rscript = rscript, 
                   rscript_args = rscript_args, 
                   ..., 
                   verbose = verbose)
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
    ips <- vapply(x, FUN = gce_get_external_ip, FUN.VALUE = character(1L), verbose = FALSE)
  } else {
    ips <- gce_get_external_ip(x, verbose = FALSE)
  }
  stopifnot(!is.null(ips))
  
  makeDockerClusterPSOCK(ips, user = x$ssh$username, rshopts = rshopts, ...)
}

