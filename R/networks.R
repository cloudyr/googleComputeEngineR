#' Make a network interface for instance creation
#' 
#' @param network Name of network resource
#' @param project Project ID for this request
#' 
#' @return A Network object
gce_make_network <- function(network = "default",
                             project = gce_get_global_project()){
  
  net <- gce_get_network(network, project = project)
  
  structure(
    list(
      list(
        network = net$selfLink
      )
    ),
    class = c("list","gce_networkInterface")
  )
  
}

#' Returns the specified network.
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
#' @param project Project ID for this request
#' @param network Name of the network to return
#' @importFrom googleAuthR gar_api_generator
#' @export
gce_get_network <- function(network,
                            project = gce_get_global_project()) {
  url <- sprintf("https://www.googleapis.com/compute/v1/projects/%s/global/networks/%s", 
                 project, network)
  # compute.networks.get
  f <- gar_api_generator(url, "GET", data_parse_function = function(x) x)
  f()
  
}

#' Retrieves the list of networks available to the specified project.
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
#' @param project Project ID for this request
#' @param filter Sets a filter expression for filtering listed resources, in the form filter={expression}
#' @param maxResults The maximum number of results per page that should be returned
#' @param pageToken Specifies a page token to use
#' @importFrom googleAuthR gar_api_generator
#' @export
gce_list_networks <- function(filter = NULL, 
                              maxResults = NULL, 
                              pageToken = NULL, 
                              project = gce_get_global_project()) {
  
  url <- sprintf("https://www.googleapis.com/compute/v1/projects/%s/global/networks", 
                 project)
  # compute.networks.list
  pars <- list(filter = filter, maxResults = maxResults, 
               pageToken = pageToken)
  pars <- rmNullObs(pars)
  
  f <- gar_api_generator(url, "GET", pars_args = pars, data_parse_function = function(x) x)
  f()
  
}