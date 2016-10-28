context("Futures and containers")


context("Futures")

test_that("We can install a package via futures", {
  skip_on_cran()
  
  vm <- gce_vm("test-container")
  
  cons <- harbor::containers(vm)
  con <- cons[[1]]
  
  expect_true(harbor::container_running(con))
  
  ## install packages
  worked <- gce_install_packages_docker(vm, "rocker/rstudio", cran_packages = "corpcor")
  expect_true(worked)
  
})

context("Google Container Registry")

test_that("Save docker containers", {
  skip_on_cran()
  
  vm <- gce_vm("test-container")
  
  ## saves the running my-rstudio image that is named rstudio
  ## commits and saves it to container registry as travis-test-container
  cons <- harbor::containers(vm)
  worked <- gce_save_container(vm, 
                               container_name = "travis-test-container",
                               image_name = cons[[1]]$name
                               )
  expect_true(worked)
})


test_that("Load docker containers", {
  skip_on_cran()
  
  vm <- gce_vm("test-container")
  
  gce_ssh_setup(vm,
                username = "travis",
                key.pub = "travis-ssh-key.pub",
                key.private = "travis-ssh-key",
                overwrite = TRUE)
  
  ## loads and runs an rstudio template from my projects container registry
  worked <- gce_load_container(vm, 
                               container_name = "travis-test-container",
                               name = paste(sample(LETTERS, 15),collapse=""))
  expect_true(worked)
})


