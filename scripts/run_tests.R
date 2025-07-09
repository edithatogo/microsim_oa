# run_tests.R

# This script runs the test suite for the AUS-OA model.

# It uses the testthat package to run the tests.

library(testthat)

# Run all tests in the tests/testthat directory
test_dir("tests/testthat")