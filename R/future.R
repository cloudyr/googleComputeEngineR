# from https://github.com/HenrikBengtsson/future/issues/101#issuecomment-253725603
makeDockerClusterPSOCK <- function(workers, 
                                   docker_image = "rocker/r-base", 
                                   rscript = c("docker", "run", "--net=host", docker_image, "Rscript"), 
                                   rscript_args = NULL, install_future = TRUE, ..., verbose = FALSE) {
  ## Should 'future' package be installed, if not already done?
  if (install_future) {
    rscript_args <- c("-e", shQuote(sprintf("if (!requireNamespace('future', quietly = TRUE)) install.packages('future', quiet = %s)", !verbose)), rscript_args)
  }
  makeClusterPSOCK(workers, rscript = rscript, rscript_args = rscript_args, ..., verbose = verbose)
}