FROM rocker/hadleyverse
MAINTAINER Mark Edmondson (r@sunholo.com)

# install cron and nano and tensorflow and tflearn
RUN apt-get update && apt-get install -y \
    cron nano \
    python-pip python-dev libhdf5-dev \
    && pip install cython \
    && pip install numpy \
    && pip install pandas \
    && export TF_BINARY_URL=https://storage.googleapis.com/tensorflow/linux/cpu/tensorflow-1.0.0-cp27-none-linux_x86_64.whl \
    && pip install --upgrade $TF_BINARY_URL \
    && pip install git+https://github.com/tflearn/tflearn.git \

    && pip install feather-format \
    && pip install h5py \
    ## clean up
    && apt-get clean \ 
    && rm -rf /var/lib/apt/lists/ \ 
    && rm -rf /tmp/downloaded_packages/ /tmp/*.rds
    
## Install packages from CRAN
RUN install2.r --error \ 
    -r 'http://cran.rstudio.com' \
    googleAuthR googleAnalyticsR searchConsoleR googleCloudStorageR bigQueryR htmlwidgets feather rPython \
    ## install Github packages
    && Rscript -e "devtools::install_github(c('MarkEdmondson1234/youtubeAnalyticsR', 'MarkEdmondson1234/googleID', 'MarkEdmondson1234/googleAuthR'))" \
    && Rscript -e "devtools::install_github(c('bnosac/cronR'))" \
    && Rscript -e "devtools::install_github(c('rstudio/tensorflow'))" \
    ## clean up
    && rm -rf /tmp/downloaded_packages/ /tmp/*.rds \
