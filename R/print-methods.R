#' @export
print.gce_instanceList <- function(x, ...){
  
  extract_ip <- function(ii){
    vapply(ii$items$networkInterfaces, function(x) {
      y <- x$accessConfigs[[1]]$natIP
      if(is.null(y)) y <- "No external IP"
      y
    }, character(1))
  }
  
  out <- x$items
  out$zone <- basename(out$zone)
  out$machineType <- basename(out$machineType)
  out$externalIP <- extract_ip(x)
  out$creationTimestamp <- timestamp_to_r(out$creationTimestamp)

  
  print_cols <- c("name","machineType","status","zone","externalIP","creationTimestamp")
  cat("==Google Cloud Engine Instance List==\n")
  print(out[, print_cols])
}
