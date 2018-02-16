options(googleAuthR.scopes.selected = "https://www.googleapis.com/auth/cloud-platform")

devtools::load_all()

vm <- gce_vm(template = "rstudio",
             name = "rstudio-server-8",
             username = "jas", password = "jas12345",
             predefined_type = "n1-standard-8",
             #externalIP = "103.323.2323.232" #invalid ip
             #externalIP = "35.230.96.64" #https://github.com/cloudyr/googleComputeEngineR/issues/69
             externalIP = "none"
)

