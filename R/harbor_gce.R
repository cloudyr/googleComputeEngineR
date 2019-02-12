#' Docker S3 method for use with harbor package
#' 
#' @param host The GCE instance
#' @param cmd The command to pass to docker
#' @param args arguments to the command
#' @param docker_opts options for docker
#' @param capture_text whether to return the output
#' @param nvidia If true will use \code{nvidia-docker} instead of {docker}
#' @param ... other arguments passed to \link{gce_ssh}
#' 
#' @details 
#' 
#' Instances launched in the \code{google-containers} image family automatically add your user to the docker group, 
#'   but for others you will need to run \code{sudo usermod -a -G docker ${USER}} and log out and back in. 
#' @export
docker_cmd.gce_instance <- function(host, cmd = NULL, args = NULL,
                                    docker_opts = NULL, capture_text = FALSE, 
                                    nvidia = FALSE, ...) {
  
  dd <- if(nvidia) "nvidia-docker" else "docker"
  
  cmd_string <- paste(c(dd, cmd, docker_opts, args), collapse = " ")
  
  gce_ssh(host, ..., cmd_string, capture_text = capture_text)
  
}

#' Build image on an instance from a local Dockerfile
#' 
#' Uploads a folder with a \code{Dockerfile} and supporting files to an instance and builds it
#'
#' @inheritParams docker_cmd
#' @param dockerfolder Local location of build directory including valid \code{Dockerfile}
#' @param new_image Name of the new image
#' @param folder Where on host to build dockerfile
#' @param wait Whether to block R console until finished build
#' 
#' @details 
#' 
#' Dockerfiles are best practice when creating your own docker images, 
#' rather than logging into a Docker container, making changes and committing.  
#' 
#' @seealso \href{https://docs.docker.com/engine/userguide/eng-image/dockerfile_best-practices/}{Best practices for writing Dockerfiles}
#' 
#' An example Dockerfile for \href{https://hub.docker.com/r/rocker/ropensci/~/dockerfile/}{rOpensci}
#' 
#' General R Docker images found at \href{https://github.com/rocker-org}{rocker-org}
#' 
#' @examples
#' \dontrun{
#' docker_build(localhost, "/home/stuff/dockerfolder" ,"new_image", wait = TRUE)
#' docker_run(localhost, "new_image")
#' }
#' @return A table of active images on the instance
#' @export
docker_build <- function(host = localhost, 
                         dockerfolder, 
                         new_image, 
                         folder = "buildimage",  
                         wait = FALSE, ...) {
  
  stopifnot(file.exists(dockerfolder))
  
  gce_ssh(host, paste0("mkdir -p -m 0755 ", folder), ...)
  gce_ssh_upload(host, dockerfolder, folder, ...)
  
  docker_cmd(host, 
             "build", 
             args = c(new_image, paste0(folder,"/",basename(dockerfolder))), 
             docker_opts = "-t", 
             wait = wait, 
             ...)
  
  ## list images
  docker_cmd(host, "images", ..., capture_text = TRUE)
}
