#' Generate CEAC with Bootstrap Confidence Intervals
#'
#' @param psa_results PSA results
#' @param wtp_threshold Willingness-to-pay threshold
#' @param wtp_range Range of WTP values for CEAC
#' @param n_bootstrap Number of bootstrap samples
#' @param conf_level Confidence level for intervals
#' @return CEAC data with bootstrap confidence intervals
generate_ceac_bootstrap <- function(psa_results, wtp_threshold = NULL, wtp_range = NULL,
                                   n_bootstrap = 1000, conf_level = 0.95) {

  # Generate base CEAC
  base_ceac <- generate_ceac(psa_results, wtp_threshold, wtp_range)

  if (is.null(base_ceac)) {
    return(NULL)
  }

  # Extract successful results
  successful_results <- Filter(function(x) is.list(x) && !("error" %in% names(x)),
                              psa_results$simulation_results)

  if (length(successful_results) == 0) {
    warning("No successful simulations for bootstrap CEAC")
    return(base_ceac)
  }

  # Extract costs and QALYs
  costs <- sapply(successful_results, function(x) x$total_cost)
  qalys <- sapply(successful_results, function(x) x$total_qaly)
  n_sim <- length(costs)

  # Bootstrap CEAC
  bootstrap_ceac <- lapply(1:n_bootstrap, function(i) {
    # Bootstrap sample
    indices <- sample(1:n_sim, n_sim, replace = TRUE)
    boot_costs <- costs[indices]
    boot_qalys <- qalys[indices]

    # Calculate ICERs for bootstrap sample
    boot_icers <- boot_costs / boot_qalys

    # Calculate CEAC for this bootstrap sample
    boot_ceac <- data.frame(
      wtp = base_ceac$wtp,
      probability_ce = sapply(base_ceac$wtp, function(wtp) {
        mean(boot_icers <= wtp, na.rm = TRUE)
      })
    )

    return(boot_ceac$probability_ce)
  })

  # Calculate confidence intervals
  bootstrap_matrix <- do.call(cbind, bootstrap_ceac)
  ci_lower <- apply(bootstrap_matrix, 1, quantile, probs = (1 - conf_level) / 2)
  ci_upper <- apply(bootstrap_matrix, 1, quantile, probs = 1 - (1 - conf_level) / 2)

  # Add confidence intervals to base CEAC
  base_ceac$ci_lower <- ci_lower
  base_ceac$ci_upper <- ci_upper
  base_ceac$conf_level <- conf_level
  base_ceac$n_bootstrap <- n_bootstrap

  return(base_ceac)
}

#' Calculate Net Monetary Benefit (NMB)
#'
#' @param psa_results PSA results
#' @param wtp_threshold Willingness-to-pay threshold
#' @return NMB statistics
calculate_nmb <- function(psa_results, wtp_threshold) {

  # Extract successful results
  successful_results <- Filter(function(x) is.list(x) && !("error" %in% names(x)),
                              psa_results$simulation_results)

  if (length(successful_results) == 0) {
    warning("No successful simulations for NMB calculation")
    return(NULL)
  }

  # Extract costs and QALYs
  costs <- sapply(successful_results, function(x) x$total_cost)
  qalys <- sapply(successful_results, function(x) x$total_qaly)

  # Calculate NMB
  nmb <- (qalys * wtp_threshold) - costs

  # Calculate statistics
  nmb_stats <- list(
    mean_nmb = mean(nmb),
    sd_nmb = sd(nmb),
    median_nmb = median(nmb),
    ci_nmb = quantile(nmb, c(0.025, 0.975)),
    prob_positive_nmb = mean(nmb > 0),
    expected_cost = mean(costs),
    expected_qaly = mean(qalys),
    expected_icer = mean(costs) / mean(qalys),
    wtp_threshold = wtp_threshold
  )

  return(nmb_stats)
}

#' Calculate Value of Information (VOI)
#'
#' @param psa_results PSA results
#' @param wtp_threshold Willingness-to-pay threshold
#' @return VOI statistics
calculate_voi <- function(psa_results, wtp_threshold) {

  # Calculate NMB
  nmb_stats <- calculate_nmb(psa_results, wtp_threshold)

  if (is.null(nmb_stats)) {
    return(NULL)
  }

  # Expected Value of Perfect Information (EVPI)
  # EVPI = Expected NMB with perfect information - Expected NMB with current information
  expected_nmb_current <- nmb_stats$mean_nmb

  # With perfect information, we'd always choose the best option
  # For a single intervention, EVPI is the difference between expected NMB and
  # the NMB we'd get if we knew the true parameter values
  evpi <- max(0, nmb_stats$mean_nmb) - nmb_stats$mean_nmb

  # Expected Value of Partial Perfect Information (EVPPI) would require
  # more sophisticated analysis of individual parameters

  voi_stats <- list(
    evpi = evpi,
    evpi_per_person = evpi,
    nmb_stats = nmb_stats,
    wtp_threshold = wtp_threshold,
    method = "Simple EVPI calculation"
  )

  return(voi_stats)
}

#' Generate Enhanced CEAC Analysis
#'
#' @param psa_results PSA results
#' @param wtp_threshold Willingness-to-pay threshold
#' @param include_bootstrap Include bootstrap confidence intervals
#' @param n_bootstrap Number of bootstrap samples
#' @return Enhanced CEAC analysis
generate_enhanced_ceac <- function(psa_results, wtp_threshold = 50000,
                                  include_bootstrap = TRUE, n_bootstrap = 1000) {

  analysis <- list()

  # Basic CEAC
  analysis$ceac <- generate_ceac(psa_results, wtp_threshold)

  # Bootstrap CEAC if requested
  if (include_bootstrap) {
    analysis$ceac_bootstrap <- generate_ceac_bootstrap(psa_results, wtp_threshold,
                                                      n_bootstrap = n_bootstrap)
  }

  # NMB analysis
  analysis$nmb <- calculate_nmb(psa_results, wtp_threshold)

  # VOI analysis
  analysis$voi <- calculate_voi(psa_results, wtp_threshold)

  # Summary statistics
  analysis$summary <- list(
    wtp_threshold = wtp_threshold,
    n_simulations = length(psa_results$simulation_results),
    successful_simulations = sum(sapply(psa_results$simulation_results,
                                       function(x) is.list(x) && !("error" %in% names(x)))),
    ceac_probability = if (!is.null(analysis$ceac)) {
      analysis$ceac$probability_ce[which.min(abs(analysis$ceac$wtp - wtp_threshold))]
    } else {
      NA
    },
    analysis_timestamp = Sys.time()
  )

  return(analysis)
}
