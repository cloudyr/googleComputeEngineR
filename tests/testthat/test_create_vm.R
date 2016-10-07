context("Networks")

test_that("We can list networks", {
  skip_on_cran()
  
  networks <- gce_list_networks()
  
  expect_equal(networks$kind, "compute#networkList")
  
})

test_that("We can get a network", {
  skip_on_cran()
  
  networks <- gce_get_network("default")
  
  expect_equal(networks$kind, "compute#network")
  
})

context("Make a VM")

test_that("We can make a VM with metadata", {
  skip_on_cran()
  
  today <- as.character(Sys.Date())
  
  vm <- gce_vm_create(name = "test-vm", 
                      predefined_type = "f1-micro",
                      metadata = list(test_date = today),
                      auth_email = "TRAVIS_GCE_AUTH_FILE")
  
  expect_equal(vm$kind, "compute#operation")
  
  vm <- gce_check_zone_op(vm$name, wait = 10)

  expect_equal(vm$status, "DONE")  
  
  ins <- gce_get_instance("test-vm")
  expect_equal(ins$kind, "compute#instance")
  expect_equal(ins$status, "RUNNING")
  
  expect_equal(ins$metadata$items$key, "test_date")
  expect_equal(ins$metadata$items$value, today)
  

})

test_that("We can make a container VM",{
  
  vm <- gce_vm_container(file = system.file("cloudconfig", 
                                             "example.yaml", 
                                             package = "googleComputeEngineR"),
                         name = "test-container",
                         predefined_type = "f1-micro",
                         auth_email = "TRAVIS_GCE_AUTH_FILE")
  
  expect_equal(vm$kind, "compute#operation")
  
  vm <- gce_check_zone_op(vm$name, wait = 10)
  
  expect_equal(vm$status, "DONE")  
  
  ins <- gce_get_instance("test-container")
  expect_equal(ins$kind, "compute#instance")
  expect_equal(ins$status, "RUNNING")
  
  expect_equal(ins$metadata$items$key, "user-data")
  
  
})

test_that("We can make a template VM", {
  skip_on_cran()
  
  vm <- gce_vm_template("rstudio", 
                        name = "rstudio-test", 
                        predefined_type = "f1-micro", 
                        username = "mark", 
                        password = "mark1234",
                        auth_email = "TRAVIS_GCE_AUTH_FILE")
  
  expect_equal(vm$kind, "compute#instance")
  
  expect_equal(vm$metadata$items$key, "user-data")
  
  ## check can fetch rstudio login screen?
  
})

context("SSH tests")

test_that("We can run SSH on an instance", {
  skip_on_cran()
  
  vm <- gce_get_instance("rstudio-test")
  
  expect_equal(vm$kind, "compute#instance")
  
  worked <- gce_ssh_setup("travis", "rstudio-test", 
                          key.pub = "travis-ssh-key.pub", 
                          key.private = "travis-ssh-key")
  
  expect_true(worked, "SSH connected successfully")
  
})

context("Metadata")

test_that("We can set metadata on a VM", {
  skip_on_cran()
  
  job <- gce_set_metadata(list(test = "blah"), instance = "rstudio-test")
  gce_check_zone_op(job$name)
  
  vm <- gce_get_instance("rstudio-test")
  
  expect_true("test" %in% vm$metadata$items$key)
  expect_true("blah" %in% vm$metadata$items$value)
  
  
})

context("Disks")

test_that("We can list disks in a zone", {
  skip_on_cran()
  
  the_list <- gce_list_disks()
  expect_equal(the_list$kind, "compute#diskList")
  
  
})

test_that("We can list disks in all", {
  skip_on_cran()
  
  the_list <- gce_list_disks_all()
  expect_equal(the_list$kind, "compute#diskAggregatedList")
  
  
})

test_that("We can create a disk", {
  skip_on_cran()
  
  disk <- gce_make_disk("test-disk")
  expect_equal(disk$kind, "compute#operation")
  
  disk <- gce_check_zone_op(disk$name, wait = 10)
  
  expect_equal(disk$kind, "compute#operation")
  expect_equal(disk$status, "DONE")
  
  
})

test_that("We can get a disk", {
  skip_on_cran()
  
  disk <- gce_get_disk("test-disk")
  expect_equal(disk$kind, "compute#disk")
  
})

test_that("We can create a disk from an image", {
  skip_on_cran()
  
  img <- gce_get_image_family("debian-cloud","debian-8")
  expect_equal(img$kind, "compute#image")
  
  disk <- gce_make_disk("test-disk-image", sourceImage = img$selfLink)
  expect_equal(disk$kind, "compute#operation")
  
  disk <- gce_check_zone_op(disk$name, wait = 10)
  
  expect_equal(disk$kind, "compute#operation")
  expect_equal(disk$status, "DONE")
  
  disk_image <- gce_get_disk("test-disk-image")
  expect_equal(disk_image$sourceImage, img$selfLink)
  
  
})

test_that("We can attach a disk", {
  skip_on_cran()
  
  disk_image <- gce_get_disk("test-disk-image")
  
  job <- gce_attach_disk(instance = "rstudio-test",
                         autoDelete = TRUE,
                         source = disk_image$selfLink)
  gce_check_zone_op(job$name)
  
  ins <- gce_get_instance("rstudio-test")
  
  expect_true(disk_image$selfLink %in% ins$disks$source)
  
})

test_that("We can delete a disk", {
  skip_on_cran()
  
  disk <- gce_delete_disk("test-disk")

  disk <- gce_check_zone_op(disk$name, wait = 10)
  
  expect_equal(disk$kind, "compute#operation")
  expect_equal(disk$status, "DONE")
  
  expect_error(gce_get_disk("test-disk"))
  
})

context("Clean up test VMs")

test_that("We can delete the test VMs",{
  skip_on_cran()
  Sys.sleep(10)
  
  del <- gce_vm_delete("test-vm")
  del2 <- gce_vm_delete("test-container")
  del3 <- gce_vm_delete("rstudio-test")
  expect_equal(del$kind, "compute#operation")
  
  vm <- gce_check_zone_op(del$name, wait = 10)
  
  expect_equal(vm$kind, "compute#operation")
  expect_equal(vm$status, "DONE")
  
  expect_error(gce_get_instance("test-vm"))
  
})