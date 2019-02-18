# options(googleAuthR.scopes.selected = "https://www.googleapis.com/auth/cloud-platform")
# 
# vm <- gce_vm(template = "rstudio",
#              name = "rstudio-server-10",
#              username = "jas", password = "jas12345",
#              predefined_type = "n1-standard-8",
#              #externalIP = "35.230.96.64" 
#              #externalIP = "103.323.2323.232" #invalid ip
#              externalIP = "none"
#              #externalIP = NULL
# )
# 
