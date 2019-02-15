#' create the shell file to upload
#' @keywords internal
#' @import assertthat
read_shell_startup_file <- function(template){
  
  the_file <- get_template_file(template, "startupscripts")

  readChar(the_file, nchars = file.info(the_file)$size)
   
}

setup_shell_metadata <- function(dots,
                                 template, 
                                 username, 
                                 password,
                                 dynamic_image = NULL){
  
  if(!is.null(dynamic_image)){
    assert_that(is.string(dynamic_image))
    the_image <- dynamic_image
  } else {
    the_image <- switch(template,
      "rstudio" = "rocker/tidyverse",
      "rstudio-gpu" = "rocker/ml",
      "rstudio-shiny" = "rocker/tidyverse"
    )
  }
  
  myMessage("Run gce_startup_logs(your-instance) to track startup script logs", level = 3)
  
  modify_metadata(dots,
                  list(rstudio_user = username,
                       rstudio_pw   = password,
                       rstudio_docker_image = the_image))
  
}

#' Get startup script logs
#' 
#' @param instance The instance to get startup script logs from
#' 
#' Will use SSH so that needs to be setup
#' @export
gce_startup_logs <- function(instance){
  gce_ssh(instance, "sudo journalctl -u google-startup-scripts.service")
}
