#' Construct a machineType URL
#' 
#' @param zone zone for URL
#' @param predefined_type A predefined machine type from \link{gce_list_machinetype}
#' @param cpus If not defining \code{predefined_type}, the number of CPUs
#' @param memory If not defining \code{predefined_type}, amount of memory
#' 
#' @details 
#' 
#' \code{cpus} must be in multiples of 2 up to 32
#' \code{memory} must be in multiples of 256
#' 
#' @return A url for use in instance creation
#' @export
gce_make_machinetype_url <- function(predefined_type = NULL,
                                     cpus = NULL,
                                     memory = NULL,
                                     zone = gce_get_global_zone()){
  
  if(is.null(predefined_type)){
    
    assertthat::assert_that(
      !is.null(cpus),
      !is.null(memory),
      is.numeric(cpus),
      is.numeric(memory),
      (cpus %% 2 == 0),
      cpus < 33,
      (memory %% 256 == 0)
    )
    
    out <- sprintf("zones/%s/machineTypes/custom-%s-%s", zone, cpus, memory)
    
  } else {
    
    assertthat::assert_that(
      assertthat::is.string(predefined_type)
    )
    
    out <- sprintf("zones/%s/machineTypes/%s", zone, predefined_type)
    
  }
  
  out
  
}





#' Retrieves an aggregated list of machine types from all zones.
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
gce_list_machinetype_all <- function(filter = NULL, 
                                     maxResults = NULL, 
                                     pageToken = NULL,
                                     project = gce_get_global_project()) {
  
  url <- sprintf("https://www.googleapis.com/compute/v1/projects/%s/aggregated/machineTypes", 
                 project)
  
  pars <- list(filter = filter, 
               maxResults = maxResults, 
               pageToken = pageToken)
  pars <- rmNullObs(pars)
  # compute.machineTypes.aggregatedList
  f <- gar_api_generator(url, 
                         "GET", 
                         pars_args = pars, 
                         data_parse_function = function(x) x)
  f()
  
}

#' Returns the specified machine type.
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
#' @param zone The name of the zone for this request
#' @param machineType Name of the machine type to return
#' @importFrom googleAuthR gar_api_generator
#' @export
gce_get_machinetype <- function(machineType, 
                                project = gce_get_global_project(), 
                                zone = gce_get_global_zone()) {
  
  url <- sprintf("https://www.googleapis.com/compute/v1/projects/%s/zones/%s/machineTypes/%s", 
                 project, zone, machineType)
  
  # compute.machineTypes.get
  f <- gar_api_generator(url, 
                         "GET", 
                         data_parse_function = function(x) x)
  f()
  
}

#' Retrieves a list of machine types available to the specified project.
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
#' @param filter Sets a filter expression for filtering listed resources, in the form filter={expression}
#' @param maxResults The maximum number of results per page that should be returned
#' @param pageToken Specifies a page token to use
#' @param project Project ID for this request
#' @param zone The name of the zone for this request
#' 
#' 
#' @importFrom googleAuthR gar_api_generator
#' @export
gce_list_machinetype <- function(filter = NULL, 
                                 maxResults = NULL, 
                                 pageToken = NULL,
                                 project = gce_get_global_project(), 
                                 zone = gce_get_global_zone()) {
  
  
  
  url <- sprintf("https://www.googleapis.com/compute/v1/projects/%s/zones/%s/machineTypes", 
                 project, zone)
  
  pars <- list(filter = filter, 
               maxResults = maxResults, 
               pageToken = pageToken)
  pars <- rmNullObs(pars)
  # compute.machineTypes.list
  f <- gar_api_generator(url, 
                         "GET", 
                         pars_args = pars, 
                         data_parse_function = function(x) x)
  out <- f()
  
  structure(
    out,
    class = c("machineTypeList", "list")
  )
  
}

#' Changes the machine type for a stopped instance to the machine type specified in the request.
#' 
#' 
#' @seealso \href{https://developers.google.com/compute/docs/reference/latest/}{Google Documentation}
#' 
#' @details 
#' Authentication scopes used by this function are:
#' \itemize{
#'   \item https://www.googleapis.com/auth/cloud-platform
#' \item https://www.googleapis.com/auth/compute
#' }
#' 
#' @inheritParams gce_make_machinetype_url
#' @param instance Name of the instance resource to change
#' @param project Project ID for this request, default as set by \link{gce_get_global_project}
#' @param zone The name of the zone for this request, default as set by \link{gce_get_global_zone}
#' @importFrom googleAuthR gar_api_generator
#' 
#' @return A zone operation job
#' @export
gce_set_machinetype <- function(predefined_type,
                                cpus,
                                memory, 
                                instance,
                                project = gce_get_global_project(), 
                                zone = gce_get_global_zone()) {
  
  if(missing(predefined_type)){
    stopifnot(all(!missing(cpus), !missing(memory)))
  }
  
  machineType <- gce_make_machinetype_url(predefined_type = predefined_type,
                                          cpus = cpus,
                                          memory = memory,
                                          zone = zone)
  
  url <- 
    sprintf("https://www.googleapis.com/compute/v1/projects/%s/zones/%s/instances/%s/setMachineType", 
                 project, zone, instance)
  
  the_machine <- list(
    machineType = machineType
  )
  # compute.instances.setMachineType
  f <- gar_api_generator(url, 
                         "POST", 
                         data_parse_function = function(x) x)
  
  f(the_body = the_machine)
  
}