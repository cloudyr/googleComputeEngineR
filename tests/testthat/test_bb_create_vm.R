

context("Make a VM")

test_that("We can make a container VM",{
  skip_on_cran()
  ins <- gce_vm("test-container",
                file = system.file("cloudconfig", 
                                   "shiny.yaml", 
                                   package = "googleComputeEngineR"),
                predefined_type = "f1-micro")
  
  expect_equal(ins$kind, "compute#instance")
  expect_equal(ins$status, "RUNNING")
  
  
})

test_that("We can make a VM with metadata", {
  skip_on_cran()
  
  today <- as.character(Sys.Date())
  
  ins <- gce_vm("test-vm", 
                predefined_type = "f1-micro",
                metadata = list(test_date = today))

  expect_equal(ins$kind, "compute#instance")
  expect_equal(ins$status, "RUNNING")
  
  expect_true("test_date" %in% ins$metadata$items$key)
  expect_true(today %in% ins$metadata$items$value)
  

})


test_that("We can make a template VM", {
  skip_on_cran()
  
  vm <- gce_vm(name = "rstudio-test",
               template = "rstudio", 
               predefined_type = "f1-micro", 
               username = "mark", 
               password = "mark1234")
  
  expect_equal(vm$kind, "compute#instance")
  
  expect_true("user-data" %in% vm$metadata$items$key)
  
  ## check can fetch rstudio login screen?
  
})

test_that("We can make a VM with custom disk size", {
  skip_on_cran()
  ins <- gce_vm("test-disk-size",
                file = system.file("cloudconfig", 
                                   "shiny.yaml", 
                                   package = "googleComputeEngineR"),
                predefined_type = "f1-micro",
                disk_size_gb = 12
                )
  
  expect_equal(ins$kind, "compute#instance")
  expect_equal(ins$status, "RUNNING")
  boot_disk <- gce_get_disk('test-disk-size')
  expect_equal(boot_disk$sizeGb, '12')
})

# test_that("We can make a shiny app instance", {
#   skip_on_cran()
#   vm <- gce_vm("shiny-test",
#                template = "shiny",
#                predefined_type = "n1-standard-1")
#   expect_equal(vm$kind, "compute#instance")
#   expect_equal(gce_get_metadata(vm, "template")$value, "shiny")
# 
#   app_dir <- system.file("dockerfiles","shiny-googleAuthRdemo", 
#                          package = "googleComputeEngineR")
# 
#   vm <- gce_ssh_setup(vm)
#   job <- gce_shiny_addapp(vm, shinyapp = app_dir)
# 
# })


context("SSH tests")

test_that("We can run SSH on an instance", {
  skip_on_cran()
  # skip_on_travis()
  
  vm <- gce_get_instance("test-vm")
  
  cmd <- gce_ssh(vm, "echo foo")
  
  expect_true(cmd, "SSH connected")
  
})

test_that("We can check SSH settings", {
  skip_on_cran()
  # skip_on_travis()
  
  vm <- gce_get_instance("test-vm")

  cmd <- gce_ssh(vm, "echo foo")
  
  expect_true(cmd, "SSH connected")
  
  ssh_settings <- gce_check_ssh(vm)
  
  expect_equal(test_user, ssh_settings$username)
  
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
                          local = "test_auth_down.R") 

  expect_true(cmd, "SSH download")
  unlink("test_auth_down.R")
})


context("Metadata")

test_that("We can set metadata on a VM", {
  skip_on_cran()
  
  job <- gce_set_metadata(list(test = "blah"), instance = "rstudio-test")
  
  gce_wait(job)
  
  vm <- gce_get_instance("rstudio-test")
  
  expect_true("test" %in% vm$metadata$items$key)
  expect_true("blah" %in% vm$metadata$items$value)
  
  
})
