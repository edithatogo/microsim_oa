# This script runs all the unit tests in the tests/testthat directory.

library(testthat)
devtools::load_all()

test_dir(here::here("tests", "testthat"))
