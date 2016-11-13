#' Add a package to a running OpenCPU instance
#' 
#' Add a package to an OpenCPU VM installed via \link{gce_vm_template}
#' 
#' @param instance The instance running Shiny
#' @param cran_packages A character vector of CRAN packages to be installed
#' @param github_packages A character vector of devtools packages to be installed
#' @param auth_token A github PAT token, if needed for private Github packages
#' 
#' @return The instance
#' @export
gce_opencpu_addpackage <- function(instance, 
                                   cran_packages = NULL, 
                                   github_packages = NULL, 
                                   auth_token = NULL){
  
  gce_container_addpackage(instance = instance, 
                           container = "opencpu",
                           cran_packages = cran_packages,
                           github_packages = github_packages,
                           auth_token = auth_token)
  
}