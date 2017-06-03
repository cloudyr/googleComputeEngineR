## script to push public versions of build Dockerfiles
## to Google project gcer-public 
## as per https://cloud.google.com/container-registry/docs/access-control
options("googleAuthR.scopes.selected" = "https://www.googleapis.com/auth/cloud-platform")
library(googleComputeEngineR)
library(googleCloudStorageR)

# auto auth


