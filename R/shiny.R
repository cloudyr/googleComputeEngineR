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
gce_shiny_addapp <- function(instance, shinyapp, ...){
  
  gce_ssh_upload(instance, 
                 local = shinyapp, 
                 remote = "/home/gcer/shinyapps/",
                 ...)
  
}