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
#' 
#' @section sourceRanges and/or sourceTags:
#' 
#' If both properties are set, 
#'   an inbound connection is allowed if the range or the tag of the source matches the 
#'   sourceRanges OR matches the sourceTags property; the connection does not need to match both properties.
#'
#' @examples 
#' 
#' \dontrun{
#' 
#'   gce_make_firewall_rule("allow-http", protocol = "tcp", ports = 80)
#'   gce_make_firewall_rule("allow-https", protocol = "tcp", ports = 443)
#'   gce_make_firewall_rule("shiny", protocol = "tcp", ports = 3838)
#'   gce_make_firewall_rule("rstudio", protocol = "tcp", ports = 8787)
#' }
#' 
#' @return A global operation object
#' @family firewall functions
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
  
  out <- f(the_body = the_rule)
  
  as.global_operation(out)
}

#' Delete a firewall rule
#' 
#' Deletes a firewall rule of name specified
#' 
#' @inheritParams gce_make_firewall_rule
#' @seealso API Documentation \url{https://cloud.google.com/compute/docs/reference/latest/firewalls/delete}
#' @export
#' @family firewall functions
gce_delete_firewall_rule <- function(name, project = gce_get_global_project()){
  
  url <-
    sprintf("https://www.googleapis.com/compute/v1/projects/%s/global/firewalls/%s",
            project, name)
  
  f <- gar_api_generator(url, "DELETE", data_parse_function = function(x) x)
  out <- suppressWarnings(f())
  
  as.global_operation(out)
}

#' Get a firewall rule
#' 
#' Get a firewall rule of name specified
#' 
#' @inheritParams gce_make_firewall_rule
#' @seealso API Documentation \url{https://cloud.google.com/compute/docs/reference/latest/firewalls/get}
#' @export
#' @family firewall functions
gce_get_firewall_rule <- function(name, project = gce_get_global_project()){
  
  url <-
    sprintf("https://www.googleapis.com/compute/v1/projects/%s/global/firewalls/%s",
            project, name)
  
  f <- gar_api_generator(url, "GET", data_parse_function = function(x) x)
  f()
  
}

#' List firewall rules
#' 
#' Get a firewall rule of name specified
#' 
#' @inheritParams gce_make_firewall_rule
#' @inheritParams gce_list_networks
#' @seealso API Documentation \url{https://cloud.google.com/compute/docs/reference/latest/firewalls/list}
#' @export
#' @family firewall functions
gce_list_firewall_rules <- function(filter = NULL, 
                                    maxResults = NULL, 
                                    pageToken = NULL, 
                                    project = gce_get_global_project()){
  
  url <-
    sprintf("https://www.googleapis.com/compute/v1/projects/%s/global/firewalls",
            project)

  pars <- list(filter = filter, 
               maxResults = maxResults, 
               pageToken = pageToken)
  pars <- rmNullObs(pars)
  
  f <- gar_api_generator(url, "GET", pars_args = pars, data_parse_function = function(x) x)
  f()
  
}

#' Make HTTP and HTTPS firewall rules
#' 
#' Do the common use case of opening HTTP and HTTPS ports
#' 
#' @param project The project the firewall will open for
#' 
#' @details 
#' 
#' This will invoke \link{gce_make_firewall_rule} and look for the rules named \code{allow-http} and \code{allow-https}.
#' If not present, it will create them.
#' 
#' @return Vector of the firewall objects
#' 
#' @export
#' @family firewall functions
gce_make_firewall_webports <- function(project = gce_get_global_project()){
  
  existing <- gce_list_firewall_rules(project = project)
  names <- existing$items$name
  
  ## find 'default-allow-http' or 'allow-http'
  if(any(grepl("allow-http$", names))){
    myMessage("http firewall exists: ", paste(names[grepl("allow-http$", names)], collapse = " "), level = 2)
    out1 <- lapply(names[grepl("allow-http$", names)], gce_get_firewall_rule, project = project)
  } else {
    myMessage("Creating http firewall rule", level = 3)
    ## make the firewall
    op <- gce_make_firewall_rule("allow-http", protocol = "tcp", ports = 80)
    out1 <- gce_wait(op)
  }
  
  ## find 'default-allow-https' or 'allow-https'
  if(any(grepl("allow-https$", names))){
    myMessage("https firewall exists: ", paste(names[grepl("allow-https$", names)], collapse = " "), level = 2)
    out2 <- lapply(names[grepl("allow-https$", names)], gce_get_firewall_rule, project = project)
  } else {
    ## make the firewall
    myMessage("Creating https firewall rule", level = 3)
    op <- gce_make_firewall_rule("allow-https", protocol = "tcp", ports = 443)
    out2 <- gce_wait(op)
  }
  
  c(out1, out2)
}
