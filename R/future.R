# from https://github.com/HenrikBengtsson/future/issues/101#issuecomment-253725603
## ADD iff Imports: future
## @importFrom future makeClusterPSOCK
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


## REMOVE Iff Imports: future
#' @keywords internal
#' @export
as.cluster <- function(x, ...) UseMethod("as.cluster")

#' @keywords internal
#' ## REMOVE iff Imports: future
#' @method as.cluster gce_instance
## ## ADD iff Imports: future
## @importFrom future as.cluster
#' @export
as.cluster.gce_instance <- function(x, user = gce_get_global_ssh_user(), project = gce_get_global_project(), zone = gce_get_global_zone(), rshopts = ssh_options(), ..., recursive = FALSE) {
  stopifnot(!is.null(user))
  if (is.null(x$kind)) {
    ips <- vapply(x, FUN = gce_get_external_ip, FUN.VALUE = character(1L))
  } else {
    ips <- gce_get_external_ip(x)
  }
  stopifnot(!is.null(ips))
  
  makeDockerClusterPSOCK(ips, user = user, rshopts = rshopts, ...)
}


## NOTE: Not really need with above as.cluster()
## Creates clusters on the GCE machines
#' @keywords internal
#' ## ADD iff Imports: future
## @importFrom future plan cluster
#' @export
gce_future_makeCluster <- function(instances, ...) {
  cl <- future::as.cluster(instances, ...)
  future::plan(future::cluster, workers = cl)
}
