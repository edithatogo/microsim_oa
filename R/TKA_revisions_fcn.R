#' Calculate TKA Revision Risk (Batch Processing Version)
#'
#' This function calculates the risk of TKA revision for all individuals across
#' all cycles in the simulation output. It is a batch-processing alternative
#' to the per-cycle `revisions_fcn`. The model uses a linear predictor for
#' individual risk and a spline function for the baseline hazard over time.
#'
#' @param am_all A data.frame representing the full simulation output, containing
#'   data for all individuals over all cycles.
#' @param cycle.coefficents A data.frame or list containing the model
#'   coefficients for the revision model (names starting with "cr_").
#'
#' @return The input `am_all` data.frame with added columns for revision hazards
#'   and binary indicators for revision events.
#' @importFrom dplyr mutate select group_by arrange across n lag
#' @importFrom magrittr %>%
#' @importFrom rlang .data
#' @importFrom stats runif
#' @export
TKA_revisions <- function(am_all, cycle.coefficents) {
  
  # Declare variables to avoid R CMD check notes
  age <- cr_age <- cr_age53 <- cr_age63 <- cr_age69 <- cr_age74 <- cr_age83 <- NULL
  female <- cr_female <- ASA2 <- cr_asa2 <- ASA3 <- cr_asa3 <- ASA4_5 <- cr_asa4_5 <- NULL
  bmi <- cr_bmi <- cr_bmi23 <- cr_bmi27 <- cr_bmi31 <- cr_bmi34 <- cr_bmi43 <- NULL
  public <- cr_public <- rev_lpv <- cr_k_1 <- cr_lambda_1 <- cr_k_min <- cr_k_max <- NULL
  cr_k_2 <- cr_lambda_2 <- cr_k_3 <- cr_lambda_3 <- cr_k_4 <- cr_lambda_4 <- NULL
  cr_k_5 <- cr_lambda_5 <- cr_k_6 <- cr_lambda_6 <- cr_k_7 <- cr_lambda_7 <- NULL
  cr_gamma_0 <- cr_gamma_1 <- cr_gamma_2 <- cr_gamma_3 <- cr_gamma_4 <- cr_gamma_5 <- NULL
  cr_gamma_6 <- cr_gamma_7 <- cr_gamma_8 <- blcv <- agetka1 <- blcv1 <- agetka2 <- NULL
  blcv2 <- log_cum_haz1 <- log_cum_haz2 <- revision_haz_1 <- revision_haz_2 <- NULL
  id <- year <- r1 <- r2 <- phi <- . <- v0 <- v1 <- v2 <- v3 <- v4 <- v5 <- v6 <- v7 <- NULL
  
  ## There are two parts to the revision model...
  ## Linear predictor
  f_linear_pred <-
    function(DF) {
      DF %>%
        # Linear prediction model
        mutate(
          rev_lpv =
            age * cr_age +
              pmax(age - 53, 0)^3 * cr_age53 +
              pmax(age - 63, 0)^3 * cr_age63 +
              pmax(age - 69, 0)^3 * cr_age69 +
              pmax(age - 74, 0)^3 * cr_age74 +
              pmax(age - 83, 0)^3 * cr_age83 +
              female * cr_female +
              ASA2 * cr_asa2 +
              ASA3 * cr_asa3 +
              ASA4_5 * cr_asa4_5 +
              bmi * cr_bmi +
              pmax(bmi - 23.3, 0)^3 * cr_bmi23 +
              pmax(bmi - 27.9, 0)^3 * cr_bmi27 +
              pmax(bmi - 31.1, 0)^3 * cr_bmi31 +
              pmax(bmi - 34.9, 0)^3 * cr_bmi34 +
              pmax(bmi - 43.3, 0)^3 * cr_bmi43 +
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
            pmax(v0 - cr_k_1, 0)^3
              - cr_lambda_1 * pmax(v0 - cr_k_min, 0)^3
              - (1 - cr_lambda_1) * pmax(v0 - cr_k_max, 0)^3,
          v2 =
            pmax(v0 - cr_k_2, 0)^3
              - cr_lambda_2 * pmax(v0 - cr_k_min, 0)^3
              - (1 - cr_lambda_2) * pmax(v0 - cr_k_max, 0)^3,
          v3 =
            pmax(v0 - cr_k_3, 0)^3
              - cr_lambda_3 * pmax(v0 - cr_k_min, 0)^3
              - (1 - cr_lambda_3) * pmax(v0 - cr_k_max, 0)^3,
          v4 =
            pmax(v0 - cr_k_4, 0)^3
              - cr_lambda_4 * pmax(v0 - cr_k_min, 0)^3
              - (1 - cr_lambda_4) * pmax(v0 - cr_k_max, 0)^3,
          v5 =
            pmax(v0 - cr_k_5, 0)^3
              - cr_lambda_5 * pmax(v0 - cr_k_min, 0)^3
              - (1 - cr_lambda_5) * pmax(v0 - cr_k_max, 0)^3,
          v6 =
            pmax(v0 - cr_k_6, 0)^3
              - cr_lambda_6 * pmax(v0 - cr_k_min, 0)^3
              - (1 - cr_lambda_6) * pmax(v0 - cr_k_max, 0)^3,
          v7 =
            pmax(v0 - cr_k_7, 0)^3
              - cr_lambda_7 * pmax(v0 - cr_k_min, 0)^3
              - (1 - cr_lambda_7) * pmax(v0 - cr_k_max, 0)^3,
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

