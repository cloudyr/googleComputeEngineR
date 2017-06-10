
context("ssh")

test_that("The SSH URL is made", {
  skip_on_cran()
  ## won't open browser on travis
  sshurl <- gce_ssh_browser("mc-server")
  
  expect_equal(sshurl, "https://ssh.cloud.google.com/projects/mark-edmondson-gde/zones/europe-west1-b/instances/mc-server?projectNumber=mark-edmondson-gde")
})

