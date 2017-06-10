
# context("Auth")

# test_that("We can login", {
#   skip_on_cran()
#   
#   expect_is(gce_auth(), "Token2.0")
#   
# })

context("Projects")

test_that("We can see a project resource", {
  skip_on_cran()
  
  proj <- gce_get_project("mark-edmondson-gde")
  expect_equal(proj$kind, "compute#project")
  
})

context("Auto projects")

test_that("We can set auto project", {
  skip_on_cran()
  
  proj <- gce_global_project("mark-edmondson-gde2")
  expect_equal(proj, "mark-edmondson-gde2")
  
  proj <- gce_global_project("mark-edmondson-gde")
  expect_equal(proj, "mark-edmondson-gde")
  
})

test_that("We can get auto project", {
  skip_on_cran()
  
  proj <- gce_get_global_project()
  
  expect_equal(proj, "mark-edmondson-gde")
  
})

context("Auto Zone")

test_that("We can set auto zones", {
  skip_on_cran()
  
  z <- gce_global_zone("europe-west1-a")
  expect_equal(z, "europe-west1-a")
  
  z <- gce_global_zone("europe-west1-b")
  expect_equal(z, "europe-west1-b")
  
})

test_that("We can get auto zone", {
  skip_on_cran()
  
  proj <- gce_get_global_zone()
  
  expect_equal(proj, "europe-west1-b")
  
})

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

