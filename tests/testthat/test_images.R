
context("Images")

test_that("We can list images", {
  skip_on_cran()
  
  images <- gce_list_images(image_project = "cos-cloud")
  
  expect_equal(images$kind, "compute#imageList")
  
})

test_that("We can get an image from a family", {
  skip_on_cran()
  
  image <- gce_get_image_family(image_project = "cos-cloud", family = "cos-stable")
    
  expect_equal(image$kind, "compute#image")
  expect_equal(image$family, "cos-stable")  
  
})

test_that("We can get a specific image", {
  skip_on_cran()
  
  images <- gce_list_images(image_project = "cos-cloud")
  
  image <- gce_get_image(image_project = "cos-cloud", image = images$items$name[[1]])
  
  expect_equal(image$kind, "compute#image")
})