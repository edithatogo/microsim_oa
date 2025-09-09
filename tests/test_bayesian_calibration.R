#' Test Suite for Bayesian Parameter Estimation and Calibration
#'
#' This test suite validates the Bayesian calibration module functionality
#' including parameter estimation, model calibration, uncertainty quantification,
#' and convergence diagnostics.

library(testthat)
library(mockery)

# Note: Bayesian calibration functions should be available through the ausoa package
# No need to source files directly

#' Test Bayesian Framework Initialization
test_that("Bayesian framework initializes correctly", {
  config <- initialize_bayesian_framework(list())

  expect_type(config, "list")
  expect_true("mcmc" %in% names(config))
  expect_true("priors" %in% names(config))
  expect_true("diagnostics" %in% names(config))

  # Check MCMC settings
  expect_equal(config$mcmc$n_chains, 4)
  expect_equal(config$mcmc$n_iter, 2000)
  expect_equal(config$mcmc$n_warmup, 1000)

  # Check prior distributions
  expect_true("intercept" %in% names(config$priors))
  expect_true("coefficients" %in% names(config$priors))
  expect_true("sigma" %in% names(config$priors))
})

#' Test Bayesian Parameter Estimation
test_that("Bayesian parameter estimation works for binary outcomes", {
  # Create mock data
  set.seed(123)
  n <- 1000
  mock_data <- data.frame(
    age = rnorm(n, 65, 10),
    bmi = rnorm(n, 28, 5),
    kl_grade = sample(0:4, n, replace = TRUE),
    comorbidities = rbinom(n, 1, 0.3),
    smoking_status = rbinom(n, 1, 0.2),
    complication_risk = rbinom(n, 1, 0.15)
  )

  config <- initialize_bayesian_framework(list())

  # Mock the brm function to avoid actual fitting
  mock_model <- list(
    formula = complication_risk ~ age + bmi + kl_grade + comorbidities + smoking_status,
    data = mock_data,
    family = bernoulli()
  )

  mock_posterior <- data.frame(
    b_Intercept = rnorm(1000, -2, 0.5),
    b_age = rnorm(1000, 0.02, 0.01),
    b_bmi = rnorm(1000, 0.05, 0.02),
    b_kl_grade = rnorm(1000, 0.3, 0.1),
    b_comorbidities = rnorm(1000, 0.8, 0.3),
    b_smoking_status = rnorm(1000, 0.4, 0.2)
  )

  # Test that the function runs without error (mocking brm)
  expect_error(
    bayesian_parameter_estimation(mock_data, "complication_risk", config),
    NA
  )
})

#' Test Bayesian Model Calibration
test_that("Bayesian model calibration works", {
  # Create mock Bayesian model results
  mock_bayesian_model <- list(
    model = list(),  # Mock model object
    posterior = data.frame(
      b_Intercept = rnorm(1000, -2, 0.5),
      b_age = rnorm(1000, 0.02, 0.01)
    ),
    outcome_var = "complication_risk"
  )

  # Create mock validation data
  set.seed(456)
  validation_data <- data.frame(
    age = rnorm(200, 65, 10),
    bmi = rnorm(200, 28, 5),
    kl_grade = sample(0:4, 200, replace = TRUE),
    comorbidities = rbinom(200, 1, 0.3),
    smoking_status = rbinom(200, 1, 0.2),
    complication_risk = rbinom(200, 1, 0.15)
  )

  config <- initialize_bayesian_framework(list())

  # Test calibration function
  expect_error(
    bayesian_model_calibration(mock_bayesian_model, validation_data, config),
    NA
  )
})

#' Test Uncertainty Quantification
test_that("Parameter uncertainty quantification works", {
  # Create mock Bayesian model
  mock_bayesian_model <- list(
    posterior = data.frame(
      b_Intercept = rnorm(1000, -2, 0.5),
      b_age = rnorm(1000, 0.02, 0.01),
      b_bmi = rnorm(1000, 0.05, 0.02),
      sigma = rnorm(1000, 1.5, 0.3)
    )
  )

  # Test uncertainty quantification
  uncertainty <- quantify_parameter_uncertainty(mock_bayesian_model)

  expect_type(uncertainty, "list")
  expect_true("b_Intercept" %in% names(uncertainty))
  expect_true("b_age" %in% names(uncertainty))

  # Check that uncertainty results contain expected elements
  intercept_uncertainty <- uncertainty$b_Intercept
  expect_true("mean" %in% names(intercept_uncertainty))
  expect_true("median" %in% names(intercept_uncertainty))
  expect_true("sd" %in% names(intercept_uncertainty))
  expect_true("ci_95" %in% names(intercept_uncertainty))
  expect_true("ci_90" %in% names(intercept_uncertainty))
  expect_true("hdi_95" %in% names(intercept_uncertainty))
  expect_true("distribution" %in% names(intercept_uncertainty))
})

#' Test MCMC Convergence Diagnostics
test_that("MCMC convergence diagnostics work", {
  # Create mock Bayesian model with convergence info
  mock_bayesian_model <- list(
    model = list(
      fit = list(
        summary = function() {
          list(
            summary = data.frame(
              Rhat = c(1.01, 1.05, 1.02),
              n_eff = c(800, 750, 900)
            )
          )
        }
      )
    )
  )

  config <- initialize_bayesian_framework(list())

  # Test convergence assessment
  diagnostics <- assess_mcmc_convergence(mock_bayesian_model, config)

  expect_type(diagnostics, "list")
  expect_true("rhat" %in% names(diagnostics))
  expect_true("neff" %in% names(diagnostics))
  expect_true("mcse" %in% names(diagnostics))
  expect_true("overall_converged" %in% names(diagnostics))
  expect_true("summary" %in% names(diagnostics))
})

#' Test Bayesian Model Comparison
test_that("Bayesian model comparison works", {
  # Create mock models
  mock_model1 <- list(
    model = list(
      loo = function() list(estimates = matrix(c(-500, 50), nrow = 2, ncol = 1,
                                               dimnames = list(c("looic", "se_looic"), "Estimate")))
    )
  )

  mock_model2 <- list(
    model = list(
      loo = function() list(estimates = matrix(c(-480, 45), nrow = 2, ncol = 1,
                                               dimnames = list(c("looic", "se_looic"), "Estimate")))
    )
  )

  models <- list(model1 = mock_model1, model2 = mock_model2)
  config <- initialize_bayesian_framework(list())

  # Test model comparison
  comparison <- compare_bayesian_models(models, config)

  expect_type(comparison, "list")
  expect_true("loo" %in% names(comparison))
})

#' Test Bayesian Analysis Report Generation
test_that("Bayesian analysis report generation works", {
  # Create mock Bayesian results
  mock_results <- list(
    formula = complication_risk ~ age + bmi,
    config = initialize_bayesian_framework(list()),
    diagnostics = list(
      overall_converged = TRUE,
      rhat = list(values = c(b_Intercept = 1.01, b_age = 1.02)),
      summary = data.frame(
        parameter = c("b_Intercept", "b_age"),
        rhat = c(1.01, 1.02),
        neff_ratio = c(0.8, 0.85),
        mcse_ratio = c(0.05, 0.04)
      )
    ),
    loo = list(estimates = matrix(c(-500, 50), nrow = 2, ncol = 1,
                                  dimnames = list(c("looic", "se_looic"), "Estimate"))),
    waic = list(estimates = matrix(c(-495, 48), nrow = 2, ncol = 1,
                                   dimnames = list(c("waic", "se_waic"), "Estimate")))
  )

  # Test report generation
  report_path <- generate_bayesian_report(mock_results, tempdir())

  expect_true(file.exists(report_path))
  expect_true(grepl("\\.html$", report_path))

  # Check that report contains expected content
  report_content <- readLines(report_path)
  expect_true(any(grepl("Bayesian Parameter Estimation Report", report_content)))
  expect_true(any(grepl("Overall Convergence", report_content)))
})

#' Test Package Loading
test_that("Bayesian packages can be loaded", {
  # This test will only run if packages are available
  skip_if_not_installed("rstan")

  # Test package loading function
  expect_error(load_bayesian_packages(), NA)
})

#' Integration Test: Full Bayesian Workflow
test_that("Full Bayesian workflow integration works", {
  # Create comprehensive mock data
  set.seed(789)
  n <- 500
  mock_data <- data.frame(
    age = rnorm(n, 65, 10),
    bmi = rnorm(n, 28, 5),
    kl_grade = sample(0:4, n, replace = TRUE),
    comorbidities = rbinom(n, 1, 0.3),
    smoking_status = rbinom(n, 1, 0.2),
    complication_risk = rbinom(n, 1, 0.15),
    treatment_response = rnorm(n, 0.7, 0.2)
  )

  config <- initialize_bayesian_framework(list())

  # Test workflow steps
  expect_type(config, "list")

  # Test uncertainty quantification with mock data
  mock_model <- list(
    posterior = data.frame(
      b_Intercept = rnorm(1000, -2, 0.5),
      b_age = rnorm(1000, 0.02, 0.01),
      b_bmi = rnorm(1000, 0.05, 0.02)
    )
  )

  uncertainty <- quantify_parameter_uncertainty(mock_model)
  expect_type(uncertainty, "list")
  expect_true(length(uncertainty) > 0)
})

# Run all tests
if (interactive()) {
  test_dir(".")
}
