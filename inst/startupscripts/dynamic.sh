#!/bin/bash
echo "Dynamic launch script"
# customise this script by overwriting  metadata then rebooting VM to apply it

GCER_DOCKER_IMAGE=$(curl http://metadata.google.internal/computeMetadata/v1/instance/attributes/gcer_docker_image -H "Metadata-Flavor: Google")

echo "Docker image: $GCER_DOCKER_IMAGE"

docker run --name=dynamic $GCER_DOCKER_IMAGE
                  