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
  zone <- f()
  
  structure(zone, class = "gce_zone")
  
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


#' Set global zone name
#'
#' Set a zone name used for this R session
#'
#' @param zone zone name you want this session to use by default, or a zone object
#'
#' @details
#'   This sets a zone to a global environment value so you don't need to
#' supply the zone argument to other API calls.
#'
#' @return The zone name (invisibly)
#'
#' @export
gce_global_zone <- function(zone){
  
  if(inherits(zone, "gce_zone")){
    zone <- zone$name
  }
  
  stopifnot(inherits(zone, "character"),
            length(zone) == 1)
  
  .gce_env$zone <- zone
  message("Set default zone name to '", zone,"'")
  return(invisible(.gce_env$zone))
  
}

#' Get global zone name
#'
#' zone name set this session to use by default
#'
#' @return zone name
#'
#' @details
#'   Set the zone name via \link{gce_global_zone}
#'
#' @family zone functions
#' @export
gce_get_global_zone <- function(){
  
  if(!exists("zone", envir = .gce_env)){
    stop("zone is NULL and couldn't find global zone name.
         Set it via gce_global_zone")
  }
  
  .gce_env$zone
  
  }
