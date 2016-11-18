#' Add Shiny app to a Shiny template instance
#' 
#' Add a local shiny app to a running Shiny VM installed via \link{gce_vm_template}
#' 
#' @param instance The instance running Shiny
#' @param shinyapp The folder container the local Shiny app
#' @param ... Other arguments passed to \link{gce_ssh_upload}
#' 
#' @return The instance
#' @export
gce_shiny_addapp <- function(instance, shinyapp = ".", ...){
  
  if(!check_ssh_set(instance)){
    stop("SSH settings not setup. Run gce_ssh_addkeys().", .call = FALSE)
  }
  
  perm <- gce_ssh(instance, "sudo chmod -R 755 /home/gcer/shinyapps")
  
  if(perm){
    uploaded <- gce_ssh_upload(instance, 
                               local = shinyapp, 
                               remote = "/home/gcer/shinyapps",
                               ...)
    if(uploaded){
      gce_set_metadata(list(shinyapps = c(basename(normalizePath(shinyapp)), 
                                          gce_get_metadata(instance, "shinyapps"))), 
                       instance = instance)
    }
  } else {
    stop("Problems setting user permissions")
  }

  instance
  
}

#' List shiny apps on the instance
#' 
#' @param instance Instance with Shiny apps installed
#' 
#' @return character vector
#' @export
gce_shiny_listapps <- function(instance){
  
  gce_get_metadata(instance, "shinyapps")$value
  
}

#' Get the latest shiny logs for a shinyapp
#' 
#' @param instance Instance with Shiny app installed
#' @param shinyapp Name of shinyapp to see logs for. If NULL will return general shiny logs
#' 
#' @return log printout
#' @export
gce_shiny_logs <- function(instance, shinyapp = NULL){
  
  if(is.null(shinyapp)){
    logs <- "cat /home/gcer/shinylog/shiny-server.log"
  } else {
    logs <- sprintf("cd /home/gcer/shinylog/shiny-server && sudo cat `ls -rt %s*.log|tail -1`", shinyapp)
  }
  
  gce_ssh(instance, logs, capture_text = TRUE)
  
}