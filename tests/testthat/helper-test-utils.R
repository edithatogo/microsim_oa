# Helper functions for AUS-OA testing

# Generate synthetic population data for testing
generate_test_population <- function(n = 100, seed = 123) {
  set.seed(seed)
  data.frame(
    id = 1:n,
    age = sample(45:85, n, replace = TRUE),
    sex = sample(c("[1] Male", "[2] Female"), n, replace = TRUE),
    bmi = rnorm(n, 28, 4),
    d_sf6d = rnorm(n, -0.01, 0.005),
    tkai = runif(n, 0, 0.1),
    oa_state = sample(0:4, n, replace = TRUE),
    kl0 = rep(0, n),
    kl1 = rep(0, n),
    kl2 = rep(0, n),
    kl3 = rep(0, n),
    kl4 = rep(0, n),
    year12 = sample(0:1, n, replace = TRUE)
  )
}

# Verify simulation result structure
verify_simulation_result <- function(result) {
  # Check that result is not null
  expect_false(is.null(result))
  
  # Check that result has expected type
  expect_true(is.data.frame(result) || is.list(result) || is.vector(result))
  
  # If it's a data frame, check basic structure
  if (is.data.frame(result)) {
    expect_gt(nrow(result), 0)
    expect_gt(ncol(result), 0)
  }
  
  # If it's a list, check for non-zero length
  if (is.list(result)) {
    expect_gt(length(result), 0)
  }
}

# Benchmark function execution time
benchmark_function <- function(func, ..., iterations = 5) {
  times <- system.time({
    for (i in 1:iterations) {
      result <- func(...)
    }
  })
  
  list(
    elapsed = times[3] / iterations,  # Average time per iteration
    result = result
  )
}

# Check memory usage of a function
check_memory_usage <- function(func, ...) {
  # Get initial memory stats
  gc()
  initial_mem <- sum(gc()[, "used"])
  
  # Execute function
  result <- func(...)
  
  # Get final memory stats
  final_mem <- sum(gc()[, "used"])
  
  list(
    memory_increase = final_mem - initial_mem,
    result = result
  )
}

# Generate various test scenarios
generate_test_scenarios <- function() {
  list(
    base_case = list(
      population_size = 100,
      time_horizon = 5,
      scenario = "base_case"
    ),
    intervention = list(
      population_size = 100,
      time_horizon = 5,
      scenario = "intervention"
    ),
    large_pop = list(
      population_size = 1000,
      time_horizon = 3,
      scenario = "base_case"
    )
  )
}

# Check if running in CI environment
is_ci_environment <- function() {
  ci_vars <- c("CI", "CONTINUOUS_INTEGRATION", "GITHUB_ACTIONS", "TRAVIS", "CIRCLECI", "GITLAB_CI")
  any(sapply(ci_vars, function(var) Sys.getenv(var, unset = "false") %in% c("true", "1", "yes", "TRUE")))
}

# Skip tests that require specific environment
skip_if_not_stress_env <- function() {
  test_env <- Sys.getenv("RUN_STRESS_TESTS", unset = "false")
  skip_if_not(test_env %in% c("true", "1", "yes", "TRUE"), 
              message = "Set RUN_STRESS_TESTS=true to run stress tests")
}

# Skip tests that require performance testing
skip_if_not_performance_env <- function() {
  test_env <- Sys.getenv("RUN_PERFORMANCE_TESTS", unset = "false")
  skip_if_not(test_env %in% c("true", "1", "yes", "TRUE"), 
              message = "Set RUN_PERFORMANCE_TESTS=true to run performance tests")
}

# Create temporary configuration for testing
create_test_config <- function() {
  temp_dir <- tempdir()
  config_file <- file.path(temp_dir, "test_config.yaml")
  
  # Write minimal configuration
  config_content <- list(
    simulation = list(
      default_cycles = 5,
      time_horizon = 10
    ),
    costs = list(
      tka_primary = list(
        hospital_stay = list(value = 18000, perspective = "healthcare_system")
      )
    )
  )
  
  # Convert to YAML format (simplified)
  yaml_lines <- c(
    "simulation:",
    "  default_cycles: 5",
    "  time_horizon: 10",
    "costs:",
    "  tka_primary:",
    "    hospital_stay:",
    "      value: 18000",
    "      perspective: healthcare_system"
  )
  
  writeLines(yaml_lines, config_file)
  config_file
}

# Compare two simulation results for similarity (allowing for stochastic variation)
compare_simulation_results <- function(result1, result2, tolerance = 0.1) {
  # Both should be non-null
  expect_false(is.null(result1))
  expect_false(is.null(result2))
  
  # Compare structures
  expect_identical(is.data.frame(result1), is.data.frame(result2))
  expect_identical(is.list(result1), is.list(result2))
  
  if (is.data.frame(result1) && is.data.frame(result2)) {
    expect_equal(nrow(result1), nrow(result2))
    expect_equal(ncol(result1), ncol(result2))
    # For stochastic simulations, exact equality isn't expected
  } else if (is.numeric(result1) && is.numeric(result2)) {
    # For summary statistics, use tolerance
    expect_equal(result1, result2, tolerance = tolerance)
  }
}