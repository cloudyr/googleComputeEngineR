library(googleCloudStorageR)
library(googleAnalyticsR)
gcs_global_bucket("mark-cron")

## gcs can authenticate via GCE auth keys
googleAuthR::gar_gce_auth()

## use GCS to download auth key (that you have previously uploaded)
gcs_get_object("ga.httr-oauth", 
               saveToDisk = "ga.httr-oauth")

auth_token <- readRDS("ga.httr-oauth")
options(googleAuthR.scopes.selected = c("https://www.googleapis.com/auth/analytics", 
                                        "https://www.googleapis.com/auth/analytics.readonly"),
        googleAuthR.httr_oauth_cache = "ga.httr-oauth")
googleAuthR::gar_auth(auth_token)

## fetch data

gadata <- google_analytics_4(81416156,
                             date_range = c(Sys.Date() - 8, Sys.Date() - 1),
                             dimensions = c("medium", "source", "landingPagePath"),
                             metrics = "sessions",
                             max = -1)

## back to Cloud Storage
googleAuthR::gar_gce_auth()
gcs_upload(gadata, name = "uploads/gadata_81416156.csv")
gcs_upload("ga.httr-oauth")

message("Upload complete", Sys.time())