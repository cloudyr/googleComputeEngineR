#' Set a minCPU platform on a stopped instance
#' 
#' @param instance The (stopped) instance to set a minimum CPU platform upon
#' @param minCpuPlatform The platform to set
#' 
#' @export
#' @importFrom googleAuthR gar_api_generator
gce_set_mincpuplatform <- function(instance, minCpuPlatform){
  instance <- as.gce_instance(instance)
  instance_pz <- gce_extract_projectzone(instance)
  
  assert_that(is.string(minCpuPlatform))
  
  f <- gar_api_generator(
    sprintf("https://www.googleapis.com/compute/v1/projects/%s/zones/%s/instances/%s/setMinCpuPlatform",
            instance_pz$project, instance_pz$zone, instance$name),
    "POST",
    data_parse_function = function(x) x
  )
  
  f(the_body = list(minCpuPlatform = minCpuPlatform))
}
