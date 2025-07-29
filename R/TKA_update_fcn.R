TKA_update_fcn <- function(am_curr, am_new, cycle.coefficents, TKR_cust, summary_TKR_observed_diff) {
  # TKR customisation
  # summary_TKR_observed_diff <-
  #   read_csv(here("data", "coefficent_selection", "TKR_correction_factors.csv"),
  #     show_col_types = FALSE
  #   )
  # # browser()
  # #### setup adjustment factors in dataset and merge in previously calculated scaling factors
  # # apply adjustment to TKA rate
  # am_curr$age_group_tka_adj <- cut(am_curr$age, breaks = c(0, 44, 54, 64, 74, 1000), labels = c("< 45", "45-54", "55-64", "65-74", "75+"))
  # am_curr$sex_tka_adj <- ifelse(am_curr$sex == "[1] Male", "Males", "Females")
  # 
  # 
  # am_curr <- am_curr %>% left_join(summary_TKR_observed_diff[, c("year", "sex", "age_group", "scaling_factor_smooth")],
  #   by = join_by(
  #     year == year,
  #     sex_tka_adj == sex,
  #     age_group_tka_adj == age_group
  #   )
  # )
  # # browser()
  # # where there is no scaling factor (either NA, INF or 0) keep current estimated risk
  am_curr$scaling_factor_smooth <- 1
  # am_curr$scaling_factor_smooth <- ifelse(is.na(am_curr$scaling_factor_smooth), 1, am_curr$scaling_factor_smooth)
  # am_curr$scaling_factor_smooth <- ifelse(is.infinite(am_curr$scaling_factor_smooth), 1, am_curr$scaling_factor_smooth)
  # am_curr$scaling_factor_smooth <- ifelse(am_curr$scaling_factor_smooth == 0, 1, am_curr$scaling_factor_smooth)

  ### Calculate probability of TKA and adjust for eligibility
  # calculate the probability of TKA
  am_curr$tkai <- cycle.coefficents$c9_age * am_curr$age +
    cycle.coefficents$c9_age2 * (am_curr$age^2) +
    cycle.coefficents$c9_drugoa * am_curr$drugoa +
    cycle.coefficents$c9_ccount * am_curr$ccount +
    cycle.coefficents$c9_mhc * am_curr$mhc +
    cycle.coefficents$c9_tkr * am_curr$tka1

  am_curr$tkai <- -exp(am_curr$tkai) * cycle.coefficents$c9_cons
  am_curr$tkai <- 1 - exp(am_curr$tkai)
  am_curr$tkai <- ((1 + am_curr$tkai)^0.2) - 1

  # summary of annual risk, before controlling for KL status
  summ_tka_risk_pre <- am_curr %>%
    group_by(age_cat, sex) %>%
    summarise(
      count_oa = sum(oa),
      count_drugoa = sum(drugoa),
      mean_tka_risk_pre = mean(tkai)
    )


  # # adjust TKA rate based on KL status
  am_curr$tkai <- cycle.coefficents$c9_kl2hr * am_curr$tkai * am_curr$kl2 +
    cycle.coefficents$c9_kl3hr * am_curr$tkai * am_curr$kl3 +
    cycle.coefficents$c9_kl4hr * am_curr$tkai * am_curr$kl4 # % only have TKA if have OA. Incorporate a HR for 4 vervsus 3 verus 2

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
  tkai_rand <- runif(nrow(am_curr), 0, 1)
  am_curr$tkai <- ifelse(am_curr$tkai > tkai_rand, 1, 0)

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

  comparison <- merge(comparison, summ_tka_risk_count, by = c("age_cat", "sex"))

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