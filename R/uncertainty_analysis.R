#' Analyze Parameter Influence (Tornado Diagram Data)
#'
#' @param psa_results PSA results
#' @param outcome_var Outcome variable to analyze ("total_cost", "total_qaly", or "icer")
#' @param n_levels Number of parameter levels for analysis
#' @return Tornado diagram data
analyze_parameter_influence <- function(psa_results, outcome_var = "icer", n_levels = 5) {
  # Extract successful results
  successful_results <- Filter(
    function(x) is.list(x) && !("error" %in% names(x)),
    psa_results$simulation_results
  )

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
    level_outcomes <- sapply(1:(n_levels - 1), function(j) {
      # Find simulations within this parameter range
      in_range <- param_values >= param_levels[j] & param_values <= param_levels[j + 1]
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
  successful_results <- Filter(
    function(x) is.list(x) && !("error" %in% names(x)),
    psa_results$simulation_results
  )

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
  successful_results <- Filter(
    function(x) is.list(x) && !("error" %in% names(x)),
    psa_results$simulation_results
  )

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
