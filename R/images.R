#' Returns the specified image.
#' 
#' @seealso
#'   \href{https://developers.google.com/compute/docs/reference/latest/}{Google
#'   Documentation}
#'   
#' @details Authentication scopes used by this function are: \itemize{ \item
#' https://www.googleapis.com/auth/cloud-platform \item
#' https://www.googleapis.com/auth/compute \item
#' https://www.googleapis.com/auth/compute.readonly }
#' 
#' You may want to use \link{gce_get_image_family} instead to ensure the most up to date image is used.
#' 
#' @param project Project ID for this request
#' @param image Name of the image resource to return
#' @importFrom googleAuthR gar_api_generator
#' @export
gce_get_image <- function(project, image) {
  
  url <- sprintf("https://www.googleapis.com/compute/v1/projects/%s/global/images/%s", 
                 project, image)
  
  # compute.images.get
  f <- gar_api_generator(url, "GET", data_parse_function = function(x) x)
  f()
  
}

#' Returns the latest image that is part of an image family and is not deprecated.
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
#' @param family Name of the image family to search for
#' @importFrom googleAuthR gar_api_generator
#' @export
gce_get_image_family <- function(project, family) {
  
  url <- sprintf("https://www.googleapis.com/compute/v1/projects/%s/global/images/family/%s", 
                 project, family)
  # compute.images.getFromFamily
  f <- gar_api_generator(url, "GET", data_parse_function = function(x) x)
  f()
  
}

#' Retrieves the list of private images available to the specified project. 
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
#' If you want to get a list of publicly-available images, 
#'  use this method to make a request to the respective image project, 
#'  such as debian-cloud, windows-cloud or google-containers.
#' 
#' 
#' @param project Project ID for this request
#' @param filter Sets a filter expression for filtering listed resources, in the form filter={expression}
#' @param maxResults The maximum number of results per page that should be returned
#' @param pageToken Specifies a page token to use
#' @importFrom googleAuthR gar_api_generator
#' @export
gce_list_images <- function(project, 
                            filter = NULL, 
                            maxResults = NULL, 
                            pageToken = NULL) {
  
  url <- sprintf("https://www.googleapis.com/compute/v1/projects/%s/global/images", 
                 project)
  
  pars <- list(filter = filter, maxResults = maxResults, 
               pageToken = pageToken)
  pars <- rmNullObs(pars)
  
  # compute.images.list
  f <- gar_api_generator(url, 
                         "GET", 
                         pars_args = pars, 
                         data_parse_function = function(x) x)
  f()
  
}