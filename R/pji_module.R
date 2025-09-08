#' Periprosthetic Joint Infection (PJI) Modeling Module
#'
#' This module implements advanced PJI modeling for the AUS-OA microsimulation model.
#' PJI is a serious complication following total knee arthroplasty with significant
#' clinical, economic, and quality of life impacts.
#'
#' @section Clinical Pathways:
#' PJI is modeled through multiple stages:
#' 1. Early infection (<3 months post-surgery)
#' 2. Delayed infection (3-12 months post-surgery)
#' 3. Late infection (>12 months post-surgery)
#' 4. Chronic infection (persistent/recurrent)
#'
#' @section Risk Factors:
#' - Age
#' - BMI
#' - Diabetes
#' - Smoking
#' - Immunosuppression
#' - Surgical complexity
#' - Previous infections
#'
#' @references
#' - Australian Orthopaedic Association National Joint Replacement Registry
#' - International Consensus Meeting on PJI
#' - Various clinical studies on PJI epidemiology and outcomes

#' Calculate PJI Risk Stratification
#'
#' @param am_curr Current attribute matrix
#' @param pji_coefficients PJI risk coefficients
#' @return Data.table with PJI risk scores and stratification
calculate_pji_risk <- function(am_curr, pji_coefficients) {
  # Ensure required columns exist
  required_cols <- c("age", "bmi", "diabetes", "smoking", "immunosuppression",
                     "surgical_complexity", "previous_infection", "tka1", "time_since_tka")

  for (col in required_cols) {
    if (!(col %in% names(am_curr))) {
      if (col %in% c("diabetes", "smoking", "immunosuppression", "surgical_complexity", "previous_infection")) {
        am_curr[[col]] <- 0  # Default to 0 for risk factors
      } else if (col == "time_since_tka") {
        am_curr[[col]] <- 0  # Default to 0 for non-TKA patients
      }
    }
  }

  # Calculate baseline PJI risk score
  am_curr$pji_risk_score <- 0

  # Only calculate for TKA patients
  tka_patients <- which(am_curr$tka1 == 1)

  if (length(tka_patients) > 0) {
    # Age component (increased risk with age)
    am_curr$pji_risk_score[tka_patients] <- am_curr$pji_risk_score[tka_patients] +
      pji_coefficients$age_coeff * (am_curr$age[tka_patients] - 65) / 10

    # BMI component (obesity increases risk)
    bmi_risk <- ifelse(am_curr$bmi[tka_patients] >= 35, 2,
                      ifelse(am_curr$bmi[tka_patients] >= 30, 1, 0))
    am_curr$pji_risk_score[tka_patients] <- am_curr$pji_risk_score[tka_patients] +
      pji_coefficients$bmi_coeff * bmi_risk

    # Diabetes (major risk factor)
    am_curr$pji_risk_score[tka_patients] <- am_curr$pji_risk_score[tka_patients] +
      pji_coefficients$diabetes_coeff * am_curr$diabetes[tka_patients]

    # Smoking
    am_curr$pji_risk_score[tka_patients] <- am_curr$pji_risk_score[tka_patients] +
      pji_coefficients$smoking_coeff * am_curr$smoking[tka_patients]

    # Immunosuppression
    am_curr$pji_risk_score[tka_patients] <- am_curr$pji_risk_score[tka_patients] +
      pji_coefficients$immunosuppression_coeff * am_curr$immunosuppression[tka_patients]

    # Surgical complexity
    am_curr$pji_risk_score[tka_patients] <- am_curr$pji_risk_score[tka_patients] +
      pji_coefficients$surgical_complexity_coeff * am_curr$surgical_complexity[tka_patients]

    # Previous infection history
    am_curr$pji_risk_score[tka_patients] <- am_curr$pji_risk_score[tka_patients] +
      pji_coefficients$previous_infection_coeff * am_curr$previous_infection[tka_patients]

    # Time-dependent risk (early post-op period has higher risk)
    time_risk <- ifelse(am_curr$time_since_tka[tka_patients] <= 3, 2,  # Early: 3 months
                       ifelse(am_curr$time_since_tka[tka_patients] <= 12, 1,  # Delayed: 3-12 months
                             0.5))  # Late: >12 months
    am_curr$pji_risk_score[tka_patients] <- am_curr$pji_risk_score[tka_patients] * time_risk
  }

  # Convert risk score to probability using logistic function
  am_curr$pji_risk_prob <- 1 / (1 + exp(-pji_coefficients$intercept - am_curr$pji_risk_score))

  # Risk stratification
  am_curr$pji_risk_category <- cut(am_curr$pji_risk_prob,
                                  breaks = c(0, 0.01, 0.03, 0.1, 1),
                                  labels = c("Low", "Moderate", "High", "Very High"),
                                  include.lowest = TRUE)

  return(am_curr)
}

#' Simulate PJI Events
#'
#' @param am_curr Current attribute matrix with PJI risk probabilities
#' @return Updated attribute matrix with PJI events
simulate_pji_events <- function(am_curr) {
  # Generate random numbers for PJI incidence
  pji_rand <- stats::runif(nrow(am_curr), 0, 1)

  # Determine PJI events
  am_curr$pji_incident <- ifelse(am_curr$pji_risk_prob > pji_rand &
                                am_curr$tka1 == 1 &
                                is.na(am_curr$pji_status), 1, 0)

  # Initialize PJI status if not exists
  if (!("pji_status" %in% names(am_curr))) {
    am_curr$pji_status <- NA_character_
  }

  # Update PJI status for new cases
  new_pji_cases <- which(am_curr$pji_incident == 1)
  if (length(new_pji_cases) > 0) {
    # Classify by timing
    time_since_tka <- am_curr$time_since_tka[new_pji_cases]
    am_curr$pji_status[new_pji_cases] <- ifelse(time_since_tka <= 3, "early",
                                               ifelse(time_since_tka <= 12, "delayed", "late"))
  }

  return(am_curr)
}

#' Model PJI Treatment Pathways
#'
#' @param am_curr Current attribute matrix
#' @param pji_treatment_params Treatment parameters
#' @return Updated attribute matrix with treatment outcomes
model_pji_treatment <- function(am_curr, pji_treatment_params) {
  # Identify active PJI cases
  active_pji <- which(!is.na(am_curr$pji_status) & am_curr$pji_status != "resolved")

  if (length(active_pji) > 0) {
    # Treatment success probabilities by infection type and stage
    for (i in active_pji) {
      infection_type <- am_curr$pji_status[i]

      # Base treatment success probability
      success_prob <- switch(infection_type,
                           "early" = pji_treatment_params$early_success_prob,
                           "delayed" = pji_treatment_params$delayed_success_prob,
                           "late" = pji_treatment_params$late_success_prob,
                           "chronic" = pji_treatment_params$chronic_success_prob,
                           0.5)  # Default

      # Adjust for risk factors
      if (am_curr$diabetes[i] == 1) success_prob <- success_prob * 0.8
      if (am_curr$immunosuppression[i] == 1) success_prob <- success_prob * 0.7
      if (am_curr$smoking[i] == 1) success_prob <- success_prob * 0.9

      # Determine treatment outcome
      treatment_rand <- stats::runif(1, 0, 1)
      if (treatment_rand < success_prob) {
        # Successful treatment
        am_curr$pji_status[i] <- "resolved"
        am_curr$pji_resolution_time[i] <- am_curr$time_since_tka[i]
      } else {
        # Treatment failure - may progress to chronic or require further intervention
        if (infection_type == "chronic") {
          # Chronic cases may require amputation in severe cases
          amputation_rand <- stats::runif(1, 0, 1)
          if (amputation_rand < pji_treatment_params$amputation_prob) {
            am_curr$pji_status[i] <- "amputation"
          }
        } else {
          # Progress to chronic infection
          am_curr$pji_status[i] <- "chronic"
        }
      }
    }
  }

  return(am_curr)
}

#' Calculate PJI Costs and QALY Impacts
#'
#' @param am_curr Current attribute matrix
#' @param pji_cost_params Cost parameters
#' @param pji_qaly_params QALY parameters
#' @return List with cost and QALY impacts
calculate_pji_impacts <- function(am_curr, pji_cost_params, pji_qaly_params) {
  # Initialize impact columns
  am_curr$pji_cost <- 0
  am_curr$pji_qaly_decrement <- 0

  # Calculate impacts for active PJI cases
  active_pji <- which(!is.na(am_curr$pji_status) & am_curr$pji_status != "resolved")

  if (length(active_pji) > 0) {
    for (i in active_pji) {
      infection_type <- am_curr$pji_status[i]

      # Cost calculation
      base_cost <- switch(infection_type,
                        "early" = pji_cost_params$early_treatment_cost,
                        "delayed" = pji_cost_params$delayed_treatment_cost,
                        "late" = pji_cost_params$late_treatment_cost,
                        "chronic" = pji_cost_params$chronic_treatment_cost,
                        "amputation" = pji_cost_params$amputation_cost,
                        0)

      am_curr$pji_cost[i] <- base_cost

      # QALY decrement
      base_qaly_decrement <- switch(infection_type,
                                  "early" = pji_qaly_params$early_qaly_decrement,
                                  "delayed" = pji_qaly_params$delayed_qaly_decrement,
                                  "late" = pji_qaly_params$late_qaly_decrement,
                                  "chronic" = pji_qaly_params$chronic_qaly_decrement,
                                  "amputation" = pji_qaly_params$amputation_qaly_decrement,
                                  0)

      am_curr$pji_qaly_decrement[i] <- base_qaly_decrement
    }
  }

  # Calculate total impacts
  total_cost <- sum(am_curr$pji_cost, na.rm = TRUE)
  total_qaly_impact <- sum(am_curr$pji_qaly_decrement, na.rm = TRUE)
  incident_cases <- sum(am_curr$pji_incident, na.rm = TRUE)

  impacts <- list(
    total_cost = total_cost,
    total_qaly_impact = total_qaly_impact,
    incident_cases = incident_cases,
    am_curr = am_curr
  )

  return(impacts)
}

#' Main PJI Module Function
#'
#' @param am_curr Current attribute matrix
#' @param am_new Next cycle attribute matrix
#' @param pji_params Complete PJI parameter set
#' @return Updated attribute matrices with PJI modeling
pji_module <- function(am_curr, am_new, pji_params) {
  # Step 1: Calculate PJI risk
  am_curr <- calculate_pji_risk(am_curr, pji_params$risk_coefficients)

  # Step 2: Simulate PJI events
  am_curr <- simulate_pji_events(am_curr)

  # Step 3: Model treatment pathways
  am_curr <- model_pji_treatment(am_curr, pji_params$treatment_params)

  # Step 4: Calculate costs and QALY impacts
  impacts <- calculate_pji_impacts(am_curr, pji_params$cost_params, pji_params$qaly_params)

  # Update next cycle matrix
  am_new$pji_status <- am_curr$pji_status
  am_new$pji_resolution_time <- am_curr$pji_resolution_time

  # Return results
  result <- list(
    am_curr = impacts$am_curr,
    am_new = am_new,
    impacts = impacts[c("total_cost", "total_qaly_impact", "incident_cases")]
  )

  return(result)
}
