#' Check if is a gce_zone_operation
#' @param x The object to test if class \code{gce_zone_operation}
#' @return TRUE or FALSE
#' @noRd
is.gce_zone_operation <- function(x){
  inherits(x, "gce_zone_operation")
}

as.zone_operation <- function(x){
  structure(x, class = c("gce_zone_operation", class(x)))
}

#' Check if is a gce_global_operation
#' @param x The object to test if class \code{gce_global_operation}
#' @return TRUE or FALSE
#' @noRd
is.gce_global_operation <- function(x){
  inherits(x, "gce_global_operation")
}

as.region_operation <- function(x){
  structure(x, class = c("gce_region_operation", class(x)))
}

#' Check if is a gce_region_operation
#' @param x The object to test if class \code{gce_region_operation}
#' @return TRUE or FALSE
#' @noRd
is.gce_region_operation <- function(x){
  inherits(x, "gce_region_operation")
}

as.global_operation <- function(x){
  structure(x, class = c("gce_global_operation", class(x)))
}

#' Deletes the specified Operations resource.
#' 
#' @seealso \href{https://developers.google.com/compute/docs/reference/latest/}{Google Documentation}
#' 
#' 
#' @param operation Name of the Operations resource to delete
#' 
#' @return TRUE if successful
#' 
#' @importFrom googleAuthR gar_api_generator
#' @export
gce_delete_op <- function(operation) {

  
  if(inherits(operation, 
              c("gce_global_operation", "gce_zone_operation","gce_region_operation"))){
    UseMethod("gce_delete_op", operation)
  } else {
    myMessage("No operation class found. Got: ", class(operation), level = 1)
    return(operation)
  }
  
}

#' Deletes the specified zone-specific Operations resource.
#' 
#' @seealso \href{https://developers.google.com/compute/docs/reference/latest/}{Google Documentation}
#' 
#' 
#' @param operation Name of the Operations resource to delete
#' 
#' @return The deleted operation
#' 
#' @importFrom googleAuthR gar_api_generator
#' @export
gce_delete_op.gce_zone_operation <- function(operation) {
  
  if(is.gce_zone_operation(operation)){
    url <- operation$selfLink
  } else {
    stop("Not a gce_zone_operation")
  }
  
  # compute.zoneOperations.delete
  f <- gar_api_generator(url, "DELETE", data_parse_function = function(x) x)
  
  suppressWarnings(out <- f())
  myMessage("Operation cancelled", level = 3)
  as.zone_operation(out)
  
}

#' Deletes the specified global Operations resource.
#' 
#' @seealso \href{https://developers.google.com/compute/docs/reference/latest/}{Google Documentation}
#' 
#' 
#' @param operation Name of the Operations resource to delete
#' 
#' @return The deleted operation
#' 
#' @importFrom googleAuthR gar_api_generator
#' @export
gce_delete_op.gce_global_operation <- function(operation) {
  
  if(is.gce_global_operation(operation)){
    url <- operation$selfLink
  } else {
    stop("Not a gce_global_operation")
  }
  
  # compute.zoneOperations.delete
  f <- gar_api_generator(url, "DELETE", data_parse_function = function(x) x)
  
  suppressWarnings(out <- f())
  myMessage("Operation cancelled", level = 3)
  as.zone_operation(out)
  
}

#' Retrieves the specified Operations resource.
#' 
#' s3 method dispatcher
#' 
#' @seealso \href{https://developers.google.com/compute/docs/reference/latest/}{Google Documentation}
#' 
#' @details 
#' 
#' S3 Methods for classes
#' \itemize{
#'   \item gce_get_op.gce_zone_operation
#'   \item gce_get_op.gce_global_operation
#'   \item gce_get_op.gce_region_operation
#'  } 
#' 
#' @param operation Name of the Operations resource to return
#' 
#' @importFrom googleAuthR gar_api_generator
#' @export
gce_get_op <- function(operation = .Last.value){
  
  if(inherits(operation, c("gce_global_operation", "gce_zone_operation","gce_region_operation"))){
    UseMethod("gce_get_op", operation)
  } else {
    myMessage("No operation class found. Got: ", class(operation), level = 1)
    return(operation)
  }

}

#' Retrieves the specified zone-specific Operations resource.
#' 
#' @seealso \href{https://developers.google.com/compute/docs/reference/latest/}{Google Documentation}
#' 
#' @param operation Name of the Operations resource to return
#' 
#' @importFrom googleAuthR gar_api_generator
#' @export
gce_get_op.gce_zone_operation <- function(operation) {
  
  if(is.gce_zone_operation(operation)){
    url <- operation$selfLink
  } else {
    stop("Not a gce_zone_operation")
  }
  
  # compute.zoneOperations.get
  f <- gar_api_generator(url, "GET", data_parse_function = function(x) x)
  out <- f()
  
  as.zone_operation(out)
}

#' Retrieves the specified global Operations resource.
#' 
#' @seealso \href{https://developers.google.com/compute/docs/reference/latest/}{Google Documentation}
#' 
#' @param operation Name of the Operations resource to return
#' 
#' @importFrom googleAuthR gar_api_generator
#' @export
gce_get_op.gce_global_operation <- function(operation) {
  
  if(is.gce_global_operation(operation)){
    url <- operation$selfLink
  } else {
    stop("Not class gce_global_operation")
  }
  
  # compute.zoneOperations.get
  f <- gar_api_generator(url, "GET", data_parse_function = function(x) x)
  out <- f()
  
  as.global_operation(out)
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



#' Wait for an operation to finish
#' 
#' Will periodically check an operation until its status is \code{DONE}
#' 
#' @param operation The operation object
#' @param wait Time in seconds between checks, default 3 seconds.
#' @param verbose Whether to give user feedback
#' @param timeout_tries Number of times to wait
#' 
#' @return The completed job object, invisibly
#' 
#' @export
gce_wait <- function(operation, wait = 3, verbose = TRUE, timeout_tries = 50){
  if(inherits(operation, "character")){
    stop("Use the job object instead of job$name")
  }
  
  if(operation$kind != "compute#operation"){
    myMessage("Not an operation, returning object")
    return(operation)
  }
  
  # stopifnot(operation$kind == "compute#operation")
  
  DO_IT <- TRUE
  tries <- 0
  
  myMessage("Starting operation...", level = 2)
  
  while(DO_IT){
    
    check <- gce_get_op(operation)
    # stopifnot(check$kind == "compute#operation")
    
    if(check$status == "DONE"){
      
      DO_IT <- FALSE
      
    } else if(check$status == "RUNNING"){
      
      if(verbose) myMessage("Operation running...", level = 3)
      
    } else {
      
      if(verbose) myMessage("Checking operation...", check$status, level = 3)
      
    }
    
    Sys.sleep(wait)
    tries <- tries + 1
    if(tries > timeout_tries){
      myMessage("Timeout reached in operation")
      check$error$errors <- "Timeout reached in operation"
      DO_IT <- FALSE
    }
    
  }
  
  if(verbose && !is.null(check$endTime)) 
    myMessage("Operation complete in ", 
              format(timestamp_to_r(check$endTime) - timestamp_to_r(check$insertTime)), level = 3)
  
  if(!is.null(check$error)){
    errors <- check$error$errors
    e.m <- paste(vapply(errors, print, character(1)), collapse = " : ", sep = " \n")
    warning("# Error: ", e.m)
    warning("# HTTP Error: ", check$httpErrorStatusCode, check$httpErrorMessage)
  }
  
  check
}
