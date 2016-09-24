#' Instance Object
#' 
#' @details 
#' An Instance resource.
#' 
#' @param canIpForward Allows this instance to send and receive packets with non-matching destination or source IPs
#' @param description An optional description of this resource
#' @param disks Array of disks associated with this instance
#' @param machineType Full or partial URL of the machine type resource to use for this instance, in the format: zones/zone/machineTypes/machine-type
#' @param metadata The metadata key/value pairs assigned to this instance
#' @param name The name of the resource, provided by the client when initially creating the resource
#' @param networkInterfaces An array of configurations for this interface
#' @param scheduling Scheduling options for this instance
#' @param serviceAccounts A list of service accounts, with their specified scopes, authorized for this instance
#' @param tags A list of tags to apply to this instance
#' 
#' @return Instance object
#' 
#' @family Instance functions
#' @keywords internal
Instance <- function(canIpForward = NULL, 
                     description = NULL, 
                     disks = NULL, 
                     machineType = NULL, 
                     metadata = NULL, 
                     name = NULL, 
                     networkInterfaces = NULL, 
                     scheduling = NULL, 
                     serviceAccounts = NULL, 
                     tags = NULL) {
  
  structure(list(canIpForward = canIpForward,
                 description = description, 
                 disks = disks, 
                 machineType = machineType, 
                 metadata = metadata, 
                 name = name, 
                 networkInterfaces = networkInterfaces, 
                 scheduling = scheduling, 
                 serviceAccounts = serviceAccounts, 
                 tags = tags), 
            class = "gar_Instance")
}


#' Deletes the specified Instance resource.
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
#' 
#' @param instance Name of the instance resource
#' @param project Project ID for this request, default as set by \link{gce_get_global_project()}
#' @param zone The name of the zone for this request, default as set by \link{gce_get_global_zone()}
#' 
#' @importFrom googleAuthR gar_api_generator
#' @export
gce_vm_delete <- function(instance,
                          project = gce_get_global_project(), 
                          zone = gce_get_global_zone() 
                          ) {
  url <- sprintf("https://www.googleapis.com/compute/v1/projects/%s/zones/%s/instances/%s", 
                 project, zone, instance)
  # compute.instances.delete
  f <- gar_api_generator(url, 
                         "DELETE", 
                         data_parse_function = function(x) x)
  f()
  
}


#' Creates an instance resource in the specified project using the data included in the request.
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
#' 
#' @inheritParams Instance
#' @param project Project ID for this request
#' @param zone The name of the zone for this request
#' 
#' @importFrom googleAuthR gar_api_generator
#' @family Instance functions
#' @export
gce_vm_create <- function(canIpForward = NULL, 
                          description = NULL, 
                          disks = NULL, 
                          machineType = NULL, 
                          metadata = NULL, 
                          name = NULL, 
                          networkInterfaces = NULL, 
                          scheduling = NULL, 
                          serviceAccounts = NULL, 
                          tags = NULL,
                          project = gce_get_global_project(), 
                          zone = gce_get_global_zone()) {
  
  url <- sprintf("https://www.googleapis.com/compute/v1/projects/%s/zones/%s/instances", 
                 project, zone)
  
  the_instance <- Instance(canIpForward = canIpForward, 
                           description = description, 
                           disks = disks, 
                           machineType = machineType, 
                           metadata = metadata, 
                           name = name, 
                           networkInterfaces = networkInterfaces, 
                           scheduling = scheduling, 
                           serviceAccounts = serviceAccounts, 
                           tags = tags)
  # compute.instances.insert
  f <- gar_api_generator(url, 
                         "POST", 
                         data_parse_function = function(x) x)
  stopifnot(inherits(the_instance, "gar_Instance"))
  
  f(the_body = the_instance)
  
}


#' Performs a hard reset on the instance.
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
#' 
#' @param instance Name of the instance resource
#' @param project Project ID for this request, default as set by \link{gce_get_global_project()}
#' @param zone The name of the zone for this request, default as set by \link{gce_get_global_zone()}
#' @importFrom googleAuthR gar_api_generator
#' @export
gce_vm_reset <- function(instance,
                         project = gce_get_global_project(), 
                         zone = gce_get_global_zone()) {
  
  url <- sprintf("https://www.googleapis.com/compute/v1/projects/%s/zones/%s/instances/%s/reset", 
                 project, zone, instance)
  # compute.instances.reset
  f <- gar_api_generator(url, 
                         "POST", 
                         data_parse_function = function(x) x)
  f()
  
}




#' Starts an instance that was stopped using the using the instances().stop method.
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
#' 
#' @param instance Name of the instance resource
#' @param project Project ID for this request, default as set by \link{gce_get_global_project()}
#' @param zone The name of the zone for this request, default as set by \link{gce_get_global_zone()}
#' @importFrom googleAuthR gar_api_generator
#' @export
gce_vm_start <- function(instance,
                         project = gce_get_global_project(), 
                         zone = gce_get_global_zone()
                         ) {
  
  url <- sprintf("https://www.googleapis.com/compute/v1/projects/%s/zones/%s/instances/%s/start", 
                 project, zone, instance)
  # compute.instances.start
  f <- gar_api_generator(url, 
                         "POST", 
                         data_parse_function = function(x) x)
  f()
  
}

#' Stops a running instance, shutting it down cleanly, and allows you to restart the instance at a later time. 
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
#' Stopped instances do not incur per-minute, virtual machine usage charges 
#'   while they are stopped, but any resources that the virtual machine is using, 
#'   such as persistent disks and static IP addresses, 
#'   will continue to be charged until they are deleted.
#'   
#' @param instance Name of the instance resource to stop
#' @param project Project ID for this request, default as set by \link{gce_get_global_project()}
#' @param zone The name of the zone for this request, default as set by \link{gce_get_global_zone()}
#' 
#' @importFrom googleAuthR gar_api_generator
#' @export
gce_vm_stop <- function(instance,
                        project = gce_get_global_project(), 
                        zone = gce_get_global_zone() 
                        ) {
  
  url <- 
    sprintf("https://www.googleapis.com/compute/v1/projects/%s/zones/%s/instances/%s/stop",
            project, zone, instance)
  # compute.instances.stop
  f <- gar_api_generator(url, 
                         "POST",
                         data_parse_function = function(x) x)
  f()
  
}

