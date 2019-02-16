#' create the cloud_init file to upload
#' @keywords internal
#' @import assertthat
read_cloud_init_file <- function(template) {
  
  the_file          <- get_template_file("generic", "cloudconfig")
  
  # written to /etc/systemd/system/gcer.service
  cloud_init_file   <- readChar(the_file, nchars = file.info(the_file)$size)
  
  # gets put into /etc/gcer/startup.sh
  shell_script_file <- read_shell_startup_file(template)
  
  # make substitution for docker image
  sprintf(cloud_init_file, 
          shell_script_file, 
          template, 
          template)
  
}
