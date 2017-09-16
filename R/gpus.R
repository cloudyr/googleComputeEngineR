#' Retrieves a list GPUs you can attach to an instance
#' 
#' @seealso \href{https://cloud.google.com/compute/docs/gpus/add-gpus#create-new-gpu-instance}{Google Documentation}
#' 
#' 
#' @details 
#' Authentication scopes used by this function are:
#' \itemize{
#'   \item https://www.googleapis.com/auth/cloud-platform
#' \item https://www.googleapis.com/auth/compute
#' \item https://www.googleapis.com/auth/compute.readonly
#' }
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
  
  warning("This is using the beta version of the Google Compute Engine API and may not work in the future.")
  url <- sprintf("https://www.googleapis.com/compute/beta/projects/%s/zones/%s/acceleratorTypes", 
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
#' 
#' @details 
#' 
#' If not specified, this function will enter defaults to get a GPU instance up and running.
#' 
#' \itemize{
#'   \item \code{use_beta: TRUE}
#'   \item \code{acceleratorCount: 1}
#'   \item \code{acceleratorType: "nvidia-tesla-k80"}
#'   \item \code{scheduling: list(onHostMaintenance = "terminate", automaticRestart = TRUE)}
#'   \item \code{image_project: "centos-cloud"}
#'   \item \code{image_family: "centos-7"}
#'   \item \code{predefined_type: "n1-standard-1"}
#'   \item \code{metadata: the contents of the the startup script in 
#'     system.file("startupscripts", "centos7cuda8.sh", package = "googleComputeEngineR")}
#'  }
#' 
#' @family GPU instances
#' @export
#' 
#' @return A VM object
gce_vm_gpu <- function(...){
  
  dots <- list(...)
  
  if(is.null(dots$scheduling)){
    dots$scheduling <- list(
      onHostMaintenance = "terminate",
      automaticRestart = TRUE
    )
  }
  
  if(is.null(dots$acceleratorCount)){
    
    dots$acceleratorCount <- 1
    dots$acceleratorType <- "nvidia-tesla-k80"
  }
  
  if(is.null(dots$image_project)){
    dots$image_project <- "centos-cloud"
  }
  
  if(is.null(dots$image_family)){
    dots$image_family <- "centos-7"
  }
  
  if(is.null(dots$predefined_type)){
    dots$predefined_type <- "n1-standard-1"
  }
  
  dots$use_beta <- TRUE
  
  if(is.null(dots$metadata)){
    startup_file <- system.file("startupscripts", "centos7cuda8.sh", package = "googleComputeEngineR")
    dots$metadata <- list("startup-script" = readChar(startup_file, 
                                                      nchars = file.info(startup_file)$size))
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