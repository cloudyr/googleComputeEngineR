library(googleAuthR)         ## authentication
library(googleCloudStorageR)  ## google cloud storage
library(readr)                ## 
## gcs auto authenticated via environment file 
## pointed to via sys.env GCS_AUTH_FILE

#* @get /demoR
demoScheduleAPI <- function(){
  
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
  
  tmp <- tempfile(fileext = ".csv")
  on.exit(unlink(tmp))
  write.csv(something, file = tmp, row.names = FALSE)
  ## upload something
  gcs_upload(tmp, 
             bucket = "mark-edmondson-public-files", 
             name = "schedule/test.csv")
  
  cat("Done", Sys.time())
}

## run locally via
# pr <- plumber::plumb("schedule.R"); pr$run(port=8080)