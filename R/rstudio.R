#' Creates a user on an RStudio templated instance
#' 
#' RStudio has users based on unix user accounts
#' 
#' @param instance An instance with RStudio installed via \link{gce_vm_template}
#' @param user The user to create
#' @param password The user password
#' @param container The rstudio container to add the user to
#' 
#' @return The instance
#' @export
gce_rstudio_adduser <- function(instance, user, password, 
                                container = "rstudio",
                                project = gce_get_global_project(),
                                zone = gce_get_global_zone()){
  
  ssh_au <- paste0("adduser ",
                    user,
                   " --gecos 'First Last,RoomNumber,WorkPhone,HomePhone' --disabled-password")
  
  docker_cmd(instance,
                     cmd = "exec",
                     args = c(container, ssh_au),
                     docker_opts = "")
  
  docker_cmd(instance,
                     "exec",
                     args = c(container, "ls /home/"))
  
  ## add user folder to host VM

  gce_rstudio_password(instance, 
                       user = user, 
                       password = password, 
                       container = container, 
                       project = project, 
                       zone = zone)
  
  gce_set_metadata(list(rstudio_users = c(gce_get_metadata(instance, "rstudio_users")$value), user), 
                   instance)
  
  instance
  
}

#' Changes password for a user on RStudio container
#' 
#' RStudio has users based on unix user accounts
#' 
#' @param instance An instance with RStudio installed via \link{gce_vm_template}
#' @param user The user to chnage the password for
#' @param password The user password
#' @param container The rstudio container to add the user to
#' 
#' @return The instance
#' @export
gce_rstudio_password <- function(instance, user, password, 
                                 container = "rstudio",
                                 project = gce_get_global_project(),
                                 zone = gce_get_global_zone()){
  
  ssh_ap <- paste0("sh -c 'echo ",user,":",password," | sudo chpasswd'")
  
  docker_cmd(instance,
                     cmd = "exec",
                     args = c(container, ssh_ap),
                     docker_opts = "")
  
  instance
  
}