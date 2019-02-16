#' create the shell file to upload
#' @keywords internal
#' @import assertthat
read_shell_startup_file <- function(template, indent = 0){
  
  the_file <- get_template_file(template, "startupscripts")

  # indent by 4 to fit in cloud-init.yaml
  paste(strwrap(readChar(the_file, nchars = file.info(the_file)$size), 
                     width = 16000, 
                     indent = indent),
             collapse = "\n")
  
  tt <- readLines(the_file, warn = FALSE)
  # indent and make one string again
  paste(paste(rep(" ", indent - 1), collapse =""), tt, collapse = "\n")
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
      "rstudio-gpu" = "rocker/ml-gpu",
      "rstudio-shiny" = "rocker/tidyverse",
      "shiny" = "rocker/shiny",
      "opencpu" = "opencpu/base",
      "r-base" = "rocker/r-base"
    )
  }
  
  modify_metadata(dots,
                  list(rstudio_user = username,
                       rstudio_pw   = password,
                       gcer_docker_image = the_image))
  
}


