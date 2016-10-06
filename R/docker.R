## This may eventually depend on https://github.com/wch/harbor/ if that gets to CRAN
## in the meantime the functions are from there.
#' @author Winston Chang \email{winston@@stdout.org}

#' @export
docker_cmd.gce_instance <- function(host, cmd = NULL, args = NULL,
                                    docker_opts = NULL, capture_text = FALSE, ...) {
  cmd_string <- paste(c("docker", cmd, docker_opts, args), collapse = " ")
  
  if (capture_text) {
    # Assume that the remote host uses /tmp as the temp dir
    temp_remote <- tempfile("docker_cmd", tmpdir = "/tmp")
    temp_local <- tempfile("docker_cmd")
    on.exit(unlink(temp_local))
    
    gce_ssh(host$name, paste(cmd_string, ">", temp_remote), ...)
    gce_ssh_download(host$name, temp_remote, temp_local, ...)
    
    text <- readLines(temp_local, warn = FALSE)
    return(text)
    
  } else {
    return(gce_ssh(host$name, ..., cmd_string))
  }
  
}

#' An object representing the current computer that R is running on.
#' @author Winston Chang \email{winston@@stdout.org}
#' @export
localhost <- structure(list(), class = c("localhost", "host"))

#' @export
print.localhost <- function(x, ...) {
  cat("<localhost>")
}


#' @export
#' @author Winston Chang \email{winston@@stdout.org}
docker_cmd.localhost <- function(host, cmd = NULL, args = NULL,
                                 docker_opts = NULL, capture_text = FALSE, ...) {
  docker <- Sys.which("docker")
  
  textopt <- capture_text
  # If FALSE, send output to console
  if (textopt == FALSE) textopt <- ""
  
  res <- system2(docker, args = c(cmd, docker_opts, args), stdout = textopt,
                 stderr = textopt)
  
  if (capture_text) return(res)
  
  invisible(host)
}

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
#' @author Winston Chang \email{winston@@stdout.org}
#' @examples
#' \dontrun{
#' docker_cmd(localhost, "ps", "-a")
#' }
#' @export
docker_cmd <- function(host, cmd = NULL, args = NULL, docker_opts = NULL,
                       capture_text = FALSE, ...) {
  UseMethod("docker_cmd")
}


#' Pull a docker image onto a host.
#' @author Winston Chang \email{winston@@stdout.org}
#' @examples
#' \dontrun{
#' docker_pull(localhost, "debian:testing")
#' }
#' @return The \code{host} object.
#' @export
docker_pull <- function(host = localhost, image, ...) {
  if (is.null(image)) stop("Must specify an image.")
  docker_cmd(host, "pull", image, ...)
}

# Return a string of random letters and numbers, with an optional prefix.
random_name <- function(prefix = NULL, length = 6) {
  chars <- c(letters, 0:9)
  rand_str <- paste(sample(chars, length), collapse = "")
  paste(c(prefix, rand_str), collapse = "_")
}


#' Run a command in a new container on a host.
#' @author Winston Chang \email{winston@@stdout.org}
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
#' @author Winston Chang \email{winston@@stdout.org}
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
docker_inspect <- function(host = localhost, names = NULL, ...) {
  if (is.null(names))
    stop("Must have at one least container name/id to inspect.")
  
  text <- docker_cmd(host, "inspect", args = names, capture_text = TRUE, ...)
  
  jsonlite::fromJSON(text, simplifyDataFrame = FALSE, simplifyMatrix = FALSE)
}

#' Coerce an object into a container object.
#' @author Winston Chang \email{winston@@stdout.org}
#' A container object represents a Docker container on a host.
#' @export
as.container <- function(x, host = localhost) UseMethod("as.container")

#' @export
#' @author Winston Chang \email{winston@@stdout.org}
as.container.character <- function(x, host = localhost) {
  info <- docker_inspect(host, x)[[1]]
  as.container(info, host)
}

#' @export
#' @author Winston Chang \email{winston@@stdout.org}
as.container.list <- function(x, host = localhost) {
  # x should be the output of docker_inspect()
  if (is.null(x$Name) || is.null(x$Id))
    stop("`x` must be information about a single container.")
  
  structure(
    list(
      host = host,
      id = substr(x$Id, 1, 12),
      name = sub("^/", "", x$Name),
      image = x$Config$Image,
      cmd = x$Config$Cmd,
      info = x
    ),
    class = "container"
  )
}

#' @export
#' @author Winston Chang \email{winston@@stdout.org}
as.container.container <- function(x, host = localhost) {
  x
}

#' @export
#' @author Winston Chang \email{winston@@stdout.org}
print.container <- function(x, ...) {
  cat("<container>")
  cat(
    "\n  ID:      ", x$id,
    "\n  Name:    ", x$name,
    "\n  Image:   ", x$image,
    "\n  Command: ", x$cmd,
    "\n  Host:  ",
    indent(
      paste(capture.output(print(x$host)), collapse = "\n"),
      indent = 2
    )
  )
}

#' Update the information about a container.
#'
#' This queries docker (on the host) for information about the container, and
#' saves the returned information into a container object, which is returned.
#' This does not use reference semantics, so if you want to store the updated
#' information, you need to save the result.
#' @author Winston Chang \email{winston@@stdout.org}
#' @examples
#' \dontrun{
#' con <- container_update_info(con)
#' }
#' @export
container_update_info <- function(container) {
  container$info <- docker_inspect(container$host, container$name)[[1]]
  container
}

#' Report whether a container is currently running.
#' @author Winston Chang \email{winston@@stdout.org}
#' @examples
#' \dontrun{
#' container_running(con)
#' }
#' @export
container_running <- function(container) {
  container <- container_update_info(container)
  container$info$State$Running
}


#' Delete a container.
#' @author Winston Chang \email{winston@@stdout.org}
#' @param force Force removal of a running container.
#' @examples
#' \dontrun{
#' container_rm(con)
#' }
#' @export
container_rm <- function(container, force = FALSE) {
  args <- c(if (force) "-f", container$id)
  docker_cmd(container$host, "rm", args)
}


#' Retrieve logs for a container.
#' @author Winston Chang \email{winston@@stdout.org}
#' @param follow Follow log output as it is happening.
#' @param timestamp Show timestamps.
#' @examples
#' \dontrun{
#' container_rm(con)
#' }
#' @export
container_logs <- function(container, timestamps = FALSE, follow = FALSE) {
  args <- c(if (timestamps) "-t", if (follow) "-f", container$id)
  docker_cmd(container$host, "logs", args)
}

pluck <- function(x, name, type) {
  if (missing(type)) {
    lapply(x, "[[", name)
  } else {
    vapply(x, "[[", name, FUN.VALUE = type)
  }
}

#' Get list of all containers on a host.
#' @author Winston Chang \email{winston@@stdout.org}
#' @export
containers <- function(host = localhost, ...) {
  ids <- docker_cmd(host, "ps", "-qa", capture_text = TRUE, ...)
  
  cons <- lapply(ids, as.container, host)
  names(cons) <- pluck(cons, "name", character(1))
  cons
}

# If we're on Mac and Windows, we're using boot2docker, and we need to run the
# equivalent of `$(boot2docker shellinit)`.
#' @author Winston Chang \email{winston@@stdout.org}
#' @export
boot2docker_shellinit <- function() {
  if (!(Sys.info()["sysname"] %in% c("Darwin", "Windows")))
    return()
  if (Sys.which("boot2docker") == "")
    return()
  
  if (boot2docker_ver() < "1.3.0")
    stop("Running boot2docker locally requires boot2docker >= 1.3.0")
  
  # Run shellinit and capture the output, which are comands setting env vars
  # for sh. We need read them in and set them from R.
  envvars <- system2("boot2docker", "shellinit", stdout = TRUE)
  if (length(envvars) != 0) {
    envvars <- sub("^ +export +", "", envvars)
    envvars <- strsplit(envvars, "=")
    envvars <- setNames(pluck(envvars, 2), pluck(envvars, 1))
    do.call(Sys.setenv, envvars)
  }
}

#' @author Winston Chang \email{winston@@stdout.org}
boot2docker_ver <- function(){
  out <- system2("boot2docker", "version", stdout = TRUE)
  ver <- gsub("^.*?v([0-9\\.]+).*", "\\1", out[1])
  as.package_version(ver)
}