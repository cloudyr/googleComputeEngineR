#' Toggle deletion protection for existing instances
#' 
#' @param instance The vm to work with its deletion protection
#' @param cmd Whether to get the status, or toggle "true" or "false" 
#'   on deletion protection for this VM
#' @param project The projectId
#' @param zone The zone
#' 
#' @export
#' @importFrom googleAuthR gar_api_generator
#' @examples 
#' 
#' \dontrun{
#' 
#' # a workflow for deleting lots of VMs across zones that have deletion protection
#' zones <- gce_list_zones()
#' instances <- lapply(zones$name, function(x) gce_list_instances(zone = x))
#' 
#' instances_e <- lapply(instances, function(x) x$items$name)
#' names(instances_e) <- zones$name
#' 
#' status <- lapply(zones$name, function(x){
#'   lapply(instances_e[[x]], function(y) {
#'     gce_vm_deletion_protection(y, cmd = "false", zone = x)))
#'     }
#'   }
#' 
#' deletes <- lapply(zones$name, function(x){
#'   lapply(instances_e[[x]], function(y) {
#'     gce_vm_delete(y, zone = x)))
#'     }
#'   }
#' }
gce_vm_deletion_protection <- function(instance,
                                       cmd = c("status", "true", "false"),
                                       project = gce_get_global_project(),
                                       zone = gce_get_global_zone()){
  
  cmd <- match.arg(cmd)

  if(cmd == "status"){
    # GET https://compute.googleapis.com/compute/v1/projects/[PROJECT_ID]/zones/[ZONE]/instances/[INSTANCE_NAME]
    f <- gar_api_generator("https://compute.googleapis.com/compute/v1/",
                           "GET",
                           path_args = list(
                             projects = project,
                             zones = zone,
                             instances = as.gce_instance_name(instance)
                           ),
                           data_parse_function = function(x) x)

  } else {
    # POST https://compute.googleapis.com/compute/v1/projects/[PROJECT_ID]/zones/[ZONE]/instances/[INSTANCE_NAME]/setDeletionProtection?deletionProtection=true
    f <- gar_api_generator("https://compute.googleapis.com/compute/v1/",
                           "POST",
                           path_args = list(
                             projects = project,
                             zones = zone,
                             instances = as.gce_instance_name(instance),
                             setDeletionProtection = ""
                           ),
                           pars_args = list(deletionProtection = cmd),
                           data_parse_function = function(x) x)
  }
  
  f()
  
}