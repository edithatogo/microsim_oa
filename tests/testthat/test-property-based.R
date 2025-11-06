# Property-based tests using hedgehog for ausoa package
library(testthat)
library(hedgehog)
library(ausoa)

test_that("apply_interventions properties", {
  # Define generators for test inputs
  gen_population <- gen_vector(gen_named_list(
    id = gen_integer(1, 10000),
    age = gen_integer(18, 100),
    sex = gen_integer(0, 1),
    bmi = gen_double(15, 50)
  ), 1, 100)
  
  gen_intervention_params <- gen_named_list(
    enabled = gen_bool(),
    interventions = gen_list(
      gen_named_list(
        type = gen_sample_one(c("bmi_modification", "qaly_and_cost_modification")),
        start_year = gen_integer(2020, 2050),
        end_year = gen_integer(2020, 2050),
        parameters = gen_named_list(
          uptake_rate = gen_double(0, 1),
          bmi_change = gen_double(-10, 10)
        )
      ),
      1, 3
    )
  )
  
  # Property: apply_interventions should preserve number of rows
  test_property(50,  # Run 50 tests
    population = gen_population,
    intervention_params = gen_intervention_params,
    current_year = gen_integer(2020, 2050)
  ) %>% 
  expect_property({
    # Generate a basic intervention to test with
    basic_interventions <- list(
      enabled = TRUE,
      interventions = list(
        bmi_intervention = list(
          type = "bmi_modification",
          start_year = 2020,
          end_year = 2050,
          parameters = list(uptake_rate = 0.5, bmi_change = -1.0)
        )
      )
    )
    
    original_nrow <- nrow(population)
    result <- apply_interventions(population, basic_interventions, current_year)
    
    # Property: number of rows should be preserved
    expect_equal(nrow(result), original_nrow)
    
    # Property: should have same columns (or at least the same primary ones)
    expect_true(all(c("id", "age", "sex", "bmi") %in% names(result)))
  })
})

test_that("calculate_costs_fcn properties", {
  # Define generators for test inputs
  gen_cost_data <- gen_vector(gen_named_list(
    tka = gen_integer(0, 1),
    revi = gen_integer(0, 1),
    oa = gen_integer(0, 1),
    dead = gen_integer(0, 1),
    ir = gen_integer(0, 1),
    comp = gen_integer(0, 1),
    comorbidity_cost = gen_double(0, 10000),
    intervention_cost = gen_double(0, 5000)
  ), 5, 50)
  
  test_property(30,  # Run 30 tests
    mock_data = gen_cost_data
  ) %>% 
  expect_property({
    # Create a basic config
    mock_config <- list(
      costs = list(
        tka_primary = list(
          hospital_stay = list(value = 15000, perspective = "healthcare_system"),
          patient_gap = list(value = 2000, perspective = "patient")
        )
      )
    )
    
    result <- calculate_costs_fcn(mock_data, mock_config)
    
    # Property: should return a data frame with same number of rows as input
    expect_equal(nrow(result), nrow(mock_data))
    
    # Property: costs should be non-negative
    if ("cycle_cost_total" %in% names(result)) {
      expect_true(all(result$cycle_cost_total >= 0, na.rm = TRUE))
    }
  })
})

test_that("load_config properties", {
  # Define generators for config files
  gen_config_list <- gen_named_list(
    parameters = gen_named_list(
      age_min = gen_integer(0, 50),
      age_max = gen_integer(60, 120),
      sim_years = gen_integer(1, 50)
    ),
    paths = gen_named_list(
      input_dir = gen_string("input"),
      output_dir = gen_string("output")
    )
  )
  
  test_property(20,  # Run 20 tests
    config_data = gen_config_list
  ) %>% 
  expect_property({
    # Create temporary YAML file
    temp_config <- tempfile(fileext = ".yaml")
    
    # Write the config data to the temp file
    result <- tryCatch({
      yaml::write_yaml(config_data, temp_config)
      
      # Load the config
      loaded_config <- load_config(temp_config)
      
      # Property: should return a list
      expect_type(loaded_config, "list")
      
      # Property: should preserve basic structure
      expect_true("parameters" %in% names(loaded_config) || 
                 "paths" %in% names(loaded_config))
      
      TRUE
    }, error = function(e) {
      # If there's an error, the property doesn't hold
      FALSE
    })
    
    # Clean up
    unlink(temp_config)
    
    expect_true(result)
  })
})