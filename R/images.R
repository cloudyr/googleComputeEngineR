#' Make initial disk image object
#' 
#' @param image_project Project ID of where the image lies
#' @param image Name of the image resource to return
#' @param family Name of the image family to search for
#' 
#' @return The selfLink of the image object
#' @export
gce_make_image_source_url <- function(image_project,
                                      image = NULL,
                                      family = NULL){
  
  if(is.null(image)){
    stopifnot(!is.null(family))
  }
  
  if(is.null(image)){
    img_obj <- gce_get_image_family(image_project, family)
  } else {
    img_obj <- gce_get_image(image_project, image)
  }
  
  ## extract the partial URL
  gsub("https://www.googleapis.com/compute/v1/","",img_obj$selfLink)
  
}

#' Returns the specified image.
#' 
#' @seealso
#'   \href{https://cloud.google.com/compute/docs/images}{Google
#'   Documentation}
#'   
#' @details Authentication scopes used by this function are: \itemize{ \item
#' https://www.googleapis.com/auth/cloud-platform \item
#' https://www.googleapis.com/auth/compute \item
#' https://www.googleapis.com/auth/compute.readonly }
#' 
#' You may want to use \link{gce_get_image_family} instead to ensure the most up to date image is used.
#' 
#' @param image_project Project ID of where the image lies
#' @param image Name of the image resource to return
#' @importFrom googleAuthR gar_api_generator
#' @export
gce_get_image <- function(image_project, image) {
  
  url <- sprintf("https://www.googleapis.com/compute/v1/projects/%s/global/images/%s", 
                 image_project, image)
  
  # compute.images.get
  f <- gar_api_generator(url, "GET", data_parse_function = function(x) x)
  f()
  
}

#' Returns the latest image that is part of an image family and is not deprecated.
#' 
#' @seealso \href{https://cloud.google.com/compute/docs/images}{Google Documentation}
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
#' @param image_project Project ID for this request
#' @param family Name of the image family to search for
#' @importFrom googleAuthR gar_api_generator
#' @export
gce_get_image_family <- function(image_project, family) {
  
  url <- sprintf("https://www.googleapis.com/compute/v1/projects/%s/global/images/family/%s", 
                 image_project, family)
  # compute.images.getFromFamily
  f <- gar_api_generator(url, "GET", data_parse_function = function(x) x)
  f()
  
}

#' Retrieves the list of private images available to the specified project. 
#' 
#' 
#' @seealso \href{https://cloud.google.com/compute/docs/images}{Google Documentation}
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
#' @param image_project Project ID for this request
#' @param filter Sets a filter expression for filtering listed resources, in the form filter={expression}
#' @param maxResults The maximum number of results per page that should be returned
#' @param pageToken Specifies a page token to use
#' @importFrom googleAuthR gar_api_generator
#' @export
gce_list_images <- function(image_project, 
                            filter = NULL, 
                            maxResults = NULL, 
                            pageToken = NULL) {
  
  url <- sprintf("https://www.googleapis.com/compute/v1/projects/%s/global/images", 
                 image_project)
  
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