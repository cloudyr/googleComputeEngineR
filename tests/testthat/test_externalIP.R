library(googleComputeEngineR)

context("externalIP")

test_that("A new External IP is automatically created and assigned to the VM", {
  vm <- gce_vm(template = "rstudio",
               name = "rstudio-server-6",
               username = "jas", password = "jas12345",
               predefined_type = "n1-standard-8",
               externalIP = NULL
  )
  expect_equal(vm$status, "RUNNING")
})

test_that("We can assign an External IP already created to the VM", {
  vm <- gce_vm(template = "rstudio",
               name = "rstudio-server-6",
               username = "jas", password = "jas12345",
               predefined_type = "n1-standard-8",
               externalIP = "35.230.96.64" 
  )
  expect_equal(vm$status, "RUNNING")
})

test_that("An invalid IP which has not been previous created shouldn't work.", {
  vm <- gce_vm(template = "rstudio",
               name = "rstudio-server-6",
               username = "jas", password = "jas12345",
               predefined_type = "n1-standard-8",
               externalIP = "103.323.2323.232" 
  )
 #An error message should appear similar to:
 #Error: API returned: Invalid value for field 'resource.networkInterfaces[0].accessConfigs[0].natIP': '103.323.2323.232'. The specified external IP address '103.323.2323.232' was not found in region 'us-west1'. 
})

test_that("No IP should be assigned to the VM if externalIP specified as none", {
  vm <- gce_vm(template = "rstudio",
               name = "rstudio-server-7",
               username = "jas", password = "jas12345",
               predefined_type = "n1-standard-8",
               externalIP = "none" 
  )
  expect_equal(gce_get_external_ip(vm), NULL)
})
