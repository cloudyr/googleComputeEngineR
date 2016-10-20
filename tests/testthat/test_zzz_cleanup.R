## forced to do thsi dependent on another file as need to avoid timeouts
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