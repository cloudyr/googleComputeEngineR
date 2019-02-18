#!/bin/bash
echo "Docker RStudio GPU launch script"
# not done via cloud-init as not on container-os image for now

RSTUDIO_USER=$(curl http://metadata.google.internal/computeMetadata/v1/instance/attributes/rstudio_user -H "Metadata-Flavor: Google")
RSTUDIO_PW=$(curl http://metadata.google.internal/computeMetadata/v1/instance/attributes/rstudio_pw -H "Metadata-Flavor: Google")
GCER_DOCKER_IMAGE=$(curl http://metadata.google.internal/computeMetadata/v1/instance/attributes/gcer_docker_image -H "Metadata-Flavor: Google")

echo "Docker image: $GCER_DOCKER_IMAGE"

echo "GPU settings"
ls -la /dev | grep nvidia
nvidia-smi

nvidia-docker run -p 80:8787 \
           -e ROOT=TRUE \
           -e USER=$RSTUDIO_USER -e PASSWORD=$RSTUDIO_PW \
           -d \
           --name=rstudio-gpu \
           --restart=always \
           $GCER_DOCKER_IMAGE
