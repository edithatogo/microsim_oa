#!/usr/bin/env Rscript

# Comprehensive Test Runner for AUS-OA Package
# This script provides organized execution of different test categories

# Load required libraries
library(testthat)
library(ausoa)

# Source the test configuration
source("tests/testthat/_test_config.R", local = TRUE)

# Parse command line arguments
args <- commandArgs(trailingOnly = TRUE)
test_category <- if (length(args) > 0) args[1] else "all"
verbose <- "--verbose" %in% args | "-v" %in% args

# Function to run specific test category
run_test_category <- function(category) {
  if (!should_run_test_category(category)) {
    cat("Skipping", category, "tests (environment requirement not met)\n")
    return(invisible())
  }
  
  cat("Running", category, "tests...\n")
  
  # Determine test files for this category
  test_pattern <- TEST_CATEGORIES[[category]]$pattern
  test_files <- list.files("tests/testthat", pattern = test_pattern, full.names = TRUE)
  
  if (length(test_files) == 0) {
    cat("No", category, "test files found matching pattern:", test_pattern, "\n")
    return(invisible())
  }
  
  cat("Found", length(test_files), category, "test files\n")
  
  # Run tests
  for (test_file in test_files) {
    cat("  Running:", basename(test_file), "\n")
    
    # Get the timeout for this category
    timeout <- TEST_CATEGORIES[[category]]$timeout
    
    # Run the test file
    test_results <- testthat::test_file(
      test_file,
      reporter = if (verbose) "progress" else "summary",
      env = new.env(parent = globalenv())
    )
  }
  
  cat("Completed", category, "tests\n\n")
}

# Function to run all tests
run_all_tests <- function() {
  cat("Running ALL test categories...\n\n")
  
  for (category in names(TEST_CATEGORIES)) {
    if (should_run_test_category(category)) {
      run_test_category(category)
    } else {
      cat("Skipping", category, "tests (environment requirement not met)\n\n")
    }
  }
}

# Main execution logic
if (test_category == "all") {
  run_all_tests()
} else if (test_category %in% names(TEST_CATEGORIES)) {
  run_test_category(test_category)
} else {
  cat("Unknown test category:", test_category, "\n")
  cat("Available categories:", paste(names(TEST_CATEGORIES), collapse = ", "), "\n")
  cat("Use 'all' to run all categories\n")
  quit(status = 1)
}

cat("Test execution completed.\n")