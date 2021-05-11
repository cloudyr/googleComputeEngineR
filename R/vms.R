#' Create or fetch a virtual machine
#' 
#' Pass in the instance name to fetch its object, or create the instance via \link{gce_vm_create}.
#' 
#' @inheritParams gce_vm_create
#' @param name The name of the instance
#' @param open_webports If TRUE, will open firewall ports 80 and 443 if not open already
#' @inheritDotParams gce_vm_create 
#' @details 
#' 
#' Will get or create the instance as specified.  Will wait for instance to be created if necessary.
#' 
#' Make sure the instance is big enough to handle what you need, 
#'   for instance the default \code{f1-micro} will hang the instance when trying to install large R libraries.
#' 
#' @section Creation logic:
#' 
#' You need these parameters defined to call the right function for creation.  Check the function definitions for more details. 
#' 
#' If the VM name exists but is not running, it start the VM and return the VM object
#' 
#' If the VM is running, it will return the VM object
#' 
#' If you specify the argument \code{template} it will call \link{gce_vm_template}
#' 
#' If you specify one of \code{file} or \code{cloud_init} it will call \link{gce_vm_container}
#' 
#' Otherwise it will call \link{gce_vm_create}
#' 
#' @return A \code{gce_instance} object
#' 
#' @examples 
#' 
#' \dontrun{
#' 
#' library(googleComputeEngineR)
#' ## auto auth, project and zone pre-set
#' ## list your VMs in the project/zone
#' 
#' the_list <- gce_list_instances()
#' 
#' ## start an existing instance
#' vm <- gce_vm("markdev")
#' 
#' ## for rstudio, you also need to specify a username and password to login
#' vm <- gce_vm(template = "rstudio",
#'              name = "rstudio-server",
#'              username = "mark", password = "mark1234")
#' 
#' ## specify your own cloud-init file and pass it into gce_vm_container()
#' vm <- gce_vm(cloud_init = "example.yml",
#'              name = "test-container",
#'              predefined_type = "f1-micro")
#' 
#' ## specify disk size at creation
#' vm <- gce_vm('my-image3', disk_size_gb = 20)
#' 
#' 
#' }
#' 
#' @export
#' @import assertthat
gce_vm <- function(name, 
                   ...,                           
                   project = gce_get_global_project(), 
                   zone = gce_get_global_zone(),
                   open_webports = TRUE) {

  if(is.gce_instance(name)){
    myMessage("Refreshing instance data", level = 3)
    name <- name$name
  }
  
  assert_that(
    is.string(name),
    is.string(project),
    is.string(zone),
    is.flag(open_webports)
  )
  
  existing_vm <- check_vm_exists(name, project = project, zone = zone)
  
  if(is.gce_instance(existing_vm)){
    return(existing_vm)
  }
  
  vm <- tryCatch({
    suppressMessages(
      suppressWarnings(
        gce_get_instance(name, zone = zone, project = project)
        )
      )
  }, error = function(ex) {
    dots <- list(...)
    if(!is.null(dots[["template"]])){
      
      myMessage("Creating template VM", level = 3)
      do.call(gce_vm_template, c(list(...), name = name, zone = zone, project = project))
      ## gce_vm_template has its own gce_wait()
      
    } else if(any(!is.null(dots[["file"]]), !is.null(dots[["cloud_init"]]))){
      
      myMessage("Creating container VM", level = 3)
      job <- do.call(gce_vm_container, c(list(...), name = name, zone = zone, project = project))
      gce_wait(job)
      gce_get_instance(name, zone = zone, project = project)
      
    } else {
      
      myMessage("Creating standard VM", level = 3)
      job <- do.call(gce_vm_create, c(list(...), name = name, zone = zone, project = project))
      gce_wait(job)
      gce_get_instance(name, zone = zone, project = project)
      
    }
  })
  
  ## check firewalls
  if(open_webports){
    gce_make_firewall_webports(project = project)
  }
  
  myMessage(name, " VM running", level = 3)
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
#' @param instances Name of the instance resource, or an instance object e.g. from \link{gce_get_instance}, or a list of instances to delete
#' @param project Project ID for this request, default as set by \link{gce_get_global_project}
#' @param zone The name of the zone for this request, default as set by \link{gce_get_global_zone}
#' 
#' @importFrom googleAuthR gar_api_generator
#' @import assertthat
#' @export
gce_vm_delete <- function(instances,
                          project = gce_get_global_project(), 
                          zone = gce_get_global_zone()) {
  if(is.gce_instance(instances)){
    instances <- list(instances)
  }
  vms <- lapply(instances, as.gce_instance_name)
  lapply(vms, gce_vm_delete_one, project = project, zone = zone)
}



gce_vm_delete_one <- function(instance,
                          project, 
                          zone) {

  assert_that(
    is.string(project),
    is.string(zone)
  )

  url <- sprintf("https://www.googleapis.com/compute/v1/projects/%s/zones/%s/instances/%s", 
                 project, zone, instance)
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
#' @section Preemptible VMS: 
#' 
#' You can set \href{https://cloud.google.com/compute/docs/instances/create-start-preemptible-instance}{preemptible} VMs by passing this in the \code{scheduling} arguments \code{scheduling = list(preemptible = TRUE)}
#'  
#' This creates a VM that may be shut down prematurely by Google - you will need to sort out how to save state if that happens in a shutdown script etc.  However, these are much cheaper. 
#' 
#' @section GPUs:
#' 
#' Some defaults for launching GPU enabled VMs are available at \link{gce_vm_gpu}
#' 
#' You can add GPUs to your instance, but they must be present in the zone you have specified - use \link{gce_list_gpus} to see which are available. Refer to \href{https://cloud.google.com/compute/docs/gpus/#introduction}{this} link for a list of current GPUs per zone.
#' 
#' @inheritParams Instance
#' @inheritParams gce_make_machinetype_url
#' @param image_project Project ID of where the image lies
#' @param image Name of the image resource to return
#' @param image_family Name of the image family to search for
#' @param disk_source Specifies a valid URL to an existing Persistent Disk resource.
#' @param network A network object created by \link{gce_make_network}
#' @param externalIP An external IP you have previously reserved, leave NULL to have one assigned or \code{"none"} for no external access.
#' @param minCpuPlatform Specify a minimum CPU platform as per \href{these Google docs}{https://cloud.google.com/compute/docs/instances/specify-min-cpu-platform}
#' @param project Project ID for this request
#' @param zone The name of the zone for this request
#' @param dry_run whether to just create the request JSON
#' @param disk_size_gb If not NULL, override default size of the boot disk (size in GB) 
#' @param use_beta If set to TRUE will use the beta version of the API. Should not be used for production purposes.
#' @param acceleratorCount Number of GPUs to add to instance.  If using this, you may want to instead use \link{gce_vm_gpu} which sets some defaults for GPU instances.
#' @param acceleratorType Name of GPU to add, see \link{gce_list_gpus}
#' 
#' @return A zone operation, or if the name already exists the VM object from \link{gce_get_instance}
#' 
#' @importFrom googleAuthR gar_api_generator
#' @importFrom jsonlite unbox toJSON
#' @import assertthat
#' @export
gce_vm_create <- function(name,
                          predefined_type = "f1-micro",
                          image_project = "debian-cloud",
                          image_family = "debian-9",
                          cpus = NULL,
                          memory = NULL,
                          image = "",
                          disk_source = NULL,
                          network = gce_make_network("default"), 
                          externalIP = NULL,
                          canIpForward = NULL, 
                          description = NULL, 
                          metadata = NULL, 
                          scheduling = NULL, 
                          serviceAccounts = NULL, 
                          tags = NULL,
                          minCpuPlatform = NULL,
                          project = gce_get_global_project(), 
                          zone = gce_get_global_zone(),
                          dry_run = FALSE,
                          disk_size_gb = NULL,
                          use_beta = FALSE,
                          acceleratorCount = NULL,
                          acceleratorType = "nvidia-tesla-p4") {
  
  assert_that(
    is.string(name),
    is.gce_networkInterface(network)
  )
  
  ## missing only works within function its called from
  if(missing(predefined_type)){
    predefined_type <- NULL
  }
  
  ## beta elements are NULL
  guestAccelerators = NULL
  
  if(!is.null(acceleratorCount)){
    acctype <- sprintf("projects/%s/zones/%s/acceleratorTypes/%s",
                       project, zone, acceleratorType)
    
    guestAccelerators <- list(
      list(
        acceleratorCount = acceleratorCount,
        acceleratorType = acctype
      )
    )
  }

  
  if(!use_beta){
    url <- sprintf("https://www.googleapis.com/compute/v1/projects/%s/zones/%s/instances", 
                   project, zone)
    

  } else {
    warning("This is using the beta version of the Google Compute Engine API and may not work in the future.")
    url <- sprintf("https://www.googleapis.com/compute/beta/projects/%s/zones/%s/instances", 
                   project, zone)
  }
  
  
  if(is.null(predefined_type) && !assertthat::is.string(predefined_type)){
    if(any(is.null(cpus), is.null(memory))){
     stop("Must supply one of 'predefined_type', or both 'cpus' and 'memory' arguments.") 
    }
  }

  ## treat null image_project same as image_project = ""
  if(is.null(image_project)){
    image_project <- ""
  }

  
  ## if an image project is defined, create a source_image_url
  if(nchar(image_project) > 0){
    if(!is.null(disk_source)){
      stop("Can specify only one of 'image_project' or 'disk_source' arguments.")
    }

    if(nchar(image_family) > 0){
      
      ## creation from image_family
      source_image_url <- gce_make_image_source_url(image_project, 
                                                    family = image_family)
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
    if(is.null(disk_source)){
      stop("Need to specify either an image_project or a disk_source")
    }
  }
  
  ## make image initialisation
  initializeParams <- list(
      sourceImage = source_image_url
    )
  if (!is.null(disk_size_gb)) {
    initializeParams <- as.list(unlist(c(initializeParams, diskSizeGb = disk_size_gb)))
  }
  init_disk <- list(
    list(
      initializeParams = initializeParams,
      source = disk_source,
      ## not in docs apart from https://cloud.google.com/compute/docs/instances/create-start-instance
      autoDelete = unbox(TRUE),
      boot       = unbox(TRUE),
      type       = unbox("PERSISTENT"),
      deviceName = unbox(paste0(name,"-boot-disk"))
    )
  )

  ## make machine type
  machineType <- gce_make_machinetype_url(predefined_type = predefined_type,
                                          cpus = cpus,
                                          memory = memory,
                                          zone = zone)
  
  ## make network interface
  networkInterfaces <- network
  
  ## make serviceAccounts
  if(is.null(serviceAccounts)){
    serviceAccounts = gce_make_serviceaccounts()
  }
  
  if(!is.null(minCpuPlatform)){
     assert_that(is.string(minCpuPlatform))
  }

  ## make instance object
  the_instance <- Instance(canIpForward = canIpForward, 
                           description = description, 
                           machineType = machineType, 
                           metadata = metadata, 
                           disks = init_disk,
                           name = name, 
                           minCpuPlatform = minCpuPlatform,
                           networkInterfaces = networkInterfaces, 
                           scheduling = scheduling, 
                           serviceAccounts = serviceAccounts, 
                           guestAccelerators = guestAccelerators,
                           tags = tags)
  if(dry_run){
    return(toJSON(the_instance, pretty = TRUE))
  }
  
  # compute.instances.insert
  f <- gar_api_generator(url, 
                         "POST", 
                         data_parse_function = function(x) x)
  
  assert_that(
    inherits(the_instance, "gar_Instance")
  )
  
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
#' @param instances Name of the instance resource, or an instance object e.g. from \link{gce_get_instance}
#' @param project Project ID for this request, default as set by \link{gce_get_global_project}
#' @param zone The name of the zone for this request, default as set by \link{gce_get_global_zone}
#' @importFrom googleAuthR gar_api_generator
#' @export
gce_vm_reset <- function(instances,
                         project = gce_get_global_project(), 
                         zone = gce_get_global_zone()){
  lapply(instances, gce_vm_reset_one, project = project, zone = zone)
}


gce_vm_reset_one <- function(instance,
                         project, 
                         zone) {

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
#' @param instances Name of the instance resource, or an instance object e.g. from \link{gce_get_instance}
#' @param project Project ID for this request, default as set by \link{gce_get_global_project}
#' @param zone The name of the zone for this request, default as set by \link{gce_get_global_zone}
#' 
#' @return A list of operation objects with pending status
#' 
#' @importFrom googleAuthR gar_api_generator
#' @export
gce_vm_start <- function(instances,
                         project = gce_get_global_project(), 
                         zone = gce_get_global_zone()){
  lapply(instances, gce_vm_start_one, project = project, zone = zone)
}

gce_vm_start_one <- function(instance,
                         project, 
                         zone
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
#' @param instances Names of the instance resource, or an instance object e.g. from \link{gce_get_instance}
#' @param project Project ID for this request, default as set by \link{gce_get_global_project}
#' @param zone The name of the zone for this request, default as set by \link{gce_get_global_zone}
#' 
#' @importFrom googleAuthR gar_api_generator
#' @export
gce_vm_stop <- function(instances,
                        project = gce_get_global_project(), 
                        zone = gce_get_global_zone()){
  
  lapply(instances, gce_vm_stop_one, project = project, zone = zone)
}



gce_vm_stop_one <- function(instance,
                        project, 
                        zone) {

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

gce_vm_suspend_one <- function(instance,
                               project, 
                               zone) {
  
  url <- 
    sprintf("https://www..googleapis.com/compute/beta/projects/%s/zones/%s/instances/%s/suspend",
            project, zone, as.gce_instance_name(instance))
  # compute.instances.stop
  f <- gar_api_generator(url, 
                         "POST",
                         data_parse_function = function(x) x)
  out <- f()
  
  as.zone_operation(out)
}

#' @export
#' @rdname gce_vm_stop
gce_vm_suspend <- function(instances,
                        project = gce_get_global_project(), 
                        zone = gce_get_global_zone()){
  
  lapply(instances, gce_vm_suspend_one, project = project, zone = zone)
}


#' Open browser to the serial console output for a VM
#' 
#' Saves a few clicks
#' 
#' @param instance The VM to see serial console output for
#' @param open_browser Whether to return a URL or open the browser
#' 
#' @return a URL
#' @export
gce_vm_logs <- function(instance, 
                        open_browser = TRUE){
  
  pz <- gce_extract_projectzone(instance)
  
  the_name <- as.gce_instance_name(instance)
  the_url <- sprintf("https://console.cloud.google.com/compute/instancesDetail/zones/%s/instances/%s/console?project=%s",
                     pz$zone, the_name, pz$project)
  
  if(open_browser){
    if(!is.null(getOption("browser"))){
      utils::browseURL(the_url)
    }
  }
  
  myMessage("Serial console output for", the_name ,": ",the_url)
  
  the_url
  
}

