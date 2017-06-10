
context("Disks")

test_that("We can list disks in a zone", {
  skip_on_cran()
  
  the_list <- gce_list_disks()
  expect_equal(the_list$kind, "compute#diskList")
  
  
})

test_that("We can list disks in all", {
  skip_on_cran()
  
  the_list <- gce_list_disks_all()
  expect_equal(the_list$kind, "compute#diskAggregatedList")
  
  
})

test_that("We can create and/or get a disk", {
  skip_on_cran()
  
  job <- gce_make_disk("test-disk")
  
  if(job$kind == "compute#operation"){
    gce_wait(job, wait = 10)
  }
  
  disk <- gce_get_disk("test-disk")

  
  disk <- gce_get_disk("test-disk")
  expect_equal(disk$kind, "compute#disk")
  
  
})

test_that("We can create a disk from an image", {
  skip_on_cran()
  
  img <- gce_get_image_family("debian-cloud","debian-8")
  expect_equal(img$kind, "compute#image")
  
  job <- gce_make_disk("test-disk-image", sourceImage = img$selfLink)
  
  disk <- gce_wait(job, wait = 10)
  
  disk_image <- gce_get_disk("test-disk-image")
  expect_equal(disk_image$sourceImage, img$selfLink)
  
  
})


test_that("We can attach a disk", {
  skip_on_cran()
  
  disk_image <- gce_get_disk("test-disk-image")
  
  job <- gce_attach_disk(instance = "rstudio-test",
                         autoDelete = TRUE,
                         source = disk_image$selfLink)
  gce_wait(job)
  
  ins <- gce_get_instance("rstudio-test")
  
  expect_true(disk_image$selfLink %in% ins$disks$source)
  
})



test_that("We can delete a disk", {
  skip_on_cran()
  
  job <- gce_delete_disk("test-disk")
  
  disk <- gce_wait(job, wait = 10)
  
  expect_equal(disk$kind, "compute#operation")
  expect_equal(disk$status, "DONE")
  
  # expect_error(gce_get_disk("test-disk"))
  
})

