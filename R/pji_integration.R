#' Integrate PJI Module with Main Simulation
#'
#' This function replaces the basic complication modeling with advanced PJI modeling
#' and integrates it into the main simulation cycle.
#'
#' @param am_curr Current attribute matrix
#' @param am_new Next cycle attribute matrix
#' @param cycle_coefficients All model coefficients including PJI parameters
#' @return Updated attribute matrices with PJI modeling
integrate_pji_module <- function(am_curr, am_new, cycle_coefficients) {
  # Extract PJI parameters from coefficients
  pji_params <- list(
    risk_coefficients = list(
      intercept = cycle_coefficients$pji_risk$intercept,
      age_coeff = cycle_coefficients$pji_risk$age_coeff,
      bmi_coeff = cycle_coefficients$pji_risk$bmi_coeff,
      diabetes_coeff = cycle_coefficients$pji_risk$diabetes_coeff,
      smoking_coeff = cycle_coefficients$pji_risk$smoking_coeff,
      immunosuppression_coeff = cycle_coefficients$pji_risk$immunosuppression_coeff,
      surgical_complexity_coeff = cycle_coefficients$pji_risk$surgical_complexity_coeff,
      previous_infection_coeff = cycle_coefficients$pji_risk$previous_infection_coeff
    ),
    treatment_params = list(
      early_success_prob = cycle_coefficients$pji_treatment$early_success_prob,
      delayed_success_prob = cycle_coefficients$pji_treatment$delayed_success_prob,
      late_success_prob = cycle_coefficients$pji_treatment$late_success_prob,
      chronic_success_prob = cycle_coefficients$pji_treatment$chronic_success_prob,
      amputation_prob = cycle_coefficients$pji_treatment$amputation_prob
    ),
    cost_params = list(
      early_treatment_cost = cycle_coefficients$pji_costs$early_treatment_cost,
      delayed_treatment_cost = cycle_coefficients$pji_costs$delayed_treatment_cost,
      late_treatment_cost = cycle_coefficients$pji_costs$late_treatment_cost,
      chronic_treatment_cost = cycle_coefficients$pji_costs$chronic_treatment_cost,
      amputation_cost = cycle_coefficients$pji_costs$amputation_cost
    ),
    qaly_params = list(
      early_qaly_decrement = cycle_coefficients$pji_qaly$early_qaly_decrement,
      delayed_qaly_decrement = cycle_coefficients$pji_qaly$delayed_qaly_decrement,
      late_qaly_decrement = cycle_coefficients$pji_qaly$late_qaly_decrement,
      chronic_qaly_decrement = cycle_coefficients$pji_qaly$chronic_qaly_decrement,
      amputation_qaly_decrement = cycle_coefficients$pji_qaly$amputation_qaly_decrement
    )
  )

  # Run PJI module
  pji_result <- pji_module(am_curr, am_new, pji_params)

  # Update matrices
  am_curr <- pji_result$am_curr
  am_new <- pji_result$am_new

  # Update the generic 'comp' variable for backward compatibility
  # PJI cases should set comp = 1
  am_new$comp <- ifelse(!is.na(am_curr$pji_status) &
                       am_curr$pji_status %in% c("early", "delayed", "late", "chronic"), 1, 0)

  # Add PJI impacts to SF6D
  am_curr$d_sf6d <- am_curr$d_sf6d + am_curr$pji_qaly_decrement

  # Return updated matrices and PJI summary
  result <- list(
    am_curr = am_curr,
    am_new = am_new,
    pji_summary = pji_result$impacts
  )

  return(result)
}
