context("Images")

test_that("We can list images", {
  skip_on_cran()
  
  images <- gce_list_images(image_project = "google-containers")
  
  expect_equal(images$kind, "compute#imageList")
  
})

test_that("We can get an image from a family", {
  skip_on_cran()
  
  image <- gce_get_image_family(image_project = "google-containers", family = "gci-stable")
    
  expect_equal(image$kind, "compute#image")
  expect_equal(image$family, "gci-stable")  
  
})

test_that("We can get a specific image", {
  skip_on_cran()
  
  image <- gce_get_image(image_project = "google-containers", image = "gci-stable-53-8530-85-0")
  
  expect_equal(image$kind, "compute#image")
})