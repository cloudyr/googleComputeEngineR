# googleComputeEngineR
An R interface to the Google Cloud Compute API, for launching virtual machines.

[![CRAN](http://www.r-pkg.org/badges/version/googleComputeEngineR)](http://cran.r-project.org/package=googleComputeEngineR)
[![Build Status](https://travis-ci.org/MarkEdmondson1234/googleComputeEngineR.png?branch=master)](https://travis-ci.org/MarkEdmondson1234/googleComputeEngineR)
[![Coverage Status](https://img.shields.io/codecov/c/github/MarkEdmondson1234/googleComputeEngineR/master.svg)](https://codecov.io/github/MarkEdmondson1234/googleComputeEngineR?branch=master)

## Default setting

You can set default projects, zone and authentication via an `.Renviron` file or `Sys.setenv()`.

Example entries:

```
GCE_AUTH_FILE="/Users/mark/xxxxx/auth.json"
GCE_DEFAULT_PROJECT="mark-xxxxxxx"
GCE_DEFAULT_ZONE="europe-west1-a"
```

## Launch a Virtual Machine

To launch an existing VM, use `gce_vm_start()`. It returns a job operation object with a name, which you can check with `gce_get_zone_op(job$name)`, or use `gce_check_zone_op(job$name)` for it to retry and return when it has finished.

```r
library(googleComputeEngineR)

## auto auth, project and zone pre-set

## list your VMs in the project/zone
the_list <- gce_list_instances()

## start an existing instance
job <- gce_vm_start("markdev")
  
## check the job status until its finished
gce_check_zone_op(job$name)
  
## get the instance metadata
inst <- gce_get_instance("markdev")
inst$status
[1] "RUNNING"
``` 

You can also reset and start instances/VMs:

```r  
## reset instance
job <- gce_vm_reset("markdev")
  
## check job until its finished
gce_check_zone_op(job$name, wait = 20)
  
## stop VM
job <- gce_vm_stop("markdev")
  
## check job until finished
gce_check_zone_op(job$name, wait = 20)
  
inst <- gce_get_instance("markdev")
inst$status
[1] "TERMINATED"  
```
