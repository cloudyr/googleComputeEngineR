## intended to be run on a small instance via cron
## use this script to launch other VMs with more expensive tasks
library(googleComputeEngineR)
library(googleCloudStorageR)

## auth to same project we're on
googleAuthR::gar_gce_auth()

## download your customised RStudio with necessary packages installed
tag <- gce_tag_container("my_rstudio")

## launch the VM
vm <- gce_vm(name = "my_rstudio",
             predefined_type = "n1-standard-1",
             template = "rstudio",
             dynamic_image = tag)

## get the script from googleCloudStorage
myscript <- tempfile(fileext = ".R")
gcs_get_object("file_name.R", saveToDisk = myscript)

## upload script to VM
gce_ssh_upload(vm, myscript, "./myscript.R")

## copy script to docker container
docker_cmd(vm, cmd = "cp", args = c("./myscript.R", "rstudio:tmp/myscript.R"))
           
## run the script on the VM
out <- docker_cmd(vm, cmd = "exec", args = c("rstudio", "Rscript -e 'tmp/myscript.R'"), wait = TRUE)

## once finished, delete the VM
gce_vm_delete(vm)