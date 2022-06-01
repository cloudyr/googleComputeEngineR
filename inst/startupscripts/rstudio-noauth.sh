#!/bin/bash
echo "Docker RStudio launch script"

GCER_DOCKER_IMAGE=$(curl http://metadata.google.internal/computeMetadata/v1/instance/attributes/gcer_docker_image -H "Metadata-Flavor: Google")
# PORT=$(curl http://metadata.google.internal/computeMetadata/v1/instance/attributes/gcer_port -H "Metadata-Flavor: Google")

# if [ -z "$PORT" ];
# then
# PORT=80
# fi

echo "Docker image: $GCER_DOCKER_IMAGE"

if [ -d /home/gcer ];
then
  chmod 775 /home/gcer
  vol_code="-v /home/gcer:/home/gcer"
fi
# Need to mount in / because of filesystem noexec
# https://cloud.google.com/container-optimized-os/docs/concepts/security
mkdir -p /R/library
chown gcer:gcer -R /R
vol_code="${vol_code} -v /R:/R"

# as per https://www.rocker-project.org/use/managing_users/
docker run -p 8787:8787 \
           -e ROOT=TRUE \
           -e USER=gcer \
           ${vol_code} \
           -e DISABLE_AUTH=true \
           --name=rstudio \
           --privileged=true \
           $GCER_DOCKER_IMAGE