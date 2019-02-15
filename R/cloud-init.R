#' create the cloud_init file to upload
#' @keywords internal
#' @import assertthat
read_cloud_init_file <- function(template,
                                dynamic_image = NULL) {
  
  if(!is.null(dynamic_image)){
    assert_that(is.string(dynamic_image))
  }
  
  the_image <- switch(template,
                  dynamic = dynamic_image,
                  shiny = "rocker/shiny", 
                  opencpu = "opencpu/base", 
                  "r-base" = "rocker/r-base")
  
  the_file <- get_template_file(template, "cloudconfig")
  cloud_init_file <- readChar(the_file, nchars = file.info(the_file)$size)
  
  # make substitution for docker image
  sprintf(cloud_init_file, the_image)
}

