
context("Firewalls")

test_that("We can list firewalls", {
  skip_on_cran()
  
  the_list <- gce_list_firewall_rules(project = "mark-edmondson-gde")
  expect_equal(the_list$kind, "compute#firewallList")
  
  
})

test_that("We can create a firewall rule", {
  skip_on_cran()
  
  the_rule <- gce_make_firewall_rule(name = "test-rule",
                                     protocol = "tcp",
                                     ports = 9988,
                                     project = "mark-edmondson-gde")
  ## global op
  expect_equal(the_rule$kind, "compute#operation")
  
  gce_wait(the_rule)
  
  fw <- gce_get_firewall_rule("test-rule")
  
  expect_equal(fw$kind, "compute#firewall")
  
})

test_that("We can get a firewall rule", {
  skip_on_cran()
  
  the_rule <- gce_get_firewall_rule("test-rule", project = "mark-edmondson-gde")
  expect_equal(the_rule$kind, "compute#firewall")
  
  
})

test_that("We can delete a firewall rule", {
  skip_on_cran()
  
  the_op <- gce_delete_firewall_rule("test-rule", project = "mark-edmondson-gde")
  expect_equal(the_op$kind, "compute#operation")
  
  job <- gce_wait(the_op)
  expect_equal(job$status, "DONE")
})

test_that("We can create a web firewall rule", {
  skip_on_cran()
  
  fws <- gce_make_firewall_webports()
  
  expect_equal(fws[[1]]$kind, "compute#firewall")
  expect_equal(fws[[2]]$kind, "compute#firewall")
})