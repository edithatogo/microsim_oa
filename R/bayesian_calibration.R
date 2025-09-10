#' Bayesian Parameter Estimation and Calibration Module
#'
#' This module implements Bayesian methods for parameter estimation and calibration
#' in the AUS-OA microsimulation model, providing probabilistic parameter learning
#' and uncertainty quantification.
#'
#' Key Components:
#' - Bayesian Parameter Estimation: MCMC-based parameter learning
#' - Model Calibration: Cross-validation and parameter tuning
#' - Uncertainty Quantification: Probabilistic parameter distributions
#' - Convergence Diagnostics: MCMC chain analysis and diagnostics

#' Load Bayesian Analysis Packages
load_bayesian_packages <- function() {
  required_packages <- c(
    "rstan", "rstanarm", "brms", "coda", "bayesplot",
    "loo", "bridgesampling", "tidybayes", "posterior"
  )

  installed <- required_packages %in% installed.packages()[, "Package"]
  if (any(!installed)) {
    missing <- required_packages[!installed]
    message("Installing missing Bayesian packages: ", paste(missing, collapse = ", "))
    install.packages(missing, dependencies = TRUE)
  }

  # Load packages
  lapply(required_packages, library, character.only = TRUE)
  message("All Bayesian packages loaded successfully")
}

#' Initialize Bayesian Framework
#'
#' @param config Configuration list
#' @return Bayesian framework configuration
#' @export
initialize_bayesian_framework <- function(config) {
  bayesian_config <- list()

  # MCMC settings
  bayesian_config$mcmc <- list(
    n_chains = 4,
    n_iter = 2000,
    n_warmup = 1000,
    n_thin = 1,
    adapt_delta = 0.95,
    max_treedepth = 15
  )

  # Prior distributions
  bayesian_config$priors <- list(
    intercept = "normal(0, 10)",
    coefficients = "normal(0, 5)",
    sigma = "exponential(1)",
    phi = "beta(2, 2)"  # For beta regression
  )

  # Convergence diagnostics
  bayesian_config$diagnostics <- list(
    rhat_threshold = 1.1,
    neff_ratio_threshold = 0.1,
    mcse_threshold = 0.1
  )

  # Model comparison
  bayesian_config$comparison <- list(
    loo = TRUE,
    waic = TRUE,
    bayes_factors = TRUE
  )

  return(bayesian_config)
}

#' Bayesian Parameter Estimation for Complication Risks
#'
#' @param data Patient data with outcomes
#' @param outcome_var Outcome variable to model
#' @param config Bayesian configuration
#' @return Bayesian model results
bayesian_parameter_estimation <- function(data, outcome_var, config) {

  message("Performing Bayesian parameter estimation for ", outcome_var)

  # Prepare formula
  predictors <- c("age", "bmi", "kl_grade", "comorbidities", "smoking_status")
  formula <- as.formula(paste(outcome_var, "~", paste(predictors, collapse = " + ")))

  # Fit Bayesian logistic regression
  if (is.factor(data[[outcome_var]]) || length(unique(data[[outcome_var]])) == 2) {
    # Binary outcome
    model <- brm(
      formula = formula,
      data = data,
      family = bernoulli(),
      prior = c(
        prior_string(config$priors$intercept, class = "Intercept"),
        prior_string(config$priors$coefficients, class = "b"),
        prior_string("exponential(1)", class = "sd")  # For random effects if any
      ),
      chains = config$mcmc$n_chains,
      iter = config$mcmc$n_iter,
      warmup = config$mcmc$n_warmup,
      control = list(
        adapt_delta = config$mcmc$adapt_delta,
        max_treedepth = config$mcmc$max_treedepth
      )
    )
  } else {
    # Continuous outcome
    model <- brm(
      formula = formula,
      data = data,
      family = gaussian(),
      prior = c(
        prior_string(config$priors$intercept, class = "Intercept"),
        prior_string(config$priors$coefficients, class = "b"),
        prior_string(config$priors$sigma, class = "sigma")
      ),
      chains = config$mcmc$n_chains,
      iter = config$mcmc$n_iter,
      warmup = config$mcmc$n_warmup,
      control = list(
        adapt_delta = config$mcmc$adapt_delta,
        max_treedepth = config$mcmc$max_treedepth
      )
    )
  }

  # Extract posterior samples
  posterior_samples <- posterior_samples(model)

  # Convergence diagnostics
  diagnostics <- list(
    rhat = rhat(model),
    neff = neff_ratio(model),
    mcse = mcse(model)
  )

  # Model evaluation
  loo_result <- loo(model)
  waic_result <- waic(model)

  return(list(
    model = model,
    posterior = posterior_samples,
    diagnostics = diagnostics,
    loo = loo_result,
    waic = waic_result,
    formula = formula,
    config = config
  ))
}

#' Bayesian Model Calibration
#'
#' @param bayesian_model Fitted Bayesian model
#' @param validation_data Validation dataset
#' @param config Configuration
#' @return Calibration results
bayesian_model_calibration <- function(bayesian_model, validation_data, config) {

  message("Performing Bayesian model calibration")

  # Generate predictions
  predictions <- posterior_predict(bayesian_model$model, newdata = validation_data)

  # Calculate prediction intervals
  pred_summary <- posterior_summary(predictions)

  # Calibration assessment
  if (is.factor(validation_data[[bayesian_model$outcome_var]]) ||
      length(unique(validation_data[[bayesian_model$outcome_var]])) == 2) {
    # Binary calibration
    observed <- validation_data[[bayesian_model$outcome_var]]

    # Calculate calibration curve
    prob_bins <- seq(0, 1, by = 0.1)
    calibration_data <- data.frame()

    for (i in 1:(length(prob_bins)-1)) {
      bin_start <- prob_bins[i]
      bin_end <- prob_bins[i+1]

      # Find predictions in this bin
      in_bin <- pred_summary[, "Estimate"] >= bin_start & pred_summary[, "Estimate"] < bin_end

      if (sum(in_bin) > 0) {
        observed_rate <- mean(observed[in_bin])
        predicted_rate <- mean(pred_summary[in_bin, "Estimate"])

        calibration_data <- rbind(calibration_data, data.frame(
          predicted = predicted_rate,
          observed = observed_rate,
          bin_start = bin_start,
          bin_end = bin_end,
          n = sum(in_bin)
        ))
      }
    }

    calibration <- list(
      calibration_curve = calibration_data,
      type = "binary"
    )
  } else {
    # Continuous calibration
    observed <- validation_data[[bayesian_model$outcome_var]]

    # Calculate calibration intercept and slope
    calibration_model <- lm(observed ~ pred_summary[, "Estimate"])

    calibration <- list(
      intercept = coef(calibration_model)[1],
      slope = coef(calibration_model)[2],
      r_squared = summary(calibration_model)$r.squared,
      type = "continuous"
    )
  }

  return(calibration)
}

#' Uncertainty Quantification for Parameters
#'
#' @param bayesian_model Fitted Bayesian model
#' @param parameters Parameters of interest
#' @return Uncertainty quantification results
quantify_parameter_uncertainty <- function(bayesian_model, parameters = NULL) {

  message("Quantifying parameter uncertainty")

  # Extract posterior distributions
  posterior <- bayesian_model$posterior

  if (is.null(parameters)) {
    parameters <- colnames(posterior)
  }

  uncertainty_results <- list()

  for (param in parameters) {
    if (param %in% colnames(posterior)) {
      param_samples <- posterior[[param]]

      uncertainty_results[[param]] <- list(
        mean = mean(param_samples),
        median = median(param_samples),
        sd = sd(param_samples),
        ci_95 = quantile(param_samples, c(0.025, 0.975)),
        ci_90 = quantile(param_samples, c(0.05, 0.95)),
        hdi_95 = HDInterval::hdi(param_samples, credMass = 0.95),
        distribution = param_samples
      )
    }
  }

  return(uncertainty_results)
}

#' MCMC Convergence Diagnostics
#'
#' @param bayesian_model Fitted Bayesian model
#' @param config Diagnostics configuration
#' @return Convergence diagnostics
assess_mcmc_convergence <- function(bayesian_model, config) {

  message("Assessing MCMC convergence")

  # R-hat statistics
  rhat_values <- rhat(bayesian_model$model)
  rhat_converged <- all(rhat_values < config$diagnostics$rhat_threshold)

  # Effective sample size
  neff_values <- neff_ratio(bayesian_model$model)
  neff_converged <- all(neff_values > config$diagnostics$neff_ratio_threshold)

  # Monte Carlo standard error
  mcse_values <- mcse(bayesian_model$model)
  mcse_converged <- all(mcse_values[, "mcse"] / mcse_values[, "sd"] < config$diagnostics$mcse_threshold)

  # Overall convergence
  converged <- rhat_converged && neff_converged && mcse_converged

  diagnostics <- list(
    rhat = list(values = rhat_values, converged = rhat_converged),
    neff = list(values = neff_values, converged = neff_converged),
    mcse = list(values = mcse_values, converged = mcse_converged),
    overall_converged = converged,
    summary = data.frame(
      parameter = names(rhat_values),
      rhat = rhat_values,
      neff_ratio = neff_values,
      mcse_ratio = mcse_values[, "mcse"] / mcse_values[, "sd"]
    )
  )

  return(diagnostics)
}

#' Bayesian Model Comparison
#'
#' @param models List of fitted Bayesian models
#' @param config Comparison configuration
#' @return Model comparison results
compare_bayesian_models <- function(models, config) {

  message("Comparing Bayesian models")

  comparison_results <- list()

  if (config$comparison$loo) {
    loo_results <- lapply(models, function(m) loo(m$model))
    loo_comparison <- loo_compare(loo_results)
    comparison_results$loo <- list(
      results = loo_results,
      comparison = loo_comparison
    )
  }

  if (config$comparison$waic) {
    waic_results <- lapply(models, function(m) waic(m$model))
    waic_comparison <- loo_compare(waic_results)
    comparison_results$waic <- list(
      results = waic_results,
      comparison = waic_comparison
    )
  }

  if (config$comparison$bayes_factors) {
    # Calculate Bayes factors using bridge sampling
    if (length(models) == 2) {
      bf <- bayes_factor(models[[1]]$model, models[[2]]$model)
      comparison_results$bayes_factor <- bf
    }
  }

  return(comparison_results)
}

#' Generate Bayesian Analysis Report
#'
#' @param bayesian_results Bayesian analysis results
#' @param output_dir Output directory
#' @return Report path
generate_bayesian_report <- function(bayesian_results, output_dir = "output") {

  if (!dir.exists(output_dir)) {
    dir.create(output_dir, recursive = TRUE)
  }

  report_path <- file.path(output_dir, "bayesian_analysis_report.html")

  # Create report content
  report_content <- paste0(
    "<!DOCTYPE html>
    <html>
    <head>
        <title>Bayesian Parameter Estimation Report</title>
        <style>
            body { font-family: Arial, sans-serif; margin: 40px; }
            h1, h2 { color: #2E86AB; }
            table { border-collapse: collapse; width: 100%; }
            th, td { border: 1px solid #ddd; padding: 8px; text-align: left; }
            th { background-color: #f2f2f2; }
            .converged { color: green; }
            .not-converged { color: red; }
        </style>
    </head>
    <body>
        <h1>Bayesian Parameter Estimation Report</h1>
        <p><strong>Generated on:</strong> ", format(Sys.time(), "%Y-%m-%d %H:%M:%S"), "</p>

        <h2>Model Summary</h2>
        <p><strong>Formula:</strong> ", deparse(bayesian_results$formula), "</p>
        <p><strong>MCMC Settings:</strong></p>
        <ul>
            <li>Chains: ", bayesian_results$config$mcmc$n_chains, "</li>
            <li>Iterations: ", bayesian_results$config$mcmc$n_iter, "</li>
            <li>Warmup: ", bayesian_results$config$mcmc$n_warmup, "</li>
        </ul>

        <h2>Convergence Diagnostics</h2>
        <p class='", ifelse(bayesian_results$diagnostics$overall_converged, "converged", "not-converged"), "'>
            <strong>Overall Convergence:</strong> ",
            ifelse(bayesian_results$diagnostics$overall_converged, "CONVERGED", "NOT CONVERGED"), "
        </p>

        <h3>R-hat Statistics</h3>
        <table>
            <tr><th>Parameter</th><th>R-hat</th><th>Status</th></tr>",
            paste(sapply(names(bayesian_results$diagnostics$rhat$values), function(param) {
              rhat_val <- bayesian_results$diagnostics$rhat$values[param]
              status <- ifelse(rhat_val < 1.1, "PASS", "FAIL")
              paste0("<tr><td>", param, "</td><td>", round(rhat_val, 3), "</td><td>", status, "</td></tr>")
            }), collapse = ""),
        "</table>

        <h2>Model Evaluation</h2>
        <p><strong>LOO-IC:</strong> ", round(bayesian_results$loo$estimates["looic", "Estimate"], 2), "</p>
        <p><strong>WAIC:</strong> ", round(bayesian_results$waic$estimates["waic", "Estimate"], 2), "</p>

    </body>
    </html>"
  )

  writeLines(report_content, report_path)
  message("Bayesian analysis report saved to: ", report_path)

  return(report_path)
}
