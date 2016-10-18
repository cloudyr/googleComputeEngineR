# from https://github.com/HenrikBengtsson/future/issues/101#issuecomment-253725603
#' @importFrom future makeClusterPSOCK
makeDockerClusterPSOCK <- function(workers, 
                                   docker_image = "rocker/r-base", 
                                   rscript = c("docker", "run", "--net=host", docker_image, "Rscript"), 
                                   rscript_args = NULL, install_future = TRUE, ..., verbose = FALSE) {
  ## Should 'future' package be installed, if not already done?
  if (install_future) {
    rscript_args <- c("-e", shQuote(sprintf("if (!requireNamespace('future', quietly = TRUE)) install.packages('future', quiet = %s)", !verbose)), rscript_args)
  }
  future::makeClusterPSOCK(workers, rscript = rscript, rscript_args = rscript_args, ..., verbose = verbose)
}


#' Create a future cluster for GCE objects
#' 
#' S3 method for \code{\link[future:as.cluster]{as.cluster}()} in the \pkg{future} package.
#' 
#' @param x The instance to make a future cluster
#' @param user Username used in SSH
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
#' vm <- gce_vm_template("r-base", name = "future", predefined_type = "f1-micro")
#' plan(cluster, workers = as.cluster(vm))
#' x %<-% { Sys.getinfo() }
#' print(x)
#' }}
#'
#' @importFrom future as.cluster
#' @export
as.cluster.gce_instance <- function(x, 
                                    user = gce_get_global_ssh_user(), 
                                    project = gce_get_global_project(), 
                                    zone = gce_get_global_zone(), 
                                    rshopts = ssh_options(), 
                                    ..., 
                                    recursive = FALSE) {
  stopifnot(!is.null(user))
  if (is.null(x$kind)) {
    ips <- vapply(x, FUN = gce_get_external_ip, FUN.VALUE = character(1L))
  } else {
    ips <- gce_get_external_ip(x)
  }
  stopifnot(!is.null(ips))
  
  makeDockerClusterPSOCK(ips, user = user, rshopts = rshopts, ...)
}
