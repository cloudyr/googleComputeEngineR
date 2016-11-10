#' Add a package to a running OpenCPU instance
#' 
#' Add a package to an OpenCPU VM installed via \link{gce_vm_template}
#' 
#' @param instance The instance running Shiny
#' @param cran_packages A character vector of CRAN packages to be installed
#' @param github_packages A character vector of devtools packages to be installed
#' 
#' @return The instance
#' @export
gce_opencpu_addpackage <- function(instance, cran_packages, github_packages){
  
  ## stop docker container?
  
  gce_install_packages_docker(instance,
                              docker_image = "opencpu",
                              cran_packages = cran_packages,
                              github_packages = github_packages)
  
  ## add individual functions to a custom package?
  
  ## just use github?
  
}