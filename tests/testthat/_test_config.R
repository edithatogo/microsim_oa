# Test configuration for AUS-OA package
# This file defines different test categories and their execution parameters

# Define test categories
TEST_CATEGORIES <- list(
  # Fast unit tests - run on every commit
  unit = list(
    pattern = "^test-(?!performance|load|stress|mutation|property).*\\.R$",
    timeout = 30,  # seconds
    tags = c("fast", "unit", "ci")
  ),
  
  # Performance tests - run on PRs and scheduled builds
  performance = list(
    pattern = "^test-performance.*\\.R$",
    timeout = 300,  # 5 minutes
    tags = c("performance", "benchmark"),
    requires_env = "RUN_PERFORMANCE_TESTS"
  ),
  
  # Stress/load tests - run in dedicated environments
  stress = list(
    pattern = "^test-(load|stress).*\\.R$",
    timeout = 600,  # 10 minutes
    tags = c("stress", "load", "memory"),
    requires_env = "RUN_STRESS_TESTS"
  ),
  
  # Mutation tests - run occasionally
  mutation = list(
    pattern = "^test-mutation.*\\.R$",
    timeout = 600,  # 10 minutes
    tags = c("mutation", "robustness"),
    requires_env = "RUN_MUTATION_TESTS"
  ),
  
  # Property-based tests - run regularly
  property = list(
    pattern = "^test-property.*\\.R$",
    timeout = 120,  # 2 minutes
    tags = c("property", "contract", "fuzz"),
    requires_env = "hedgehog"
  ),
  
  # Recovery/error handling tests - run regularly
  recovery = list(
    pattern = "^test-recovery.*\\.R$",
    timeout = 60,   # 1 minute
    tags = c("recovery", "error_handling", "edge_cases")
  )
)

# Default test settings
TEST_DEFAULTS <- list(
  parallel = FALSE,
  stop_on_failure = FALSE,
  reporter = "check",
  load_helpers = TRUE
)

# Environment variable to control test execution
get_test_env_setting <- function(setting_name, default = NULL) {
  env_var <- paste0("AUSOA_TEST_", toupper(setting_name))
  env_value <- Sys.getenv(env_var, unset = NA)
  
  if (is.na(env_value)) {
    return(default)
  }
  
  # Convert string to appropriate type
  if (env_value %in% c("TRUE", "true", "1")) {
    return(TRUE)
  } else if (env_value %in% c("FALSE", "false", "0")) {
    return(FALSE)
  }
  
  return(env_value)
}

# Check if specific test category should run based on environment
should_run_test_category <- function(category) {
  if (category %in% names(TEST_CATEGORIES)) {
    req_env <- TEST_CATEGORIES[[category]]$requires_env
    if (!is.null(req_env)) {
      if (is.character(req_env)) {
        # Check environment variable
        env_setting <- Sys.getenv(req_env, unset = "false")
        return(env_setting %in% c("true", "TRUE", "1", "yes", "YES"))
      } else if (is.function(req_env)) {
        # Check function result
        return(req_env())
      }
    }
    return(TRUE)
  }
  return(FALSE)
}

# Test timeout in seconds
TEST_TIMEOUT <- as.numeric(Sys.getenv("AUSOA_TEST_TIMEOUT", unset = 300))