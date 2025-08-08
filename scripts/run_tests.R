# run_tests.R

# This script runs the test suite for the AUS-OA model.

# Install the package
devtools::install()

# Load the package
library(ausoa)
library(testthat)

# Run all tests in the tests/testthat directory
test_dir("tests/testthat")
