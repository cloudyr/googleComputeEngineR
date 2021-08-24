#' Get the external IP of an instance
#' 
#' @param instance Name or instance object to find the external IP for
#' @param verbose Give a user message about the IP
#' @param ... passed to \link{gce_get_instance}
#' 
#' This is a helper to extract the external IP of an instance
#' @return The external IP
#' @export
gce_get_external_ip <- function(instance, 
                                verbose = TRUE,
                                ...){
  
  ins <- as.gce_instance(instance, ...)
  
  ip <- ins$networkInterfaces$accessConfigs[[1]]$natIP
  
  if(verbose){
    myMessage("External IP for instance ", as.gce_instance_name(ins), " : ", ip, level = 3)
  }
  
  invisible(ip)
}

#' Make a network interface for instance creation
#' 
#' @param name Name of the access config
#' @param network Name of network resource
#' @param externalIP An external IP you have created previously, leave NULL to have one assigned or "none" for none
#' @param project Project ID for this request
#' @param subnetwork A subnetwork name if its exists
#' 
#' You need to provide accessConfig explicitly if you want an ephemeral IP assigned, see \code{https://cloud.google.com/compute/docs/vm-ip-addresses}
#' 
#' @return A Network object
#' @export
gce_make_network <- function(network = "default",
                             name = NULL,
                             subnetwork = NULL,
                             externalIP = NULL,
                             project = gce_get_global_project()){
  
  make_ac <- function(externalIP, name){
    if(!is.null(externalIP) && externalIP == "none") return(NULL)
    
    list(
      list(
        natIP = jsonlite::unbox(externalIP),
        type = jsonlite::unbox("ONE_TO_ONE_NAT")
      )
    )
  }
  
  net <- gce_get_network(network, project = project)
  
  structure(
    list(
      rmNullObs(list(
        network = jsonlite::unbox(net$selfLink),
        subnetwork = jsonlite::unbox(subnetwork),
        name = name,
        accessConfigs = make_ac(externalIP, name)
      ))
    ),
    class = c("gce_networkInterface", "list")
  )
  
}

is.gce_networkInterface <- function(x){
  inherits(x, "gce_networkInterface")
}

#' Returns the specified network.
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
#' @param network Name of the network to return
#' @importFrom googleAuthR gar_api_generator
#' @export
gce_get_network <- function(network,
                            project = gce_get_global_project()) {
  url <- sprintf("https://www.googleapis.com/compute/v1/projects/%s/global/networks/%s", 
                 project, network)
  # compute.networks.get
  f <- gar_api_generator(url, "GET", data_parse_function = function(x) x)
  f()
  
}

#' Retrieves the list of networks available to the specified project.
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
gce_list_networks <- function(filter = NULL, 
                              maxResults = NULL, 
                              pageToken = NULL, 
                              project = gce_get_global_project()) {
  
  url <- sprintf("https://www.googleapis.com/compute/v1/projects/%s/global/networks", 
                 project)
  # compute.networks.list
  pars <- list(filter = filter, maxResults = maxResults, 
               pageToken = pageToken)
  pars <- rmNullObs(pars)
  
  f <- gar_api_generator(url, "GET", 
                         pars_args = pars, 
                         data_parse_function = function(x) x$items)
  f()
  
}


#' Deletes an Access Config, Typically for an External IP Address.
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
#' @param access_config The name of the access config to delete.
#' @param network_interface The name of the network interface.
#' @param project Project ID for this request, default as set by \link{gce_get_global_project}
#' @param zone The name of the zone for this request, default as set by \link{gce_get_global_zone}
#' 
#' @return A list of operation objects with pending status
#' 
#' @importFrom googleAuthR gar_api_generator
#' @export
gce_delete_access_config <- function(
  instance,
  access_config = "external-nat",
  network_interface = "nic0",
  project = gce_get_global_project(), 
  zone = gce_get_global_zone()){
  
  url <- sprintf(
    "https://compute.googleapis.com/compute/v1/projects/%s/zones/%s/instances/%s/deleteAccessConfig", 
    project, zone, as.gce_instance_name(instance))
  
  pars <- list(accessConfig = access_config,
               networkInterface = network_interface)
  pars <- rmNullObs(pars)
  
  # compute.instances.deleteAccessConfig
  f <- gar_api_generator(url, 
                         "POST", 
                         pars_args = pars, 
                         data_parse_function = function(x) x)
  f()
}

