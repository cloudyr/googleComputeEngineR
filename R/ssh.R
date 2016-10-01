#' Open a cloud SSH browser for an instance
#' 
#' This will open an SSH from the browser session if \code{getOption("browser")} is not NULL
#' 
#' You will need to login the first time with an email that has access to the instance.
#' 
#' @seealso \url{https://cloud.google.com/compute/docs/ssh-in-browser}
#' 
#' @param instance Name of the instance resource
#' @param project Project ID for this request, default as set by \link{gce_get_global_project}
#' @param zone The name of the zone for this request, default as set by \link{gce_get_global_zone}
#' 
#' @return Opens a browser window to the SSH session, returns the SSH URL.
#' @importFrom utils browseURL
#' @export
gce_ssh_browser <- function(instance,
                            project = gce_get_global_project(), 
                            zone = gce_get_global_zone()){
  
  ssh_url <- sprintf("https://ssh.cloud.google.com/projects/%s/zones/%s/instances/%s?projectNumber=%s",
                     project, zone, instance, project)
  
  if(!is.null(getOption("browser"))){
    utils::browseURL(ssh_url)
  }

  ssh_url
  
}