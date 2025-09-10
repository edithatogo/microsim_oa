#' Integrate Waiting List Module with Main Simulation
#'
#' This function integrates the waiting list dynamics module with the main simulation cycle.
#' It models patient prioritization, queue management, capacity constraints, and wait time impacts.
#'
#' @param am_curr Current attribute matrix
#' @param am_new Next cycle attribute matrix
#' @param cycle_coefficients All model coefficients including waiting list parameters
#' @return Updated attribute matrices with waiting list modeling
integrate_waiting_list_module <- function(am_curr, am_new, cycle_coefficients) {
  # Extract waiting list parameters from coefficients
  waiting_list_params <- list(
    prioritization_scheme = cycle_coefficients$waiting_list$prioritization_scheme,
    capacity = list(
      total_capacity = cycle_coefficients$waiting_list$capacity$total_capacity,
      public_proportion = cycle_coefficients$waiting_list$capacity$public_proportion
    ),
    wait_time_impacts = list(
      qaly_loss_per_month = cycle_coefficients$waiting_list$wait_time_impacts$qaly_loss_per_month,
      additional_cost_per_month = cycle_coefficients$waiting_list$wait_time_impacts$additional_cost_per_month,
      oa_progression_prob_per_month = cycle_coefficients$waiting_list$wait_time_impacts$oa_progression_prob_per_month
    ),
    pathways = list(
      private_base_prob = cycle_coefficients$waiting_list$pathways$private_base_prob,
      socioeconomic_weight = cycle_coefficients$waiting_list$pathways$socioeconomic_weight,
      urgency_weight = cycle_coefficients$waiting_list$pathways$urgency_weight,
      private_cost_multiplier = cycle_coefficients$waiting_list$pathways$private_cost_multiplier
    )
  )

  # Run waiting list module
  waiting_list_result <- waiting_list_module(am_curr, am_new, waiting_list_params)

  # Extract updated matrices and waiting list summary
  am_curr <- waiting_list_result$am_curr
  am_new <- waiting_list_result$am_new
  waiting_list_summary <- waiting_list_result$waiting_list_summary

  # Update TKA scheduling based on waiting list outcomes
  # Patients scheduled for TKA will receive it in the next cycle
  am_new$tka <- am_curr$tka + am_curr$scheduled_tka

  # Apply pathway cost multipliers to TKA costs
  if ("tka_cost" %in% names(am_curr)) {
    am_curr$tka_cost <- am_curr$tka_cost * am_curr$pathway_cost_multiplier
  }

  # Track cumulative wait time impacts
  if (!"cumulative_wait_qaly_loss" %in% names(am_new)) {
    am_new$cumulative_wait_qaly_loss <- 0
  }
  if ("cumulative_wait_qaly_loss" %in% names(am_curr)) {
    am_new$cumulative_wait_qaly_loss <- am_curr$cumulative_wait_qaly_loss + am_curr$wait_time_qaly_loss
  } else {
    am_new$cumulative_wait_qaly_loss <- am_curr$wait_time_qaly_loss
  }

  # Return updated matrices and waiting list summary
  result <- list(
    am_curr = am_curr,
    am_new = am_new,
    waiting_list_summary = waiting_list_summary
  )

  return(result)
}
