FROM opencpu/base
MAINTAINER Mark Edmondson (r@sunholo.com)

# install any package dependencies
RUN apt-get update && apt-get install -y \
    nano \
    ## clean up
    && apt-get clean \ 
    && rm -rf /var/lib/apt/lists/ \ 
    && rm -rf /tmp/downloaded_packages/ /tmp/*.rds
    
## Install your custom package from Github
RUN Rscript -e "devtools::install_github(c('MarkEdmondson1234/predictClickOpenCPU'))"
