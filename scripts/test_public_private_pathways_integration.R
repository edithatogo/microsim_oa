#' Test Public-Private Pathways Integration
#'
#' This script tests the integration of the public-private healthcare pathways
#' module with the AUS-OA simulation framework.
#'
#' Test Coverage:
#' - Module loading and parameter extraction
#' - Pathway assignment and outcome calculation
#' - Cost modeling by pathway
#' - Patient satisfaction modeling
#' - Equity analysis
#' - Integration with simulation cycle
#' - Validation of results

# Load required libraries
library(data.table)
library(here)
library(yaml)

# Set up test environment
print("Setting up Public-Private Pathways Integration Test Environment")

# Load configuration
config_path <- here::here("config", "coefficients.yaml")
config <- yaml::read_yaml(config_path)
# Wrap in coefficients structure to match expected format
config <- list(coefficients = config)

# Source required functions
source(here::here("R", "config_loader.R"))
source(here::here("R", "public_private_pathways_module.R"))
source(here::here("R", "public_private_pathways_integration.R"))

print("Configuration and modules loaded successfully")

#' Create Test Dataset
#'
#' @param n_patients Number of patients to simulate
#' @return Test attribute matrix
create_test_dataset <- function(n_patients = 1000) {
  set.seed(123)  # For reproducible results

  # Create synthetic patient data
  am_test <- data.table(
    id = 1:n_patients,
    age = sample(45:85, n_patients, replace = TRUE),
    male = sample(0:1, n_patients, replace = TRUE),
    year12 = sample(0:1, n_patients, replace = TRUE),
    bmi = rnorm(n_patients, mean = 28, sd = 4),
    ccount = sample(0:5, n_patients, replace = TRUE),
    function_score = runif(n_patients, 30, 80),
    sf6d = runif(n_patients, 0.5, 0.9),
    dead = 0,
    tka = sample(0:1, n_patients, replace = TRUE, prob = c(0.9, 0.1)),
    care_pathway = sample(c("public", "private"), n_patients, replace = TRUE, prob = c(0.7, 0.3)),
    wait_time_months = runif(n_patients, 0, 24)
  )

  # Add socioeconomic indicators
  am_test$high_income <- ifelse(am_test$year12 == 1, sample(0:1, nrow(am_test), replace = TRUE, prob = c(0.4, 0.6)), 0)

  return(am_test)
}

#' Test Basic Module Functionality
#'
#' @return Test results summary
test_basic_functionality <- function() {
  print("Testing Basic Module Functionality...")

  # Create test data
  am_curr <- create_test_dataset(500)
  am_new <- copy(am_curr)

  # Extract pathway parameters
  pathway_params <- extract_pathway_parameters(config)

  # Test parameter extraction
  test_results <- list(
    parameters_extracted = !is.null(pathway_params),
    outcomes_section = "outcomes" %in% names(pathway_params),
    treatment_section = "treatment" %in% names(pathway_params),
    costs_section = "costs" %in% names(pathway_params),
    satisfaction_section = "satisfaction" %in% names(pathway_params)
  )

  # Test module execution
  tryCatch({
    result <- public_private_pathways_module(am_curr, am_new, pathway_params)
    test_results$module_execution <- TRUE
    test_results$summary_generated <- !is.null(result$pathway_summary)
    test_results$matrices_updated <- !is.null(result$am_new)
  }, error = function(e) {
    test_results$module_execution <- FALSE
    test_results$error_message <- e$message
  })

  return(test_results)
}

#' Test Integration Functionality
#'
#' @return Integration test results
test_integration_functionality <- function() {
  print("Testing Integration Functionality...")

  # Create test data
  am_curr <- create_test_dataset(300)
  am_new <- copy(am_curr)

  # Initialize test_results
  test_results <- list()

  # Test full integration
  tryCatch({
    integration_result <- integrate_public_private_pathways_module(am_curr, am_new, config, simulation_cycle = 1)

    test_results <- list(
      integration_successful = TRUE,
      matrices_returned = all(c("am_curr", "am_new") %in% names(integration_result)),
      summary_present = !is.null(integration_result$integration_summary),
      parameters_used = !is.null(integration_result$parameters_used)
    )

    # Test validation
    validation <- validate_pathway_integration(integration_result)
    test_results$validation_passed <- validation$overall_valid

  }, error = function(e) {
    test_results <- list(
      integration_successful = FALSE,
      error_message = e$message
    )
  })

  return(test_results)
}

#' Test Pathway-Specific Calculations
#'
#' @return Calculation test results
test_pathway_calculations <- function() {
  print("Testing Pathway-Specific Calculations...")

  # Create test data with known pathway assignments
  am_curr <- data.table(
    id = 1:200,
    age = 65,
    male = 1,
    year12 = 1,
    bmi = 28,
    ccount = 2,
    function_score = 60,
    sf6d = 0.7,
    dead = 0,
    tka = 1,
    care_pathway = rep(c("public", "private"), 100),
    wait_time_months = rep(c(12, 3), 100)
  )
  am_new <- copy(am_curr)

  # Extract parameters
  pathway_params <- extract_pathway_parameters(config)

  # Run module
  result <- public_private_pathways_module(am_curr, am_new, pathway_params)

  # Test calculations
  test_results <- list(
    pathway_modifiers_applied = all(c("pathway_quality_modifier", "pathway_cost_modifier") %in% names(result$am_new)),
    costs_calculated = "pathway_total_cost" %in% names(result$am_new),
    satisfaction_modeled = "patient_satisfaction" %in% names(result$am_new)
  )

  # Test pathway differences
  public_idx <- which(result$am_new$care_pathway == "public")
  private_idx <- which(result$am_new$care_pathway == "private")

  if (length(public_idx) > 0 && length(private_idx) > 0) {
    test_results$quality_difference <- mean(result$am_new$pathway_quality_modifier[private_idx]) >
                                      mean(result$am_new$pathway_quality_modifier[public_idx])
    test_results$cost_difference <- mean(result$am_new$pathway_total_cost[private_idx]) >
                                    mean(result$am_new$pathway_total_cost[public_idx])
    test_results$satisfaction_difference <- mean(result$am_new$patient_satisfaction[private_idx]) >
                                           mean(result$am_new$patient_satisfaction[public_idx])
  }

  return(test_results)
}

#' Test Equity and Access Analysis
#'
#' @return Equity test results
test_equity_analysis <- function() {
  print("Testing Equity and Access Analysis...")

  # Create test data with socioeconomic variation
  am_curr <- data.table(
    id = 1:400,
    age = 65,
    male = 1,
    year12 = rep(c(0, 1), 200),  # Half with low education, half with high
    bmi = 28,
    ccount = 2,
    function_score = 60,
    sf6d = 0.7,
    dead = 0,
    tka = sample(0:1, 400, replace = TRUE, prob = c(0.8, 0.2)),
    care_pathway = sample(c("public", "private"), 400, replace = TRUE, prob = c(0.75, 0.25)),
    wait_time_months = runif(400, 0, 18),
    high_income = rep(c(0, 1), 200)
  )
  am_new <- copy(am_curr)

  # Extract parameters
  pathway_params <- extract_pathway_parameters(config)

  # Run module
  result <- public_private_pathways_module(am_curr, am_new, pathway_params)

  # Test equity metrics
  equity <- result$pathway_summary$equity_metrics

  test_results <- list(
    equity_metrics_calculated = !is.null(equity),
    socioeconomic_analysis = all(c("high_edu_private_rate", "low_edu_private_rate") %in% names(equity)),
    wait_time_analysis = all(c("public_avg_wait", "private_avg_wait") %in% names(equity))
  )

  return(test_results)
}

#' Run All Tests
#'
#' @return Complete test summary
run_all_tests <- function() {
  print("=== Public-Private Pathways Integration Test Suite ===")
  print("Starting comprehensive testing...")

  test_results <- list()

  # Run individual test suites
  test_results$basic_functionality <- test_basic_functionality()
  test_results$integration_functionality <- test_integration_functionality()
  test_results$pathway_calculations <- test_pathway_calculations()
  test_results$equity_analysis <- test_equity_analysis()

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
  saveRDS(final_results, file = here::here("output", "test_public_private_pathways_results.rds"))
  print("\nTest results saved to: output/test_public_private_pathways_results.rds")
}
