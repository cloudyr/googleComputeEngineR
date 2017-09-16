#' Add Shiny app to a Shiny template instance
#' 
#' Add a local shiny app to a running Shiny VM installed via \link{gce_vm_template} 
#'   via \link{docker_build} and \link{gce_push_registry} / \link{gce_pull_registry}.
#' 
#' @param instance The instance running Shiny
#' @param dockerfolder The folder location containing the \code{Dockerfile} and app dependencies
#' @param app_image The name of the Docker image to create or use existing from Google Container Registry. Must be numbers, dashes or lowercase letters only.
#' 
#' @details 
#' 
#' To deploy a Shiny app, you first need to construct a \code{Dockerfile} which load the R packages and
#'   dependencies, as well as copying over the Shiny app in the same folder.
#'
#' This function will take the Dockerfile, build it into a Docker image and 
#'   upload it to Google Container Registry for use later.
#' 
#' If already created, then the function will download the \code{app_image} from Google Container Registry 
#'   and start it on the instance provided. 
#' 
#' Any existing Shiny Docker containers are stopped and removed, 
#'   so if you want multiple apps put them in the same \code{Dockerfile}.
#'   
#'
#' @seealso The vignette entry called \code{Shiny App} has examples and a walk through.
#'   
#' @section Dockerfile:
#' 
#' Example \code{Dockerfile}'s are found in 
#' \code{system.file("dockerfiles",package = "googleComputeEngineR")}
#' 
#' The Dockerfile is in the same folder as your shiny app, 
#' which consists of a \code{ui.R} and \code{server.R} in a shiny subfolder.  
#' This is copied into the Dockerfile in the last line.  
#' Change the name of the subfolder to have that name appear 
#' in the final URL of the Shinyapp. 
#' 
#' This is then run using the R commands below:
#' 
#' @examples 
#' \dontrun{
#' 
#' vm <- gce_vm("shiny-test",  
#'              template = "shiny", 
#'              predefined_type = "n1-standard-1")
#'              
#' vm <- vm_ssh_setup(vm)
#' 
#' app_dir <- system.file("dockerfiles","shiny-googleAuthRdemo",
#'                        package = "googleComputeEngineR") 
#'                        
#' gce_shiny_addapp(vm, app_image = "gceshinydemo", dockerfolder = app_dir)
#' 
#' # a new VM, it loads the Shiny docker image from before
#' gce_shiny_addapp(vm2, app_image = "gceshinydemo")
#' 
#' }
#' 
#' @return The instance
#' @export
gce_shiny_addapp <- function(instance, app_image, dockerfolder = NULL){
  
  if(!grepl("^[a-z0-9\\-]+$", app_image)){
    stop("app_image must only be lowercase, numbers, dash only. Got ", app_image)
  }
  
  assertthat::assert_that(
    is.gce_instance(instance),
    "shiny" %in% instance$metadata$items$value,
    assertthat::is.string(app_image)
  )
  
  if(!check_ssh_set(instance)){
    stop("SSH settings not setup. Run 'vm <- gce_ssh_setup(vm)'", call. = FALSE)
  }
  
  ip <- gce_get_external_ip(instance, verbose = FALSE)
  
  
  check_connected <- try(httr::GET(paste0("http://",ip)))
  if(is.error(check_connected)){
    check_connected <- try(httr::GET(paste0("https://",ip)))
    if(is.error(check_connected)){
      stop("Couldn't connect to ", ip)
    }
  } else {
    myMessage("Checked connection to ", ip, " : status_code ", check_connected$status_code, level = 3)
  }
  

  if(!is.null(dockerfolder)){
    assertthat::assert_that(
      assertthat::is.readable(file.path(dockerfolder, "Dockerfile"))
    )
    
    myMessage("Building dockerfile to create Shiny app:", app_image)
    
    ## builds images, then lists current images on VM
    images <- docker_build(instance, dockerfolder = dockerfolder, new_image = app_image, wait = TRUE)
    
    if(!any(grepl(app_image, images))){
      stop("Problem building image on instance")
    }
    
    image_tag <- gce_push_registry(instance, save_name = app_image, image_name = app_image, wait = TRUE)
    myMessage("Pushed built Shiny app image to Google Container Registry: ", image_tag, level =3)
  } else {
    myMessage("Pulling existing Shiny app from Google Container Registry", level = 3)
    
    gce_pull_registry(instance, container_name = app_image, pull_only = TRUE)
    image_tag <- gce_tag_container(app_image)
    
  }
  
  ## stop previously running docker shiny server
  docker_cmd(instance, cmd = "stop", args = "shinyserver")
  docker_cmd(instance, cmd = "rm", args = "shinyserver")  
  
  container <- docker_run(instance, 
                          image = image_tag, 
                          name = "shinyserver", 
                          detach = TRUE, 
                          docker_opts = '-p 80:3838')

  if(class(container) == "container"){
    
    gce_set_metadata(list(shinyapps = paste0(app_image,",", 
                                             gce_get_metadata(instance, "shinyapps")$value)), 
                     instance = instance)
  }
  

  
  myMessage("Shiny app running at ", ip, " in the folder copied to in your Dockerfile i.e.",ip,"/shiny/", level = 3)
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