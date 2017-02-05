#' Add one firewall rule to the network
#' 
#' @description 
#' 
#' Use this to create firewall rules to apply to the network settings.  
#'   Most commonly this is to setup web access (port 80 and 443)
#' 
#' @param name Name of the firewall rule
#' @param protocol Protocol such as \code{tcp, udp, icmp, esp, ah, sctp} or IP protocol number.
#' @param ports Port numbers to open
#' @param sourceRanges From where to accept connections.  If \code{NULL} then will default to \code{0.0.0.0/0} (everywhere)
#' @param sourceTags A list of instance tags this rule applies to. One or both of \code{sourceRanges} and \code{sourceTags} may be set.
#' @param project The Google Cloud project
#' 
#' @seealso API Documentation \url{https://cloud.google.com/compute/docs/reference/latest/firewalls/insert}
#' 
#' @details 
#' 
#' @section sourceRanges and/or sourceTags:
#' 
#' If both properties are set, 
#'   an inbound connection is allowed if the range or the tag of the source matches the 
#'   sourceRanges OR matches the sourceTags property; the connection does not need to match both properties.
#' 
#' @return A global operation object
#' @export
gce_make_firewall_rule <- function(name,
                                   protocol,
                                   ports,
                                   sourceRanges = NULL,
                                   sourceTags = NULL,
                                   project = gce_get_global_project()) {
  url <-
    sprintf("https://www.googleapis.com/compute/v1/projects/%s/global/firewalls",
            project)
  
  if(is.null(sourceRanges)) sourceRanges <- "0.0.0.0/0"
  
  the_rule <- list(
    name = jsonlite::unbox(name),
    allowed = list(
      list(IPProtocol = jsonlite::unbox(protocol), 
           ports = list(ports)
      )
    ),
    sourceRanges = sourceRanges,
    sourceTags = sourceTags
  )
  
  f <- gar_api_generator(url, "POST", data_parse_function = function(x) x)
  
  f(the_body = the_rule)
  
}

#' Delete a firewall rule
#' 
#' Deletes a firewall rule of name specified
#' 
#' @inheritParams gce_make_firewall_rule
#' 
#' @export
gce_delete_firewall_rule <- function(name, project = gce_get_global_project()){
  
  url <-
    sprintf("https://www.googleapis.com/compute/v1/projects/%s/global/firewalls/%s",
            project, name)
  
  f <- gar_api_generator(url, "DELETE", data_parse_function = function(x) x)
  suppressWarnings(f())
  
}