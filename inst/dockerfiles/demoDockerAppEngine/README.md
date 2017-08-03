# README

0. Create a Google Appengine project in the US region (only region that supports flexible containers at the moment)
1. Create a scheduled script e.g. `schedule.R` - you can use auth from environment files specified in `app.yaml`.
2. Make an API out of the script by using `plumber` - example:

```r
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

```

3. Create Dockerfile.  If using `containerit` then replace FROM with `trestletech/plumber` and add the below lines to use correct AppEngine port:

Example:

```r
library(containerit)

dockerfile <- dockerfile("schedule.R", copy = "script_dir", soft = TRUE)
write(dockerfile, file = "Dockerfile")
```

Then change/add these lines:

```
EXPOSE 8080
ENTRYPOINT ["R", "-e", "pr <- plumber::plumb(commandArgs()[4]); pr$run(host='0.0.0.0', port=8080)"]
CMD ["schedule.R"]
```

Example output:

```
FROM trestletech/plumber
LABEL maintainer="mark"
RUN export DEBIAN_FRONTEND=noninteractive; apt-get -y update \
 && apt-get install -y libcairo2-dev \
	libcurl4-openssl-dev \
	libgmp-dev \
	libpng-dev \
	libssl-dev \
	libxml2-dev \
	make \
	pandoc \
	pandoc-citeproc \
	zlib1g-dev
RUN ["install2.r", "-r 'https://cloud.r-project.org'", "readr", "googleCloudStorageR", "Rcpp", "digest", "crayon", "withr", "mime", "R6", "jsonlite", "xtable", "magrittr", "httr", "curl", "testthat", "devtools", "hms", "shiny", "httpuv", "memoise", "htmltools", "openssl", "tibble", "remotes"]
RUN ["installGithub.r", "MarkEdmondson1234/googleAuthR@7917351", "hadley/rlang@ff87439"]
WORKDIR /payload/
COPY [".", "./"]

EXPOSE 8080
ENTRYPOINT ["R", "-e", "pr <- plumber::plumb(commandArgs()[4]); pr$run(host='0.0.0.0', port=8080)"]
CMD ["schedule.R"]
```


3. Specify `app.yaml` with any environment vars such as auth files, that will be included in same folder.  Also limit instances if needed to make sure errors down't spawn hundreds of VMs.

Example:

```yaml
runtime: custom
env: flex

env_variables:
  GCS_AUTH_FILE: auth.json
```

4. Specify `cron.yaml` for the schedule needed:

```yaml
cron:
- description: "test cron"
  url: /demoR
  schedule: every 1 hours
```

5. Deploy via `gcloud app deploy --project your-project`

Deploy new cron via `gcloud app deploy cron.yaml --project your-project`

6. App should then be deployed on https://your-project.appspot.com/ - every GET request to https://your-project.appspot.com/demoR (or other endpoints you have specified in R script) will run the R code.  The cron will run every hour to this endpoint as specified by the cron file above.  Logs for the instance are found [here](https://console.cloud.google.com/logs/viewer).
