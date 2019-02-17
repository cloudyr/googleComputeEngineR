#!/bin/bash
echo "Docker Shiny launch script"

GCER_DOCKER_IMAGE=$(curl http://metadata.google.internal/computeMetadata/v1/instance/attributes/gcer_docker_image -H "Metadata-Flavor: Google")

echo "Docker image: $GCER_DOCKER_IMAGE"

docker run -p 80:3838 --name=shiny $GCER_DOCKER_IMAGE
