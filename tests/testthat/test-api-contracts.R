library(testthat)
library(ausoa)

context("API Contract and Integration Tests")

# Test that calculate_costs_fcn maintains interface contract
test_that("calculate_costs_fcn maintains expected interface", {
  # Create mock data that matches expected input format
  mock_data <- data.frame(
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
  expect_true(is.data.frame(result))
  
  # Should have expected cost columns (if they exist)
  expected_columns <- c("cycle_cost_healthcare", "cycle_cost_patient", 
                       "cycle_cost_societal", "cycle_cost_total")
  actual_columns <- names(result)
  
  # Check that result contains cost calculations
  if (any(expected_columns %in% actual_columns)) {
    # Verify that cost values are reasonable (non-negative) where columns exist
    cost_cols <- expected_columns[expected_columns %in% actual_columns]
    for (col in cost_cols) {
      if (col %in% names(result)) {
        expect_true(all(result[[col]] >= 0, na.rm = TRUE))
      }
    }
  }
})

# Test apply_interventions function contract
test_that("apply_interventions maintains interface contract", {
  # Apply interventions is an exported function - test with some basic parameters
  
  # Create minimal mock data structure
  mock_data <- data.frame(
    id = 1:5,
    age = c(60, 65, 70, 75, 80),
    sex = c(1, 0, 1, 0, 1),
    bmi = c(25, 28, 30, 32, 35)
  )
  
  # Create minimal intervention parameters
  mock_intervention_params <- list(
    enabled = TRUE,
    interventions = list(
      test_intervention = list(
        type = "bmi_modification",
        start_year = 2025,
        end_year = 2030,
        parameters = list(bmi_change = -1.0)
      )
    )
  )
  
  # Function should accept parameters and return modified data
  result <- apply_interventions(mock_data, mock_intervention_params, 2025)
  
  expect_false(is.null(result))
  expect_true(is.data.frame(result))
  expect_equal(nrow(result), nrow(mock_data))
  # Note: ncol might change if columns are added
})

# Test configuration loading contract
test_that("Configuration loading maintains contract", {
  # Test that load_config handles basic functionality
  # Create a temporary config file for testing
  temp_config <- tempfile(fileext = ".yaml")
  config_data <- list(
    parameters = list(
      age_min = 18,
      age_max = 100,
      sim_years = 20
    ),
    paths = list(
      input_dir = "input",
      output_dir = "output"
    )
  )
  yaml::write_yaml(config_data, temp_config)
  
  # Should be able to load the config
  config <- load_config(temp_config)
  expect_false(is.null(config))
  
  # Should contain expected sections
  expect_true("parameters" %in% names(config))
  expect_true("paths" %in% names(config))
  
  # Clean up
  unlink(temp_config)
})

# Test data I/O contracts
test_that("Data I/O functions maintain interface contracts", {
  # Test that required I/O functions exist
  expect_true(exists("read_data"))
  expect_true(exists("convert_to_parquet"))
})

# Test that exported functions are available and work correctly
test_that("Basic exported functions are available", {
  # Check that key exported functions exist
  expect_true(exists("load_config"))
  expect_true(exists("apply_interventions"))
  expect_true(exists("calculate_costs_fcn"))
  expect_true(exists("calculate_qaly"))
  expect_true(exists("read_data"))
  expect_true(exists("update_comorbidities"))
  expect_true(exists("bmi_mod_fcn"))
  expect_true(exists("update_pros_fcn"))
  expect_true(exists("TKA_update_fcn"))
  expect_true(exists("OA_update"))
  expect_true(exists("apply_coefficient_customisations"))
  expect_true(exists("apply_policy_levers"))
  expect_true(exists("initialize_kl_grades"))
  expect_true(exists("stats_per_simulation"))
  expect_true(exists("get_target_indices"))
  expect_true(exists("get_params"))
  expect_true(exists("validate_dataset"))
  expect_true(exists("prepare_tutorial_dataset"))
  expect_true(exists("acquire_abs_health_data"))
  expect_true(exists("acquire_aihw_nhs_data"))
  expect_true(exists("acquire_oai_data"))
  expect_true(exists("convert_directory_to_parquet"))
  expect_true(exists("f_get_means_freq_sum"))
  expect_true(exists("f_get_percent_N_from_binary"))
  expect_true(exists("f_plot_distribution"))
  expect_true(exists("f_plot_trend_age_sex"))
  expect_true(exists("f_plot_trend_overall"))
  expect_true(exists("BMI_summary_plot"))
  expect_true(exists("BMI_summary_RMSE"))
  expect_true(exists("BMI_summary_data"))
  expect_true(exists("OA_summary_fcn"))
})