.onAttach <- function(libname, pkgname){
  
  attempt <- try(googleAuthR::gar_attach_auto_auth("https://www.googleapis.com/auth/cloud-platform",
                                    environment_var = "GCE_AUTH_FILE"))
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
  
  if(Sys.getenv("GCE_DEFAULT_PROJECT_ID") != ""){
    .gce_env$project <- Sys.getenv("GCE_DEFAULT_PROJECT_ID")
    packageStartupMessage("Set default project ID to '", .gce_env$project,"'")
  }
  
  if(Sys.getenv("GCE_DEFAULT_ZONE") != ""){
    .gce_env$zone <- Sys.getenv("GCE_DEFAULT_ZONE")
    packageStartupMessage("Set default zone to '", .gce_env$zone,"'")
  }
  
  invisible()
  
}