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
gce_get_project <- function(project = gce_get_global_project()) {
  url <- sprintf("https://www.googleapis.com/compute/v1/projects/%s", project)
  # compute.projects.get
  f <- gar_api_generator(url, "GET", data_parse_function = function(x) x)
  
  proj <- f()
  
  structure(proj, class = "gce_project")
  
}


#' Set global project name
#'
#' Set a project name used for this R session
#'
#' @param project project name you want this session to use by default, or a project object
#'
#' @details
#'   This sets a project to a global environment value so you don't need to
#' supply the project argument to other API calls.
#'
#' @return The project name (invisibly)
#'
#' @export
gce_global_project <- function(project = gce_get_global_project()){
  
  if(inherits(project, "gce_project")){
    project <- project$name
  }
  
  assertthat::assert_that(
    assertthat::is.string(project),
    is.lower_hypen(project)
  )
  
  .gce_env$project <- project
  message("Set default project name to '", project,"'")
  return(invisible(.gce_env$project))
  
}

#' Get global project name
#'
#' Project name set this session to use by default
#'
#' @return Project name
#'
#' @details
#'   Set the project name via \link{gce_global_project}
#'
#' @family project functions
#' @export
gce_get_global_project <- function(){
  
  if(!exists("project", envir = .gce_env)){
    stop("Project is NULL and couldn't find global project name.
         Set it via gce_global_project")
  }
  
  .gce_env$project
  
  }