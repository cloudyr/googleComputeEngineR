context("Futures and containers")


context("Futures")

test_that("We can install a package via futures", {
  skip_on_cran()
  
  # vm <- gce_vm(name = "test-container-nodelete",
  #              template = "r-base",
  #              auth_email = "TRAVIS_GCE_AUTH_FILE")
  vm <- gce_vm("test-container-nodelete")
  
  vm <- gce_ssh_addkeys(vm,
                        username = "travis",
                        key.pub = "travis-ssh-key.pub",
                        key.private = "travis-ssh-key")
  ## install packages
  worked <- gce_future_install_packages(vm, "rocker/r-base", cran_packages = "corpcor")
  expect_true(worked)
  

  
})

context("Google Container Registry")

# 
# ## this needs a container that can be saved quickly to avoid timeouts
test_that("Save docker containers", {
  skip_on_cran()

  vm <- gce_vm("test-container-nodelete")

  vm <- gce_ssh_addkeys(vm,
                        username = "travis",
                        key.pub = "travis-ssh-key.pub",
                        key.private = "travis-ssh-key")
  
  ## saves the running my-rstudio image that is named rstudio
  ## commits and saves it to container registry as travis-test-container
  cons <- containers(vm)
  worked <- gce_save_container(vm,
                               container_name = "travis-test-container",
                               image_name = cons[[1]]$name,
                               wait = TRUE
                               )
  expect_true(worked)
})
# 
# 
test_that("Load docker containers", {
  skip_on_cran()

  vm <- gce_vm("test-container-nodelete")
  
  vm <- gce_ssh_addkeys(vm,
                        username = "travis",
                        key.pub = "travis-ssh-key.pub",
                        key.private = "travis-ssh-key")

  ## loads and runs an rstudio template from my projects container registry
  worked <- gce_load_container(vm,
                               container_name = "travis-test-container",
                               name = paste(sample(LETTERS, 15),collapse=""))
  expect_true(worked)
  gce_vm_stop("test-container-nodelete")
})
