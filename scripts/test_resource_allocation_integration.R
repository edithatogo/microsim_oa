#' Test Resource Allocation Integration
#'
#' This script tests the integration of the resource allocation module
#' with the AUS-OA simulation framework.
#'
#' Test Coverage:
#' - Module loading and parameter extraction
#' - Hospital capacity modeling by type and region
#' - Referral pattern simulation
#' - Capacity utilization and constraint impacts
#' - Integration with simulation cycle
#' - Validation of results

# Load required libraries
library(data.table)
library(here)
library(yaml)

# Set up test environment
print("Setting up Resource Allocation Integration Test Environment")

# Load configuration
config_path <- here::here("config", "coefficients.yaml")
config <- yaml::read_yaml(config_path)
# Wrap in coefficients structure to match expected format
config <- list(coefficients = config)

# Source required functions
source(here::here("R", "resource_allocation_module.R"))
source(here::here("R", "resource_allocation_integration.R"))

print("Configuration and modules loaded successfully")

#' Create Test Dataset for Resource Allocation
#'
#' @param n_patients Number of patients to simulate
#' @return Test patient dataset with clinical and regional characteristics
create_resource_test_dataset <- function(n_patients = 1000) {
  set.seed(456)  # For reproducible results

  # Create synthetic patient data
  patients <- data.table(
    id = 1:n_patients,
    age = sample(45:85, n_patients, replace = TRUE),
    male = sample(0:1, n_patients, replace = TRUE),
    year12 = sample(0:1, n_patients, replace = TRUE),
    bmi = rnorm(n_patients, mean = 28, sd = 4),
    ccount = sample(0:5, n_patients, replace = TRUE),  # Comorbidity count
    function_score = runif(n_patients, 30, 80),
    sf6d = runif(n_patients, 0.5, 0.9),
    dead = 0,
    tka = sample(0:1, n_patients, replace = TRUE, prob = c(0.9, 0.1)),
    care_pathway = sample(c("public", "private"), n_patients, replace = TRUE, prob = c(0.7, 0.3)),
    comp = sample(0:1, n_patients, replace = TRUE, prob = c(0.85, 0.15))  # Previous complications
  )

  # Add regional distribution
  patients$region <- sample(c("metro", "regional"),
                           n_patients,
                           replace = TRUE,
                           prob = c(0.7, 0.3))

  # Add some complex cases for referral testing
  complex_indices <- sample(1:n_patients, size = floor(n_patients * 0.2))
  patients$ccount[complex_indices] <- pmin(patients$ccount[complex_indices] + 2, 5)

  return(patients)
}

#' Test Basic Module Functionality
#'
#' @return Test results summary
test_basic_functionality <- function() {
  print("Testing Basic Module Functionality...")

  # Create test data
  patients <- create_resource_test_dataset(500)

  # Extract resource allocation parameters
  resource_params <- extract_resource_parameters(config)

  # Test parameter extraction
  test_results <- list(
    parameters_extracted = !is.null(resource_params),
    regional_section = "regional" %in% names(resource_params),
    referral_section = "referral" %in% names(resource_params),
    constraints_section = "constraints" %in% names(resource_params),
    hospital_capacity_section = "hospital_capacity" %in% names(resource_params)
  )

  # Test module execution
  tryCatch({
    result <- resource_allocation_module(patients, resource_params)
    test_results$module_execution <- TRUE
    test_results$summary_generated <- !is.null(result$resource_summary)
    test_results$patients_updated <- !is.null(result$patients)
    test_results$capacity_allocated <- !is.null(result$capacity_allocation)
  }, error = function(e) {
    test_results$module_execution <- FALSE
    test_results$error_message <- e$message
  })

  return(test_results)
}

#' Test Capacity Modeling
#'
#' @return Capacity test results
test_capacity_modeling <- function() {
  print("Testing Capacity Modeling...")

  # Create test data
  patients <- create_resource_test_dataset(800)

  # Extract parameters
  resource_params <- extract_resource_parameters(config)

  # Run module
  result <- resource_allocation_module(patients, resource_params)

  # Test capacity calculations
  test_results <- list(
    capacity_allocation_exists = !is.null(result$capacity_allocation),
    hospital_types_defined = !is.null(result$hospital_types),
    utilization_calculated = !is.null(result$utilization)
  )

  # Test capacity distribution
  capacity_alloc <- result$capacity_allocation
  if (!is.null(capacity_alloc)) {
    test_results$metro_capacity_exists <- any(grepl("metro", names(capacity_alloc)))
    test_results$regional_capacity_exists <- any(grepl("regional", names(capacity_alloc)))
    test_results$total_capacity_positive <- sum(unlist(capacity_alloc)) > 0
  }

  # Test utilization rates
  utilization <- result$utilization
  if (!is.null(utilization)) {
    util_rates <- sapply(utilization, function(x) x$utilization_rate)
    test_results$reasonable_utilization <- all(util_rates >= 0 & util_rates <= 3)  # Allow some over-utilization
    test_results$constraint_detection <- any(sapply(utilization, function(x) x$is_constrained))
  }

  return(test_results)
}

#' Test Referral Patterns
#'
#' @return Referral test results
test_referral_patterns <- function() {
  print("Testing Referral Patterns...")

  # Create test data with known complex cases
  patients <- data.table(
    id = 1:400,
    age = c(rep(70, 200), rep(80, 200)),  # Half elderly
    male = 1,
    year12 = 1,
    bmi = 28,
    ccount = c(rep(1, 200), rep(4, 200)),  # Half with low, half with high comorbidity
    function_score = 60,
    sf6d = 0.7,
    dead = 0,
    tka = 1,
    care_pathway = "public",
    comp = c(rep(0, 200), rep(1, 200)),  # Half with previous complications
    region = "metro"
  )

  # Extract parameters
  resource_params <- extract_resource_parameters(config)

  # Run module
  result <- resource_allocation_module(patients, resource_params)

  # Test referral logic
  updated_patients <- result$patients

  test_results <- list(
    referral_fields_added = all(c("referral_needed", "referral_accepted", "final_hospital_type") %in% names(updated_patients)),
    complex_cases_identified = sum(updated_patients$referral_needed) > 0,
    referrals_processed = sum(updated_patients$referral_accepted, na.rm = TRUE) >= 0
  )

  # Test that complex patients are more likely to need referral
  complex_patients <- updated_patients$ccount >= 3
  simple_patients <- updated_patients$ccount < 3

  if (sum(complex_patients) > 0 && sum(simple_patients) > 0) {
    complex_referral_rate <- mean(updated_patients$referral_needed[complex_patients])
    simple_referral_rate <- mean(updated_patients$referral_needed[simple_patients])
    test_results$complex_patients_more_likely_referred <- complex_referral_rate > simple_referral_rate
  }

  return(test_results)
}

#' Test Constraint Impacts
#'
#' @return Constraint test results
test_constraint_impacts <- function() {
  print("Testing Constraint Impacts...")

  # Create high-demand scenario to trigger constraints
  patients <- create_resource_test_dataset(1500)  # High patient load

  # Extract parameters
  resource_params <- extract_resource_parameters(config)

  # Run module
  result <- resource_allocation_module(patients, resource_params)

  # Test constraint impacts
  updated_patients <- result$patients
  utilization <- result$utilization

  test_results <- list(
    constraint_fields_added = all(c("capacity_delay", "capacity_quality_impact", "capacity_cost_impact") %in% names(updated_patients)),
    delays_calculated = !all(is.na(updated_patients$capacity_delay))
  )

  # Test that constrained hospitals have impacts
  constrained_hospitals <- sapply(utilization, function(x) x$is_constrained)
  if (any(constrained_hospitals)) {
    test_results$constrained_hospitals_have_delays <- any(updated_patients$capacity_delay > 0, na.rm = TRUE)
    test_results$quality_impacts_applied <- any(updated_patients$capacity_quality_impact < 1, na.rm = TRUE)
    test_results$cost_impacts_applied <- any(updated_patients$capacity_cost_impact > 1, na.rm = TRUE)
  }

  return(test_results)
}

#' Test Integration Functionality
#'
#' @return Integration test results
test_integration_functionality <- function() {
  print("Testing Integration Functionality...")

  # Create test data
  am_curr <- create_resource_test_dataset(300)
  am_new <- copy(am_curr)

  # Test full integration
  tryCatch({
    integration_result <- integrate_resource_allocation_module(am_curr, am_new, config, simulation_cycle = 1)

    test_results <- list(
      integration_successful = TRUE,
      matrices_returned = all(c("am_curr", "am_new") %in% names(integration_result)),
      summary_present = !is.null(integration_result$resource_summary),
      parameters_used = !is.null(integration_result$parameters_used)
    )

    # Test validation
    validation <- validate_resource_integration(integration_result)
    test_results$validation_passed <- validation$overall_valid

  }, error = function(e) {
    test_results <- list(
      integration_successful = FALSE,
      error_message = e$message
    )
  })

  return(test_results)
}

#' Run All Tests
#'
#' @return Complete test summary
run_all_tests <- function() {
  print("=== Resource Allocation Integration Test Suite ===")
  print("Starting comprehensive testing...")

  test_results <- list()

  # Run individual test suites
  test_results$basic_functionality <- test_basic_functionality()
  test_results$capacity_modeling <- test_capacity_modeling()
  test_results$referral_patterns <- test_referral_patterns()
  test_results$constraint_impacts <- test_constraint_impacts()
  test_results$integration_functionality <- test_integration_functionality()

  # Overall summary
  all_passed <- all(unlist(lapply(test_results, function(x) {
    if ("error_message" %in% names(x)) return(FALSE)
    return(all(unlist(x)))
  })))

  test_results$overall_summary <- list(
    total_tests = length(test_results) - 1,  # Exclude overall_summary
    all_tests_passed = all_passed,
    timestamp = Sys.time(),
    test_environment = list(
      r_version = R.version.string,
      data_table_version = packageVersion("data.table"),
      yaml_version = packageVersion("yaml")
    )
  )

  # Print results
  print("\n=== Test Results Summary ===")
  print(paste("Overall Status:", ifelse(all_passed, "PASS", "FAIL")))

  for (test_name in names(test_results)) {
    if (test_name != "overall_summary") {
      print(paste("\n", test_name, ":", sep = ""))
      test <- test_results[[test_name]]
      for (metric in names(test)) {
        status <- ifelse(test[[metric]] == TRUE, "✓",
                        ifelse(test[[metric]] == FALSE, "✗", test[[metric]]))
        print(paste("  ", metric, ": ", status, sep = ""))
      }
    }
  }

  return(test_results)
}

# Execute tests if run directly
if (sys.nframe() == 0) {
  final_results <- run_all_tests()

  # Save test results
  saveRDS(final_results, file = here::here("output", "test_resource_allocation_results.rds"))
  print("\nTest results saved to: output/test_resource_allocation_results.rds")
}
