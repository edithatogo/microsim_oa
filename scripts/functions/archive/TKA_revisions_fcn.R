# Risk of TKA revision
## This function calculates the risk of TKA revision for the AUS-OA model.

TKA_revisions <- function(am_all, cycle.coefficents) {
  ## There are two parts to the revision model...
  ## Linear predictor
  f_linear_pred <-
    function(DF) {
      DF %>%
        # Linear prediction model
        mutate(
          rev_lpv =
            age * cr_age +
              max(age - 53, 0)^3 * cr_age53 +
              max(age - 63, 0)^3 * cr_age63 +
              max(age - 69, 0)^3 * cr_age69 +
              max(age - 74, 0)^3 * cr_age74 +
              max(age - 83, 0)^3 * cr_age83 +
              female * cr_female +
              ASA2 * cr_asa2 +
              ASA3 * cr_asa3 +
              ASA4_5 * cr_asa4_5 +
              bmi * cr_bmi +
              max(bmi - 23.3, 0)^3 * cr_bmi23 +
              max(bmi - 27.9, 0)^3 * cr_bmi27 +
              max(bmi - 31.1, 0)^3 * cr_bmi31 +
              max(bmi - 34.9, 0)^3 * cr_bmi34 +
              max(bmi - 43.3, 0)^3 * cr_bmi43 +
              public * cr_public
        )
    }

  ## Spline function
  f_spline <-
    function(DF, time) {
      DF %>%
        mutate(
          time = {{ time }},
          # Intercept
          intercept = 1,
          v0 = log(time),
          v1 =
            max(v0 - cr_k_1, 0)^3
              - cr_lambda_1 * max(v0 - cr_k_min, 0)^3
              - (1 - cr_lambda_1) * max(v0 - cr_k_max, 0)^3,
          v2 =
            max(v0 - cr_k_2, 0)^3
              - cr_lambda_2 * max(v0 - cr_k_min, 0)^3
              - (1 - cr_lambda_2) * max(v0 - cr_k_max, 0)^3,
          v3 =
            max(v0 - cr_k_3, 0)^3
              - cr_lambda_3 * max(v0 - cr_k_min, 0)^3
              - (1 - cr_lambda_3) * max(v0 - cr_k_max, 0)^3,
          v4 =
            max(v0 - cr_k_4, 0)^3
              - cr_lambda_4 * max(v0 - cr_k_min, 0)^3
              - (1 - cr_lambda_4) * max(v0 - cr_k_max, 0)^3,
          v5 =
            max(v0 - cr_k_5, 0)^3
              - cr_lambda_5 * max(v0 - cr_k_min, 0)^3
              - (1 - cr_lambda_5) * max(v0 - cr_k_max, 0)^3,
          v6 =
            max(v0 - cr_k_6, 0)^3
              - cr_lambda_6 * max(v0 - cr_k_min, 0)^3
              - (1 - cr_lambda_6) * max(v0 - cr_k_max, 0)^3,
          v7 =
            max(v0 - cr_k_7, 0)^3
              - cr_lambda_7 * max(v0 - cr_k_min, 0)^3
              - (1 - cr_lambda_7) * max(v0 - cr_k_max, 0)^3,
          blcv =
            cr_gamma_0 + cr_gamma_1 * v0 +
              cr_gamma_2 * v1 + cr_gamma_3 * v2 +
              cr_gamma_4 * v3 + cr_gamma_5 * v4 +
              cr_gamma_6 * v5 + cr_gamma_7 * v6 +
              cr_gamma_8 * v7,
        ) %>%
        select(-starts_with("v"))
    }

  # Let's do it
  ## Attach model coefficients to the attribute matrix
  Z <-
    cbind(am_all, cycle.coefficents %>% select(starts_with("cr"))) %>%
    # Need some extra variables
    ## Add ASA variable needed for the model
    mutate(ASA2 = 1, ASA3 = 0, ASA4_5 = 0) %>%
    ## Identifier for public hospital
    mutate(public = ifelse(phi == 1, 0, 1)) %>%
    # Cumulative hazard for revision
    f_linear_pred() %>%
    # TKA 1 spline
    f_spline(., agetka1) %>%
    mutate(blcv1 = blcv) %>%
    # TKA 2 spline
    f_spline(., agetka2) %>%
    mutate(blcv2 = blcv) %>%
    # Hazard ratios
    mutate(
      # Log cumulative hazard
      log_cum_haz1 = rev_lpv + blcv1,
      log_cum_haz2 = rev_lpv + blcv2,
      # Cumulative hazard
      revision_haz_1 = exp(log_cum_haz1),
      revision_haz_2 = exp(log_cum_haz2)
    ) %>%
    group_by(id) %>%
    arrange(id, year) %>%
    # Hazard for each year
    mutate(
      across(
        c(revision_haz_1, revision_haz_2),
        ~ . - lag(.)
      ),
      across(
        c(revision_haz_1, revision_haz_2),
        ~ ifelse(is.na(.) | . < 0, 0, .)
      )
    ) %>%
    # Generate a random number per individual per year
    group_by(year) %>%
    arrange(year, id) %>%
    mutate(
      r1 = runif(n(), min = 0, max = 1),
      r2 = runif(n(), min = 0, max = 1)
    ) %>%
    # When risk is greater than random number, revision occurs
    mutate(
      revision_1 = ifelse(revision_haz_1 > r1, 1, 0),
      revision_2 = ifelse(revision_haz_2 > r2, 1, 0)
    )

  am_all <- Z
  return(am_all)
}
