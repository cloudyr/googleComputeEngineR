# from https://github.com/HenrikBengtsson/future/issues/101#issuecomment-253725603
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

## Creates future clusters on the GCE machines
#' @export
gce_future_makeCluster <- function(instances, 
                                   username = gce_get_global_ssh_user(),
                                   project = gce_get_global_project(), 
                                   zone = gce_get_global_zone()){
  
  stopifnot(!is.null(username))
  
  if(is.null(instances$kind)){
    ## a list of instances.  S3 methods instead?
    ips <- vapply(instances, gce_get_external_ip, character(1))
  } else {
    ## only one 
    ips <- gce_get_external_ip(instances)
  }

  
  worker <- paste0(username,"@", ips)
  cl <- makeDockerClusterPSOCK(worker, verbose = TRUE, rshopts = ssh_options())
  
  future::plan(future::cluster, workers = cl)
  
}