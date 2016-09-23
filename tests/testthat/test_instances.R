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
  
  expect_equal(the_list$kind, "compute#instanceList")
  
})

# test_that("We can get an instance", {
#   skip_on_cran()
#   
#   the_inst <- gce_get_instance(project = "mark-edmondson-gde",
#                                zone = "europe-west1-b",
#                                instance = "mc-server")
#   
#   expect_equal(the_list$kind, "compute#instanceList")
#   
# })