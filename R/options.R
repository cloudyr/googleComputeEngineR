.onAttach <- function(libname, pkgname){
  
  attempt <- try(googleAuthR::gar_attach_auto_auth("https://www.googleapis.com/auth/cloud-platform",
                                    environment_var = "GCE_AUTH_FILE",
                                    travis_environment_var = "TRAVIS_GCE_AUTH_FILE"))
  if(inherits(attempt, "try-error")){
    warning("Tried to auto-authenticate but failed.")
  }
  
  if(Sys.getenv("GCE_CLIENT_ID") != ""){
    options(googleAuthR.client_id = Sys.getenv("GCE_CLIENT_ID"))
  }
  
  if(Sys.getenv("GCE_CLIENT_SECRET") != ""){
    options(googleAuthR.client_secret = Sys.getenv("GCE_CLIENT_SECRET"))
  }
  
  if(Sys.getenv("GCE_WEB_CLIENT_ID") != ""){
    options(googleAuthR.webapp.client_id = Sys.getenv("GCE_WEB_CLIENT_ID"))
  }
  
  if(Sys.getenv("GCE_WEB_CLIENT_SECRET") != ""){
    options(googleAuthR.webapp.client_id = Sys.getenv("GCE_WEB_CLIENT_SECRET"))
  }
  
  # if(Sys.getenv("GCE_DEFAULT_BUCKET") != ""){
  #   .gcs_env$bucket <- Sys.getenv("GCS_DEFAULT_BUCKET")
  #   packageStartupMessage("Set default bucket name to '", Sys.getenv("GCS_DEFAULT_BUCKET"),"'")
  # }
  
  invisible()
  
}