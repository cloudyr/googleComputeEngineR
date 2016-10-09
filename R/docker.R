#' Docker S3 method for use with harbor package
#' 
#' @param host The GCE instance
#' @param cmd The command to pass to docker
#' @param args arguments to the command
#' @param docker_opts options for docker
#' @param capture_text whether to return the output
#' @param ... other arguments passed to \link{gce_ssh}
#' 
#' @details 
#' 
#' Instances launched in the \code{google-containers} image family automatically add your user to the docker group, 
#'   but for others you will need to run \code{sudo usermod -a -G docker ${USER}} and log out and back in. 
#' 
#' @export
docker_cmd.gce_instance <- function(host, cmd = NULL, args = NULL,
                                    docker_opts = NULL, capture_text = FALSE, ...) {
  
  host <- as.gce_instance_name(host)
  
  cmd_string <- paste(c("docker", cmd, docker_opts, args), collapse = " ")
  
  gce_ssh(host, ..., cmd_string, capture_text = capture_text)
  
}
