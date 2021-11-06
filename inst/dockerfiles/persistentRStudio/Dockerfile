FROM rocker/tidyverse
MAINTAINER Mark Edmondson (r@sunholo.com)

# install gcsfuse deps
RUN apt-get update && apt-get install -y gnupg lsb-release wget
RUN lsb_release -c -s > /tmp/lsb_release

RUN GCSFUSE_REPO=$(cat /tmp/lsb_release); \
    echo "deb http://packages.cloud.google.com/apt gcsfuse-$GCSFUSE_REPO main" | \
    tee /etc/apt/sources.list.d/gcsfuse.list
RUN wget -O - https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -

# install system deps
RUN apt-get -qqy update && apt-get install -qqy \
    openssh-client \
    qpdf \
    libsodium-dev \
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
