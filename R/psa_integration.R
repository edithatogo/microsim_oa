#' PSA Framework Integration Module
#'
#' This module provides integration functions for the Probabilistic Sensitivity
#' Analysis (PSA) framework within the AUS-OA simulation model.
#'
#' Key Functions:
#' - integrate_psa_framework(): Main integration function
#' - run_psa_analysis(): Execute PSA with convergence diagnostics
#' - generate_psa_report(): Create comprehensive PSA reports
#' - validate_psa_results(): Validate PSA results and convergence
#' - create_ceac(): Generate Cost-Effectiveness Acceptability Curves

#' Extract PSA Parameters from Configuration
#'
#' @param config Configuration list containing PSA parameters
#' @return List of PSA control parameters
extract_psa_parameters <- function(config) {
  # Extract PSA parameters from coefficients
  coeffs <- config$coefficients

  if (!"psa" %in% names(coeffs)) {
    warning("PSA parameters not found in configuration, using defaults")
    return(get_default_psa_parameters())
  }

  psa_params <- coeffs$psa

  # Validate required sections
  required_sections <- c("monte_carlo", "convergence", "uncertainty", "cost_effectiveness")
  missing_sections <- setdiff(required_sections, names(psa_params))

  if (length(missing_sections) > 0) {
    warning("Missing PSA parameter sections: ", paste(missing_sections, collapse = ", "))
  }

  return(psa_params)
}

#' Get Default PSA Parameters
#'
#' @return Default PSA parameter configuration
get_default_psa_parameters <- function() {
  list(
    monte_carlo = list(
      default_n_samples = list(live = 1000),
      min_samples_convergence = list(live = 500),
      target_samples_convergence = list(live = 2000),
      default_seed = list(live = 12345)
    ),
    convergence = list(
      ci_width_threshold = list(live = 0.05),
      relative_se_threshold = list(live = 0.02),
      half_width_ratio_threshold = list(live = 0.1),
      n_batches_convergence = list(live = 10)
    ),
    uncertainty = list(
      default_uncertainty_level = list(live = 0.1),
      min_uncertainty_level = list(live = 0.01),
      max_uncertainty_level = list(live = 0.5)
    ),
    cost_effectiveness = list(
      wtp_threshold = list(live = 50000)
    )
  )
}

#' Run PSA Analysis with Convergence Diagnostics
#'
#' @param config Base configuration
#' @param n_samples Number of PSA samples (optional, uses config default)
#' @param seed Random seed (optional, uses config default)
#' @param convergence_check Run convergence diagnostics
#' @return PSA results with convergence assessment
run_psa_analysis <- function(config, n_samples = NULL, seed = NULL, convergence_check = TRUE) {
  # Load PSA framework
  source("R/psa_framework.R")

  # Extract PSA parameters
  psa_params <- extract_psa_parameters(config)

  # Set defaults if not provided
  if (is.null(n_samples)) {
    n_samples <- psa_params$monte_carlo$default_n_samples$live
  }
  if (is.null(seed)) {
    seed <- psa_params$monte_carlo$default_seed$live
  }

  # Create simulation wrapper function
  simulation_wrapper <- function(config_psa, cycle_count = 10) {
    # This would integrate with the main simulation cycle
    # For now, return mock results
    list(
      total_cost = rnorm(1, 50000, 10000),
      total_qaly = rnorm(1, 8, 1),
      complications = rbinom(1, 1, 0.1),
      successful = TRUE
    )
  }

  # Run PSA
  psa_results <- psa_framework(
    config = config,
    n_samples = n_samples,
    simulation_function = simulation_wrapper,
    seed = seed
  )

  # Add convergence assessment if requested
  if (convergence_check) {
    psa_results$convergence_assessment <- assess_psa_convergence(psa_results, psa_params)
  }

  return(psa_results)
}

#' Assess PSA Convergence
#'
#' @param psa_results PSA results from framework
#' @param psa_params PSA control parameters
#' @return Convergence assessment results
assess_psa_convergence <- function(psa_results, psa_params) {
  assessment <- list()

  # Extract successful results
  successful_results <- Filter(function(x) is.list(x) && !("error" %in% names(x)),
                              psa_results$simulation_results)

  n_successful <- length(successful_results)

  # Basic convergence checks
  assessment$sufficient_samples <- n_successful >= psa_params$monte_carlo$min_samples_convergence$live
  assessment$target_samples <- n_successful >= psa_params$monte_carlo$target_samples_convergence$live

  if (n_successful >= psa_params$monte_carlo$min_samples_convergence$live) {
    # Extract outcomes for convergence analysis
    costs <- sapply(successful_results, function(x) x$total_cost)
    qalys <- sapply(successful_results, function(x) x$total_qaly)

    # Calculate confidence intervals
    cost_ci <- quantile(costs, c(0.025, 0.975))
    qaly_ci <- quantile(qalys, c(0.025, 0.975))

    # Relative confidence interval width
    cost_ci_width <- (cost_ci[2] - cost_ci[1]) / mean(costs)
    qaly_ci_width <- (qaly_ci[2] - qaly_ci[1]) / mean(qalys)

    # Relative standard error
    cost_rse <- sd(costs) / mean(costs)
    qaly_rse <- sd(qalys) / mean(qalys)

    assessment$cost_convergence <- list(
      ci_width = cost_ci_width,
      ci_width_converged = cost_ci_width <= psa_params$convergence$ci_width_threshold$live,
      relative_se = cost_rse,
      rse_converged = cost_rse <= psa_params$convergence$relative_se_threshold$live,
      confidence_interval = cost_ci
    )

    assessment$qaly_convergence <- list(
      ci_width = qaly_ci_width,
      ci_width_converged = qaly_ci_width <= psa_params$convergence$ci_width_threshold$live,
      relative_se = qaly_rse,
      rse_converged = qaly_rse <= psa_params$convergence$relative_se_threshold$live,
      confidence_interval = qaly_ci
    )

    # Overall convergence status
    assessment$overall_converged <- assessment$cost_convergence$ci_width_converged &&
                                    assessment$cost_convergence$rse_converged &&
                                    assessment$qaly_convergence$ci_width_converged &&
                                    assessment$qaly_convergence$rse_converged
  } else {
    assessment$overall_converged <- FALSE
    assessment$message <- "Insufficient successful simulations for convergence assessment"
  }

  assessment$n_successful_simulations <- n_successful
  assessment$timestamp <- Sys.time()

  return(assessment)
}

#' Generate Cost-Effectiveness Acceptability Curve (CEAC)
#'
#' @param psa_results PSA results
#' @param wtp_threshold Willingness-to-pay threshold
#' @param wtp_range Range of WTP values for CEAC
#' @return CEAC data for plotting
generate_ceac <- function(psa_results, wtp_threshold = NULL, wtp_range = NULL) {
  # Extract successful results
  successful_results <- Filter(function(x) is.list(x) && !("error" %in% names(x)),
                              psa_results$simulation_results)

  if (length(successful_results) == 0) {
    warning("No successful simulations for CEAC generation")
    return(NULL)
  }

  # Extract costs and QALYs
  costs <- sapply(successful_results, function(x) x$total_cost)
  qalys <- sapply(successful_results, function(x) x$total_qaly)

  # Calculate incremental cost-effectiveness ratios
  icers <- costs / qalys

  # Set default WTP range if not provided
  if (is.null(wtp_range)) {
    wtp_range <- seq(0, 150000, by = 5000)
  }

  # Calculate probability cost-effective for each WTP value
  ceac_data <- data.frame(
    wtp = wtp_range,
    probability_ce = sapply(wtp_range, function(wtp) {
      mean(icers <= wtp, na.rm = TRUE)
    })
  )

  # Add expected values
  ceac_data$expected_cost <- mean(costs)
  ceac_data$expected_qaly <- mean(qalys)
  ceac_data$expected_icer <- mean(icers, na.rm = TRUE)

  # Add WTP threshold line if provided
  if (!is.null(wtp_threshold)) {
    threshold_prob <- ceac_data$probability_ce[which.min(abs(ceac_data$wtp - wtp_threshold))]
    ceac_data$wtp_threshold <- wtp_threshold
    ceac_data$threshold_probability <- threshold_prob
  }

  return(ceac_data)
}

#' Generate Comprehensive PSA Report
#'
#' @param psa_results Complete PSA results
#' @param output_dir Directory to save report files
#' @return PSA report summary
generate_psa_report <- function(psa_results, output_dir = "output") {
  # Create output directory if it doesn't exist
  if (!dir.exists(output_dir)) {
    dir.create(output_dir, recursive = TRUE)
  }

  report <- list()

  # Basic summary
  report$summary <- list(
    total_simulations = length(psa_results$simulation_results),
    successful_simulations = sum(sapply(psa_results$simulation_results,
                                       function(x) is.list(x) && !("error" %in% names(x)))),
    convergence_status = ifelse("convergence_assessment" %in% names(psa_results),
                               psa_results$convergence_assessment$overall_converged,
                               "NOT_ASSESSED"),
    timestamp = Sys.time()
  )

  # Parameter summary
  report$parameters <- list(
    n_parameters = length(psa_results$distributions),
    parameter_names = names(psa_results$distributions),
    distributions_used = sapply(psa_results$distributions, function(x) x$type)
  )

  # Results summary
  if ("simulation_results" %in% names(psa_results)) {
    successful_results <- Filter(function(x) is.list(x) && !("error" %in% names(x)),
                                psa_results$simulation_results)

    if (length(successful_results) > 0) {
      costs <- sapply(successful_results, function(x) x$total_cost)
      qalys <- sapply(successful_results, function(x) x$total_qaly)

      report$results <- list(
        cost_summary = list(
          mean = mean(costs, na.rm = TRUE),
          sd = sd(costs, na.rm = TRUE),
          median = median(costs, na.rm = TRUE),
          ci_95 = quantile(costs, c(0.025, 0.975), na.rm = TRUE)
        ),
        qaly_summary = list(
          mean = mean(qalys, na.rm = TRUE),
          sd = sd(qalys, na.rm = TRUE),
          median = median(qalys, na.rm = TRUE),
          ci_95 = quantile(qalys, c(0.025, 0.975), na.rm = TRUE)
        ),
        icer = list(
          mean = mean(costs/qalys, na.rm = TRUE),
          median = median(costs/qalys, na.rm = TRUE)
        )
      )
    }
  }

  # Convergence assessment
  if ("convergence_assessment" %in% names(psa_results)) {
    report$convergence <- psa_results$convergence_assessment
  }

  # Save report
  report_file <- file.path(output_dir, paste0("psa_report_", format(Sys.time(), "%Y%m%d_%H%M%S"), ".rds"))
  saveRDS(report, file = report_file)

  # Create summary text file
  summary_file <- file.path(output_dir, paste0("psa_summary_", format(Sys.time(), "%Y%m%d_%H%M%S"), ".txt"))
  write_psa_summary_text(report, summary_file)

  report$files <- list(
    rds_file = report_file,
    summary_file = summary_file
  )

  return(report)
}

#' Write PSA Summary to Text File
#'
#' @param report PSA report
#' @param filename Output filename
write_psa_summary_text <- function(report, filename) {
  sink(filename)

  cat("=== AUS-OA Probabilistic Sensitivity Analysis Report ===\n")
  cat("Generated:", format(report$summary$timestamp, "%Y-%m-%d %H:%M:%S"), "\n\n")

  cat("SUMMARY:\n")
  cat("- Total Simulations:", report$summary$total_simulations, "\n")
  cat("- Successful Simulations:", report$summary$successful_simulations, "\n")
  cat("- Convergence Status:", report$summary$convergence_status, "\n\n")

  cat("PARAMETERS:\n")
  cat("- Number of Parameters:", report$parameters$n_parameters, "\n")
  cat("- Distribution Types Used:", paste(unique(report$parameters$distributions_used), collapse = ", "), "\n\n")

  if ("results" %in% names(report)) {
    cat("RESULTS:\n")
    cat("Costs (AUD):\n")
    cat("- Mean:", format(report$results$cost_summary$mean, big.mark = ","), "\n")
    cat("- SD:", format(report$results$cost_summary$sd, big.mark = ","), "\n")
    cat("- 95% CI:", paste(format(report$results$cost_summary$ci_95, big.mark = ","), collapse = " - "), "\n\n")

    cat("QALYs:\n")
    cat("- Mean:", format(report$results$qaly_summary$mean, digits = 3), "\n")
    cat("- SD:", format(report$results$qaly_summary$sd, digits = 3), "\n")
    cat("- 95% CI:", paste(format(report$results$qaly_summary$ci_95, digits = 3), collapse = " - "), "\n\n")

    cat("ICER (Cost per QALY):\n")
    cat("- Mean:", format(report$results$icer$mean, big.mark = ","), "\n")
    cat("- Median:", format(report$results$icer$median, big.mark = ","), "\n\n")
  }

  sink()
}

#' Validate PSA Results
#'
#' @param psa_results PSA results to validate
#' @return Validation summary
validate_psa_results <- function(psa_results) {
  validation <- list()

  # Check basic structure
  validation$has_parameter_matrix <- !is.null(psa_results$parameter_matrix)
  validation$has_simulation_results <- !is.null(psa_results$simulation_results)
  validation$has_distributions <- !is.null(psa_results$distributions)

  # Check parameter matrix
  if (validation$has_parameter_matrix) {
    param_matrix <- psa_results$parameter_matrix
    validation$parameter_matrix_valid <- is.matrix(param_matrix) &&
                                        nrow(param_matrix) > 0 &&
                                        ncol(param_matrix) > 0
    validation$n_samples <- nrow(param_matrix)
    validation$n_parameters <- ncol(param_matrix)
  }

  # Check simulation results
  if (validation$has_simulation_results) {
    sim_results <- psa_results$simulation_results
    validation$n_simulations <- length(sim_results)
    validation$successful_simulations <- sum(sapply(sim_results,
                                                   function(x) is.list(x) && !("error" %in% names(x))))
    validation$failed_simulations <- validation$n_simulations - validation$successful_simulations
  }

  # Overall validation
  validation$overall_valid <- all(unlist(validation))

  return(validation)
}

#' Main PSA Integration Function
#'
#' @param config Base configuration
#' @param n_samples Number of PSA samples
#' @param seed Random seed
#' @param generate_report Generate comprehensive report
#' @param output_dir Output directory for reports
#' @return Complete PSA analysis results
integrate_psa_framework <- function(config, n_samples = NULL, seed = NULL,
                                   generate_report = TRUE, output_dir = "output") {

  # Run PSA analysis
  psa_results <- run_psa_analysis(config, n_samples, seed)

  # Validate results
  validation <- validate_psa_results(psa_results)
  psa_results$validation <- validation

  # Generate CEAC
  psa_results$ceac <- generate_ceac(psa_results)

  # Generate comprehensive report if requested
  if (generate_report) {
    psa_results$report <- generate_psa_report(psa_results, output_dir)
  }

  # Add integration metadata
  psa_results$integration_info <- list(
    framework_version = "1.0",
    integration_timestamp = Sys.time(),
    config_used = config,
    parameters = list(
      n_samples = n_samples,
      seed = seed,
      generate_report = generate_report,
      output_dir = output_dir
    )
  )

  return(psa_results)
}

#' Analyze Parameter Influence (Tornado Diagram Data)
#'
#' @param psa_results PSA results
#' @param outcome_var Outcome variable to analyze ("total_cost", "total_qaly", or "icer")
#' @param n_levels Number of parameter levels for analysis
#' @return Tornado diagram data
analyze_parameter_influence <- function(psa_results, outcome_var = "icer", n_levels = 5) {

  # Extract successful results
  successful_results <- Filter(function(x) is.list(x) && !("error" %in% names(x)),
                              psa_results$simulation_results)

  if (length(successful_results) == 0) {
    warning("No successful simulations for parameter influence analysis")
    return(NULL)
  }

  # Extract parameter matrix
  if (is.null(psa_results$parameter_matrix)) {
    warning("No parameter matrix available for influence analysis")
    return(NULL)
  }

  param_matrix <- psa_results$parameter_matrix
  n_params <- ncol(param_matrix)
  param_names <- colnames(param_matrix)

  # Calculate outcome variable
  outcomes <- sapply(successful_results, function(x) {
    if (outcome_var == "icer") {
      return(x$total_cost / x$total_qaly)
    } else {
      return(x[[outcome_var]])
    }
  })

  # Initialize results
  influence_data <- list()

  # Analyze each parameter
  for (i in 1:n_params) {
    param_values <- param_matrix[, i]
    param_name <- param_names[i]

    # Create parameter levels
    param_levels <- quantile(param_values, probs = seq(0, 1, length.out = n_levels))

    # Calculate outcome for each level
    level_outcomes <- sapply(1:(n_levels-1), function(j) {
      # Find simulations within this parameter range
      in_range <- param_values >= param_levels[j] & param_values <= param_levels[j+1]
      if (sum(in_range) > 0) {
        return(mean(outcomes[in_range], na.rm = TRUE))
      } else {
        return(NA)
      }
    })

    # Calculate influence (range of outcomes)
    valid_outcomes <- level_outcomes[!is.na(level_outcomes)]
    if (length(valid_outcomes) >= 2) {
      influence <- max(valid_outcomes) - min(valid_outcomes)
      influence_data[[param_name]] <- list(
        parameter = param_name,
        influence = influence,
        min_outcome = min(valid_outcomes),
        max_outcome = max(valid_outcomes),
        levels = param_levels,
        level_outcomes = level_outcomes
      )
    }
  }

  # Sort by influence (descending)
  if (length(influence_data) > 0) {
    influence_data <- influence_data[order(sapply(influence_data, function(x) x$influence), decreasing = TRUE)]
  }

  return(influence_data)
}

#' Analyze Parameter Correlations
#'
#' @param psa_results PSA results
#' @param outcome_var Outcome variable to analyze
#' @return Parameter correlation analysis
analyze_parameter_correlations <- function(psa_results, outcome_var = "icer") {

  # Extract successful results
  successful_results <- Filter(function(x) is.list(x) && !("error" %in% names(x)),
                              psa_results$simulation_results)

  if (length(successful_results) == 0) {
    warning("No successful simulations for correlation analysis")
    return(NULL)
  }

  # Extract parameter matrix
  if (is.null(psa_results$parameter_matrix)) {
    warning("No parameter matrix available for correlation analysis")
    return(NULL)
  }

  param_matrix <- psa_results$parameter_matrix

  # Calculate outcome variable
  outcomes <- sapply(successful_results, function(x) {
    if (outcome_var == "icer") {
      return(x$total_cost / x$total_qaly)
    } else {
      return(x[[outcome_var]])
    }
  })

  # Calculate correlations
  correlations <- apply(param_matrix, 2, function(param) {
    cor(param, outcomes, use = "complete.obs")
  })

  # Calculate partial correlations (accounting for other parameters)
  partial_cors <- list()
  param_names <- colnames(param_matrix)

  for (i in 1:length(param_names)) {
    other_params <- param_matrix[, -i, drop = FALSE]
    if (ncol(other_params) > 0) {
      # Simple partial correlation approximation
      param_i <- param_matrix[, i]
      lm_outcome <- lm(outcomes ~ other_params)
      lm_param <- lm(param_i ~ other_params)

      residual_outcome <- residuals(lm_outcome)
      residual_param <- residuals(lm_param)

      partial_cor <- cor(residual_param, residual_outcome, use = "complete.obs")
      partial_cors[[param_names[i]]] <- partial_cor
    } else {
      partial_cors[[param_names[i]]] <- correlations[i]
    }
  }

  # Create correlation data frame
  correlation_data <- data.frame(
    parameter = param_names,
    pearson_correlation = correlations,
    partial_correlation = unlist(partial_cors),
    abs_correlation = abs(correlations),
    abs_partial_correlation = abs(unlist(partial_cors))
  )

  # Sort by absolute correlation
  correlation_data <- correlation_data[order(correlation_data$abs_correlation, decreasing = TRUE), ]

  return(list(
    correlation_data = correlation_data,
    parameter_matrix = param_matrix,
    outcomes = outcomes,
    outcome_var = outcome_var
  ))
}

#' Perform Sensitivity Analysis
#'
#' @param psa_results PSA results
#' @param parameters_to_vary Parameters to vary in sensitivity analysis
#' @param outcome_var Outcome variable to analyze
#' @param variation_percent Percentage variation for parameters
#' @return Sensitivity analysis results
perform_sensitivity_analysis <- function(psa_results, parameters_to_vary = NULL,
                                       outcome_var = "icer", variation_percent = 0.1) {

  # Extract successful results
  successful_results <- Filter(function(x) is.list(x) && !("error" %in% names(x)),
                              psa_results$simulation_results)

  if (length(successful_results) == 0) {
    warning("No successful simulations for sensitivity analysis")
    return(NULL)
  }

  # Extract parameter matrix
  if (is.null(psa_results$parameter_matrix)) {
    warning("No parameter matrix available for sensitivity analysis")
    return(NULL)
  }

  param_matrix <- psa_results$parameter_matrix
  param_names <- colnames(param_matrix)

  # If no parameters specified, use all
  if (is.null(parameters_to_vary)) {
    parameters_to_vary <- param_names
  }

  # Calculate base case outcome
  base_outcomes <- sapply(successful_results, function(x) {
    if (outcome_var == "icer") {
      return(x$total_cost / x$total_qaly)
    } else {
      return(x[[outcome_var]])
    }
  })

  base_mean <- mean(base_outcomes, na.rm = TRUE)

  # Initialize sensitivity results
  sensitivity_results <- list()

  # Analyze each parameter
  for (param_name in parameters_to_vary) {
    if (!(param_name %in% param_names)) {
      warning(sprintf("Parameter %s not found in parameter matrix", param_name))
      next
    }

    param_col <- which(param_names == param_name)
    param_values <- param_matrix[, param_col]

    # Calculate sensitivity for different parameter values
    param_range <- range(param_values, na.rm = TRUE)
    param_mean <- mean(param_values, na.rm = TRUE)

    # Create variation scenarios
    low_value <- param_mean * (1 - variation_percent)
    high_value <- param_mean * (1 + variation_percent)

    # Find simulations close to low and high values
    low_indices <- which(abs(param_values - low_value) ==
                        min(abs(param_values - low_value)))[1:10] # Take closest 10
    high_indices <- which(abs(param_values - high_value) ==
                         min(abs(param_values - high_value)))[1:10]

    low_outcomes <- base_outcomes[low_indices]
    high_outcomes <- base_outcomes[high_indices]

    low_mean <- mean(low_outcomes, na.rm = TRUE)
    high_mean <- mean(high_outcomes, na.rm = TRUE)

    # Calculate sensitivity measures
    sensitivity_results[[param_name]] <- list(
      parameter = param_name,
      base_value = param_mean,
      low_value = low_value,
      high_value = high_value,
      base_outcome = base_mean,
      low_outcome = low_mean,
      high_outcome = high_mean,
      outcome_change = high_mean - low_mean,
      sensitivity_ratio = (high_mean - low_mean) / (high_value - low_value),
      elasticity = ((high_mean - low_mean) / base_mean) / ((high_value - low_value) / param_mean)
    )
  }

  return(sensitivity_results)
}

#' Generate Comprehensive Uncertainty Analysis
#'
#' @param psa_results PSA results
#' @param outcome_var Outcome variable to analyze
#' @param wtp_threshold Willingness-to-pay threshold (for ICER analysis)
#' @return Comprehensive uncertainty analysis
generate_uncertainty_analysis <- function(psa_results, outcome_var = "icer",
                                        wtp_threshold = 50000) {

  analysis <- list()

  # Parameter influence analysis (tornado diagram data)
  analysis$parameter_influence <- analyze_parameter_influence(psa_results, outcome_var)

  # Parameter correlation analysis
  analysis$parameter_correlations <- analyze_parameter_correlations(psa_results, outcome_var)

  # Sensitivity analysis
  analysis$sensitivity_analysis <- perform_sensitivity_analysis(psa_results, outcome_var = outcome_var)

  # Uncertainty summary
  analysis$uncertainty_summary <- list(
    outcome_variable = outcome_var,
    wtp_threshold = wtp_threshold,
    n_simulations = length(psa_results$simulation_results),
    n_parameters = if (!is.null(psa_results$parameter_matrix)) ncol(psa_results$parameter_matrix) else 0,
    analysis_timestamp = Sys.time()
  )

  # Key insights
  analysis$insights <- list()

  # Most influential parameters
  if (!is.null(analysis$parameter_influence) && length(analysis$parameter_influence) > 0) {
    top_params <- names(analysis$parameter_influence)[1:min(5, length(analysis$parameter_influence))]
    analysis$insights$most_influential <- top_params
  }

  # Strongest correlations
  if (!is.null(analysis$parameter_correlations)) {
    strong_cors <- analysis$parameter_correlations$correlation_data
    strong_cors <- strong_cors[abs(strong_cors$pearson_correlation) > 0.3, ]
    if (nrow(strong_cors) > 0) {
      analysis$insights$strong_correlations <- strong_cors$parameter
    }
  }

  return(analysis)
}

# Test function
test_function <- function() {
  return("test")
}
