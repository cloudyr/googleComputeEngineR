
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

