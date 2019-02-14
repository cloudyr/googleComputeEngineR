#' Make serviceAccounts objects
#' @noRd
gce_make_serviceaccounts <- function(){
  
  if(Sys.getenv("GCE_AUTH_FILE") == ""){
    stop("No email found in the authentication file at Sys.getenv('GCE_AUTH_FILE')", call.=FALSE)
  }
  
  email <- jsonlite::unbox(jsonlite::fromJSON(Sys.getenv("GCE_AUTH_FILE"))$client_email)
  
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