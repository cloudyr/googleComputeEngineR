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