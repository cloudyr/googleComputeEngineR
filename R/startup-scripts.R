#' create the shell file to upload
#' @keywords internal
#' @import assertthat
read_shell_startup_file <- function(template){
  
  the_file <- get_template_file(template, "startupscripts")
  
  read_and_indent(the_file, indent = 4)

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


