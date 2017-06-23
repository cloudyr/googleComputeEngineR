FROM rocker/r-ver:3.4.0
LABEL maintainer="mark"
RUN export DEBIAN_FRONTEND=noninteractive; apt-get -y update \
 && apt-get install -y libcairo2-dev \
	libcurl4-openssl-dev \
	libgmp-dev \
	libpng-dev \
	libssl-dev \
	libxml2-dev \
	make \
	pandoc \
	pandoc-citeproc \
	zlib1g-dev
RUN ["install2.r", "-r 'https://cloud.r-project.org'", "googleCloudStorageR", "googleAuthR", "Rcpp", "assertthat", "digest", "crayon", "withr", "mime", "R6", "jsonlite", "xtable", "magrittr", "httr", "curl", "testthat", "devtools", "readr", "hms", "shiny", "httpuv", "memoise", "htmltools", "openssl", "tibble", "remotes"]
RUN ["installGithub.r", "hadley/rlang@c351186"]
WORKDIR /payload/
COPY [".", "./"]
CMD ["R", "--vanilla", "-f", "schedule.R"]
