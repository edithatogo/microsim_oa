#' Calculate TKA Revision Risk (Refactored)
#'
#' This function calculates the hazard of a total knee arthroplasty (TKA)
#' revision. It uses separate models for early (first year) and late (year 2+)
#' revision risk to better represent long-term implant survivorship.
#'
#' @param am_curr A data.table representing the attribute matrix for the current
#'   cycle.
#' @param rev_coeffs A list of coefficients for the revision model.
#'
#' @return The updated `am_curr` data.table with new columns for revision events.
#' @importFrom stats runif
#' @export
calculate_revision_risk_fcn <- function(am_curr, rev_coeffs) {
  # --- 1. Calculate Linear Predictor for patient-specific risk ---
  # This is common to both early and late revision risk.
  am_curr[, rev_lpv :=
    rev_coeffs$linear_predictor$age * age +
    rev_coeffs$linear_predictor$female * female +
    rev_coeffs$linear_predictor$bmi * bmi +
    rev_coeffs$linear_predictor$public * public]

  # --- 2. Calculate Hazard for Early Revision (Year 1 post-TKA) ---
  # Individuals in their first year since TKA (agetka1 == 1)
  am_curr[agetka1 == 1,
          rev_haz_early := rev_coeffs$early_hazard$intercept + rev_lpv]

  # Convert log-hazard to probability
  am_curr[agetka1 == 1,
          rev_prob_early := 1 - exp(-exp(rev_haz_early))]

  # --- 3. Calculate Hazard for Late Revision (Year 2+ post-TKA) ---
  # Individuals with 2 or more years since TKA (agetka1 >= 2)
  # Using a simple log-time model for late hazard
  am_curr[agetka1 >= 2,
          rev_haz_late := rev_coeffs$late_hazard$intercept +
            rev_coeffs$late_hazard$log_time * log(agetka1) +
            rev_lpv]

  # Convert log-hazard to probability
  am_curr[agetka1 >= 2,
          rev_prob_late := 1 - exp(-exp(rev_haz_late))]

  # --- 4. Determine Revision Events ---
  # Combine probabilities and generate random numbers
  am_curr[, rev_prob := 0]
  am_curr[agetka1 == 1, rev_prob := rev_prob_early]
  am_curr[agetka1 >= 2, rev_prob := rev_prob_late]

  rev_rand <- runif(nrow(am_curr), 0, 1)

  # Determine revision event
  am_curr[, revi := ifelse(rev_prob > rev_rand, 1, 0)]

  # --- 5. Clean up and Finalize ---
  # Ensure no revisions for the dead, or those without a TKA
  am_curr[dead == 1 | agetka1 == 0, revi := 0]

  # For now, assume only one revision is possible.
  # Prevent revision if one has already occurred (rev1 is the state of ever
  # having a revision)
  am_curr[rev1 == 1, revi := 0]

  # Update the state of ever having a revision
  am_curr[revi == 1, rev1 := 1]

  # Remove intermediate columns
  am_curr[, c(
    "rev_lpv",
    "rev_haz_early",
    "rev_prob_early",
    "rev_haz_late",
    "rev_prob_late",
    "rev_prob"
  ) := NULL]

  am_curr
}
