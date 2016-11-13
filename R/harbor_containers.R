#' Get list of all containers on a host.
#' @inheritParams docker_cmd
#' @export
#' @author Winston Change \email{winston@@stdout.org}
containers <- function(host = localhost, ...) {
  ids <- docker_cmd(host, "ps", "-qa", capture_text = TRUE, ...)

  cons <- lapply(ids, as.container, host)
  names(cons) <- pluck(cons, "name", character(1))
  cons
}
