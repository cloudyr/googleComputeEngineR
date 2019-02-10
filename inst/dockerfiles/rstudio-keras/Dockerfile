FROM rocker/tidyverse
#LABEL maintainer="alperyilmaz@gmail.com"
LABEL maintainer="r$markedmondson.me"

ENV WORKON_HOME /tensorflow
    
# from https://www.tensorflow.org/install/gpu
# Add NVIDIA package repository
RUN apt-key adv --fetch-keys http://developer.download.nvidia.com/compute/cuda/repos/ubuntu1604/x86_64/7fa2af80.pub \
    && wget http://developer.download.nvidia.com/compute/cuda/repos/ubuntu1604/x86_64/cuda-repo-ubuntu1604_9.1.85-1_amd64.deb \
    && apt install -y ./cuda-repo-ubuntu1604_9.1.85-1_amd64.deb \
    && wget http://developer.download.nvidia.com/compute/machine-learning/repos/ubuntu1604/x86_64/nvidia-machine-learning-repo-ubuntu1604_1.0.0-1_amd64.deb \
    && apt install -y ./nvidia-machine-learning-repo-ubuntu1604_1.0.0-1_amd64.deb \
    && apt update

# Install CUDA and tools. Include optional NCCL 2.x
RUN apt install -y -q \
         cuda9.0 \
         cuda-cublas-9-0 \
         cuda-cufft-9-0 \
         cuda-curand-9-0 \
         cuda-cusolver-9-0 \
         cuda-cusparse-9-0 \
         libcudnn7=7.2.1.38-1+cuda9.0 \
         libnccl2=2.2.13-1+cuda9.0 \
         cuda-command-line-tools-9-0
# Optional: Install the TensorRT runtime (must be after CUDA install)
RUN apt update -y \
    && apt install libnvinfer4=4.1.2-1+cuda9.0

RUN apt-get update -y && \
    DEBIAN_FRONTEND=noninteractive \
      apt-get install --no-install-recommends -y -q \
          build-essential \
          python2.7 \
          python2.7-dev \
          python-pip \
          virtualenv \
          zlib1g-dev \
          linux-headers-$(uname -r) \
          cuda-9-0 \
      && pip install --upgrade pip virtualenv \
      && apt-get clean \
      && rm /var/lib/dpkg/info/* \
      && rm /var/lib/apt/lists/*debian*

RUN mkdir /tensorflow \
    && virtualenv --system-site-packages /tensorflow
    
RUN . /tensorflow/bin/activate 

RUN echo 'WORKON_HOME = "/tensorflow"' >> /usr/local/lib/R/etc/Renviron 

RUN install2.r --error reticulate keras

COPY install.R ./install.R
COPY hello-world.R /home/rstudio

RUN Rscript install.R

RUN rm -rf /tmp/Rtmp*/downloaded_packages/* \
    && rm -rf /tmp/downloaded_packages/* \
    && rm -rf /home/rstudio/.cache/pip \
    && rm -rf /root/.cache/pip
