#!/bin/bash
echo "Docker RStudio Shiny launch script"

RSTUDIO_USER=$(curl http://metadata.google.internal/computeMetadata/v1/instance/attributes/rstudio_user -H "Metadata-Flavor: Google")
RSTUDIO_PW=$(curl http://metadata.google.internal/computeMetadata/v1/instance/attributes/rstudio_pw -H "Metadata-Flavor: Google")
GCER_DOCKER_IMAGE=$(curl http://metadata.google.internal/computeMetadata/v1/instance/attributes/gcer_docker_image -H "Metadata-Flavor: Google")

echo "Docker image: $GCER_DOCKER_IMAGE"

echo "Create network bridge for RStudio and Shiny"
# https://kgrz.io/simple-multiple-container-deployment-without-docker-compose.html

docker network create --driver=bridge r-net

echo "Start Rstudio and Shiny image"

docker run -e ADD=shiny \
           -e ROOT=TRUE \
           -d \
           -e USER=$RSTUDIO_USER -e PASSWORD=$RSTUDIO_PW \
           --name=rstudio-shiny \
           --network=r-net \
           $GCER_DOCKER_IMAGE

echo "
user nginx;

events {
  worker_connections  1024;
}

http {

  map \$http_upgrade \$connection_upgrade {
      default upgrade;
      ''      close;
    }
  
  access_log  /var/log/nginx/access.log;

  server {
    listen 80;
    
    rewrite ^/shiny$ \$scheme://\$http_host/shiny/ permanent;
    
    location / {
      proxy_pass http://rstudio-shiny:8787;
      proxy_redirect http://rstudio-shiny:8787/ \$scheme://\$http_host/;
      proxy_http_version 1.1;
      proxy_set_header Upgrade \$http_upgrade;
      proxy_set_header Connection \$connection_upgrade;
      proxy_read_timeout 20d;
    }
    
    location /shiny/ {
      rewrite ^/shiny/(.*)$ /\$1 break;
      proxy_pass http://rstudio-shiny:3838;
      proxy_redirect / \$scheme://\$http_host/shiny/;
      proxy_http_version 1.1;
      proxy_set_header Upgrade \$http_upgrade;
      proxy_set_header Connection \$connection_upgrade;
      proxy_read_timeout 20d;
      proxy_buffering off;
    }
    
  }
}" > /etc/nginx.conf

echo "Start nginx image"

# use nginx to map shiny (:3838) to /shiny and rstudio (:8787) to /
docker run --name r-nginx \
           -d \
           -p 80:80 \
           -v /etc/nginx.conf:/etc/nginx/nginx.conf:ro \
           --network=r-net \
           nginx
