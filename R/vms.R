#' Create or fetch a virtual machine
#' 
#' Pass in the instance name to fetch its object, or create the instance.
#' 
#' @inheritParams gce_vm_create
#' @param name The name of the instance
#' @param ... Other arguments passed to create an instance if it doesn't exist
#' 
#' @details 
#' 
#' Will get or create the instance as specified.  Will wait for instance to be created if necessary.
#' 
#' Make sure the instance is big enough to handle what you need, for instance the default "f1-micro" will hang the instance 
#' when trying to install certain R libraries.
#' 
#' @section Creation logic:
#' 
#' You need these parameters defined to call the right function for creation.  Check the function definitions for more details. 
#' 
#' If you specify the argument \code{template} it will call \link{gce_vm_template}
#' 
#' If you specify one of \code{file} or \code{cloud_init} it will call \link{gce_vm_container}
#' 
#' Otherwise it will call \link{gce_vm_create}
#' 
#' @return A \code{gce_instance} object
#' 
#' @export
gce_vm <- function(name, 
                   ...,                           
                   project = gce_get_global_project(), 
                   zone = gce_get_global_zone() ) {
  
  if(inherits(name, "gce_instance")){
    myMessage("Refreshing instance data", level = 3)
    name <- name$name
  }
  
  stopped <- gce_list_instances("status eq TERMINATED", project = project, zone = zone)
  
  if(name %in% stopped$items$name){
    myMessage("VM previously created but not running, starting VM", level = 3)
    job <- gce_vm_start(name, project = project, zone = zone)
    gce_wait(job)
  }
  
  vm <- tryCatch({
    suppressMessages(suppressWarnings(gce_get_instance(name)))
  }, error = function(ex) {
    dots <- list(...)
    if(!is.null(dots[["template"]])){
      
      myMessage("Creating template VM", level = 3)
      do.call(gce_vm_template, c(list(...), name = name))
      ## gce_vm_template has its own gce_wait()
      
    } else if(any(!is.null(dots[["file"]]), !is.null(dots[["cloud_init"]]))){
      
      myMessage("Creating container VM", level = 3)
      job <- do.call(gce_vm_container, c(list(...), name = name))
      gce_wait(job)
      gce_get_instance(name)
      
    } else {
      
      myMessage("Creating standard VM", level = 3)
      job <- do.call(gce_vm_create, c(list(...), name = name))
      gce_wait(job)
      gce_get_instance(name)
      
    }
  })
  
  myMessage("VM running", level = 3)
  vm
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
#' @param instance Name of the instance resource, or an instance object e.g. from \link{gce_get_instance}
#' @param project Project ID for this request, default as set by \link{gce_get_global_project}
#' @param zone The name of the zone for this request, default as set by \link{gce_get_global_zone}
#' 
#' @importFrom googleAuthR gar_api_generator
#' @export
gce_vm_delete <- function(instance,
                          project = gce_get_global_project(), 
                          zone = gce_get_global_zone() 
                          ) {

  url <- sprintf("https://www.googleapis.com/compute/v1/projects/%s/zones/%s/instances/%s", 
                 project, zone, as.gce_instance_name(instance))
  # compute.instances.delete
  f <- gar_api_generator(url, 
                         "DELETE", 
                         data_parse_function = function(x) x)
  out <- f()
  
  as.zone_operation(out)
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
#' \code{cpus} must be in multiples of 2 up to 32
#' \code{memory} must be in multiples of 256
#' 
#' One of \code{image} or \code{image_family} must be supplied
#' 
#' To create an instance you need to specify:
#' 
#' \itemize{
#'   \item Name
#'   \item Project [if not default]
#'   \item Zone [if not default]
#'   \item Machine type - either a predefined type or custom CPU and memory
#'   \item Network - usually default, specifies open ports etc.
#'   \item Image - a source image containing the operating system
#'  }
#'  
#'  You can add metadata to the server such as \code{startup-script} and \code{shutdown-script}.  Details available here: \url{https://cloud.google.com/compute/docs/storing-retrieving-metadata}
#'  
#'  If you want to not have an external IP then modify the instance afterwards
#' 
#' 
#' @inheritParams Instance
#' @inheritParams gce_make_machinetype_url
#' @param image_project Project ID of where the image lies
#' @param image Name of the image resource to return
#' @param image_family Name of the image family to search for
#' @param disk_source Specifies a valid URL to an existing Persistent Disk resource.
#' @param network The name of the network interface
#' @param externalIP An external IP you have previously reserved, leave NULL to have one assigned or \code{"none"} for no external access.
#' @param project Project ID for this request
#' @param zone The name of the zone for this request
#' @param dry_run whether to just create the request JSON
#' @param auth_email If it includes '@' then assume the email, otherwise an environment file var that includes the email
#' 
#' @return A zone operation, or if the name already exists the VM object from \link{gce_get_instance}
#' 
#' @importFrom googleAuthR gar_api_generator
#' @export
gce_vm_create <- function(name,
                          predefined_type = "f1-micro",
                          image_project = "debian-cloud",
                          image_family = "debian-8",
                          cpus = NULL,
                          memory = NULL,
                          image = "",
                          disk_source = NULL,
                          network = "default", 
                          externalIP = NULL,
                          canIpForward = NULL, 
                          description = NULL, 
                          metadata = NULL, 
                          scheduling = NULL, 
                          serviceAccounts = NULL, 
                          tags = NULL,
                          auth_email = "GCE_AUTH_FILE",
                          project = gce_get_global_project(), 
                          zone = gce_get_global_zone(),
                          dry_run = FALSE) {
  
  stopifnot(inherits(name, "character"))
  
  url <- sprintf("https://www.googleapis.com/compute/v1/projects/%s/zones/%s/instances", 
                 project, zone)
  
  if(missing(predefined_type) && !is.character(predefined_type)){
    if(any(is.null(cpus), is.null(memory))){
     stop("Must supply one of 'predefined_type', or both 'cpus' and 'memory' arguments.") 
    }
  }

  ## if an image project is defined, create a source_image_url
  if(nchar(image_project) > 0){
    if(!is.null(disk_source)){
      stop("Can specify only one of 'image_project' or 'disk_source' arguments.")
    }

    if(nchar(image_family) > 0){
      
      ## creation from image_family
      source_image_url <- gce_make_image_source_url(image_project, family = image_family)
    } else {
      ## creation from image
      stopifnot(nchar(image) > 0)
      source_image_url <- gce_make_image_source_url(image_project, image = image)
    }
    
    if(is.null(source_image_url)){
      stop("No source image URL was found for selected image")
    }
    
  } else {
    source_image_url <- NULL
    if(!is.null(disk_source)){
      stop("Need to specify either an image_project or a disk_source")
    }
  }
  
  ## make image initialisation
  init_disk <- list(
    list(
      initializeParams = list(
        sourceImage = source_image_url
      ),
      source = disk_source,
      ## not in docs apart from https://cloud.google.com/compute/docs/instances/create-start-instance
      autoDelete = jsonlite::unbox(TRUE),
      boot       = jsonlite::unbox(TRUE),
      type       = jsonlite::unbox("PERSISTENT"),
      deviceName = jsonlite::unbox(paste0(name,"-boot-disk"))
    )
  )

  ## make machine type
  machineType <- gce_make_machinetype_url(predefined_type = predefined_type,
                                          cpus = cpus,
                                          memory = memory,
                                          zone = zone)
  
  ## make network interface
  networkInterfaces <- gce_make_network(name = paste0(name, "-ip"),
                                        network = network, 
                                        externalIP = externalIP,
                                        project = project)
  
  ## make serviceAccounts
  if(is.null(serviceAccounts)){
    serviceAccounts = list(
      list(
        email = jsonlite::unbox(auth_email(auth_email)),
        scopes = list("https://www.googleapis.com/auth/cloud-platform")
      )
    )
  }
  

  ## make instance object
  the_instance <- Instance(canIpForward = canIpForward, 
                           description = description, 
                           machineType = machineType, 
                           metadata = metadata, 
                           disks = init_disk,
                           name = name, 
                           networkInterfaces = networkInterfaces, 
                           scheduling = scheduling, 
                           serviceAccounts = serviceAccounts, 
                           tags = tags)
  if(dry_run){
    return(jsonlite::toJSON(the_instance, pretty = TRUE))
  }
  
  # compute.instances.insert
  f <- gar_api_generator(url, 
                         "POST", 
                         data_parse_function = function(x) x)
  stopifnot(inherits(the_instance, "gar_Instance"))
  
  out <- f(the_body = rmNullObs(the_instance))
  
  if(is.null(out)){
    stop("Error fetching VM, returned NULL")
  }
  
  if(!is.gce_instance(out)){
    out <- as.zone_operation(out)
  }
  
  out

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
#' @param instance Name of the instance resource, or an instance object e.g. from \link{gce_get_instance}
#' @param project Project ID for this request, default as set by \link{gce_get_global_project}
#' @param zone The name of the zone for this request, default as set by \link{gce_get_global_zone}
#' @importFrom googleAuthR gar_api_generator
#' @export
gce_vm_reset <- function(instance,
                         project = gce_get_global_project(), 
                         zone = gce_get_global_zone()) {

  url <- sprintf("https://www.googleapis.com/compute/v1/projects/%s/zones/%s/instances/%s/reset", 
                 project, zone, as.gce_instance_name(instance))
  # compute.instances.reset
  f <- gar_api_generator(url, 
                         "POST", 
                         data_parse_function = function(x) x)
  out <- f()
  
  as.zone_operation(out)
}




#' Starts an instance that was stopped using the using the stop method.
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
#' @param instance Name of the instance resource, or an instance object e.g. from \link{gce_get_instance}
#' @param project Project ID for this request, default as set by \link{gce_get_global_project}
#' @param zone The name of the zone for this request, default as set by \link{gce_get_global_zone}
#' 
#' @return An Operation object with pending status
#' 
#' @importFrom googleAuthR gar_api_generator
#' @export
gce_vm_start <- function(instance,
                         project = gce_get_global_project(), 
                         zone = gce_get_global_zone()
                         ) {

  url <- sprintf("https://www.googleapis.com/compute/v1/projects/%s/zones/%s/instances/%s/start", 
                 project, zone, as.gce_instance_name(instance))
  # compute.instances.start
  f <- gar_api_generator(url, 
                         "POST", 
                         data_parse_function = function(x) x)
  out <- f()
  
  as.zone_operation(out)
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
#' @param instance Name of the instance resource, or an instance object e.g. from \link{gce_get_instance}
#' @param project Project ID for this request, default as set by \link{gce_get_global_project}
#' @param zone The name of the zone for this request, default as set by \link{gce_get_global_zone}
#' 
#' @importFrom googleAuthR gar_api_generator
#' @export
gce_vm_stop <- function(instance,
                        project = gce_get_global_project(), 
                        zone = gce_get_global_zone() 
                        ) {

  
  url <- 
    sprintf("https://www.googleapis.com/compute/v1/projects/%s/zones/%s/instances/%s/stop",
            project, zone, as.gce_instance_name(instance))
  # compute.instances.stop
  f <- gar_api_generator(url, 
                         "POST",
                         data_parse_function = function(x) x)
  out <- f()
  
  as.zone_operation(out)
}

