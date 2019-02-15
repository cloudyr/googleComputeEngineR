#' Turn metadata into an environment argument
#' 
#' This turns instance metadata into an environment argument R (and other software) can see.  
#'   Only works on a running instance. 
#' 
#' @param key The metadata key.  Pass "" to list the keys
#' 
#' @return The metadata key value, if successful
#' @export
gce_metadata_env <- function(key){
  
  call_url <- sprintf("http://metadata.google.internal/computeMetadata/v1/instance/attributes/%s", 
                      key)
  req <- tryCatch(httr::GET(call_url, httr::add_headers(`Metadata-Flavor` = "Google")),
                  error = function(ex){
                    myMessage("Not detected as being on Google Compute Engine", 
                              level = 2)
                    return(NULL)
                  })
                  
  value <- httr::content(req, as = "text", encoding = "UTF-8")
  
  if(grepl("Error 404",value)){
    stop("404 for metdata key ", key)
  }
  
  if(key != ""){
    myMessage("Setting environment value: ", key, "=", value, level=3)
    args = list(value)
    names(args) = key
    do.call(Sys.setenv, args)
  }
  
  value
  
}

#' Return dots$metadata modified if needed
#' @noRd
#' @import assertthat
modify_metadata <- function(dots, new_metadata){
  assert_that(is.list(new_metadata),
              !is.null(names(new_metadata)))
  
  if(!is.null(dots$metadata)){
    dots$metadata <- c(new_metadata,
                       dots$metadata)
  } else {
    dots$metadata <- new_metadata
  }
  
  dots
}


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
#' @import assertthat
Metadata <- function(items) {
  
  if(is.null(items)) return(NULL)
  
  assert_that(!is.null(names(items)))
  
  key_values <- lapply(names(items), function(x) list(key = jsonlite::unbox(x), 
                                                      value = jsonlite::unbox(items[[x]])))
  
  structure(list(items = key_values), 
            class = c("gar_Metadata", "list"))
}

#' Sets metadata for the specified instance or projectwise to the data included in the request.
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
#' @param instance Name of the instance scoping this request. If "project-wide" will set the metadata project wide, available to all instances
#' @param project Project ID for this request, default as set by \link{gce_get_global_project}
#' @param zone The name of the zone for this request, default as set by \link{gce_get_global_zone}
#' @importFrom googleAuthR gar_api_generator
#' @importFrom utils modifyList
#' @importFrom stats setNames
#' @family Metadata functions
#' @export
#' @examples 
#' 
#' \dontrun{
#'  # Use "project-wide" to set "enable-oslogin" = "TRUE" to take advantage of OS Login.
#'  # But you won't be able to login via SSH if you do
#'  gce_set_metadata(list("enable-oslogin" = "TRUE"), instance = "project-wide")
#'  
#'  # enable google logging
#'  gce_set_metadata(list("google-logging-enabled"="True"), instance = "project-wide")
#' }
#'  
gce_set_metadata <- function(metadata, 
                             instance, 
                             project = gce_get_global_project(), 
                             zone = gce_get_global_zone()) {
  
  instance <- if(is.gce_instance(instance)) instance$name else instance
  
  if(instance == "project-wide"){
    pw_obj <- gce_get_metadata_project(project)
    meta_now <- pw_obj$commonInstanceMetadata$items
    fingerprint <- pw_obj$commonInstanceMetadata$fingerprint
    url <- sprintf("https://www.googleapis.com/compute/v1/projects/%s/setCommonInstanceMetadata",
                   project)
  } else {
    ## refetch to ensure latest version of metadata fingerprint
    ins <- gce_get_instance(instance, project = project, zone = zone)
    meta_now <- ins$metadata$items
    fingerprint <- ins$metadata$fingerprint
    url <- sprintf("https://www.googleapis.com/compute/v1/projects/%s/zones/%s/instances/%s/setMetadata", 
                   project, zone, as.gce_instance_name(ins))

  }

  ## turn data.frame back into named list
  meta_now_nl <- meta_df_to_list(meta_now)
  
  meta <- Metadata(modifyList(meta_now_nl, metadata))
  ## need current fingerprint to allow modification
  meta$fingerprint <- fingerprint
  
  stopifnot(inherits(meta, "gar_Metadata"))
  # compute.instances.setMetadata  
  f <- gar_api_generator(url, "POST", data_parse_function = function(x) x)

  out <- f(the_body = meta)
  as.zone_operation(out)
  
}

meta_df_to_list <- function(meta_df){
  setNames(lapply(meta_df$key, function(x) meta_df[meta_df$key == x, "value"]), 
           meta_df$key)
}

#' Get project wide metadata
#' 
#' @param project The project to get the project-wide metadata from
#' 
#' @export
gce_get_metadata_project <- function(project = gce_global_project()){
  pw_url <- sprintf("https://www.googleapis.com/compute/v1/projects/%s", project)
  pw <- gar_api_generator(pw_url, "GET", data_parse_function = function(x) x)
  pw()
}