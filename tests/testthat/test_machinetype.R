context("Machine types")

test_that("We can list machinetypes", {
  skip_on_cran()
  
  the_list <- gce_list_machinetype()
  expect_equal(the_list$kind, "compute#machineTypeList")
  
  
})

test_that("We can list aggregated machinetypes", {
  skip_on_cran()
  
  the_list <- gce_list_machinetype_all()
  expect_equal(the_list$kind, "compute#machineTypeAggregatedList")
  
  
})

test_that("We can get a machine type", {
  skip_on_cran()
  
  the_mt <- gce_get_machinetype("f1-micro")
  expect_equal(the_mt$kind, "compute#machineType")
  
  
})

test_that("We can make a predefined machine type URL ", {
  skip_on_cran()
  
  mt_url<- gce_make_machinetype_url("f1-micro", zone = "europe-west1-b")
  expect_equal(mt_url, "zones/europe-west1-b/machineTypes/f1-micro")
  
  
})

test_that("We can make a custom machine type URL ", {
  skip_on_cran()
  
  mt_url<- gce_make_machinetype_url(cpus = 2, memory = 256, zone = "europe-west1-b")
  expect_equal(mt_url, "zones/europe-west1-b/machineTypes/custom-2-256")
  
  
})

test_that("We can change a machine type", {
  skip_on_cran()
  
  mt <- gce_set_machinetype("f1-micro", instance = "markdev")
  
  expect_equal(mt$kind, "compute#operation")
  
  job <- gce_check_zone_op(mt$name)
  
  expect_equal(job$status, "DONE")
  
  ## change it back
  Sys.sleep(10)
  mt <- gce_set_machinetype("n1-standard-1", instance = "markdev")
  
  expect_equal(mt$kind, "compute#operation")
  
  job <- gce_check_zone_op(mt$name)
  
  expect_equal(job$status, "DONE")
  
})