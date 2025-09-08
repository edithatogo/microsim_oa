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
      intercept = cycle_coefficients$pji_risk$intercept$live,
      age_coeff = cycle_coefficients$pji_risk$age_coeff$live,
      bmi_coeff = cycle_coefficients$pji_risk$bmi_coeff$live,
      diabetes_coeff = cycle_coefficients$pji_risk$diabetes_coeff$live,
      smoking_coeff = cycle_coefficients$pji_risk$smoking_coeff$live,
      immunosuppression_coeff = cycle_coefficients$pji_risk$immunosuppression_coeff$live,
      surgical_complexity_coeff = cycle_coefficients$pji_risk$surgical_complexity_coeff$live,
      previous_infection_coeff = cycle_coefficients$pji_risk$previous_infection_coeff$live
    ),
    treatment_params = list(
      early_success_prob = cycle_coefficients$pji_treatment$early_success_prob$live,
      delayed_success_prob = cycle_coefficients$pji_treatment$delayed_success_prob$live,
      late_success_prob = cycle_coefficients$pji_treatment$late_success_prob$live,
      chronic_success_prob = cycle_coefficients$pji_treatment$chronic_success_prob$live,
      amputation_prob = cycle_coefficients$pji_treatment$amputation_prob$live
    ),
    cost_params = list(
      early_treatment_cost = cycle_coefficients$pji_costs$early_treatment_cost$live,
      delayed_treatment_cost = cycle_coefficients$pji_costs$delayed_treatment_cost$live,
      late_treatment_cost = cycle_coefficients$pji_costs$late_treatment_cost$live,
      chronic_treatment_cost = cycle_coefficients$pji_costs$chronic_treatment_cost$live,
      amputation_cost = cycle_coefficients$pji_costs$amputation_cost$live
    ),
    qaly_params = list(
      early_qaly_decrement = cycle_coefficients$pji_qaly$early_qaly_decrement$live,
      delayed_qaly_decrement = cycle_coefficients$pji_qaly$delayed_qaly_decrement$live,
      late_qaly_decrement = cycle_coefficients$pji_qaly$late_qaly_decrement$live,
      chronic_qaly_decrement = cycle_coefficients$pji_qaly$chronic_qaly_decrement$live,
      amputation_qaly_decrement = cycle_coefficients$pji_qaly$amputation_qaly_decrement$live
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
