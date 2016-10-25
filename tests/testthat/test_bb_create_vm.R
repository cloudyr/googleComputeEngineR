context("Make a VM")

test_that("We can make a VM with metadata", {
  skip_on_cran()
  
  today <- as.character(Sys.Date())
  
  ins <- gce_vm(name = "test-vm", 
               predefined_type = "f1-micro",
               metadata = list(test_date = today),
               auth_email = "TRAVIS_GCE_AUTH_FILE")

  expect_equal(ins$kind, "compute#instance")
  expect_equal(ins$status, "RUNNING")
  
  expect_equal(ins$metadata$items$key, "test_date")
  expect_equal(ins$metadata$items$value, today)
  

})


test_that("We can make a template VM", {
  skip_on_cran()
  
  vm <- gce_vm(name = "rstudio-test",
               template = "rstudio", 
               predefined_type = "f1-micro", 
               username = "mark", 
               password = "mark1234",
               auth_email = "TRAVIS_GCE_AUTH_FILE")
  
  expect_equal(vm$kind, "compute#instance")
  
  expect_equal(vm$metadata$items$key[[1]], "user-data")
  
  ## check can fetch rstudio login screen?
  
})

context("SSH tests")

test_that("We can set SSH settings", {
  skip_on_cran()
  
  vm <- gce_get_instance("rstudio-test")
  
  expect_equal(vm$kind, "compute#instance")
  
  worked <- gce_ssh_setup(vm,
                          username = "travis", 
                          key.pub = "travis-ssh-key.pub", 
                          key.private = "travis-ssh-key")
  
  expect_true(worked, "SSH settings set")
  
})

test_that("We can run SSH on an instance", {
  skip_on_cran()
  # skip_on_travis()
  
  vm <- gce_get_instance("rstudio-test")
  
  gce_ssh_setup(vm,
                username = "travis", 
                key.pub = "travis-ssh-key.pub", 
                key.private = "travis-ssh-key")
  
  cmd <- gce_ssh(vm, "echo foo")
  
  expect_true(cmd, "SSH connected")
  
})

test_that("We can upload via SSH", {
  skip_on_cran()
  # skip_on_travis()
  vm <- gce_get_instance("rstudio-test")
  
  gce_ssh_setup(vm,
                username = "travis", 
                key.pub = "travis-ssh-key.pub", 
                key.private = "travis-ssh-key")
  
  cmd <- gce_ssh_upload(vm, 
                        local = "test_auth.R",
                        remote = "test_auth_up.R")
  
  expect_true(cmd, "SSH upload")
  
})


test_that("We can download via SSH", {
  skip_on_cran()

  vm <- gce_get_instance("rstudio-test")
  
  gce_ssh_setup(vm,
                username = "travis", 
                key.pub = "travis-ssh-key.pub", 
                key.private = "travis-ssh-key")
  
  cmd <- gce_ssh_download(vm, 
                          remote = "test_auth_up.R",
                          local = "test_auth_down.R",
                          overwrite = TRUE) 

  expect_true(cmd, "SSH download")
  unlink("test_auth_down.R")
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
