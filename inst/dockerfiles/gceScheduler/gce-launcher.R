## intended to be run on a small instance via cron
## use this script to launch other VMs with more expensive tasks
library(googleComputeEngineR)
library(googleCloudStorageR)

gce_global_project("mark-edmondson-gde")
gce_global_zone("europe-west1-b")
## auth to same project we're on
googleAuthR::gar_gce_auth()

## download your customised RStudio with necessary packages installed
tag <- gce_tag_container("slave-1")

## launch the VM
## will either create or start the VM if its not created already
vm <- gce_vm(name = "slave-1",
             predefined_type = "n1-standard-1",
             template = "rstudio",
             dynamic_image = tag)

vm <- gce_ssh_setup(vm, username = "master", ssh_overwrite = TRUE)
## get the script from googleCloudStorage
myscript <- tempfile(fileext = ".R")
gcs_get_object("download.R", bucket = "mark-cron", saveToDisk = myscript)

## upload script to VM
gce_ssh_upload(vm, myscript, "./myscript.R")

## copy script to docker container
docker_cmd(vm, cmd = "cp", args = c("./myscript.R", "rstudio:tmp/myscript.R"))

## run the script on the VM
out <- docker_cmd(vm, 
                  cmd = "exec", 
                  args = c("rstudio", "Rscript 'tmp/myscript.R'"), 
                  wait = TRUE)

## once finished, stop the VM
gce_vm_stop(vm)