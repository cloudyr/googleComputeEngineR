context("Make a VM")

test_that("We can make a container VM",{
  
  ins <- gce_vm("test-container",
                file = system.file("cloudconfig", 
                                   "rstudio.yaml", 
                                   package = "googleComputeEngineR"),
                predefined_type = "f1-micro",
                auth_email = "TRAVIS_GCE_AUTH_FILE")
  
  expect_equal(ins$kind, "compute#instance")
  expect_equal(ins$status, "RUNNING")
  
  gce_ssh_setup(ins,
                username = "travis",
                key.pub = "travis-ssh-key.pub",
                key.private = "travis-ssh-key",
                overwrite = TRUE)
  
  
})

test_that("We can make a VM with metadata", {
  skip_on_cran()
  
  today <- as.character(Sys.Date())
  
  ins <- gce_vm("test-vm", 
                predefined_type = "f1-micro",
                metadata = list(test_date = today),
                auth_email = "TRAVIS_GCE_AUTH_FILE")

  expect_equal(ins$kind, "compute#instance")
  expect_equal(ins$status, "RUNNING")
  
  expect_true("test_date" %in% ins$metadata$items$key)
  expect_true(today %in% ins$metadata$items$value)
  
  gce_ssh_setup(ins,
                username = "travis",
                key.pub = "travis-ssh-key.pub",
                key.private = "travis-ssh-key",
                overwrite = TRUE)
  

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
  
  gce_ssh_setup(vm,
                username = "travis",
                key.pub = "travis-ssh-key.pub",
                key.private = "travis-ssh-key",
                overwrite = TRUE)
  
  ## check can fetch rstudio login screen?
  
})

context("SSH tests")

test_that("We can set SSH settings", {
  skip_on_cran()
  
  vm <- gce_get_instance("test-vm")
  
  expect_equal(vm$kind, "compute#instance")
  
  worked <- gce_ssh_setup(vm,
                          username = "travis", 
                          key.pub = "travis-ssh-key.pub", 
                          key.private = "travis-ssh-key",
                          overwrite = TRUE)
  
  expect_true(worked, "SSH settings set")
  
})

test_that("We can run SSH on an instance", {
  skip_on_cran()
  # skip_on_travis()
  
  vm <- gce_get_instance("test-vm")
  
  cmd <- gce_ssh(vm, "echo foo")
  
  expect_true(cmd, "SSH connected")
  
})

test_that("We can upload via SSH", {
  skip_on_cran()
  # skip_on_travis()
  vm <- gce_get_instance("test-vm")
  
  cmd <- gce_ssh_upload(vm, 
                        local = "test_aa_auth.R",
                        remote = "test_auth_up.R")
  
  expect_true(cmd, "SSH upload")
  
})


test_that("We can download via SSH", {
  skip_on_cran()

  vm <- gce_get_instance("test-vm")
  
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
