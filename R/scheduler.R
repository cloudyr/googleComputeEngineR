#' Schedule a script upon a VM
#' 
#' Utility function to start a VM, upload your script and set it up on a schedule
#' 
#' @param script The script to schedule
#' @param vm A VM object to schedule the script upon
#' @param schedule The schedule you want to run via cron
#' @param ... Other arguments pass to \code{containeRit::dockerfile}
#' 
#' @value The Dockerfile that should be built into an image via build triggers 
#'   or \link{docker_build} and pushed to a repository
#' 
#' @export
gce_schedule_build_script <- function(script, vm, schedule, ...){
  
  # ## generate docker file for script environment
  # container <- containeRit::dockerfile(script, 
  #                                      save_image = TRUE,
  #                                      image = gce_tag_container("gcer-scheduler", project = "gcer-public"),
  #                                      copy = "script_dir",
  #                                      ...)
  # 
  # ## assume Dockerfile will create an image hosted somewhere 
  # ## get a VM that has cronR installed on it
  # vm <- gce_vm(vm, dynamic_image = )
  # 
  # cronR::cron_add()
  
  my_script <- "test.R"
  the_dockerfile <- containeRit::dockerfile(my_script, 
                          save_image = TRUE, 
                          image = gce_tag_container("gcer-scheduler", project = "gcer-public"))
  ## or use build triggers etc.
  docker_build(vm, the_dockerfile)
  
  
}