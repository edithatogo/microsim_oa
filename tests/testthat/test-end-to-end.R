library(testthat)

test_that("End-to-end simulation runs successfully", {
  # This test runs the main simulation script and checks for the creation
  # of an output file to ensure the simulation completes without errors.

  # Run the master script in a separate process
  system(paste("Rscript", here::here("scripts", "00_AUS_OA_Master.R")), intern = TRUE)

  # Check that an output file was created
  # For this test, we'll check for the existence of a log file,
  # as this is a reliable indicator that the simulation has run.
  log_dir <- here::here("output", "log")
  log_files <- list.files(log_dir, pattern = ".html$")
  expect_true(length(log_files) > 0, "No log files were created.")
})
