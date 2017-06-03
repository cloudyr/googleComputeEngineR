FROM rocker/hadleyverse
MAINTAINER Mark Edmondson (r@sunholo.com)

# install cron and R package dependencies
RUN apt-get update && apt-get install -y \
    cron \
    nano \
    ## clean up
    && apt-get clean \ 
    && rm -rf /var/lib/apt/lists/ \ 
    && rm -rf /tmp/downloaded_packages/ /tmp/*.rds
    
## Install packages from CRAN
RUN install2.r --error \ 
    -r 'http://cran.rstudio.com' \
    googleComputeEngineR googleCloudStorageR shinyFiles cronR \
    ## && Rscript -e "devtools::install_github(c('bnosac/cronR', 'MarkEdmondson1234/googleAuthR'))" \
    ## clean up
    && rm -rf /tmp/downloaded_packages/ /tmp/*.rds

## Start cron
RUN sudo service cron start
