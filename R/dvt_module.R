#' Deep Vein Thrombosis (DVT) Modeling Module
#'
#' This module implements advanced DVT modeling for the AUS-OA microsimulation model.
#' DVT is a major complication following total knee arthroplasty with potential progression
#' to pulmonary embolism (PE). The module includes:
#'
#' - Risk stratification based on clinical factors
#' - Prophylaxis strategy modeling (mechanical vs pharmacological)
#' - DVT occurrence and progression to PE
#' - Treatment pathways and outcomes
#' - Cost and QALY impact assessment
#'
#' Key Clinical References:
#' - NICE guidelines for venous thromboembolism prevention
#' - ACCP guidelines for antithrombotic therapy
#' - Australian Orthopaedic Association guidelines
#' - Meta-analyses of DVT prophylaxis effectiveness

#' Calculate DVT Risk Stratification
#'
#' @param am_curr Current attribute matrix
#' @param dvt_coefficients DVT risk coefficients from configuration
#' @return Data.table with DVT risk scores and stratification
calculate_dvt_risk <- function(am_curr, dvt_coefficients) {
  # Initialize DVT risk score
  am_curr$dvt_risk_score <- 0

  # Identify patients who have undergone TKA (DVT risk applies post-TKA)
  tka_patients <- which(am_curr$tka == 1)

  if (length(tka_patients) > 0) {
    # Base risk factors (applied to all TKA patients)
    am_curr$dvt_risk_score[tka_patients] <- dvt_coefficients$intercept$live

    # Age risk (continuous)
    age_risk <- (am_curr$age[tka_patients] - 60) / 10 * dvt_coefficients$age_coeff$live
    am_curr$dvt_risk_score[tka_patients] <- am_curr$dvt_risk_score[tka_patients] + age_risk

    # BMI risk (categorical)
    bmi_risk <- ifelse(am_curr$bmi[tka_patients] >= 40, dvt_coefficients$bmi40_coeff$live,
              ifelse(am_curr$bmi[tka_patients] >= 35, dvt_coefficients$bmi35_coeff$live,
              ifelse(am_curr$bmi[tka_patients] >= 30, dvt_coefficients$bmi30_coeff$live, 0)))
    am_curr$dvt_risk_score[tka_patients] <- am_curr$dvt_risk_score[tka_patients] + bmi_risk

    # Sex risk
    male_risk <- am_curr$male[tka_patients] * dvt_coefficients$male_coeff$live
    am_curr$dvt_risk_score[tka_patients] <- am_curr$dvt_risk_score[tka_patients] + male_risk

    # Comorbidities
    am_curr$dvt_risk_score[tka_patients] <- am_curr$dvt_risk_score[tka_patients] +
      am_curr$ccount[tka_patients] * dvt_coefficients$comorbidity_coeff$live

    # Previous VTE history
    if ("prev_vte" %in% names(am_curr)) {
      prev_vte_risk <- am_curr$prev_vte[tka_patients] * dvt_coefficients$prev_vte_coeff$live
      am_curr$dvt_risk_score[tka_patients] <- am_curr$dvt_risk_score[tka_patients] + prev_vte_risk
    }

    # Cancer history
    if ("cancer" %in% names(am_curr)) {
      cancer_risk <- am_curr$cancer[tka_patients] * dvt_coefficients$cancer_coeff$live
      am_curr$dvt_risk_score[tka_patients] <- am_curr$dvt_risk_score[tka_patients] + cancer_risk
    }

    # Convert to probability using logistic function
    am_curr$dvt_risk_prob <- 0
    am_curr$dvt_risk_prob[tka_patients] <- exp(am_curr$dvt_risk_score[tka_patients]) /
      (1 + exp(am_curr$dvt_risk_score[tka_patients]))

    # Apply prophylaxis effectiveness modifier
    if ("dvt_prophylaxis" %in% names(am_curr)) {
      prophylaxis_effect <- ifelse(am_curr$dvt_prophylaxis[tka_patients] == "none", 1.0,
                          ifelse(am_curr$dvt_prophylaxis[tka_patients] == "mechanical", dvt_coefficients$mechanical_rr$live,
                          ifelse(am_curr$dvt_prophylaxis[tka_patients] == "pharmacological", dvt_coefficients$pharma_rr$live,
                          ifelse(am_curr$dvt_prophylaxis[tka_patients] == "combined", dvt_coefficients$combined_rr$live, 1.0))))
      am_curr$dvt_risk_prob[tka_patients] <- am_curr$dvt_risk_prob[tka_patients] * prophylaxis_effect
    }
  }

  return(am_curr)
}

#' Simulate DVT Events and Progression
#'
#' @param am_curr Current attribute matrix with DVT risk probabilities
#' @param dvt_coefficients DVT coefficients including progression rates
#' @return Updated attribute matrix with DVT events and progression
simulate_dvt_events <- function(am_curr, dvt_coefficients) {
  # Initialize DVT status if not present
  if (!"dvt_status" %in% names(am_curr)) {
    am_curr$dvt_status <- "none"
  }
  if (!"pe_status" %in% names(am_curr)) {
    am_curr$pe_status <- "none"
  }

  # Only consider TKA patients for DVT events
  tka_patients <- which(am_curr$tka == 1 & am_curr$dvt_status == "none")

  if (length(tka_patients) > 0) {
    # Generate random numbers for DVT occurrence
    dvt_rand <- runif(length(tka_patients))

    # Determine DVT occurrence
    dvt_occurs <- dvt_rand < am_curr$dvt_risk_prob[tka_patients]
    dvt_indices <- tka_patients[dvt_occurs]

    if (length(dvt_indices) > 0) {
      # Set DVT status
      am_curr$dvt_status[dvt_indices] <- "acute"

      # Determine progression to PE (symptomatic DVT may progress to PE)
      pe_rand <- runif(length(dvt_indices))
      pe_occurs <- pe_rand < dvt_coefficients$pe_progression_prob$live
      pe_indices <- dvt_indices[pe_occurs]

      if (length(pe_indices) > 0) {
        am_curr$pe_status[pe_indices] <- "acute"
        am_curr$dvt_status[pe_indices] <- "with_pe"
      }
    }
  }

  return(am_curr)
}

#' Model DVT Treatment and Outcomes
#'
#' @param am_curr Current attribute matrix with DVT events
#' @param dvt_coefficients DVT treatment coefficients
#' @return Updated attribute matrix with treatment outcomes
model_dvt_treatment <- function(am_curr, dvt_coefficients) {
  # Identify patients with acute DVT
  dvt_patients <- which(am_curr$dvt_status == "acute")
  pe_patients <- which(am_curr$pe_status == "acute")

  if (length(dvt_patients) > 0) {
    # DVT Treatment outcomes
    dvt_rand <- runif(length(dvt_patients))

    # Treatment success (resolution without complications)
    success_prob <- dvt_coefficients$dvt_treatment_success$live
    success <- dvt_rand < success_prob

    # Update status
    am_curr$dvt_status[dvt_patients[success]] <- "resolved"
    am_curr$dvt_status[dvt_patients[!success]] <- "chronic"
  }

  if (length(pe_patients) > 0) {
    # PE Treatment outcomes (more serious)
    pe_rand <- runif(length(pe_patients))

    # PE treatment success
    success_prob <- dvt_coefficients$pe_treatment_success$live
    success <- pe_rand < success_prob

    # PE can be fatal
    mortality_prob <- dvt_coefficients$pe_mortality_prob$live
    fatal <- runif(length(pe_patients)) < mortality_prob

    # Update status
    resolved_indices <- pe_patients[success & !fatal]
    chronic_indices <- pe_patients[!success & !fatal]
    fatal_indices <- pe_patients[fatal]

    am_curr$pe_status[resolved_indices] <- "resolved"
    am_curr$pe_status[chronic_indices] <- "chronic"
    am_curr$pe_status[fatal_indices] <- "fatal"
    am_curr$dead[fatal_indices] <- 1  # Mark as dead
  }

  return(am_curr)
}

#' Calculate DVT Costs and QALY Impacts
#'
#' @param am_curr Current attribute matrix with DVT status
#' @param dvt_coefficients DVT cost and QALY coefficients
#' @return Updated attribute matrix with DVT impacts
calculate_dvt_impacts <- function(am_curr, dvt_coefficients) {
  # Initialize impact columns if not present
  if (!"dvt_cost" %in% names(am_curr)) am_curr$dvt_cost <- 0
  if (!"dvt_qaly_decrement" %in% names(am_curr)) am_curr$dvt_qaly_decrement <- 0

  # Calculate costs and QALY decrements based on DVT status
  dvt_patients <- which(am_curr$dvt_status != "none")

  if (length(dvt_patients) > 0) {
    for (i in dvt_patients) {
      status <- am_curr$dvt_status[i]
      pe_status <- am_curr$pe_status[i]

      # Cost calculation
      if (status == "acute") {
        am_curr$dvt_cost[i] <- dvt_coefficients$dvt_acute_cost$live
      } else if (status == "chronic") {
        am_curr$dvt_cost[i] <- dvt_coefficients$dvt_chronic_cost$live
      } else if (status == "with_pe") {
        am_curr$dvt_cost[i] <- dvt_coefficients$dvt_acute_cost$live + dvt_coefficients$pe_acute_cost$live
      }

      # QALY decrement
      if (status == "acute") {
        am_curr$dvt_qaly_decrement[i] <- dvt_coefficients$dvt_acute_qaly$live
      } else if (status == "chronic") {
        am_curr$dvt_qaly_decrement[i] <- dvt_coefficients$dvt_chronic_qaly$live
      }

      # Additional PE impacts
      if (pe_status == "acute") {
        am_curr$dvt_cost[i] <- am_curr$dvt_cost[i] + dvt_coefficients$pe_acute_cost$live
        am_curr$dvt_qaly_decrement[i] <- am_curr$dvt_qaly_decrement[i] + dvt_coefficients$pe_acute_qaly$live
      } else if (pe_status == "chronic") {
        am_curr$dvt_cost[i] <- am_curr$dvt_cost[i] + dvt_coefficients$pe_chronic_cost$live
        am_curr$dvt_qaly_decrement[i] <- am_curr$dvt_qaly_decrement[i] + dvt_coefficients$pe_chronic_qaly$live
      }
    }
  }

  return(am_curr)
}

#' Main DVT Module Function
#'
#' @param am_curr Current attribute matrix
#' @param am_new Next cycle attribute matrix
#' @param dvt_params DVT parameters from configuration
#' @return List containing updated matrices and DVT summary
dvt_module <- function(am_curr, am_new, dvt_params) {
  # Extract coefficients
  risk_coeffs <- dvt_params$risk_coefficients
  treatment_params <- dvt_params$treatment_params
  cost_params <- dvt_params$cost_params
  qaly_params <- dvt_params$qaly_params

  # Step 1: Calculate DVT risk
  am_curr <- calculate_dvt_risk(am_curr, risk_coeffs)

  # Step 2: Simulate DVT events
  am_curr <- simulate_dvt_events(am_curr, risk_coeffs)

  # Step 3: Model treatment outcomes
  am_curr <- model_dvt_treatment(am_curr, treatment_params)

  # Step 4: Calculate costs and QALY impacts
  am_curr <- calculate_dvt_impacts(am_curr, cost_params)

  # Create DVT summary
  dvt_summary <- list(
    total_dvt_cases = sum(am_curr$dvt_status != "none"),
    acute_dvt_cases = sum(am_curr$dvt_status == "acute"),
    chronic_dvt_cases = sum(am_curr$dvt_status == "chronic"),
    dvt_with_pe_cases = sum(am_curr$dvt_status == "with_pe"),
    pe_cases = sum(am_curr$pe_status != "none"),
    pe_fatal_cases = sum(am_curr$pe_status == "fatal"),
    total_dvt_cost = sum(am_curr$dvt_cost),
    total_dvt_qaly_loss = sum(am_curr$dvt_qaly_decrement),
    prophylaxis_distribution = if ("dvt_prophylaxis" %in% names(am_curr))
      table(am_curr$dvt_prophylaxis) else NULL
  )

  # Update am_new with DVT status (for tracking across cycles)
  am_new$dvt_status <- am_curr$dvt_status
  am_new$pe_status <- am_curr$pe_status
  am_new$dvt_cost <- am_curr$dvt_cost
  am_new$dvt_qaly_decrement <- am_curr$dvt_qaly_decrement

  result <- list(
    am_curr = am_curr,
    am_new = am_new,
    impacts = dvt_summary
  )

  return(result)
}
