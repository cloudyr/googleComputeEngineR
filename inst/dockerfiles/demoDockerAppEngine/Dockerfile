FROM trestletech/plumber
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
RUN ["install2.r", "-r 'https://cloud.r-project.org'", "readr", "googleCloudStorageR", "Rcpp", "digest", "crayon", "withr", "mime", "R6", "jsonlite", "xtable", "magrittr", "httr", "curl", "testthat", "devtools", "hms", "shiny", "httpuv", "memoise", "htmltools", "openssl", "tibble", "remotes"]
RUN ["installGithub.r", "MarkEdmondson1234/googleAuthR@7917351", "hadley/rlang@ff87439"]
WORKDIR /payload/
COPY [".", "./"]

EXPOSE 8080
ENTRYPOINT ["R", "-e", "pr <- plumber::plumb(commandArgs()[4]); pr$run(host='0.0.0.0', port=8080, swagger=TRUE)"]
CMD ["api.R"]