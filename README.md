# googleComputeEngineR

[![CRAN](http://www.r-pkg.org/badges/version/googleComputeEngineR)](http://cran.r-project.org/package=googleComputeEngineR)
[![Build Status](https://travis-ci.org/cloudyr/googleComputeEngineR.png?branch=master)](https://travis-ci.org/cloudyr/googleComputeEngineR)
[![Coverage Status](https://img.shields.io/codecov/c/github/cloudyr/googleComputeEngineR/master.svg)](https://codecov.io/github/cloudyr/googleComputeEngineR?branch=master)

An R interface to the Google Cloud Compute Engine API, for launching virtual machines.

> See all documentation on the [googleComputeEngineR website](https://cloudyr.github.io/googleComputeEngineR/)

## TL;DR - Creating an RStudio server VM

1. Configure a Google Cloud Project with billing
2. Download a service acount key JSON file
3. Put your default project, zone and JSON file location in your `.Renviron`
4. Run `library(googleComputeEngineR)` and auto-authenticate
5. Run `vm <- gce_vm("rstudio", name = "rstudio-server", username = "mark", password = "mark1234")` (or other credentials) to start up an RStudio Server.
6. Wait for it to install, login via the returned URL.

## Thanks to:

* Scott Chamberlin for the [analogsea](https://github.com/sckott/analogsea) package for launching Digital Ocean VMs, which inspired the SSH connector functions for this one.
* Winston Chang for the [harbor](https://github.com/wch/harbor/) package where the docker functions come from.  If `harbor` will be published to CRAN, it will become a dependency for this one.
* Henrik Bengtsson for help in integrating the fantastic [future](https://cran.r-project.org/web/packages/future/index.html) package that allows asynchronous R functions run in GCE clusters.
* Carl Boettiger and Dirk Eddelbuettel for [rocker](https://hub.docker.com/u/rocker/) that Docker containers some of the R templates used in this package. 

## Install

CRAN version:

```r
install.packages("googleComputeEngineR")
```

Development version:

```r
devtools::install_github("cloudyr/googleComputeEngineR")
```


