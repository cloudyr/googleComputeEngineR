FROM nvcr.io/nvidia/tensorflow:18.04-py3

LABEL maintainer="Kai Lichtenberg <kai@sentin.ai>"

#Arguments
ARG USER="docker"
ARG myUID="1000"
ARG myGID="1000"

#Specifiy R and Keras Version
ENV R_BASE_VERSION=3.4.4
ENV KERAS_VERSION=2.1.5

#Set a user 
RUN groupadd --gid "${myGID}" "${USER}" \
  && useradd \
    --uid ${myUID} \
    --gid ${myGID} \
    --create-home \
    --shell /bin/bash \
    ${USER}

#Install packages needed
RUN apt-get update \ 
  && apt-get install -y --no-install-recommends \
    ed \
    locales \
    vim-tiny \
    fonts-texgyre \
    gnupg2 \
    libcurl4-openssl-dev \
    libssl-dev \
    libssh2-1-dev \
    sudo \
    virtualenv \
  && rm -rf /var/lib/apt/lists/*

#Add mirror 
RUN echo "deb http://cran.rstudio.com/bin/linux/ubuntu xenial/" >> /etc/apt/sources.list \
  && gpg --keyserver keyserver.ubuntu.com --recv-key E084DAB9 \
  && gpg -a --export E084DAB9 | apt-key add -

# Install R-base (rocker/r-base with little modification)
# Now install R and littler, and create a link for littler in /usr/local/bin
# Also set a default CRAN repo, and make sure littler knows about it too
RUN apt-get update \
  && apt-get install -y --no-install-recommends \
    littler \
    r-cran-littler \
    r-base=${R_BASE_VERSION}-* \
    r-base-dev=${R_BASE_VERSION}-* \
    r-recommended=${R_BASE_VERSION}-* \
  && echo 'options(repos = c(CRAN = "https://cran.rstudio.com/"), download.file.method = "libcurl")' >> /etc/R/Rprofile.site \
  && echo 'source("/etc/R/Rprofile.site")' >> /etc/littler.r \
  && ln -s /usr/share/doc/littler/examples/install.r /usr/local/bin/install.r \
  && ln -s /usr/share/doc/littler/examples/install2.r /usr/local/bin/install2.r \
  && ln -s /usr/share/doc/littler/examples/installGithub.r /usr/local/bin/installGithub.r \
  && ln -s /usr/share/doc/littler/examples/testInstalled.r /usr/local/bin/testInstalled.r \
  && install.r docopt \
  && rm -rf /tmp/downloaded_packages/ /tmp/*.rds \
  && rm -rf /var/lib/apt/lists/* 

#Install tensorflow and keras
ENV WORKON_HOME=/home/${USER}/.virtualenvs

RUN install2.r devtools remotes \
  && installGithub.r rstudio/tensorflow \
  && installGithub.r rstudio/keras \
  && virtualenv --system-site-packages /home/${USER}/.virtualenvs/r-tensorflow --python=python3.5 \
  && /bin/bash -c "cd /home/${USER}/.virtualenvs/r-tensorflow/bin/; \
     source activate; \
     pip3 --no-cache-dir install git+git://github.com/fchollet/keras.git@${KERAS_VERSION}"
     