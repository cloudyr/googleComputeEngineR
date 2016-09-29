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

test_that("We can create a disk", {
  skip_on_cran()
  
  disk <- gce_make_disk("test-disk")
  expect_equal(disk$kind, "compute#operation")
  
  disk <- gce_check_zone_op(disk$name, wait = 20)
  
  expect_equal(disk$kind, "compute#operation")
  expect_equal(disk$status, "DONE")
  
  
})

test_that("We can get a disk", {
  skip_on_cran()
  
  disk <- gce_get_disk("test-disk")
  expect_equal(disk$kind, "compute#disk")
  
})

test_that("We can create a disk from an image", {
  skip_on_cran()
  
  img <- gce_get_image_family("debian-cloud","debian-8")
  expect_equal(img$kind, "compute#image")
  
  disk <- gce_make_disk("test-disk-image", sourceImage = img$selfLink)
  expect_equal(disk$kind, "compute#operation")
  
  disk <- gce_check_zone_op(disk$name, wait = 20)
  
  expect_equal(disk$kind, "compute#operation")
  expect_equal(disk$status, "DONE")
  
  disk_image <- gce_get_disk("test-disk-image")
  expect_equal(disk_image$sourceImage, img$selfLink)
  
  
})

test_that("We can delete a disk", {
  skip_on_cran()
  
  disk <- gce_delete_disk("test-disk")
  gce_delete_disk("test-disk-image")
  disk <- gce_check_zone_op(disk$name, wait = 20)
  
  expect_equal(disk$kind, "compute#operation")
  expect_equal(disk$status, "DONE")
  
  expect_error(gce_get_disk("test-disk"))
  
})