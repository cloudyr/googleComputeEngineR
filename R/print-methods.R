#' @export
print.gce_instanceList <- function(x, ...){
  
  cat("==Google Compute Engine Instance List==\n")
  out <- x$items
  if (!is.null(out)) {
    out$zone <- basename(out$zone)
    out$machineType <- basename(out$machineType)
    out$externalIP <- extract_ip(x)
    out$creationTimestamp <- timestamp_to_r(out$creationTimestamp)

    print_cols <- c("name","machineType","status","zone","externalIP","creationTimestamp")
  
    print(out[, print_cols])
  } else {
    cat("<none>\n")
  }
  invisible(x)
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
  
}

#' @export
print.gce_zone_operation <- function(x, ...){
  
  cat("==Operation", x$operationType, ": ", x$status)
  cat("\nStarted: ", as.character(timestamp_to_r(x$insertTime)))
  
  if(!is.null(x$endTime)){
    cat0("\nEnded:", as.character(timestamp_to_r(x$endTime)))
    cat("Operation complete in", 
        format(timestamp_to_r(x$endTime) - timestamp_to_r(x$insertTime)), 
        "\n")
  }

  if(!is.null(x$error)){
    errors <- x$error$errors
    e.m <- paste(vapply(errors, print, character(1)), collapse = " : ", sep = " \n")
    cat("\n# Error: ", e.m)
    cat("\n# HTTP Error: ", x$httpErrorStatusCode, x$httpErrorMessage)
  }
}