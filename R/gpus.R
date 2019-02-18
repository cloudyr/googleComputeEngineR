#' A deeplearning templated VM for use with gce_vm_template
#' @noRd
set_gpu_template <- function(dots){
  
  dots <- do.call(gce_vm_gpu, 
                  args = c(list(return_dots=TRUE), dots))
  
  # these are set explicity in gce_vm_container, so avoiding double-args
  dots$image_project <- NULL
  dots$image_family <- NULL
  
  dots


}


#' Retrieves a list GPUs you can attach to an instance
#' 
#' @seealso \href{https://cloud.google.com/compute/docs/gpus/#introduction}{GPUs on Compute Engine}
#' 
#' 
#' @details 
#' 
#' To filter you need a single string in the form \code{field_name eq|ne string} 
#'   e.g. \code{gce_list_instances("status eq RUNNING")} where \code{eq} is 'equals' and \code{ne} is 'not-equals'.
#' 
#' @param filter Sets a filter expression for filtering listed resources, in the form filter={expression}
#' @param maxResults The maximum number of results per page that should be returned
#' @param pageToken Specifies a page token to use
#' @param project Project ID for this request
#' @param zone The name of the zone for this request
#' 
#' @importFrom googleAuthR gar_api_generator
#' @family GPU instances
#' @export
gce_list_gpus <- function(filter = NULL, 
                          maxResults = NULL, 
                          pageToken = NULL,
                          project = gce_get_global_project(), 
                          zone = gce_get_global_zone()) {
  
  url <- sprintf("https://www.googleapis.com/compute/v1/projects/%s/zones/%s/acceleratorTypes", 
                 project, zone)
  pars <- list(filter = filter, 
               maxResults = maxResults, 
               pageToken = pageToken)
  pars <- rmNullObs(pars)
  # gpu.instances.list
  f <- gar_api_generator(url, 
                         "GET", 
                         pars_args = pars, 
                         data_parse_function = function(x) x)
  out <- f()
  
  structure(
    out,
    class = c("gce_gpuList", class(out))
  )
  
}

#' Launch a GPU enabled instance
#' 
#' Helper function that fills in some defaults passed to \link{gce_vm}
#' 
#' @param ... arguments passed to \link{gce_vm}
#' @param return_dots Only return the settings, do not call \link{gce_vm}
#' 
#' @details 
#' 
#' If not specified, this function will enter defaults to get a GPU instance up and running.
#' 
#' \itemize{
#'   \item \code{acceleratorCount: 1}
#'   \item \code{acceleratorType: "nvidia-tesla-p4"}
#'   \item \code{scheduling: list(onHostMaintenance = "TERMINATE", automaticRestart = TRUE)}
#'   \item \code{image_project: "deeplearning-platform-release"}
#'   \item \code{image_family: "tf-latest-cu92"}
#'   \item \code{predefined_type: "n1-standard-8"}
#'   \item \code{metadata: "install-nvidia-driver" = "True"}
#'  }
#' 
#' @family GPU instances
#' @export
#' 
#' @seealso \href{Deep Learning VM}{https://cloud.google.com/deep-learning-vm/docs/quickstart-cli}
#' 
#' @return A VM object
gce_vm_gpu <- function(..., return_dots = FALSE){
  
  dots <- list(...)
  
  if(is.null(dots$scheduling)){
    dots$scheduling <- list(
      onHostMaintenance = "TERMINATE",
      automaticRestart = TRUE
    )
  }
  
  if(is.null(dots$acceleratorCount)){
    dots$acceleratorCount <- 1
  }
  
  if(is.null(dots$acceleratorType)){
    dots$acceleratorType <- "nvidia-tesla-p4"
  }
  
  if(is.null(dots$image_project)){
    dots$image_project <- "deeplearning-platform-release"
  }
  
  if(is.null(dots$image_family)){
    dots$image_family <- "tf-latest-cu92"
  }
  
  if(is.null(dots$predefined_type)){
    dots$predefined_type <- "n1-standard-8"
  }
  
  dots <- modify_metadata(dots, list("install-nvidia-driver" = "True"))
  
  myMessage("Launching VM with GPU support. If using docker_cmd() functions make sure to include nvidia=TRUE parameter", level = 3)
  
  if(return_dots){
    return(dots)
  }
  
  do.call(gce_vm,
          args = dots)
  
}

#' Check GPU installed ok
#' 
#' @param vm The instance to check
#' @export
#' @family GPU instances
#' 
#' @seealso \url{https://cloud.google.com/compute/docs/gpus/add-gpus#verify-driver-install}
#' 
#' @return The NVIDIA-SMI output via ssh
gce_check_gpu <- function(vm){
  
  gce_ssh(vm, "nvidia-smi")
  
}