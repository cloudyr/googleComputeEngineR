#!/bin/bash
echo "Docker RStudio launch script"

RSTUDIO_USER=$(curl http://metadata.google.internal/computeMetadata/v1/instance/attributes/rstudio_user -H "Metadata-Flavor: Google")
RSTUDIO_PW=$(curl http://metadata.google.internal/computeMetadata/v1/instance/attributes/rstudio_pw -H "Metadata-Flavor: Google")
RSTUDIO_DOCKER_IMAGE=$(curl http://metadata.google.internal/computeMetadata/v1/instance/attributes/rstudio_docker_image -H "Metadata-Flavor: Google")

echo "Docker image: $GCER_DOCKER_IMAGE"

docker run -p 80:8787 \
           -e ROOT=TRUE \
           -e USER=$GCER_USER -e PASSWORD=$GCER_PW \
           -v /home/gcer:/home/rstudio \
           --restart=always \
           --name=rstudio \
           $GCER_DOCKER_IMAGE
                  