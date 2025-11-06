# Mutation testing for ausoa package
# These tests verify that function behavior is robust to minor changes

library(testthat)
library(ausoa)

test_that("calculate_costs_fcn is robust to parameter variations", {
  # Create baseline test data
  baseline_data <- data.frame(
    tka = c(0, 1, 0, 1),
    revi = c(0, 0, 1, 0),
    oa = c(1, 1, 1, 1),
    dead = c(0, 0, 0, 0),
    ir = c(1, 0, 1, 0),
    comp = c(0, 0, 0, 1),
    comorbidity_cost = c(1000, 1500, 2000, 2500),
    intervention_cost = c(0, 100, 0, 200)
  )
  
  baseline_config <- list(
    costs = list(
      tka_primary = list(
        hospital_stay = list(value = 15000, perspective = "healthcare_system"),
        patient_gap = list(value = 2000, perspective = "patient")
      )
    )
  )
  
  # Baseline result
  baseline_result <- calculate_costs_fcn(baseline_data, baseline_config)
  
  expect_false(is.null(baseline_result))
  expect_true(is.data.frame(baseline_result))
  
  # Test with slightly varied input
  variant_data <- baseline_data
  variant_data$comorbidity_cost <- variant_data$comorbidity_cost * 1.05  # 5% increase
  
  variant_result <- calculate_costs_fcn(variant_data, baseline_config)
  
  # Results should have same structure
  expect_equal(nrow(variant_result), nrow(baseline_result))
  expect_true(all(names(baseline_result) %in% names(variant_result)))
  
  # Cost should have increased appropriately
  if ("cycle_cost_total" %in% names(baseline_result) && 
      "cycle_cost_total" %in% names(variant_result)) {
    expect_true(mean(variant_result$cycle_cost_total, na.rm = TRUE) >= 
                mean(baseline_result$cycle_cost_total, na.rm = TRUE))
  }
})

test_that("apply_interventions is robust to parameter variations", {
  # Create baseline test data
  baseline_data <- data.frame(
    id = 1:10,
    age = c(60, 65, 70, 75, 80, 62, 68, 72, 78, 82),
    sex = c(0, 1, 1, 0, 1, 0, 1, 0, 0, 1),
    bmi = c(25, 28, 30, 32, 35, 26, 29, 31, 33, 36)
  )
  
  baseline_interventions <- list(
    enabled = TRUE,
    interventions = list(
      test_intervention = list(
        type = "bmi_modification", 
        start_year = 2025,
        end_year = 2030,
        parameters = list(
          uptake_rate = 0.6,
          bmi_change = -1.5
        )
      )
    )
  )
  
  # Baseline result
  baseline_result <- apply_interventions(baseline_data, baseline_interventions, 2025)
  
  expect_false(is.null(baseline_result))
  expect_true(is.data.frame(baseline_result))
  expect_equal(nrow(baseline_result), nrow(baseline_data))
  
  # Test with variant parameters
  variant_interventions <- baseline_interventions
  variant_interventions$interventions$test_intervention$parameters$bmi_change <- -2.0  # Changed from -1.5 to -2.0
  
  variant_result <- apply_interventions(baseline_data, variant_interventions, 2025)
  
  expect_false(is.null(variant_result))
  expect_true(is.data.frame(variant_result))
  expect_equal(nrow(variant_result), nrow(baseline_data))
  
  # With greater bmi reduction, bmi should be lower on average
  if ("bmi" %in% names(baseline_result) && "bmi" %in% names(variant_result)) {
    avg_bmi_baseline <- mean(baseline_result$bmi, na.rm = TRUE)
    avg_bmi_variant <- mean(variant_result$bmi, na.rm = TRUE)
    
    # The variant should have lower BMI on average due to stronger intervention
    expect_true(avg_bmi_variant <= avg_bmi_baseline)
  }
})

test_that("load_config handles edge cases gracefully", {
  # Create a temporary config file
  temp_config <- tempfile(fileext = ".yaml")
  
  # Test 1: Config with additional fields shouldn't break
  extended_config <- list(
    parameters = list(
      age_min = 18,
      age_max = 100,
      sim_years = 20
    ),
    paths = list(
      input_dir = "input",
      output_dir = "output"
    ),
    extra_field = "this should be ignored"  # Additional field
  )
  
  yaml::write_yaml(extended_config, temp_config)
  
  # This should not fail
  result <- load_config(temp_config)
  expect_false(is.null(result))
  expect_type(result, "list")
  
  # Should still contain expected fields
  expect_true("parameters" %in% names(result))
  expect_true("paths" %in% names(result))
  
  unlink(temp_config)
})

test_that("Function behavior is predictable with different inputs", {
  # Test that functions behave consistently with various input sizes
  sizes <- c(10, 50, 100)  # Different data sizes to test
  
  for (size in sizes) {
    # Create test data of different sizes
    test_data <- data.frame(
      id = 1:size,
      age = sample(40:80, size, replace = TRUE),
      sex = sample(c(0, 1), size, replace = TRUE),
      bmi = runif(size, 20, 40)
    )
    
    # Create simple intervention
    interventions <- list(
      enabled = TRUE,
      interventions = list(
        simple_intervention = list(
          type = "bmi_modification",
          start_year = 2025,
          end_year = 2030,
          parameters = list(uptake_rate = 0.5, bmi_change = -1.0)
        )
      )
    )
    
    # Apply intervention
    result <- suppressWarnings(apply_interventions(test_data, interventions, 2025))
    
    # Should return consistently structured results
    expect_false(is.null(result))
    expect_true(is.data.frame(result))
    expect_equal(nrow(result), nrow(test_data))
    expect_true(all(c("id", "age", "sex", "bmi") %in% names(result)))
  }
})

test_that("Functions handle boundary values appropriately", {
  # Test with boundary values to ensure robustness
  
  # Edge case: minimal data
  minimal_data <- data.frame(
    id = 1,
    age = 65,
    sex = 1,
    bmi = 25.0
  )
  
  interventions <- list(
    enabled = TRUE,
    interventions = list(
      minimal_intervention = list(
        type = "bmi_modification",
        start_year = 2025,
        end_year = 2030,
        parameters = list(uptake_rate = 1.0, bmi_change = -0.5)
      )
    )
  )
  
  result <- apply_interventions(minimal_data, interventions, 2025)
  
  expect_false(is.null(result))
  expect_true(is.data.frame(result))
  expect_equal(nrow(result), 1)
  
  # Edge case: maximum values
  max_data <- data.frame(
    id = 1:5,
    age = 100,  # Maximum age
    sex = 1,
    bmi = 100  # High BMI
  )
  
  result_max <- apply_interventions(max_data, interventions, 2025)
  
  expect_false(is.null(result_max))
  expect_true(is.data.frame(result_max))
  expect_equal(nrow(result_max), 5)
})