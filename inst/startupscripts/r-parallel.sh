#!/bin/bash
echo "Docker R-Parallel launch script"

GCER_DOCKER_IMAGE=$(curl http://metadata.google.internal/computeMetadata/v1/instance/attributes/gcer_docker_image -H "Metadata-Flavor: Google")

echo "Docker image: $GCER_DOCKER_IMAGE"

docker run --name=r-parallel $GCER_DOCKER_IMAGE
