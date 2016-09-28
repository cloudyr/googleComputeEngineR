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

test_that("We can make a simple VM", {
  skip_on_cran()
  
  vm <- gce_vm_create(name = "test-vm", predefined_type = "f1-micro")
  expect_equal(vm$kind, "compute#operation")
  
  vm <- gce_check_zone_op(vm$name, wait = 20)

  expect_equal(vm$status, "DONE")  
  
  ins <- gce_get_instance("test-vm")
  expect_equal(ins$kind, "compute#instance")
  expect_equal(ins$status, "RUNNING")
  

})

test_that("We can delete the test VM",{
  skip_on_cran()
  
  del <- gce_vm_delete("test-vm")
  expect_equal(del$kind, "compute#operation")
  
  vm <- gce_check_zone_op(del$name, wait = 20)
  
  expect_equal(vm$kind, "compute#operation")
  expect_equal(vm$status, "DONE")
  
  expect_error(gce_get_instance("test-vm"))
  
})