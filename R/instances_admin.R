#' Check if instance exists already, if it does return it
#' @noRd
check_vm_exists <- function(name, project, zone){
  
  # for stopped VMs
  for (status in c("TERMINATED", "STOPPING")) {
    stopped <- gce_list_instances(paste0("status eq ", status), 
                                  project = project, zone = zone)
    
    if (name %in% stopped$items$name){
      myMessage("VM previously created but not running, starting VM", level = 3)
      job <- gce_vm_start(name, project = project, zone = zone)
      gce_wait(job[[1]])
      return(gce_get_instance(name, project, zone))
    }
  }
  
  # for Suspended
  for (status in c("SUSPENDING", "SUSPENDED")) {
    stopped <- gce_list_instances(paste0("status eq ", status), 
                                  project = project, zone = zone)
    
    if (name %in% stopped$items$name){
      myMessage("VM previously created but not suspended, resuming VM", level = 3)
      job <- gce_vm_resume(name, project = project, zone = zone)
      gce_wait(job[[1]])
      return(gce_get_instance(name, project, zone))
    }  
  }
  
  NULL
  
}


#' Extract zone and project from an instance object
#' 
#' @param instance The instance
#' @return A list of $project and $zone
#' @export
gce_extract_projectzone <- function(instance){
  
  instance <- as.gce_instance(instance)
  
  list(project = gsub(paste0("https://www.googleapis.com/compute/v1/projects/(.+)/zones/",
                             basename(instance$zone)),"\\1", 
                      instance$zone),
       zone = basename(instance$zone))
}

#' Retrieves the list of instances contained within the specified zone.
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
#' @details 
#' 
#' To filter you need a single string in the form \code{field_name eq|ne string} 
#'   e.g. \code{gce_list_instances("status eq RUNNING")} where \code{eq} is 'equals' and \code{ne} is 'not-equals'.
#' 
#' @param filter Sets a filter expression for filtering listed resources, in the form filter={expression}
#' @param maxResults The maximum number of results per page that should be returned
#' @param pageToken Specifies a page token to use
#' @param project Project ID for this request
#' @param zone The name of the zone for this request
#' 
#' @importFrom googleAuthR gar_api_generator
#' @export
gce_list_instances <- function(filter = NULL, 
                               maxResults = NULL, 
                               pageToken = NULL,
                               project = gce_get_global_project(), 
                               zone = gce_get_global_zone()) {
  
  url <- sprintf("https://www.googleapis.com/compute/v1/projects/%s/zones/%s/instances", 
                 project, zone)
  
  if(!is.null(filter)){
    filter <- utils::URLencode(filter, reserved = TRUE)
  }
  
  pars <- list(filter = filter, 
               maxResults = maxResults, 
               pageToken = pageToken)
  pars <- rmNullObs(pars)
  
  
  # compute.instances.list
  f <- gar_api_generator(url, 
                         "GET", 
                         pars_args = pars, 
                         data_parse_function = function(x) x)
  out <- f()
  
  structure(
    out,
    class = c("gce_instanceList", class(out))
  )
  
}

#' Returns the specified Instance resource.
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
#' @param instance Name of the instance resource
#' @param project Project ID for this request, default as set by \link{gce_get_global_project}
#' @param zone The name of the zone for this request, default as set by \link{gce_get_global_zone}
#' 
#' @importFrom googleAuthR gar_api_generator
#' @export
gce_get_instance <- function(instance,
                             project = gce_get_global_project(), 
                             zone = gce_get_global_zone()) {
  
  url <- sprintf("https://www.googleapis.com/compute/v1/projects/%s/zones/%s/instances/%s", 
                 project, zone, as.gce_instance_name(instance))
  # compute.instances.get
  f <- gar_api_generator(url, 
                         "GET", 
                         data_parse_function = function(x) x)
  out <- f()
  
  structure(
    out,
    class = c("gce_instance", class(out))
  )
  
}

#' Get the instance name(s) if passed instance(s)
#' @param A list or a single instance 
#' @noRd
#' @keywords internal
as.gce_instance_name <- function(x){
  
  if(is.gce_instance(x) || is.gce_zone_operation(x) || inherits(x, "character")){
    return(as.gce_instance_name_one(x))
  } else {
    return(vapply(as.list(x), as.gce_instance_name_one, character(1)))
  }
  
}

#' Turn an instance name into an instance, or return the instance
#' @param x A character name of instance or instance object
#' @param project GDE project
#' @param zone GCE zone
#' @noRd
#' @keywords internal
as.gce_instance <- function(x, 
                            project = gce_get_global_project(), 
                            zone = gce_get_global_zone()){
  if(is.gce_instance(x)){
    ins <- x
  } else if(is.character(x)){
    ## get existing metadata
    ins <- gce_get_instance(x, project = project, zone = zone)
  } else {
    stop("Unrecognised instance class - ", class(x))
  }
  
  ins
}

#' Check if is gce_instance
#' @param x The object to test if class \code{gce_instance}
#' @return TRUE or FALSE
#' @noRd
is.gce_instance <- function(x){
  inherits(x, "gce_instance")
}


#' Get the instance name if passed an instance
#' @param a character name or gce_instance object
#' @noRd
#' @keywords internal
as.gce_instance_name_one <- function(x){
  if(is.gce_instance(x)){
    out <- x$name
  } else if(is.gce_zone_operation(x)){
    out <- basename(x$targetLink)
  } else if(inherits(x, "character")) {
    out <- x
  } else {
    stop("Instance supplied was not a character name or gce_instance")
  }
  
  out
}


#' Instance Object
#' 
#' @details 
#' An Instance resource.
#' 
#' @param canIpForward Allows this instance to send and receive packets with non-matching destination or source IPs
#' @param description An optional description of this resource
#' @param disks The source image used to create this disk
#' @param machineType Full or partial URL of the machine type resource to use for this instance, in the format: \code{zones/zone/machineTypes/machine-type}
#' @param metadata A named list of metadata key/value pairs assigned to this instance
#' @param name The name of the resource, provided by the client when initially creating the resource
#' @param networkInterfaces An array of configurations for this interface
#' @param scheduling Scheduling options for this instance, such as preemptible instances
#' @param serviceAccounts A list of service accounts, with their specified scopes, authorized for this instance
#' @param tags A list of tags to apply to this instance
#' 
#' @return Instance object
#' 
#' @family Instance functions
#' @keywords internal
Instance <- function(name = NULL,
                     machineType = NULL, 
                     canIpForward = NULL, 
                     description = NULL, 
                     disks = NULL,
                     metadata = NULL, 
                     networkInterfaces = NULL, 
                     scheduling = NULL, 
                     serviceAccounts = NULL, 
                     tags = NULL,
                     minCpuPlatform = NULL,
                     guestAccelerators = NULL) {
  
  structure(list(canIpForward = canIpForward,
                 description = description, 
                 machineType = machineType, 
                 metadata = Metadata(metadata), 
                 name = name, 
                 disks = disks,
                 minCpuPlatform = minCpuPlatform,
                 networkInterfaces = networkInterfaces, 
                 scheduling = scheduling, 
                 serviceAccounts = serviceAccounts, 
                 guestAccelerators = guestAccelerators,
                 tags = tags), 
            class = c("gar_Instance", "list"))
}


