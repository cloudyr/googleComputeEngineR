# googleComputeEngineR

[![CRAN](http://www.r-pkg.org/badges/version/googleComputeEngineR)](http://cran.r-project.org/package=googleComputeEngineR)
[![Build Status](https://travis-ci.org/cloudyr/googleComputeEngineR.png?branch=master)](https://travis-ci.org/cloudyr/googleComputeEngineR)
[![codecov.io](https://codecov.io/github/cloudyr/googleComputeEngineR/coverage.svg?branch=master)](https://codecov.io/github/cloudyr/googleComputeEngineR?branch=master)

`googleComputeEngineR` provides an R interface to the Google Cloud Compute Engine API, for launching virtual machines.  It looks to make the deployment of cloud resources for R as painless as possible, and includes some special templates to launch R-specific resources such as RStudio, Shiny, and OpenCPU with a few lines from your local R session.

> See all documentation on the [googleComputeEngineR website](https://cloudyr.github.io/googleComputeEngineR/)

## TL;DR - Creating an RStudio server VM

1. Configure a Google Cloud Project with billing.
2. Download a service account key JSON file.
3. Put your default project, zone and JSON file location in your `.Renviron`.
4. Run `library(googleComputeEngineR)` and auto-authenticate.
5. Run `vm <- gce_vm(template = "rstudio", name = "rstudio-server", username = "mark", password = "mark1234")` (or other credentials) to start up an RStudio Server.
6. Wait for it to install, login via the returned URL.

A video guide to setup and launching an RStudio server has been kindly created by Donal Phipps and is [available at this link](https://www.youtube.com/watch?v=1oM0NZbRhSI).

<iframe width="560" height="315" src="http://www.youtube.com/embed/1oM0NZbRhSI?rel=0" frameborder="0" allowfullscreen></iframe> 

## Thanks to

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
if (!require("ghit")) {
    install.packages("ghit")
}
ghit::install_github("cloudyr/googleComputeEngineR")
```

---
[![cloudyr project logo](http://i.imgur.com/JHS98Y7.png)](https://github.com/cloudyr)
