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
  
  ## TODO: wait for global operation, test operaation finished
  Sys.sleep(5)
  
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
  
  ## TODO: wait for global operation, test operatation finished
})