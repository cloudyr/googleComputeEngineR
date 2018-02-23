FROM rocker/tidyverse
MAINTAINER Mark Edmondson (r@sunholo.com)

RUN apt-get -qqy update && apt-get install -qqy \
        openssh-client \
        qpdf
        
## Install packages from CRAN
RUN install2.r --error \ 
    -r 'http://cran.rstudio.com' \
    googleAuthR \ 
## install Github packages
    && installGithub.r \
    MarkEdmondson1234/gcloudR
    
## clean up
    && rm -rf /tmp/downloaded_packages/ /tmp/*.rds

COPY rserver.conf /etc/rstudio/rserver.conf

EXPOSE 80
