FROM rocker/tidyverse
MAINTAINER Mark Edmondson (r@sunholo.com)

# install gcsfuse
ENV GCSFUSE_REPO=gcsfuse-`lsb_release -c -s`
RUN echo "deb http://packages.cloud.google.com/apt $GCSFUSE_REPO main" | \
    sudo tee /etc/apt/sources.list.d/gcsfuse.list \
    curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | \
    sudo apt-key add -


RUN apt-get -qqy update && apt-get install -qqy \
    openssh-client \
    qpdf \
    gcsfuse
        
## Install packages from CRAN
RUN install2.r --error \ 
    -r 'http://cran.rstudio.com' \
    googleAuthR \ 
    googleComputeEngineR \ 
    googleAnalyticsR \ 
    searchConsoleR \ 
    googleCloudStorageR \
    bigQueryR \ 
    googleCloudRunner \
    zip \
    ## install Github packages
    && installGithub.r cloudyr/googleCloudStorageR \
                       cloudyr/googleComputeEngineR \
                       MarkEdmondson1234/googleCloudRunner \
    ## clean up
    && rm -rf /tmp/downloaded_packages/ /tmp/*.rds

COPY Rprofile.site /usr/local/lib/R/etc/Rprofile.site
