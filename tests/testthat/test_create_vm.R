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
                      metadata = list(test_date = today))
  
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
                         predefined_type = "f1-micro")
  
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
                        password = "mark1234")
  
  expect_equal(vm$kind, "compute#instance")
  
  expect_equal(vm$metadata$items$key, "user-data")
  
  ## check can fetch rstudio login screen?
  
})

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