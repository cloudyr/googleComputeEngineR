#!/bin/bash
echo "Docker RStudio GPU launch script"

GCER_USER=$(curl http://metadata.google.internal/computeMetadata/v1/instance/attributes/GCER_USER -H "Metadata-Flavor: Google")
GCER_PW=$(curl http://metadata.google.internal/computeMetadata/v1/instance/attributes/GCER_PW -H "Metadata-Flavor: Google")
GCER_DOCKER_IMAGE=$(curl http://metadata.google.internal/computeMetadata/v1/instance/attributes/GCER_DOCKER_IMAGE -H "Metadata-Flavor: Google")

echo "Docker image: $GCER_DOCKER_IMAGE"

nvidia-docker run -p 80:8787 \
           -e ROOT=TRUE \
           -e USER=$GCER_USER -e PASSWORD=$GCER_PW \
           -v /home/gcer:/home/rstudio \
           --restart=always \
           --name=rstudio \
           $GCER_DOCKER_IMAGE
                  