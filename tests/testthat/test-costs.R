# Test for the cost calculation function

library(testthat)

# --- Test: Characterization of calculate_costs_fcn ---
test_that("calculate_costs_fcn output matches the golden master", {
  # 1. Load the golden master data
  golden_master_file <- test_path("fixtures", "golden_master_costs.csv")
  expect_true(file.exists(golden_master_file), "Golden master file must exist.")
  golden_master_data <- read.csv(golden_master_file)

  # 2. Re-run the function to get the current output
  am_file <- system.file("extdata", "mysim_public.csv", package = "ausoa")
  attribute_matrix <- read.csv(am_file)

  model_coefficients <- load_config(system.file("extdata", "coefficients.yaml", package = "ausoa"))
  cost_params <- model_coefficients$coefficients$costs

  current_result_matrix <- calculate_costs_fcn(attribute_matrix, cost_params)
  cost_columns <- c("cycle_cost_healthcare", "cycle_cost_patient", "cycle_cost_societal", "cycle_cost_total")
  # Convert current_data to a standard data.frame for comparison
  current_data <- as.data.frame(current_result_matrix[, cost_columns, with = FALSE])

  # 3. Compare the current output to the golden master
  # expect_equal is used for a deep comparison of the data frames.
  expect_equal(current_data, golden_master_data,
    info = "The output of calculate_costs_fcn has changed from the golden master.
If this change is intentional, delete the old golden master file and re-run the test harness to create a new baseline."
  )
})
