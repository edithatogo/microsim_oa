# run_tests.R

# This script runs the test suite for the AUS-OA model.

# Aggressive approach: source all R files directly to bypass loading issues.
r_files <- list.files("R", pattern = "\\.R$", full.names = TRUE)
for (file in r_files) {
  source(file)
}

library(testthat)

# Run all tests in the tests/testthat directory
test_dir("tests/testthat")