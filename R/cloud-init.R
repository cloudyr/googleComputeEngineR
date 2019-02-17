#' create the cloud_init file to upload
#' @keywords internal
#' @import assertthat
read_cloud_init_file <- function(template) {
  
  the_file          <- get_template_file(template, "cloudconfig")
  
  # written to /etc/systemd/system/gcer.service
  cloud_init_file   <- readChar(the_file, nchars = file.info(the_file)$size)
  
  # gets put into /etc/gcer/startup.sh
  shell_script_file <- read_shell_startup_file(template)
  
  # needs a nginx configuration as well
  if(template == "rstudio-shiny"){
    # gets nginx config file for /etc/nginx.conf
    nginx_config <- read_and_indent(system.file("nginx", "r-proxy-pass.conf", 
                                                package = "googleComputeEngineR"),
                                    indent = 4)
    return(sprintf(cloud_init_file, 
                   shell_script_file, 
                   nginx_config)
    )
  }
  
  # most others only put in the shell script
  sprintf(cloud_init_file, shell_script_file)

}

