#' Defunct - Authenticate this session
#' 
#' No longer used.  Authenticate via downloading a JSON file and setting in your environment arguments instead.
#'
#' @param new_user If TRUE, reauthenticate via Google login screen
#' @param no_auto Will ignore auto-authentication settings if TRUE
#'
#' @return Invisibly, the token that has been saved to the session
#' @import googleAuthR
#' @export
gce_auth <- function(new_user = FALSE, no_auto = FALSE){
  .Defunct("gar_attach_auto_auth", package = "googleAuthR", 
           msg = "gce_auth() is defunct.  Authenticate instead by downloading your JSON key and placing in a GCE_AUTH_FILE environment argument.  See https://cloudyr.github.io/googleComputeEngineR/articles/installation-and-authentication.html or vignette('installation-and-authentication', package = 'googleComputeEngineR')")
}

