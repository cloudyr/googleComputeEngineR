#!/bin/bash
echo "Docker OpenCPU launch script"

GCER_DOCKER_IMAGE=$(curl http://metadata.google.internal/computeMetadata/v1/instance/attributes/gcer_docker_image -H "Metadata-Flavor: Google")

echo "Docker image: $GCER_DOCKER_IMAGE"

docker run --name=opencpu -p 80:80 -p 8004:8004 $GCER_DOCKER_IMAGE
                  