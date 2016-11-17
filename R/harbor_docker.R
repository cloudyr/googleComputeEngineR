#' Run a docker command on a host.
#'
#'
#' @param host A host object.
#' @param cmd A docker command, such as "run" or "ps"
#' @param args Arguments to pass to the docker command
#' @param docker_opts Options to docker. These are things that come before the
#'   docker command, when run on the command line.
#' @param capture_text If \code{FALSE} (the default), return the host object.
#'   This is useful for chaining functions. If \code{TRUE}, capture the text
#'   output from both stdout and stderr, and return that. Note that \code{TRUE}
#'   may not be available on all types of hosts.
#' @param ... Other arguments passed to the SSH command for the host
#'
#' @examples
#' \dontrun{
#' docker_cmd(localhost, "ps", "-a")
#' }
#' @export
#' @author Winston Change \email{winston@@stdout.org}
docker_cmd <- function(host, cmd = NULL, args = NULL, docker_opts = NULL,
                       capture_text = FALSE, ...) {
  UseMethod("docker_cmd")
}


#' Pull a docker image onto a host.
#'
#' @inheritParams docker_cmd
#' @param image The docker image to pull e.g. \code{rocker/rstudio}
#' @examples
#' \dontrun{
#' docker_pull(localhost, "debian:testing")
#' }
#' @return The \code{host} object.
#' @export
#' @author Winston Change \email{winston@@stdout.org}
docker_pull <- function(host = localhost, image, ...) {
  if (is.null(image)) stop("Must specify an image.")
  docker_cmd(host, "pull", image, ...)
}



#' Run a command in a new container on a host.
#'
#' @inheritParams docker_cmd
#' @param host An object representing the host where the container will be run.
#' @param image The name or ID of a docker image.
#' @param cmd A command to run in the container.
#' @param name A name for the container. If none is provided, a random name will
#'   be used.
#' @param rm If \code{TRUE}, remove the container after it finishes. This is
#'   incompatible with \code{detach=TRUE}.
#' @param detach If \code{TRUE}, run the container in the background.
#'
#' @return A \code{container} object. When \code{rm=TRUE}, this function returns
#'   \code{NULL} instead of a container object, because the container no longer
#'   exists.
#'
#' @examples
#' \dontrun{
#' docker_run(localhost, "debian:testing", "echo foo")
#' #> foo
#'
#' # Arguments will be concatenated
#' docker_run(localhost, "debian:testing", c("echo foo", "bar"))
#' #> foo bar
#'
#' docker_run(localhost, "rocker/r-base", c("Rscript", "-e", "1+1"))
#' #> [1] 2
#' }
#' @export
#' @author Winston Change \email{winston@@stdout.org}
docker_run <- function(host = localhost, image = NULL, cmd = NULL,
                       name = NULL, rm = FALSE, detach = FALSE,
                       docker_opts = NULL, ...) {

  if (is.null(image)) stop("Must specify an image.")

  # Generate names here, instead of having docker do it automatically, so that
  # we can refer to this container later.
  if (is.null(name)) name <- random_name(prefix = "harbor")

  args <- c(
    sprintf('--name="%s"', name),
    if (rm) "--rm",
    if (detach) "-d",
    docker_opts,
    image,
    cmd
  )

  docker_cmd(host, "run", args = args, ...)
  if (rm) return(invisible())

  info <- docker_inspect(host, name, ...)[[1]]
  invisible(as.container(info, host))
}


#' Inspect one or more containers, given name(s) or ID(s).
#'
#' @inheritParams docker_cmd
#' @param names Names of the containers
#' @return A list of lists, where each sublist represents one container. This is
#'   the output of `docker inspect` translated directly from raw JSON to an R
#'   object.
#'
#' @examples
#' \dontrun{
#' docker_run(localhost, "debian:testing", "echo foo", name = "harbor-test")
#' docker_inspect(localhost, "harbor-test")
#' }
#' @export
#' @author Winston Change \email{winston@@stdout.org}
docker_inspect <- function(host = localhost, names = NULL, ...) {
  if (is.null(names))
    stop("Must have at one least container name/id to inspect.")

  text <- docker_cmd(host, "inspect", args = names, capture_text = TRUE, ...)

  jsonlite::fromJSON(text, simplifyDataFrame = FALSE, simplifyMatrix = FALSE)
}
