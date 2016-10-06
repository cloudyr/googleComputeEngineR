#' Docker S3 method for use with harbor package
#' 
#' @param host The GCE instance
#' @param cmd The command to pass to docker
#' @param args arguments to the command
#' @param docker_opts options for docker
#' @param capture_text whether to return the output
#' @param ... other arguments passed to \link{gce_ssh}
#' 
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
