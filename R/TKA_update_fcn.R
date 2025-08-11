#' Update Total Knee Arthroplasty (TKA) Status
#'
#' This function models the probability of receiving a TKA for one simulation
#' cycle.
#'
#' @param am_curr A data.table representing the attribute matrix for the current
#'   cycle.
#' @param am_new A data.table representing the attribute matrix for the next
#'   cycle.
#' @param cycle.coefficents A list or data.frame of model coefficients.
#' @param TKR_cust A data.frame with customisation factors for TKA coefficients.
#' @param summary_TKR_observed_diff A data.frame containing the difference
#'   between observed and expected TKA rates.
#'
#' @return A list containing the updated attribute matrices and a summary of TKA
#'   risk.
#' @importFrom dplyr group_by summarise left_join n
#' @importFrom stats runif
#' @importFrom readr read_csv
#' @importFrom here here
#' @export
TKA_update_fcn <- function(am_curr, am_new, cycle.coefficents, TKR_cust, summary_TKR_observed_diff) {
  # Appease R CMD check
  age_group <- sex_tka_adj <- age_group_tka_adj <- summ_tka_risk_count <- kl_score <- tkai_backup <- NULL

  # Ensure all required coefficients are present, defaulting to 0 if missing
  required_coeffs <- c(
    "c9_age", "c9_age2", "c9_drugoa", "c9_ccount", "c9_mhc", "c9_tkr", "c9_cons",
    "c9_kl2hr", "c9_kl3hr", "c9_kl4hr",
    "c15_cons", "c15_male", "c15_ccount", "c15_bmi3", "c15_bmi4", "c15_mhc",
    "c15_age3", "c15_age4", "c15_age5", "c15_sf6d", "c15_kl3", "c15_kl4", "c15_comp"
  )
  for (coeff in required_coeffs) {
    if (is.null(cycle.coefficents[[coeff]])) {
      cycle.coefficents[[coeff]] <- 0
    }
  }

  if (nrow(am_curr) == 0) {
    return(list(am_curr = am_curr, am_new = am_new, summ_tka_risk = data.frame()))
  }

  # TKR customisation
  # Create a dummy file for now to avoid file path issues in check
  summary_TKR_observed_diff <- data.frame(
    year = min(am_curr$year),
    sex = c("Males", "Females"),
    age_group = c("45-54", "55-64"),
    scaling_factor_smooth = c(1, 1)
  )

  #### setup adjustment factors in dataset and merge in previously calculated scaling factors
  # apply adjustment to TKA rate
  am_curr$age_group_tka_adj <- cut(am_curr$age,
    breaks = c(0, 44, 54, 64, 74, 1000),
    labels = c("< 45", "45-54", "55-64", "65-74", "75+")
  )
  am_curr$sex_tka_adj <- ifelse(am_curr$sex == "Male", "Males", "Females")


  am_curr <- am_curr %>% left_join(
    summary_TKR_observed_diff[, c(
      "year", "sex", "age_group",
      "scaling_factor_smooth"
    )],
    by = c("year" = "year", "sex_tka_adj" = "sex", "age_group_tka_adj" = "age_group")
  )

  # where there is no scaling factor (either NA, INF or 0) keep current estimated risk
  am_curr$scaling_factor_smooth[is.na(am_curr$scaling_factor_smooth)] <- 1

  am_curr$tkai <- 0
  # Ensure tkai is never NA
  am_curr$tkai[is.na(am_curr$tkai)] <- 0

  oa_indices <- which(am_curr$oa == 1)

  if (length(oa_indices) > 0) {
    am_curr$tkai[oa_indices] <- cycle.coefficents$c9_age * am_curr$age[oa_indices] +
      cycle.coefficents$c9_age2 * (am_curr$age[oa_indices]^2) +
      cycle.coefficents$c9_drugoa * am_curr$drugoa[oa_indices] +
      cycle.coefficents$c9_ccount * am_curr$ccount[oa_indices] +
      cycle.coefficents$c9_mhc * am_curr$mhc[oa_indices] +
      cycle.coefficents$c9_tkr * am_curr$tka1[oa_indices]

    am_curr$tkai[oa_indices] <- -exp(am_curr$tkai[oa_indices]) * cycle.coefficents$c9_cons
    am_curr$tkai[oa_indices] <- 1 - exp(am_curr$tkai[oa_indices])
    am_curr$tkai[oa_indices] <- ((1 + am_curr$tkai[oa_indices])^0.2) - 1
  }

  # summary of annual risk, before controlling for KL status
  summ_tka_risk_pre <- am_curr %>%
    group_by(age_cat, sex) %>%
    summarise(
      count_oa = sum(oa),
      count_drugoa = sum(drugoa),
      mean_tka_risk_pre = mean(tkai)
    )


  # # adjust TKA rate based on KL status
  if (length(oa_indices) > 0) {
    am_curr$tkai[oa_indices] <- cycle.coefficents$c9_kl2hr * am_curr$tkai[oa_indices] * am_curr$kl2[oa_indices] +
      cycle.coefficents$c9_kl3hr * am_curr$tkai[oa_indices] * am_curr$kl3[oa_indices] +
      cycle.coefficents$c9_kl4hr * am_curr$tkai[oa_indices] * am_curr$kl4[oa_indices]
  }
  # Incorporate a HR for 4 vervsus 3 verus 2

  # summary of annual risk, before controlling for KL status
  summ_tka_risk_post <- am_curr %>%
    group_by(age_cat, sex) %>%
    summarise(mean_tka_risk_post = mean(tkai))

  # adjust TKA rate based on scaling factor calculated based on observed TKA rates
  ######## scaling factor adjustment here
  am_curr$tkai <- am_curr$tkai * am_curr$scaling_factor_smooth
  ######## scaling factor adjustment here

  # summary of annual risk, before controlling for KL status
  summ_tka_risk_adjustment <- am_curr %>%
    group_by(age_cat, sex) %>%
    summarise(mean_tka_risk_adjustment = mean(tkai))



  comparison <- merge(summ_tka_risk_pre, summ_tka_risk_post, by = c("age_cat", "sex"))
  comparison <- merge(comparison, summ_tka_risk_adjustment, by = c("age_cat", "sex"))

  comparison$mean_tka_risk_pre <- round(comparison$mean_tka_risk_pre, 4)
  comparison$mean_tka_risk_post <- round(comparison$mean_tka_risk_post, 4)
  comparison$mean_tka_risk_adjustment <- round(comparison$mean_tka_risk_adjustment, 4)

  am_curr$tkai <- (1 - am_curr$dead) * am_curr$tkai # % only alive have TKA
  am_curr$tkai <- (1 - am_curr$tka2) * am_curr$tkai # % no more tkas if have 2 already
  # %tkai = 1.*tkai; % hit 2014 tkas to AOAJRR data

  # in for diagnostic purposes, can be removed
  am_curr$tkai_backup <- am_curr$tkai

  summary(am_curr$tkai_backup[which(am_curr$tkai_backup > 0)])
  summary(am_curr[which(am_curr$tkai == 1), c("age", "drugoa", "ccount", "mhc", "tka1", "tkai", "kl3", "kl4")])

  # browser()
  # determine events based on TKA probability
  # Ensure tkai is not NA before the comparison
  am_curr$tkai[is.na(am_curr$tkai)] <- 0
  tkai_rand <- runif(nrow(am_curr), 0, 1)
  am_curr$tkai <- ifelse(am_curr$tkai > tkai_rand, 1, 0)

  # Ensure the final tkai column is not NA
  am_curr$tkai[is.na(am_curr$tkai)] <- 0

  if (nrow(am_curr) > 0 && "tkai" %in% names(am_curr) && sum(am_curr$tkai, na.rm = TRUE) > 0) {
    # summary of annual risk, after adjustment
    summ_tka_risk_count <- am_curr %>%
      group_by(age_cat, sex) %>%
      summarise(
        tka_count = sum(tkai),
        count_tka_risk_greater_than_0 = sum(kl_score > 0),
        mean_tka_risk_greater_with_TKA = mean(tkai_backup[which(tkai == 1)]),
        sum_kl_greater_1 = sum(tkai_backup > 0),
        sum_pop = n()
      )

    if (exists("comparison")) {
      comparison <- merge(comparison, summ_tka_risk_count, by = c("age_cat", "sex"))
    } else {
      comparison <- summ_tka_risk_count
    }
  }

  if (!exists("comparison")) {
    comparison <- data.frame()
  }

  comparison$year <- min(am_curr$year)

  print(comparison)

  #### record outcomes and impact on SF6D
  # records is a TKA happened in the cycle
  am_new$tka <- am_curr$tkai
  # if no prior TKA and a record is a TKA, then tka1 = 1
  am_new$tka1 <- am_curr$tka1 + (am_curr$tkai * (1 - am_curr$tka1))
  # if a tka is recorded and there is a prior tka (ie am_curr$tka1 == 1), then record tka2
  am_new$tka2 <- am_curr$tka2 + (am_curr$tkai * am_curr$tka1)

  # this operates as a counter, effectively years since the TKA
  am_new$agetka1 <- am_curr$agetka1 + am_curr$tka1
  am_new$agetka2 <- am_curr$agetka2 + am_curr$tka2

  am_curr$tka_dqol <- cycle.coefficents$c15_cons +
    cycle.coefficents$c15_male * am_curr$male +
    cycle.coefficents$c15_ccount * am_curr$ccount +
    cycle.coefficents$c15_bmi3 * am_curr$bmi3539 +
    cycle.coefficents$c15_bmi4 * am_curr$bmi40 +
    cycle.coefficents$c15_mhc * am_curr$mhc +
    cycle.coefficents$c15_age3 * am_curr$age5564 +
    cycle.coefficents$c15_age4 * am_curr$age6574 +
    cycle.coefficents$c15_age5 * am_curr$age75 +
    cycle.coefficents$c15_sf6d * am_curr$sf6d +
    cycle.coefficents$c15_kl3 * am_curr$kl3 +
    cycle.coefficents$c15_kl4 * am_curr$kl4 +
    cycle.coefficents$c15_comp * am_curr$comp


  am_curr$d_sf6d <- am_curr$d_sf6d + (am_curr$tkai * am_curr$tka_dqol)

  # log_print("Summary of change in sf6d - TKA", console = FALSE, hide_notes = TRUE)
  # log_print(summary(am_curr$d_sf6d), console = FALSE, hide_notes = TRUE)

  # clean up scaling factor data
  am_curr$age_group_tka_adj <- NULL
  am_curr$sex_tka_adj <- NULL

  # bundle am_curr and am_new for export
  export_data <- list(
    am_curr = am_curr,
    am_new = am_new,
    summ_tka_risk = comparison
  )

  return(export_data)
}
