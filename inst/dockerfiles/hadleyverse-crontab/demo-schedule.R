library(googleCloudStorageR)
library(bigQueryR)
library(gmailr)
library(googleAnalyticsR)

## set options for authentication
options(googleAuthR.client_id = XXXXX)
options(googleAuthR.client_secret = XXXX)
options(googleAuthR.scopes.selected = c("https://www.googleapis.com/auth/cloud-platform",
                                        "https://www.googleapis.com/auth/analytics.readonly"))

## authenticate
## using service account, ensure service account email added to GA account, BigQuery user permissions set, etc.
googleAuthR::gar_auth_service("auth.json")

## get Google Analytics data
gadata <- google_analytics_4(123456, 
                             date_range = c(Sys.Date() - 2, Sys.Date() - 1),
                             metrics = "sessions",
                             dimensions = "medium",
                             anti_sample = TRUE)

## upload to Google BigQuery
bqr_upload_data(projectId = "myprojectId", 
                datasetId = "mydataset",
                tableId = paste0("gadata_",format(Sys.Date(),"%Y%m%d")),
                upload_data = gadata,
                create = TRUE)

## upload to Google Cloud Storage
gcs_upload(gadata, name = paste0("gadata_",Sys.Date(),".csv"))


## get top medium referrer
top_ref <- paste(gadata[order(gadata$sessions, decreasing = TRUE),][1, ], collapse = ",")
# 3456, organic

## send email with todays figures
daily_email <- mime(
  To = "bob@myclient.com",
  From = "bill@coolagency.com",
  Subject = "Todays winner is....",
  body = paste0("Top referrer was: "),top_ref)
send_message(daily_email)
