library(testthat)
library(googleComputeEngineR)

if(Sys.getenv("CI") != "true"){
  test_check("googleComputeEngineR")
}

