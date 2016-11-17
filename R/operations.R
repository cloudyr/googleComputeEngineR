#' Check if is a gce_zone_operation
#' @param x The object to test if class \code{gce_zone_operation}
#' @return TRUE or FALSE
#' @export
is.gce_zone_operation <- function(x){
  inherits(x, "gce_zone_operation")
}

# sets operation class
as.zone_operation <- function(x){
  structure(x, class = c("gce_zone_operation", class(x)))
}

#' Deletes the specified zone-specific Operations resource.
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
#' @param operation Name of the Operations resource to delete
#' @param project Project ID for this request
#' @param zone Name of the zone for this request
#' 
#' @return TRUE if successful
#' 
#' @importFrom googleAuthR gar_api_generator
#' @export
gce_delete_zone_op <- function(operation,
                               project = gce_get_global_project(), 
                               zone = gce_get_global_zone() ) {
  url <- sprintf("https://www.googleapis.com/compute/v1/projects/%s/zones/%s/operations/%s", 
                 project, zone, operation)
  # compute.zoneOperations.delete
  f <- gar_api_generator(url, "DELETE", data_parse_function = function(x) x)
  
  suppressWarnings(out <- f())
  myMessage("Operation cancelled", level = 3)
  as.zone_operation(out)
  
}

#' Retrieves the specified zone-specific Operations resource.
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
#' @param operation Name of the Operations resource to return
#' @param project Project ID for this request
#' @param zone Name of the zone for this request
#' 
#' @importFrom googleAuthR gar_api_generator
#' @export
gce_get_zone_op <- function(operation,
                            project = gce_get_global_project(), 
                            zone = gce_get_global_zone()) {
  
  if(is.gce_zone_operation(operation)){
    operation <- operation$name
  }
  
  url <- sprintf("https://www.googleapis.com/compute/v1/projects/%s/zones/%s/operations/%s", 
                 project, zone, operation)
  # compute.zoneOperations.get
  f <- gar_api_generator(url, "GET", data_parse_function = function(x) x)
  out <- f()
  
  as.zone_operation(out)
}

#' Retrieves a list of Operation resources contained within the specified zone.
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
#' @param zone Name of the zone for request
#' 
#' @importFrom googleAuthR gar_api_generator
#' @export
gce_list_zone_op <- function(filter = NULL, 
                             maxResults = NULL,
                             pageToken = NULL,
                             project = gce_get_global_project(), 
                             zone = gce_get_global_zone()) {
  url <- sprintf("https://www.googleapis.com/compute/v1/projects/%s/zones/%s/operations", 
                 project, zone)
  
  pars <- list(filter = filter, 
               maxResults = maxResults, 
               pageToken = pageToken)
  pars <- rmNullObs(pars)
  # compute.zoneOperations.list
  f <- gar_api_generator(url, 
                         "GET", 
                         pars_args = pars, 
                         data_parse_function = function(x) x)
  f()
  
}

#' @rdname gce_check_zone_op
#' @export
gce_wait <- function(operation, wait = 3, verbose = TRUE){
  gce_check_zone_op(operation = operation, 
                    wait = wait, 
                    verbose = verbose)
}

#' Wait for an operation to finish
#' 
#' Will periodically check an operation until its status is \code{DONE}
#' 
#' @param operation The operation object or name
#' @param wait Time in seconds between checks, default 3 seconds.
#' @param verbose Whether to give user feedback
#' 
#' @return The completed job object, invisibly
#' 
#' @export
gce_check_zone_op <- function(operation, wait = 3, verbose = TRUE){
  
  if(inherits(operation, "character")){
    job_name <- operation
  } else if(operation$kind == "compute#operation"){
    job_name <- operation$name
  } else {
    myMessage("Operation was not a compute#operation or name, returning object")
    return(operation)
  }
  
  testthat::expect_type(job_name, "character")
  testthat::expect_true(grepl("^operation-",job_name))
  
  DO_IT <- TRUE
  
  myMessage("Starting operation...", level = 2)
  
  while(DO_IT){
    
    check <- gce_get_zone_op(job_name)
    testthat::expect_equal(check$kind, "compute#operation")
    check
    
    if(check$status == "DONE"){
      
      DO_IT <- FALSE
      
    } else if(check$status == "RUNNING"){
      
      if(verbose) myMessage("Operation running...", level = 3)

    } else {
      
      if(verbose) myMessage("Checking operation...", check$status, level = 3)
      
    }
    
    Sys.sleep(wait)
    
  }
  
  if(verbose) 
    myMessage("Operation complete in ", 
        format(timestamp_to_r(check$endTime) - timestamp_to_r(check$insertTime)), level = 3)
  
  if(!is.null(check$error)){
    errors <- check$error$errors
    e.m <- paste(vapply(errors, print, character(1)), collapse = " : ", sep = " \n")
    warning("# Error: ", e.m)
    warning("# HTTP Error: ", check$httpErrorStatusCode, check$httpErrorMessage)
  }
  
  as.zone_operation(check)
}
