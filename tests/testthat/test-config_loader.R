test_that("load_config loads configuration correctly", {
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
  
  # Test loading the configuration
  config <- load_config(temp_config)
  
  # Check that the configuration is loaded correctly
  expect_type(config, "list")
  expect_named(config, c("parameters", "paths"))
  expect_equal(config$parameters$age_min, 18)
  expect_equal(config$parameters$age_max, 100)
  expect_equal(config$parameters$sim_years, 20)
  
  # Clean up
  unlink(temp_config)
})

test_that("load_config handles missing file gracefully", {
  # Test with non-existent file
  expect_error(load_config("non_existent_file.yaml"))
})