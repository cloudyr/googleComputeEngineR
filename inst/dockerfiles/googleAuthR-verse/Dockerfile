FROM rocker/verse
MAINTAINER Mark Edmondson (r@sunholo.com)

# install R package dependencies
RUN apt-get update && apt-get install -y \
    ## clean up
    && apt-get clean \ 
    && rm -rf /var/lib/apt/lists/ \ 
    && rm -rf /tmp/downloaded_packages/ /tmp/*.rds
    
## Install packages from CRAN
RUN install2.r --error \ 
    -r 'http://cran.rstudio.com' \
    googleAuthR googleAnalyticsR searchConsoleR googleCloudStorageR bigQueryR \
    ## install Github packages
    && Rscript -e "devtools::install_github(c('MarkEdmondson1234/youtubeAnalyticsR', 'MarkEdmondson1234/googleID', 'cloudyr/googleComputeEngineR'))" \
    ## clean up
    && rm -rf /tmp/downloaded_packages/ /tmp/*.rds \
