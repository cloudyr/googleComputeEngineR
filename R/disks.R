#' Disk Object
#' 
#' @details 
#' A Disk resource.
#' 
#' @param description An optional description of this resource
#' @param diskEncryptionKey Encrypts the disk using a customer-supplied encryption key
#' @param licenses Any applicable publicly visible licenses
#' @param name Name of the resource
#' @param sizeGb Size of the persistent disk, specified in GB
#' @param sourceImage The source image used to create this disk
#' @param sourceImageEncryptionKey The customer-supplied encryption key of the source image
#' @param sourceSnapshot The source snapshot used to create this disk
#' @param sourceSnapshotEncryptionKey The customer-supplied encryption key of the source snapshot
#' @param type URL of the disk type resource describing which disk type to use to create the disk
#' 
#' @return Disk object
#' 
#' @family Disk functions
#' @keywords internal
Disk <- function(name = NULL, 
                 sourceImage = NULL, 
                 sizeGb = NULL, 
                 description = NULL, 
                 diskEncryptionKey = NULL, 
                 licenses = NULL, 
                 sourceImageEncryptionKey = NULL, 
                 sourceSnapshot = NULL, 
                 sourceSnapshotEncryptionKey = NULL, 
                 type = NULL) {
  
  structure(list(description = description, 
                 diskEncryptionKey = diskEncryptionKey,
                 licenses = licenses, 
                 sourceImage = sourceImage,
                 name = name, 
                 sizeGb = sizeGb, 
                 sourceImageEncryptionKey = sourceImageEncryptionKey, 
                 sourceSnapshot = sourceSnapshot, 
                 sourceSnapshotEncryptionKey = sourceSnapshotEncryptionKey, 
                 type = type), class = c("list","gar_Disk"))
}

#' Creates a persistent disk in the specified project using the data in the request. 
#' 
#' You can create a disk with a sourceImage, a sourceSnapshot, or create an empty 500 GB data disk by omitting all properties. 
#' 
#' You can also create a disk that is larger than the default size by specifying the sizeGb property.
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
#' @inheritParams Disk
#' @param project Project ID for this request
#' @param zone The name of the zone for this request
#' 
#' @importFrom googleAuthR gar_api_generator
#' 
#' @return a zone operation
#' 
#' @export
gce_make_disk <- function(name, 
                          sourceImage = NULL, 
                          sizeGb = NULL, 
                          description = NULL, 
                          diskEncryptionKey = NULL, 
                          licenses = NULL, 
                          sourceSnapshot = NULL, 
                          sourceImageEncryptionKey = NULL, 
                          sourceSnapshotEncryptionKey = NULL, 
                          type = NULL, 
                          project = gce_get_global_project(), 
                          zone = gce_get_global_zone()) {
  
  url <- sprintf("https://www.googleapis.com/compute/v1/projects/%s/zones/%s/disks", 
                 project, zone)
  
  a_disk <- Disk(name = name, 
                 sourceImage = sourceImage, 
                 sizeGb = sizeGb, 
                 description = description, 
                 diskEncryptionKey = diskEncryptionKey, 
                 licenses = licenses, 
                 sourceImageEncryptionKey = sourceImageEncryptionKey, 
                 sourceSnapshot = sourceSnapshot, 
                 sourceSnapshotEncryptionKey = sourceImageEncryptionKey, 
                 type = type)
  
  # compute.disks.insert
  f <- gar_api_generator(url, 
                         "POST", 
                         data_parse_function = function(x) x)
  
  f(the_body = a_disk)
  
}


#' Retrieves an aggregated list of persistent disks across all zones.
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
#' @param filter Sets a filter expression for filtering listed resources, in the form filter={expression}
#' @param maxResults The maximum number of results per page that should be returned
#' @param pageToken Specifies a page token to use
#' @importFrom googleAuthR gar_api_generator
#' @export
gce_list_disks_all <- function(filter = NULL, 
                               maxResults = NULL, 
                               pageToken = NULL, 
                               project = gce_get_global_project()) {
  
  url <- sprintf("https://www.googleapis.com/compute/v1/projects/%s/aggregated/disks",
                 project)
  pars <- list(filter = filter, maxResults = maxResults,
               pageToken = pageToken)
  pars <- rmNullObs(pars)
  # compute.disks.aggregatedList
  f <- gar_api_generator(url, 
                         "GET", 
                         pars_args = pars, 
                         data_parse_function = function(x) x)
  f()

}
# 
# #' Creates a snapshot of a specified persistent disk.
# #'
# #' Autogenerated via \code{\link[googleAuthR]{gar_create_api_skeleton}}
# #'
# #' @seealso \href{https://developers.google.com/compute/docs/reference/latest/}{Google Documentation}
# #'
# #' @details
# #' Authentication scopes used by this function are:
# #' \itemize{
# #'   \item https://www.googleapis.com/auth/cloud-platform
# #' \item https://www.googleapis.com/auth/compute
# #' }
# #'
# #' Set \code{options(googleAuthR.scopes.selected = c(https://www.googleapis.com/auth/cloud-platform, https://www.googleapis.com/auth/compute)}
# #' Then run \code{googleAuthR::gar_auth()} to authenticate.
# #' See \code{\link[googleAuthR]{gar_auth}} for details.
# #'
# #' @param Snapshot The \link{Snapshot} object to pass to this method
# #' @param project Project ID for this request
# #' @param zone The name of the zone for this request
# #' @param disk Name of the persistent disk to snapshot
# #' @importFrom googleAuthR gar_api_generator
# #' @family Snapshot functions
# #' @export
# disks.createSnapshot <- function(Snapshot, project, zone, disk) {
#   url <- sprintf("https://www.googleapis.com/compute/v1/projects/%s/zones/%s/disks/%s/createSnapshot",
#                  disk, project, zone)
#   # compute.disks.createSnapshot
#   f <- gar_api_generator(url, "POST", data_parse_function = function(x) x)
#   stopifnot(inherits(Snapshot, "gar_Snapshot"))
# 
#   f(the_body = Snapshot)
# 
# }

#' Deletes the specified persistent disk. 
#' 
#' Deleting a disk removes its data permanently and is irreversible. 
#' 
#' However, deleting a disk does not delete any snapshots previously made from the disk. 
#' You must separately delete snapshots.
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
#' @param project Project ID for this request
#' @param zone The name of the zone for this request
#' @param disk Name of the persistent disk to delete
#' @importFrom googleAuthR gar_api_generator
#' @export
gce_delete_disk <- function(disk, 
                            project = gce_get_global_project(), 
                            zone = gce_get_global_zone()) {
  
  url <- sprintf("https://www.googleapis.com/compute/v1/projects/%s/zones/%s/disks/%s",
                 project, zone, disk)
  
  # compute.disks.delete
  f <- gar_api_generator(url, 
                         "DELETE", 
                         data_parse_function = function(x) x)
  suppressWarnings(f())

}

#' Returns a specified persistent disk.
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
#' @param zone The name of the zone for this request
#' @param disk Name of the persistent disk to return
#' @importFrom googleAuthR gar_api_generator
#' @export
gce_get_disk <- function(disk, 
                         project = gce_get_global_project(), 
                         zone = gce_get_global_zone()) {
  
  url <- sprintf("https://www.googleapis.com/compute/v1/projects/%s/zones/%s/disks/%s",
                 project, zone, disk)
  
  # compute.disks.get
  f <- gar_api_generator(url, 
                         "GET", 
                         data_parse_function = function(x) x)
  f()

}



#' Retrieves a list of persistent disks contained within the specified zone.
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
#' @param zone The name of the zone for this request
#' @param filter Sets a filter expression for filtering listed resources, in the form filter={expression}
#' @param maxResults The maximum number of results per page that should be returned
#' @param pageToken Specifies a page token to use
#' @importFrom googleAuthR gar_api_generator
#' @export
gce_list_disks <- function(filter = NULL, 
                           maxResults = NULL, 
                           pageToken = NULL, 
                           project = gce_get_global_project(), 
                           zone = gce_get_global_zone()) {
  
  url <- sprintf("https://www.googleapis.com/compute/v1/projects/%s/zones/%s/disks",
                 project, zone)
  
  pars <- list(filter = filter, maxResults = maxResults,
               pageToken = pageToken)
  pars <- rmNullObs(pars)
  # compute.disks.list
  f <- gar_api_generator(url, 
                         "GET", 
                         pars_args = pars, 
                         data_parse_function = function(x) x)
  f()

}
# 
# #' Resizes the specified persistent disk.
# #'
# #' Autogenerated via \code{\link[googleAuthR]{gar_create_api_skeleton}}
# #'
# #' @seealso \href{https://developers.google.com/compute/docs/reference/latest/}{Google Documentation}
# #'
# #' @details
# #' Authentication scopes used by this function are:
# #' \itemize{
# #'   \item https://www.googleapis.com/auth/cloud-platform
# #' \item https://www.googleapis.com/auth/compute
# #' }
# #'
# #' Set \code{options(googleAuthR.scopes.selected = c(https://www.googleapis.com/auth/cloud-platform, https://www.googleapis.com/auth/compute)}
# #' Then run \code{googleAuthR::gar_auth()} to authenticate.
# #' See \code{\link[googleAuthR]{gar_auth}} for details.
# #'
# #' @param DisksResizeRequest The \link{DisksResizeRequest} object to pass to this method
# #' @param project Project ID for this request
# #' @param zone The name of the zone for this request
# #' @param disk The name of the persistent disk
# #' @importFrom googleAuthR gar_api_generator
# #' @family DisksResizeRequest functions
# #' @export
# disks.resize <- function(DisksResizeRequest, project, zone, disk) {
#   url <- sprintf("https://www.googleapis.com/compute/v1/projects/%s/zones/%s/disks/%s/resize",
#                  disk, project, zone)
#   # compute.disks.resize
#   f <- gar_api_generator(url, "POST", data_parse_function = function(x) x)
#   stopifnot(inherits(DisksResizeRequest, "gar_DisksResizeRequest"))
# 
#   f(the_body = DisksResizeRequest)
# 
# }
