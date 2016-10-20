context("Futures and containers")

test_that("We can make a container VM",{
  
  job <- gce_vm_container(file = system.file("cloudconfig", 
                                             "example.yaml", 
                                             package = "googleComputeEngineR"),
                          name = "test-container",
                          predefined_type = "f1-micro",
                          auth_email = "TRAVIS_GCE_AUTH_FILE")
  
  expect_equal(job$kind, "compute#operation")
  
  vm <- gce_wait(job, wait = 10)
  
  expect_equal(vm$status, "DONE")  
  
  ins <- gce_get_instance("test-container")
  expect_equal(ins$kind, "compute#instance")
  expect_equal(ins$status, "RUNNING")
  
  expect_equal(ins$metadata$items$key, "user-data")
  
  
})


context("Futures")

test_that("We can install a package via futures", {
  skip_on_cran()
  
  vm <- gce_get_instance("test-container")
  
  gce_ssh_setup(vm,
                username = "travis",
                key.pub = "travis-ssh-key.pub",
                key.private = "travis-ssh-key",
                overwrite = TRUE)
  
  ## install packages
  worked <- gce_install_packages_docker(vm, "rocker/r-base", cran_packages = "corpcor")
  expect_true(worked)
  
})

context("Google Container Registry")

test_that("Load docker containers", {
  skip_on_cran()
  
  vm <- gce_get_instance("test-container")
  
  gce_ssh_setup(vm,
                username = "travis",
                key.pub = "travis-ssh-key.pub",
                key.private = "travis-ssh-key",
                overwrite = TRUE)
  
  ## loads and runs an rstudio template from my projects container registry
  worked <- gce_load_container(vm, 
                               container_name = "my-rstudio",
                               name = "travis-test-container")
  expect_true(worked)
})

test_that("Save docker containers", {
  skip_on_cran()
  
  vm <- gce_get_instance("test-container")
  
  gce_ssh_setup(vm,
                username = "travis",
                key.pub = "travis-ssh-key.pub",
                key.private = "travis-ssh-key",
                overwrite = TRUE)
  
  ## saves the running my-rstudio image that is now named travis-test-container
  ## commits and saves it to container registry 
  worked <- gce_save_container(vm,  
                               container_name = "travis-test-container",
                               image_name = "travis-test-container")
  expect_true(worked)
})

