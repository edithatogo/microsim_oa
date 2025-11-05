#' Integrate DVT Module with Main Simulation
#'
#' This function replaces basic DVT modeling with advanced DVT module
#' and integrates it into the main simulation cycle.
#'
#' @param am_curr Current attribute matrix
#' @param am_new Next cycle attribute matrix
#' @param cycle_coefficients All model coefficients including DVT parameters
#' @return Updated attribute matrices with DVT modeling
integrate_dvt_module <- function(am_curr, am_new, cycle_coefficients) {
  # Extract DVT parameters from coefficients
  dvt_params <- list(
    risk_coefficients = list(
      intercept = cycle_coefficients$dvt_risk$intercept$live,
      age_coeff = cycle_coefficients$dvt_risk$age_coeff$live,
      bmi30_coeff = cycle_coefficients$dvt_risk$bmi30_coeff$live,
      bmi35_coeff = cycle_coefficients$dvt_risk$bmi35_coeff$live,
      bmi40_coeff = cycle_coefficients$dvt_risk$bmi40_coeff$live,
      male_coeff = cycle_coefficients$dvt_risk$male_coeff$live,
      comorbidity_coeff = cycle_coefficients$dvt_risk$comorbidity_coeff$live,
      prev_vte_coeff = cycle_coefficients$dvt_risk$prev_vte_coeff$live,
      cancer_coeff = cycle_coefficients$dvt_risk$cancer_coeff$live,
      mechanical_rr = cycle_coefficients$dvt_risk$mechanical_rr$live,
      pharma_rr = cycle_coefficients$dvt_risk$pharma_rr$live,
      combined_rr = cycle_coefficients$dvt_risk$combined_rr$live,
      pe_progression_prob = cycle_coefficients$dvt_risk$pe_progression_prob$live
    ),
    treatment_params = list(
      dvt_treatment_success = cycle_coefficients$dvt_treatment$dvt_treatment_success$live,
      pe_treatment_success = cycle_coefficients$dvt_treatment$pe_treatment_success$live,
      pe_mortality_prob = cycle_coefficients$dvt_treatment$pe_mortality_prob$live
    ),
    cost_params = list(
      dvt_acute_cost = cycle_coefficients$dvt_costs$dvt_acute_cost$live,
      dvt_chronic_cost = cycle_coefficients$dvt_costs$dvt_chronic_cost$live,
      pe_acute_cost = cycle_coefficients$dvt_costs$pe_acute_cost$live,
      pe_chronic_cost = cycle_coefficients$dvt_costs$pe_chronic_cost$live
    ),
    qaly_params = list(
      dvt_acute_qaly = cycle_coefficients$dvt_qaly$dvt_acute_qaly$live,
      dvt_chronic_qaly = cycle_coefficients$dvt_qaly$dvt_chronic_qaly$live,
      pe_acute_qaly = cycle_coefficients$dvt_qaly$pe_acute_qaly$live,
      pe_chronic_qaly = cycle_coefficients$dvt_qaly$pe_chronic_qaly$live
    )
  )

  # Run DVT module
  dvt_result <- dvt_module(am_curr, am_new, dvt_params)

  # Extract updated matrices and DVT summary
  am_curr <- dvt_result$am_curr
  am_new <- dvt_result$am_new
  dvt_summary <- dvt_result$impacts

  # Update SF6D with DVT QALY impacts
  am_curr$d_sf6d <- am_curr$d_sf6d + am_curr$dvt_qaly_decrement

  # Return updated matrices and DVT summary
  result <- list(
    am_curr = am_curr,
    am_new = am_new,
    dvt_summary = dvt_summary
  )

  return(result)
}
