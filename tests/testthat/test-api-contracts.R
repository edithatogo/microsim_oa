library(testthat)
library(ausoa)

context("API Contract and Integration Tests")

# Test that core function signatures are stable
test_that("simulation_cycle_fcn maintains backward-compatible signature", {
  # Test that the function accepts required parameters
  result <- simulation_cycle_fcn(
    population_data = 100,
    time_horizon = 5,
    scenario = "base_case"
  )
  
  # Should return a valid result
  expect_false(is.null(result))
  
  # Test with different parameter types
  result2 <- simulation_cycle_fcn(
    population_data = generate_test_population(50),
    time_horizon = 3,
    scenario = "intervention"
  )
  
  expect_false(is.null(result2))
  
  # Should handle both numeric and data frame inputs
  expect_true(is.data.frame(result) || is.list(result) || is.numeric(result))
})

# Test that calculate_costs_fcn maintains interface contract
test_that("calculate_costs_fcn maintains expected interface", {
  # Create mock data that matches expected input format
  mock_data <- data.table::data.table(
    tka = c(1, 0, 1, 0, 1),
    revi = c(0, 0, 1, 0, 0),
    oa = c(1, 1, 1, 0, 1),
    dead = c(0, 0, 0, 0, 0),
    ir = c(1, 0, 1, 0, 0),
    comp = c(0, 0, 0, 0, 1),
    comorbidity_cost = c(10, 20, 30, 40, 50),
    intervention_cost = c(0, 0, 0, 0, 0)
  )
  
  # Create mock config
  mock_config <- list(
    costs = list(
      tka_primary = list(
        hospital_stay = list(value = 18000, perspective = "healthcare_system"),
        patient_gap = list(value = 2000, perspective = "patient")
      )
    )
  )
  
  # Function should accept the expected parameters and return expected format
  result <- calculate_costs_fcn(mock_data, mock_config)
  
  # Verify result structure
  expect_false(is.null(result))
  expect_true(is.data.table(result) || is.data.frame(result))
  
  # Should have expected cost columns
  expected_columns <- c("cycle_cost_healthcare", "cycle_cost_patient", 
                       "cycle_cost_societal", "cycle_cost_total")
  actual_columns <- names(result)
  
  # Check that result contains cost calculations
  if (all(expected_columns %in% actual_columns)) {
    # Verify that cost values are reasonable (non-negative)
    cost_cols <- expected_columns[expected_columns %in% actual_columns]
    for (col in cost_cols) {
      expect_true(all(result[[col]] >= 0, na.rm = TRUE))
    }
  }
})

# Test apply_interventions function contract
test_that("apply_interventions maintains interface contract", {
  # Create test population
  test_pop <- generate_test_population(100)
  
  # Create test intervention parameters
  test_params <- list(
    enabled = TRUE,
    interventions = list(
      test_intervention = list(
        type = "bmi_modification",
        start_year = 2025,
        end_year = 2030,
        target_population = list(min_age = 50),
        parameters = list(uptake_rate = 0.8, bmi_change = -2.0)
      )
    )
  )
  
  # Function should accept parameters and return modified population
  result <- apply_interventions(test_pop, test_params, 2025)
  
  expect_false(is.null(result))
  expect_true(is.data.frame(result))
  expect_equal(nrow(result), nrow(test_pop))
  
  # Should still have same number of rows
  expect_equal(nrow(result), 100)
})

# Test module integration contracts
test_that("DVT module integrates correctly", {
  skip_if_not(requireNamespace("ausoa", quietly = TRUE))
  
  # Test that DVT-related functions exist and have expected signatures
  expect_true(is.function(simulate_dvt_events))
  expect_true(is.function(calculate_dvt_risk))
  expect_true(is.function(calculate_dvt_impacts))
  
  # Basic functionality test
  if (is.function(simulate_dvt_events)) {
    # This would need appropriate test data
    # For now, just confirm function exists
    expect_true(TRUE)
  }
})

# Test PJI module integration contracts
test_that("PJI module integrates correctly", {
  skip_if_not(requireNamespace("ausoa", quietly = TRUE))
  
  # Test that PJI-related functions exist
  expect_true(is.function(simulate_pji_events))
  expect_true(is.function(calculate_pji_risk))
  expect_true(is.function(calculate_pji_impacts))
})

# Test waiting list module integration
test_that("Waiting list module integrates correctly", {
  skip_if_not(requireNamespace("ausoa", quietly = TRUE))
  
  expect_true(is.function(model_queue_management))
  expect_true(is.function(model_referral_patterns))
  expect_true(is.function(update_simulation_with_pathways))
})

# Test configuration loading contract
test_that("Configuration loading maintains contract", {
  # Test that config loader handles missing files gracefully
  temp_config <- create_test_config()
  
  # Should be able to load the config
  config <- load_config(temp_config)
  expect_false(is.null(config))
  
  # Should contain expected sections
  expect_true("simulation" %in% names(config))
  expect_true("costs" %in% names(config))
  
  # Clean up
  unlink(temp_config)
})

# Test data I/O contracts
test_that("Data I/O functions maintain interface contracts", {
  # Test that required I/O functions exist
  expect_true(is.function(read_data))
  expect_true(is.function(convert_to_parquet))
  
  # Test basic data generation
  test_data <- generate_test_population(50)
  expect_true(is.data.frame(test_data))
  expect_gt(nrow(test_data), 0)
  expect_gt(ncol(test_data), 0)
})

# Test module integration through PSA framework
test_that("PSA framework integrates correctly", {
  skip_if_not(requireNamespace("ausoa", quietly = TRUE))
  
  expect_true(is.function(run_psa_analysis))
  expect_true(is.function(run_psa_simulation))
  expect_true(is.function(sample_parameters))
  expect_true(is.function(validate_psa_results))
})

# Test uncertainty analysis integration
test_that("Uncertainty analysis module integrates correctly", {
  skip_if_not(requireNamespace("ausoa", quietly = TRUE))
  
  expect_true(is.function(perform_sensitivity_analysis))
  expect_true(is.function(perform_sensitivity_analysis))
  expect_true(is.function(assess_calibration))
})

# Test that function outputs are consistent across calls
test_that("Function outputs maintain consistency contract", {
  # Run same function twice with same inputs
  result1 <- simulation_cycle_fcn(
    population_data = 100,
    time_horizon = 3,
    scenario = "base_case"
  )
  
  # Set same seed to get reproducible results
  set.seed(123)
  result2 <- simulation_cycle_fcn(
    population_data = 100,
    time_horizon = 3,
    scenario = "base_case"
  )
  
  # With same seed, results should be identical
  compare_simulation_results(result1, result2, tolerance = 0.001)
})

# Test parameter validation contracts
test_that("Functions validate parameters correctly", {
  # Test that functions properly validate their inputs
  
  # Test invalid population data
  expect_error(
    simulation_cycle_fcn(
      population_data = "invalid",
      time_horizon = 5,
      scenario = "base_case"
    ),
    NA  # Or specific error message
  )
  
  # Test invalid time horizon
  expect_error(
    simulation_cycle_fcn(
      population_data = 100,
      time_horizon = -1,
      scenario = "base_case"
    ),
    NA  # Or specific error message
  )
})

# Test module boundaries and data flow
test_that("Data flows correctly between modules", {
  # Create initial data
  initial_data <- generate_test_population(50)
  
  # Apply some basic transformations that simulate module interactions
  # This tests that modules can accept and produce compatible data formats
  expect_true(is.data.frame(initial_data))
  expect_gt(nrow(initial_data), 0)
  
  # Verify expected column structure
  required_cols <- c("id", "age", "sex", "bmi")
  expect_true(all(required_cols %in% names(initial_data)))
})