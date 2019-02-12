FROM rocker/tidyverse:latest

RUN apt-get update && apt-get install -y \
  --force-yes \
  --allow-unauthenticated \ 
  --no-install-recommends \
  --no-upgrade \
  build-essential \
  curl \
  cmake \ 
  gnupg \
  libcurl4-openssl-dev \
  libncurses5-dev \
  libopenmpi-dev \ 
## Consider migrating these to python-3
  python-pip \
  python-setuptools \
  python-dev

## CUDA Version
ENV CUDA_MAJOR_VERSION=9.0
ENV CUDA_MAJOR_VERSION_HYP=9.0
ENV CUDA_MINOR_VERSION=9.0.176-1
ENV NVIDIA_REQUIRE_CUDA="cuda==9.0"

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

# Python Xgboost for GPU
RUN pip install wheel setuptools scipy --upgrade
RUN pip install xgboost

### R Xgboost
RUN git clone --recursive https://github.com/dmlc/xgboost \
  && mkdir -p xgboost/build && cd xgboost/build \
  && cmake .. -DUSE_CUDA=ON -DR_LIB=ON \
  && make install -j$(nproc) 

## Get latest release of h2o
RUN Rscript -e 'install.packages("h2o", type="source", repos="http://h2o-release.s3.amazonaws.com/h2o/latest_stable_R")'


## Install Keras
## note: virtualenv pulls in python3, not 2.7
RUN apt-get update && apt-get -y install virtualenv \
## pip install h5py pyyaml requests Pillow tensorflow-gpu keras --no-cache-dir \
  && install2.r keras \
&& R -e "keras::install_keras(tensorflow='gpu')"