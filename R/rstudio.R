#' Creates a user on an RStudio templated instance
#' 
#' RStudio has users based on unix user accounts
#' 
#' @param instance An instance with RStudio installed via \link{gce_vm_template}
#' @param user The user to create
#' @param password The user password
#' 
#' @return The instance
#' @export
gce_rstudio_adduser <- function(instance, user, password){
  
  # ssh_au <- paste0("adduser ",
  #                   user, 
  #                  " --gecos 'First Last,RoomNumber,WorkPhone,HomePhone' --disabled-password")
  # 
  # ssh_ap <- paste0("echo '",user,":",password,"' | chpasswd")
  
  #stop container and relaunch with new user
  
  # harbor::docker_cmd(instance, 
  #                    cmd = "exec",
  #                    args = c("rstudio", paste0(ssh_au, " && ", ssh_ap)),
  #                    docker_opts = "")
  
  gce_set_metadata(list(rstudio_users = c(gce_get_metadata(instance, "rstudio_users")$value), user), 
                   instance)
  
  instance
  
}