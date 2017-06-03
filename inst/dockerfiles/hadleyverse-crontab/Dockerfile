FROM rocker/tidyverse
MAINTAINER Mark Edmondson (r@sunholo.com)

# install cron and R package dependencies
RUN apt-get update && apt-get install -y \
    cron \
    nano \
    libxml2-dev \
    ## clean up
    && apt-get clean \ 
    && rm -rf /var/lib/apt/lists/ \ 
    && rm -rf /tmp/downloaded_packages/ /tmp/*.rds
    
## Install packages from CRAN
RUN install2.r --error \ 
    -r 'http://cran.rstudio.com' \
    googleAuthR shinyFiles googleCloudStorageR \
    bigQueryR gmailr googleAnalyticsR cronR googleComputeEngineR searchConsoleR \
    ## install Github packages
    && Rscript -e "devtools::install_github(c('MarkEdmondson1234/googleLanguageR'))" \
    ## clean up
    && rm -rf /tmp/downloaded_packages/ /tmp/*.rds \

## Start cron
RUN sudo service cron start
