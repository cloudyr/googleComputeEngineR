FROM rocker/tidyverse

LABEL maintainer="alperyilmaz@gmail.com"

ENV WORKON_HOME /tensorflow

RUN apt-get update && apt-get install -y --no-install-recommends \
    && libpython2.7 python-pip virtualenv zlib1g-dev \
    && rm /var/lib/dpkg/info/* \
    && rm /var/lib/apt/lists/*debian*

RUN mkdir /tensorflow \
    && virtualenv --system-site-packages /tensorflow
    
RUN . /tensorflow/bin/activate 

RUN echo 'WORKON_HOME = "/tensorflow"' >> /usr/local/lib/R/etc/Renviron 

RUN installGithub.r rstudio/reticulate rstudio/keras

RUN git clone https://github.com/rstudio/keras.git && \
    cp -r keras/vignettes/examples /home/rstudio && \
    rm -r keras/

COPY install.R ./install.R

RUN Rscript install.R

RUN rm -rf /tmp/Rtmp*/downloaded_packages/* \
    && rm -rf /tmp/downloaded_packages/* \
    && rm -rf /home/rstudio/.cache/pip \
    && rm -rf /root/.cache/pip
