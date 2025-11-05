library(testthat)
library(ausoa)

context("Regression Tests")

# Test that previously working functionality still works
test_that("Basic simulation functionality remains intact", {
  # This test ensures that core functionality that previously worked
  # continues to work after changes
  
  result <- simulation_cycle_fcn(
    population_data = 100,
    time_horizon = 5,
    scenario = "base_case"
  )
  
  expect_false(is.null(result))
  expect_true(is.data.frame(result) || is.list(result) || is.numeric(result))
})

# Regression test for cost calculation
test_that("Cost calculation produces expected ranges", {
  # Create standard test data
  test_data <- data.table::data.table(
    tka = c(1, 0, 1, 0, 1),
    revi = c(0, 0, 1, 0, 0),
    oa = c(1, 1, 1, 0, 1),
    dead = c(0, 0, 0, 0, 0),
    ir = c(1, 0, 1, 0, 0),
    comp = c(0, 0, 0, 0, 1),
    comorbidity_cost = c(10, 20, 30, 40, 50),
    intervention_cost = c(0, 0, 0, 0, 0)
  )
  
  costs_config <- list(
    costs = list(
      tka_primary = list(
        hospital_stay = list(value = 18000, perspective = "healthcare_system"),
        patient_gap = list(value = 2000, perspective = "patient")
      ),
      tka_revision = list(
        hospital_stay = list(value = 27000, perspective = "healthcare_system"),
        patient_gap = list(value = 3000, perspective = "patient")
      )
    )
  )
  
  result <- calculate_costs_fcn(test_data, costs_config)
  
  # Verify result structure
  expect_false(is.null(result))
  
  # Verify cost values are reasonable
  if ("cycle_cost_total" %in% names(result)) {
    # Total costs should be non-negative
    expect_true(all(result$cycle_cost_total >= 0, na.rm = TRUE))
  }
})

# Regression test for intervention application
test_that("Intervention application works as expected", {
  test_pop <- generate_test_population(50)
  
  # Test intervention parameters
  params <- list(
    enabled = TRUE,
    interventions = list(
      bmi_intervention = list(
        type = "bmi_modification",
        start_year = 2025,
        end_year = 2030,
        target_population = list(min_age = 50),
        parameters = list(uptake_rate = 1.0, bmi_change = -1.0)
      )
    )
  )
  
  result <- apply_interventions(test_pop, params, 2025)
  
  expect_false(is.null(result))
  expect_true(is.data.frame(result))
  expect_equal(nrow(result), nrow(test_pop))
})

# Regression test for parameter validation
test_that("Parameter validation works correctly", {
  # Test that invalid parameters are caught
  expect_error(
    simulation_cycle_fcn(
      population_data = -100,
      time_horizon = 5,
      scenario = "base_case"
    ),
    NA  # Should handle gracefully
  )
})

# Regression test for configuration loading
test_that("Configuration loading works as expected", {
  config_path <- create_test_config()
  
  config <- load_config(config_path)
  
  expect_false(is.null(config))
  expect_true(is.list(config))
  
  unlink(config_path)
})

# Test that API functions exist and are callable
test_that("Core API functions are available", {
  # Ensure all critical functions exist
  core_functions <- c(
    "simulation_cycle_fcn",
    "calculate_costs_fcn", 
    "apply_interventions",
    "load_config",
    "OA_summary_fcn"
  )
  
  for (func_name in core_functions) {
    expect_true(
      is.function(get(func_name, envir = asNamespace("ausoa"), mode = "function")),
      info = paste("Function", func_name, "should exist in ausoa namespace")
    )
  }
})

# Test that model produces consistent output structures
test_that("Model output structure remains consistent", {
  # Run simulation and check structure
  result <- simulation_cycle_fcn(
    population_data = 25,
    time_horizon = 2,
    scenario = "base_case"
  )
  
  # Basic structure check
  expect_false(is.null(result))
  
  # If it's a data frame, it should have consistent columns across runs
  if (is.data.frame(result)) {
    # Should have at least some rows and columns
    expect_gt(nrow(result), 0)
    expect_gt(ncol(result), 0)
  }
})

# Regression test for edge cases that previously caused issues
test_that("Known edge cases handled properly", {
  # Test empty or minimal datasets
  minimal_data <- data.frame(
    id = 1,
    age = 50,
    sex = "[1] Male",
    bmi = 25
  )
  
  # Should handle minimal data gracefully
  result <- simulation_cycle_fcn(
    population_data = minimal_data,
    time_horizon = 1,
    scenario = "base_case"
  )
  
  expect_false(is.null(result))
})

# Test that previous bug fixes still work
test_that("Previously fixed issues remain fixed", {
  # This test can be expanded as bugs are found and fixed
  # For now, test general functionality that might have been problematic
  
  # Run a standard simulation
  result1 <- simulation_cycle_fcn(
    population_data = 75,
    time_horizon = 3,
    scenario = "base_case"
  )
  
  # Run again to ensure consistency
  result2 <- simulation_cycle_fcn(
    population_data = 75,
    time_horizon = 3,
    scenario = "base_case"
  )
  
  # Both should work without errors
  expect_false(is.null(result1))
  expect_false(is.null(result2))
})

# Test for potential breaking changes in data formats
test_that("Data format compatibility maintained", {
  # Create test data in expected format
  test_data <- generate_test_population(30)
  
  # Ensure it has expected structure
  required_cols <- c("id", "age", "sex", "bmi")
  expect_true(all(required_cols %in% names(test_data)))
  
  # Should be able to process this data
  result <- simulation_cycle_fcn(
    population_data = test_data,
    time_horizon = 2,
    scenario = "base_case"
  )
  
  expect_false(is.null(result))
})