FROM rocker/tidyverse
#LABEL maintainer="alperyilmaz@gmail.com"
LABEL maintainer="r$markedmondson.me"

ENV WORKON_HOME /tensorflow

RUN apt-get update -y && \
    DEBIAN_FRONTEND=noninteractive \
      apt-get install --no-install-recommends -y -q \
          build-essential \
          python2.7 \
          python2.7-dev \
          python-pip \
          virtualenv \
          zlib1g-dev \
          libcublas8.0 \
          libcusolver.so.8.0 \
          libopenmpi-dev libcurl4-openssl-dev \
          gnupg \
          cmake libncurses5-dev \
      && pip install --upgrade pip virtualenv \
      && apt-get clean \
      && rm /var/lib/dpkg/info/* \
      && rm /var/lib/apt/lists/*debian*
      
##### CUDA stuff from https://github.com/rocker-org/ml/blob/master/tidyverse-gpu/Dockerfile
## CUDA Version
ENV CUDA_MAJOR_VERSION=9.2
ENV CUDA_MAJOR_VERSION_HYP=9.2
ENV CUDA_MINOR_VERSION=9.2.148-1
ENV NVIDIA_REQUIRE_CUDA="cuda>=9.2"

## CUDA Install
RUN wget -nv -P /root/manual http://developer.download.nvidia.com/compute/cuda/repos/ubuntu1604/x86_64/7fa2af80.pub \
&& echo "47217c49dcb9e47a8728b354450f694c9898cd4a126173044a69b1e9ac0fba96  /root/manual/7fa2af80.pub" | sha256sum -c --strict - \
&& apt-key add /root/manual/7fa2af80.pub \
&& wget -nv -P /root/manual http://developer.download.nvidia.com/compute/cuda/repos/ubuntu1604/x86_64/cuda-repo-ubuntu1604_${CUDA_MINOR_VERSION}_amd64.deb \
&& dpkg -i /root/manual/cuda-repo-ubuntu1604_${CUDA_MINOR_VERSION}_amd64.deb \
&& echo 'deb http://developer.download.nvidia.com/compute/machine-learning/repos/ubuntu1604/x86_64 /' > /etc/apt/sources.list.d/nvidia-ml.list \
&& rm -rf /root/manual \
&& apt-get update  && apt-get install --no-install-recommends -y \
cuda-toolkit-${CUDA_MAJOR_VERSION_HYP} \
libcudnn7 \
libcudnn7-dev \
&& ls /usr/local/cuda-${CUDA_MAJOR_VERSION}/targets/x86_64-linux/lib/stubs/* | xargs -I{} ln -s {} /usr/lib/x86_64-linux-gnu/ \
&& ln -s libcuda.so /usr/lib/x86_64-linux-gnu/libcuda.so.1 \
&& ln -s libnvidia-ml.so /usr/lib/x86_64-linux-gnu/libnvidia-ml.so.1 \
## Remove Stubs - to solve this issue: https://discuss.ropensci.org/t/using-the-gpu-backend-in-h2o-xgboost-in-a-rocker-based-docker-container/1561/2
&& rm -r -f  /usr/local/cuda/lib64/stubs

ENV CUDA_HOME=/usr/local/cuda
ENV CUDA_PATH=/usr/local/cuda
ENV PATH=$CUDA_HOME/bin:$PATH
ENV LD_LIBRARY_PATH=$CUDA_HOME/lib64:$CUDA_HOME/extras/CUPTI/lib64:$LD_LIBRARY_PATH
ENV NVIDIA_VISIBLE_DEVICES=all
ENV NVIDIA_DRIVER_CAPABILITIES=compute,utility 


## Get JAVA
RUN apt-get update -qq \
&& apt-get -y --no-install-recommends install \
default-jdk \
default-jre \
&& R CMD javareconf

# Set up env variables in R
RUN echo "rsession-ld-library-path=$LD_LIBRARY_PATH" | tee -a /etc/rstudio/rserver.conf \
&& echo "Sys.setenv(CUDA_HOME=\"$CUDA_HOME\"); Sys.setenv(CUDA_PATH=\"$CUDA_PATH\"); Sys.setenv(PATH=\"$PATH\")" | tee -a /usr/local/lib/R/etc/Rprofile.site

###################### End CUDA stuff

RUN mkdir /tensorflow \
    && virtualenv --system-site-packages /tensorflow
    
RUN . /tensorflow/bin/activate 

RUN echo 'WORKON_HOME = "/tensorflow"' >> /usr/local/lib/R/etc/Renviron 

RUN /usr/lib/R/site-library/littler/examples/install.r Rcpp gpuR reticulate keras

COPY install.R ./install.R
COPY hello-world.R /home/rstudio

RUN Rscript install.R

RUN rm -rf /tmp/Rtmp*/downloaded_packages/* \
    && rm -rf /tmp/downloaded_packages/* \
    && rm -rf /home/rstudio/.cache/pip \
    && rm -rf /root/.cache/pip
