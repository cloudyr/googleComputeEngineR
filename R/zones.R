#' Returns the specified Zone resource. Get a list of available zones by making a list() request.
#' 
#' 
#' @seealso \href{https://developers.google.com/compute/docs/reference/latest/}{Google Documentation}
#' 
#' @details 
#' Authentication scopes used by this function are:
#' \itemize{
#'   \item https://www.googleapis.com/auth/cloud-platform
#' \item https://www.googleapis.com/auth/compute
#' \item https://www.googleapis.com/auth/compute.readonly
#' }
#' 
#' 
#' @param project Project ID for this request
#' @param zone Name of the zone resource to return
#' @importFrom googleAuthR gar_api_generator
#' @export
gce_get_zone <- function(project, 
                         zone) {
  
  url <- sprintf("https://www.googleapis.com/compute/v1/projects/%s/zones/%s", 
                 project, zone)
  # compute.zones.get
  f <- gar_api_generator(url, 
                         "GET", 
                         data_parse_function = function(x) x)
  f()
  
}


#' Retrieves the list of Zone resources available to the specified project.
#' 
#' 
#' @seealso \href{https://developers.google.com/compute/docs/reference/latest/}{Google Documentation}
#' 
#' @details 
#' Authentication scopes used by this function are:
#' \itemize{
#'   \item https://www.googleapis.com/auth/cloud-platform
#' \item https://www.googleapis.com/auth/compute
#' \item https://www.googleapis.com/auth/compute.readonly
#' }
#' 
#' 
#' @param project Project ID for this request

#' @param filter Sets a filter expression for filtering listed resources, in the form filter={expression}

#' @param maxResults The maximum number of results per page that should be returned

#' @param pageToken Specifies a page token to use
#' @importFrom googleAuthR gar_api_generator
#' @export
gce_list_zones <- function(project, 
                           filter = NULL, 
                           maxResults = NULL, 
                           pageToken = NULL) {
  
  
  url <- sprintf("https://www.googleapis.com/compute/v1/projects/%s/zones", project)
  
  pars <- list(filter = filter, 
               maxResults = maxResults, 
               pageToken = pageToken)
  pars <- rmNullObs(pars)
  # compute.zones.list
  f <- gar_api_generator(url, 
                         "GET", 
                         pars_args = pars, 
                         data_parse_function = function(x) x)
  
  f()
  
  
}



