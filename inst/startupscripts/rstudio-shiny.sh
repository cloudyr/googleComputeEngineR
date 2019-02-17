#!/bin/bash
echo "Docker RStudio Shiny launch script"

RSTUDIO_USER=$(curl http://metadata.google.internal/computeMetadata/v1/instance/attributes/rstudio_user -H "Metadata-Flavor: Google")
RSTUDIO_PW=$(curl http://metadata.google.internal/computeMetadata/v1/instance/attributes/rstudio_pw -H "Metadata-Flavor: Google")
GCER_DOCKER_IMAGE=$(curl http://metadata.google.internal/computeMetadata/v1/instance/attributes/gcer_docker_image -H "Metadata-Flavor: Google")

echo "Docker image: $GCER_DOCKER_IMAGE"

docker run -e ADD=shiny \
           -e ROOT=TRUE \
           -e USER=$RSTUDIO_USER -e PASSWORD=$RSTUDIO_PW \
           --name=gcer-docker \
           --network=r-net \
           $GCER_DOCKER_IMAGE
