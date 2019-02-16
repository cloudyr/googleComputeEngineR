#!/bin/bash
echo "Docker RStudio GPU launch script"

RSTUDIO_USER=$(curl http://metadata.google.internal/computeMetadata/v1/instance/attributes/rstudio_user -H "Metadata-Flavor: Google")
RSTUDIO_PW=$(curl http://metadata.google.internal/computeMetadata/v1/instance/attributes/rstudio_pw -H "Metadata-Flavor: Google")
RSTUDIO_DOCKER_IMAGE=$(curl http://metadata.google.internal/computeMetadata/v1/instance/attributes/rstudio_docker_image -H "Metadata-Flavor: Google")

echo "Docker image: $RSTUDIO_DOCKER_IMAGE"

# auth for private docker images
docker-credential-gcr configure-docker

nvidia-docker run -p 80:8787 \
           -e ROOT=TRUE \
           -e USER=$RSTUDIO_USER -e PASSWORD=$RSTUDIO_PW \
           --detach \
           --restart=always \
           --name=rstudio \
           $RSTUDIO_DOCKER_IMAGE
                  