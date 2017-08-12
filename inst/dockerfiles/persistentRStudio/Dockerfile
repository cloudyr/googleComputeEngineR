FROM gcr.io/gcer-public/googleauthr-verse
MAINTAINER Mark Edmondson (r@sunholo.com)

# install R package dependencies
RUN apt-get update && apt-get install -y \
    openssh-client
    ## clean up
    && apt-get clean \ 
    && rm -rf /var/lib/apt/lists/ \ 
    && rm -rf /tmp/downloaded_packages/ /tmp/*.rds

COPY Rprofile.site /usr/local/lib/R/etc/Rprofile.site
