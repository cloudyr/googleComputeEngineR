FROM gcr.io/gcer-public/googleauthr-verse
MAINTAINER Mark Edmondson (r@sunholo.com)

# install R package dependencies
RUN apt-get update && apt-get install -y \
    openssh-client

COPY Rprofile.site /usr/local/lib/R/etc/Rprofile.site
