FROM gcr.io/gcer-public/googleauthr-verse
MAINTAINER Mark Edmondson (r@sunholo.com)

# install R package dependencies
RUN apt-get update && apt-get install -y \
    openssh-client

## install gcloud
RUN export CLOUD_SDK_REPO="cloud-sdk-$(lsb_release -c -s)" && \
  echo "deb http://packages.cloud.google.com/apt $CLOUD_SDK_REPO main" \
        | sudo tee -a /etc/apt/sources.list.d/google-cloud-sdk.list && \
  curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add - && \
  sudo apt-get update && sudo apt-get install google-cloud-sdk

# Update the package list and install the Cloud SDK
sudo apt-get update && sudo apt-get install google-cloud-sdk

## Install packages from CRAN
RUN install2.r --error \ 
    -r 'http://cran.rstudio.com' \
    zip \ 
    ## install Github packages
    && installGithub.r cloudyr/googleCloudStorageR \
                       cloudyr/googleComputeEngineR \
    ## clean up
    && rm -rf /tmp/downloaded_packages/ /tmp/*.rds \

COPY Rprofile.site /usr/local/lib/R/etc/Rprofile.site



