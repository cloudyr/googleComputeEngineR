context("Zones")

test_that("We can list zones", {
  skip_on_cran()
  
  the_list <- gce_list_zones(project = "mark-edmondson-gde")
  expect_equal(the_list$kind, "compute#zoneList")
  
  
})

test_that("We can get one zone", {
  skip_on_cran()
  
  the_zone <- gce_get_zone(project = "mark-edmondson-gde", 
                           zone = "europe-west1-b")
  expect_equal(the_zone$kind, "compute#zone")
  
})

context("Instances")

test_that("We list instances", {
  skip_on_cran()
  
  the_list <- gce_list_instances(project = "mark-edmondson-gde",
                                 zone = "europe-west1-b")
  print(the_list)
  expect_equal(the_list$kind, "compute#instanceList")
  
})

test_that("We can get an instance", {
  skip_on_cran()

  the_inst <- gce_get_instance(project = "mark-edmondson-gde",
                               zone = "europe-west1-b",
                               instance = "mc-server")

  print(the_inst)
  expect_equal(the_inst$kind, "compute#instance")

})

context("Start up cycle")

test_that("We can start an instance", {
  skip_on_cran()
  
  job <- gce_vm("markdev")

  inst <- gce_get_instance("markdev")
  
  expect_equal(inst$status, "RUNNING")
  
})



test_that("We list operation jobs", {
  skip_on_cran()
  
  jobs <- gce_list_zone_op()
  expect_equal(jobs$kind, "compute#operationList")
  
})

test_that("We can reset a VM", {
  skip_on_cran()

  job <- gce_vm_reset("markdev")
  
  expect_equal(job$kind, "compute#operation")
  
  gce_wait(job, wait = 10)
  
  cat("\nmarkdev VM reset")
  inst <- gce_get_instance("markdev")
  
  expect_equal(inst$status, "RUNNING")
  
})

test_that("We can get an external IP", {
  skip_on_cran()
  
  ip <- gce_get_external_ip("mc-server")
  
  expect_equal(ip, "146.148.24.37")
})

test_that("We can suspend a VM", {
  skip_on_cran()
  
  job <- gce_vm_suspend("markdev")
  
  expect_equal(job$kind, "compute#operation")
  
  gce_wait(job, wait = 10)
  
  cat("\nmarkdev VM suspended")
  inst <- gce_get_instance("markdev")
  
  expect_equal(inst$status, "SUSPENDED")
  
  
})


test_that("We can resume a VM", {
  skip_on_cran()
  
  job <- gce_vm_resume("markdev")
  
  expect_equal(job$kind, "compute#operation")
  
  gce_wait(job, wait = 10)
  
  cat("\nmarkdev VM resumed")
  inst <- gce_get_instance("markdev")
  
  expect_equal(inst$status, "RUNNING")
  
  
})


test_that("We can stop a VM", {
  skip_on_cran()

  job <- gce_vm_stop("markdev")
  
  expect_equal(job$kind, "compute#operation")
  
  gce_wait(job, wait = 10)
  
  cat("\nmarkdev VM stopped")
  inst <- gce_get_instance("markdev")
  
  expect_equal(inst$status, "TERMINATED")
  
  
})

