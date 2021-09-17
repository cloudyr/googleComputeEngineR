#!/bin/bash
echo "Docker RStudio launch script"

GCER_DOCKER_IMAGE=$(curl http://metadata.google.internal/computeMetadata/v1/instance/attributes/gcer_docker_image -H "Metadata-Flavor: Google")
# PORT=$(curl http://metadata.google.internal/computeMetadata/v1/instance/attributes/gcer_port -H "Metadata-Flavor: Google")

# if [ -z "$PORT" ];
# then
# PORT=80
# fi

echo "Docker image: $GCER_DOCKER_IMAGE"

# as per https://www.rocker-project.org/use/managing_users/
docker run -p 8787:8787 \
           -e ROOT=TRUE \
           -e USER=rstudio -e DISABLE_AUTH=true \
           --name=rstudio \
           $GCER_DOCKER_IMAGE