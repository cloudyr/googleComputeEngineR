library(testthat)
library(googleComputeEngineR)

# change this to run tests
do_test <- FALSE

if(all(Sys.getenv("CI") != "true", do_test)){
  test_check("googleComputeEngineR")
}

