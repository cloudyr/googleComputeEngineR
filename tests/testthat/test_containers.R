context("Futures and containers")

test_that("We can make a container VM",{
  
  ins <- gce_vm("test-container",
                file = system.file("cloudconfig", 
                                   "rstudio.yaml", 
                                   package = "googleComputeEngineR"),
                predefined_type = "f1-micro",
                auth_email = "TRAVIS_GCE_AUTH_FILE")
  
  expect_equal(ins$kind, "compute#instance")
  expect_equal(ins$status, "RUNNING")
  
  
})


context("Futures")

test_that("We can install a package via futures", {
  skip_on_cran()
  
  vm <- gce_vm("test-container")
  
  ## install packages
  worked <- gce_install_packages_docker(vm, "rocker/rstudio", cran_packages = "corpcor")
  expect_true(worked)
  
})

context("Google Container Registry")

test_that("Save docker containers", {
  skip_on_cran()
  
  vm <- gce_vm("test-container")
  
  gce_ssh_setup(vm,
                username = "travis",
                key.pub = "travis-ssh-key.pub",
                key.private = "travis-ssh-key",
                overwrite = TRUE)
  
  ## saves the running my-rstudio image that is named rstudio
  ## commits and saves it to container registry as travis-test-container
  cons <- harbor::containers(vm)
  worked <- gce_save_container(vm,  
                               container_name = cons[[1]]$name,
                               image_name = "travis-test-container")
  expect_true(worked)
})


test_that("Load docker containers", {
  skip_on_cran()
  
  vm <- gce_vm("test-container")
  
  ## loads and runs an rstudio template from my projects container registry
  worked <- gce_load_container(vm, 
                               container_name = "my-rstudio",
                               name = paste(sample(LETTERS, 15),collapse=""))
  expect_true(worked)
})


