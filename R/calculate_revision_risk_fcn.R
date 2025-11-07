#' @importFrom dplyr mutate case_when
calculate_revision_risk_fcn <- function(am_curr, rev_coeffs) {
  # Ensure am_curr is a data.frame for dplyr
  am_curr <- as.data.frame(am_curr)

  # --- 1. Calculate Linear Predictor ---
  am_curr <- am_curr %>%
    mutate(
      rev_lpv =
        rev_coeffs$linear_predictor$age * age +
          rev_coeffs$linear_predictor$female * female +
          rev_coeffs$linear_predictor$bmi * bmi +
          rev_coeffs$linear_predictor$public * public
    )

  # --- 2. Calculate Hazard and Probability ---
  am_curr <- am_curr %>%
    mutate(
      rev_prob = case_when(
        # Early revision
        agetka1 == 1 ~ {
          rev_haz_early <- rev_coeffs$early_hazard$intercept + rev_lpv
          1 - exp(-exp(rev_haz_early))
        },
        # Late revision
        agetka1 >= 2 ~ {
          rev_haz_late <- rev_coeffs$late_hazard$intercept +
            rev_coeffs$late_hazard$log_time * log(agetka1) +
            rev_lpv
          1 - exp(-exp(rev_haz_late))
        },
        # No revision risk
        TRUE ~ 0
      )
    )

  # --- 3. Determine Revision Events ---
  rev_rand <- runif(nrow(am_curr), 0, 1)
  am_curr <- am_curr %>%
    mutate(
      revi = ifelse(rev_prob > rev_rand, 1, 0)
    )

  # --- 4. Clean up and Finalize ---
  am_curr <- am_curr %>%
    mutate(
      # No revisions for the dead or those without a TKA
      revi = ifelse(dead == 1 | agetka1 == 0, 0, revi),
      # No revision if one has already occurred
      revi = ifelse(rev1 == 1, 0, revi),
      # Update ever-revised status
      rev1 = ifelse(revi == 1, 1, rev1)
    ) %>%
    # Remove intermediate columns
    select(-rev_lpv, -rev_prob)

  return(as.data.table(am_curr))
}
