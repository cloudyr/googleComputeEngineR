FROM rocker/r-ver:3.4.0
LABEL maintainer="mark"
RUN export DEBIAN_FRONTEND=noninteractive; apt-get -y update \
 && apt-get install -y "libcairo2-dev", \
	"libcurl4-openssl-dev", \
	"libcurl4-openssl-dev") \
	"libgmp-dev", \
	"libpng-dev", \
	"libssl-dev", \
	"libssl-dev") \
	"libxml2-dev", \
	"libxml2-dev") \
	"make", \
	"make") \
	"pandoc \
	"zlib1g-dev", \
	"zlib1g-dev") \
	c("libcurl4-openssl-dev", \
	c("libssl-dev", \
	c("libxml2-dev", \
	c("make", \
	c("pandoc \
	character(0) \
	pandoc \
	pandoc-citeproc \
	pandoc-citeproc", \
	pandoc-citeproc")
RUN ["install2.r", "-r 'https://cloud.r-project.org'", "googleCloudStorageR", "googleAuthR", "Rcpp", "assertthat", "digest", "crayon", "withr", "mime", "R6", "jsonlite", "xtable", "magrittr", "httr", "curl", "testthat", "devtools", "readr", "hms", "shiny", "httpuv", "memoise", "htmltools", "openssl", "tibble", "remotes"]
RUN ["installGithub.r", "hadley/rlang@c351186"]
WORKDIR /payload/
COPY [".", "./"]
CMD ["R", "--vanilla", "-f", "schedule.R"]
