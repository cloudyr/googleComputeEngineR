#!/bin/bash
echo "Docker RStudio Shiny launch script"

RSTUDIO_USER=$(curl http://metadata.google.internal/computeMetadata/v1/instance/attributes/rstudio_user -H "Metadata-Flavor: Google")
RSTUDIO_PW=$(curl http://metadata.google.internal/computeMetadata/v1/instance/attributes/rstudio_pw -H "Metadata-Flavor: Google")
GCER_DOCKER_IMAGE=$(curl http://metadata.google.internal/computeMetadata/v1/instance/attributes/gcer_docker_image -H "Metadata-Flavor: Google")

echo "Docker image: $GCER_DOCKER_IMAGE"

echo "Start Rstudio and Shiny image"
docker run -p 3838:3838 -p 8787:8787 \
           -e ADD=shiny \
           -e ROOT=TRUE \
           -e USER=$RSTUDIO_USER -e PASSWORD=$RSTUDIO_PW \
           --name=rstudio-shiny \
           $GCER_DOCKER_IMAGE

echo "http {

  map \$http_upgrade \$connection_upgrade {
      default upgrade;
      ''      close;
    }

  server {
    listen 80;
    
    rewrite ^/shiny$ \$scheme://\$http_host/shiny/ permanent;
    
    location / {
      proxy_pass http://localhost:8787;
      proxy_redirect http://localhost:8787/ \$scheme://\$http_host/;
      proxy_http_version 1.1;
      proxy_set_header Upgrade \$http_upgrade;
      proxy_set_header Connection \$connection_upgrade;
      proxy_read_timeout 20d;
    }
    
    location /shiny/ {
      rewrite ^/shiny/(.*)$ /\$1 break;
      proxy_pass http://localhost:3838;
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
docker run --name docker-nginx \
           --detach \
           -p 80:80 \
           -v /etc/nginx.conf:/etc/nginx/nginx.conf \
           nginx
           