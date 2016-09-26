
context("Auth")

test_that("We can login", {
  skip_on_cran()
  
  expect_is(gce_auth(), "Token2.0")
  
})

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


