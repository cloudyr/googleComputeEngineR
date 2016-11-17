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
#' @export
docker_cmd.gce_instance <- function(host, cmd = NULL, args = NULL,
                                    docker_opts = NULL, capture_text = FALSE, ...) {
  
  cmd_string <- paste(c("docker", cmd, docker_opts, args), collapse = " ")
  
  gce_ssh(host, ..., cmd_string, capture_text = capture_text)
  
}

#' Execute a command within a docker container
#'
#' @inheritParams docker_cmd
#' @param container The running container to execute within
#' @examples
#' \dontrun{
#' docker_exec(localhost, "container-id" ,"echo foo")
#' }
#' @return The \code{host} object.
#' @export
docker_exec <- function(host = localhost, container = NULL, ...) {
  if (is.null(container)) stop("Must specify a container.")
  docker_cmd(host, "exec", container, ...)
}

#' Build image on an instance from a local Dockerfile
#' 
#' Helps create a dockerfile for your own images running R
#'
#' @inheritParams docker_cmd
#' @param dockerfile Location of local dockerfile
#' @param new_image Name of the new image
#' @param folder Where on host to build dockerfile
#' 
#' @details 
#' 
#' Dockerfiles are best practice when creating your own images.  
#' 
#' @seealso \href{https://docs.docker.com/engine/userguide/eng-image/dockerfile_best-practices/}{Best practices for writing Dockerfiles}
#' 
#' An example Dockerfile for \href{https://hub.docker.com/r/rocker/ropensci/~/dockerfile/}{rOpensci}
#' 
#' General R Docker images found at \href{https://github.com/rocker-org}{rocker-org}
#' 
#' @examples
#' \dontrun{
#' docker_build(localhost, "/home/stuff/dockerfile" ,"new_image")
#' }
#' @return The \code{host} object.
#' @export
docker_build <- function(host = localhost, dockerfile, new_image, folder = "buildimage",  ...) {
  
  stopifnot(file.exists(dockerfile))
  
  gce_ssh(host, paste0("mkdir -p -m 0755 ", folder), ...)
  gce_ssh_upload(host, dockerfile, folder, ...)
  
  docker_cmd(host, "build", args = c(new_image, folder), docker_opts = "-t", ...)
  
  ## list images
  docker_cmd(host, "images", ...)
}
