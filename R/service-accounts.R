#' Make serviceAccounts objects
#' @noRd
gce_make_serviceaccounts <- function(){
  
  # use this on GCE only
  token = try({gargle::credentials_gce()}, silent = TRUE)
  email = NULL
  if (inherits(token, "GceToken")) {
    email = token$params$service_account
    scope =  token$params$scope
    if (is.null(scope) || !tolower(basename(scope)) %in% "cloud-platform") {
      email = NULL
    }
  }
  if(Sys.getenv("GCE_AUTH_FILE") == "" && is.null(email)){
    stop("No email found in the authentication file at Sys.getenv('GCE_AUTH_FILE')", call.=FALSE)
  }
  
  if (is.null(email)) {
    email <- jsonlite::unbox(jsonlite::fromJSON(Sys.getenv("GCE_AUTH_FILE"))$client_email)
  }
  if(is.null(email)){
    stop("Couldn't find client_email in GCE_AUTH_FILE environment file", call.=FALSE)
  }
  
  list(
    list(
      email = email,
      scopes = list("https://www.googleapis.com/auth/cloud-platform")
    )
  )
  
}