#' Extract metadata from an instance object
#' 
#' @param instance instance to get metadata from
#' @param key optional metadata key to filter metadata result
#' 
#' @return data.frame $key and $value of metadata or NULL
#' @export
gce_get_metadata <- function(instance, key = NULL){
  
  instance <- as.gce_instance(instance)
  
  if(!is.null(instance$metadata$items)){
    out <- instance$metadata$items
    if(!is.null(key)){
      out <- out[out$key == key,]
      if(!nrow(out) > 0){
        out <- NULL
      }
    }
  } else {
    out <- NULL
  }
  
  out
  
}


#' Metadata Object
#' 
#' 
#' @param items A named list of key = value pairs
#' 
#' @return Metadata object
#' 
#' @family Metadata functions
#' @keywords internal
Metadata <- function(items) {
  
  if(is.null(items)) return(NULL)
  
  testthat::expect_named(items)
  
  key_values <- lapply(names(items), function(x) list(key = jsonlite::unbox(x), 
                                                      value = jsonlite::unbox(items[[x]])))
  
  structure(list(items = key_values), 
            class = c("gar_Metadata", "list"))
}

#' Sets metadata for the specified instance to the data included in the request.
#' 
#' Set, change and append metadata for an instance.
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
#' To append to existing metadata passed a named list.
#' 
#' To change existing metadata pass a named list with the same key and modified value you will change.
#' 
#' To delete metadata pass an empty string \code{""} with the same key
#' 
#' @param metadata A named list of metadata key/value pairs to assign to this instance
#' @param instance Name of the instance scoping this request
#' @param project Project ID for this request, default as set by \link{gce_get_global_project}
#' @param zone The name of the zone for this request, default as set by \link{gce_get_global_zone}
#' @importFrom googleAuthR gar_api_generator
#' @importFrom utils modifyList
#' @importFrom stats setNames
#' @family Metadata functions
#' @export
gce_set_metadata <- function(metadata, 
                             instance, 
                             project = gce_get_global_project(), 
                             zone = gce_get_global_zone()) {

  ## refetch to ensure latest version of metadata fingerprint
  ins <- gce_get_instance(instance)
  
  url <- sprintf("https://www.googleapis.com/compute/v1/projects/%s/zones/%s/instances/%s/setMetadata", 
                 project, zone, as.gce_instance_name(ins))
  
  meta_now <- ins$metadata$items
  ## turn data.frame back into named list
  meta_now_nl <- setNames(lapply(meta_now$key, function(x) meta_now[meta_now$key == x, "value"]), 
                          meta_now$key)
  
  meta <- Metadata(modifyList(meta_now_nl, metadata))
  ## need current fingerprint to allow modification
  meta$fingerprint <- ins$metadata$fingerprint
  
  stopifnot(inherits(meta, "gar_Metadata"))
  # compute.instances.setMetadata  
  f <- gar_api_generator(url, "POST", data_parse_function = function(x) x)

  out <- f(the_body = meta)
  as.zone_operation(out)
  
}