#' @export
print.gce_instanceList <- function(x, ...){
  
  out <- x$items
  out$zone <- basename(out$zone)
  out$machineType <- basename(out$machineType)
  out$externalIP <- extract_ip(x)
  out$creationTimestamp <- timestamp_to_r(out$creationTimestamp)

  print_cols <- c("name","machineType","status","zone","externalIP","creationTimestamp")
  
  cat("==Google Compute Engine Instance List==\n")
  print(out[, print_cols])
}

#' @export
print.gce_instance <- function(x, ...){
  
  cat("==Google Compute Engine Instance==\n")
  cat("\nName:               ", x$name)
  cat("\nCreated:            ", as.character(timestamp_to_r(x$creationTimestamp)))
  cat("\nMachine Type:       ", basename(x$machineType))
  cat("\nStatus:             ", x$status)
  cat("\nZone:               ", basename(x$zone))
  cat("\nExternal IP:        ", x$networkInterfaces$accessConfigs[[1]]$natIP)
  cat("\nDisks: \n")
  print(x$disks[ , c("deviceName","type","mode","boot","autoDelete")])
  
  if(!is.null(x$metadata$items)){
    cat("\nMetadata:\n")
    print(x$metadata$items)
  }
  
  
}
