library(googleAuthR)         ## authentication
library(googleCloudStorageR) ## google cloud storage

## set authentication details for non-cloud services
# options(googleAuthR.scopes.selected = "XXX",
#         googleAuthR.client_id = "",
#         googleAuthR.client_secret = "")

## download or do something
something <- tryCatch({
    gcs_get_object("schedule/test.csv", 
                   bucket = "mark-edmondson-public-files")
  }, error = function(ex) {
    NULL
  })
    
something_else <- data.frame(X1 = 1,
                             time = Sys.time(), 
                             blah = paste(sample(letters, 10, replace = TRUE), collapse = ""))
something <- rbind(something, something_else)

## authenticate on GCE for google cloud services
googleAuthR::gar_gce_auth()

tmp <- tempfile(fileext = ".csv")
on.exit(unlink(tmp))
write.csv(something, file = tmp, row.names = FALSE)
## upload something
gcs_upload(tmp, 
           bucket = "mark-edmondson-public-files", 
           name = "schedule/test.csv")
