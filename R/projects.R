#' Returns the specified Project resource.
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
#' @importFrom googleAuthR gar_api_generator
#' @export
gce_get_project <- function(project) {
  url <- sprintf("https://www.googleapis.com/compute/v1/projects/%s", project)
  # compute.projects.get
  f <- gar_api_generator(url, "GET", data_parse_function = function(x) x)
  f()
  
}