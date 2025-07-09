TKA_update_fcn <- function(am_curr,
                           am_new,
                           pin,
                           TKA_time_trend,
                           tkadata_melt) {
  browser()
  # NOTE: in future the tkadata_melt can be removed, the purpose of the
  # data is basically being taken over by the TKA_time_trend data
  # kept in at the moment for debugging purposes

  # setup categorical variables
  am_curr$age_group_tka_adj <- cut(am_curr$age, breaks = c(0, 44, 54, 64, 74, 1000), labels = c("< 45", "45-54", "55-64", "65-74", "75+"))
  am_curr$sex_tka_adj <- ifelse(am_curr$sex == "[1] Male", "Males", "Females")

  # find proportion in the synthetic population with OA, will be used to adjust the
  # overall rate of TKA (ie including those without OA) to represent the risk
  # of those with OA. Ie the risk is going to be upscaled from representing
  # the overall population to the risk for the OA population based on this
  # proportion


  # # get current year data
  # tkadata_current <- tkadata_melt %>%
  #   filter(Year == am_curr$year[1]) %>%
  #   mutate(TKR_annual_pop_risk = value/100000)
  #
  #
  # tkadata_current$sex_tka_adj <- grepl("female",tkadata_current$variable)
  # tkadata_current$sex_tka_adj <- ifelse(tkadata_current$sex_tka_adj == TRUE, "Females", "Males")
  #
  # tkadata_current$age_group_tka_adj <- ifelse(grepl("4554",tkadata_current$variable),"45-54",
  #                                             ifelse(grepl("5564",tkadata_current$variable),"55-64",
  #                                                    ifelse(grepl("6574",tkadata_current$variable),"65-74",
  #                                                           ifelse(grepl("75",tkadata_current$variable),"75+",
  #                                                                  "<45"))))
  #
  # am_curr <-left_join(am_curr,
  #                     tkadata_current[,c("sex_tka_adj", "age_group_tka_adj","TKR_annual_pop_risk")],
  #                     by = dplyr::join_by(sex_tka_adj == sex_tka_adj,
  #                                         age_group_tka_adj == age_group_tka_adj))
  #
  #
  # # for those <45 0 annual risk
  # am_curr$TKR_annual_pop_risk[which(is.na(am_curr$TKR_annual_pop_risk))] <- 0



  cycle.coefficents$c9_cons <- cycle.coefficents$c9_cons * as.numeric(OA_cust$proportion_reduction[which(OA_cust$covariate_set == "c6_cons")])
  cycle.coefficents$c9_age <- cycle.coefficents$c9_age * as.numeric(OA_cust$proportion_reduction[which(OA_cust$covariate_set == "c6_age1m")])
  cycle.coefficents$c9_age2 <- cycle.coefficents$c9_age2 * as.numeric(OA_cust$proportion_reduction[which(OA_cust$covariate_set == "c6_age2m")])
  cycle.coefficents$c9_drugoa <- cycle.coefficents$c9_drugoa * as.numeric(OA_cust$proportion_reduction[which(OA_cust$covariate_set == "c6_age3m")])
  cycle.coefficents$c9_ccount <- cycle.coefficents$c9_ccount * as.numeric(OA_cust$proportion_reduction[which(OA_cust$covariate_set == "c6_age4m")])
  cycle.coefficents$c9_mhc <- cycle.coefficents$c9_mhc * as.numeric(OA_cust$proportion_reduction[which(OA_cust$covariate_set == "c6_age5m")])
  cycle.coefficents$c9_tkr <- cycle.coefficents$c9_tkr * as.numeric(OA_cust$proportion_reduction[which(OA_cust$covariate_set == "c6_age1f")])
  cycle.coefficents$c9_kl2hr <- cycle.coefficents$c9_kl2hr * as.numeric(OA_cust$proportion_reduction[which(OA_cust$covariate_set == "c6_age3f")])
  cycle.coefficents$c9_kl3hr <- cycle.coefficents$c9_kl3hr * as.numeric(OA_cust$proportion_reduction[which(OA_cust$covariate_set == "c6_age4f")])
  cycle.coefficents$c9_kl4hr <- cycle.coefficents$c9_kl4hr * as.numeric(OA_cust$proportion_reduction[which(OA_cust$covariate_set == "c6_age5f")])

  am_curr$tkai <- cycle.coefficents$c9_cons +
    cycle.coefficents$c9_age * am_curr$age +
    cycle.coefficents$c9_age2 * (am_curr$age^2) +
    cycle.coefficents$c9_drugoa * am_curr$drugoa +
    cycle.coefficents$c9_ccount * am_curr$ccount +
    cycle.coefficents$c9_mhc * am_curr$mhc +
    cycle.coefficents$c9_tkr * am_curr$tka +
    cycle.coefficents$c9_kl2hr * am_curr$kl2 +
    cycle.coefficents$c9_kl3hr * am_curr$kl3 +
    cycle.coefficents$c9_kl4hr * am_curr$kl4

  # risk is a 5 year value so divided by 5 to get annual risk
  am_curr$tkai <- am_curr$tkai / 5

  # divide by 100 to get proportion for comparison with
  am_curr$tkai <- am_curr$tkai / 100

  # zero risk for anyone without OA, who is dead or who has already had two TKA
  am_curr$tkai <- am_curr$oa * am_curr$tkai
  am_curr$tkai <- (1 - am_curr$dead) * am_curr$tkai # % only alive have TKA
  am_curr$tkai <- (1 - am_curr$tka2) * am_curr$tkai

  # apply secular scaling, difference values for gender*age groups so 8 groups in total
  am_curr$current_scaling_factor <- 1
  # females
  am_curr$current_scaling_factor[which(am_curr$sex == "[2] Female" & am_curr$age4554 == 1)] <- TKA_time_trend$female4554[which(TKA_time_trend$Year == am_curr$year[1])]
  am_curr$current_scaling_factor[which(am_curr$sex == "[2] Female" & am_curr$age5564 == 1)] <- TKA_time_trend$female5564[which(TKA_time_trend$Year == am_curr$year[1])]
  am_curr$current_scaling_factor[which(am_curr$sex == "[2] Female" & am_curr$age6574 == 1)] <- TKA_time_trend$female6574[which(TKA_time_trend$Year == am_curr$year[1])]
  am_curr$current_scaling_factor[which(am_curr$sex == "[2] Female" & am_curr$age75 == 1)] <- TKA_time_trend$female75[which(TKA_time_trend$Year == am_curr$year[1])]
  # males
  am_curr$current_scaling_factor[which(am_curr$sex == "[1] Male" & am_curr$age4554 == 1)] <- TKA_time_trend$male4554[which(TKA_time_trend$Year == am_curr$year[1])]
  am_curr$current_scaling_factor[which(am_curr$sex == "[1] Male" & am_curr$age5564 == 1)] <- TKA_time_trend$male5564[which(TKA_time_trend$Year == am_curr$year[1])]
  am_curr$current_scaling_factor[which(am_curr$sex == "[1] Male" & am_curr$age6574 == 1)] <- TKA_time_trend$male6574[which(TKA_time_trend$Year == am_curr$year[1])]
  am_curr$current_scaling_factor[which(am_curr$sex == "[1] Male" & am_curr$age75 == 1)] <- TKA_time_trend$male75[which(TKA_time_trend$Year == am_curr$year[1])]

  # adjust annual risk to reflect secular trend
  am_curr$tkai <- am_curr$tkai * am_curr$current_scaling_factor

  # determine events based on TKA probability
  tkai_rand <- runif(nrow(am_curr), 0, 1)
  am_curr$tkai <- ifelse(am_curr$tkai > tkai_rand, 1, 0)

  # records is a TKA happened in the cycle
  am_new$tka <- am_curr$tkai
  # if no prior TKA and a record is a TKA, then tka1 = 1
  am_new$tka1 <- am_curr$tka1 + (am_curr$tkai * (1 - am_curr$tka1))
  # if a tka is recorded and there is a prior tka (ie am_curr$tka1 == 1), then record tka2
  am_new$tka2 <- am_curr$tka2 + (am_curr$tkai * am_curr$tka1)

  # this operates as a counter, effectively years since the TKA
  am_new$agetka1 <- am_curr$agetka1 + am_curr$tka1
  am_new$agetka2 <- am_curr$agetka2 + am_curr$tka2

  comparison <- 1 # placeholder

  # bundle am_curr and am_new for export
  export_data <- list(
    am_curr = am_curr,
    am_new = am_new,
    summ_tka_risk = comparison
  )

  return(export_data)
}

#   # get conversion factor to scale up annual risk based on the number of individuals with OA
#
#
#
#   # tkai = tkai.*am_curr.oa.*oam4554.*am_curr.male.*am_curr.age4554.*pin.pcal_m4554 +
#   #   tkai.*am_curr.oa.*oam5564.*am_curr.male.*am_curr.age5564.*pin.pcal_m5564 +
#   #   tkai.*am_curr.oa.*oam6574.*am_curr.male.*am_curr.age6574.*pin.pcal_m6574 +
#   #   tkai.*am_curr.oa.*oam75.*am_curr.male.*am_curr.age75.*pin.pcal_m75 +
#   #
#   #   tkai.*am_curr.oa.*oaf4554.*am_curr.female.*am_curr.age4554.*pin.pcal_f4554 +
#   #   tkai.*am_curr.oa.*oaf5564.*am_curr.female.*am_curr.age5564.*pin.pcal_f5564 +
#   #   tkai.*am_curr.oa.*oaf6574.*am_curr.female.*am_curr.age6574.*pin.pcal_f6574 +
#   #   tkai.*am_curr.oa.*oaf75.*am_curr.female.*am_curr.age75.*pin.pcal_f75;
#
#
#   # # summary of annual risk, before adjusting for impact of OA on annual risk
#   # summ_tka_risk_pre <- am_curr %>%
#   #   group_by(age_cat, sex) %>%
#   #   summarise(count_oa = sum(oa),
#   #             mean_tka_risk_pre = mean(TKR_annual_pop_risk))
#
#   oashares <- am_curr %>%
#     filter(dead == 0) %>%
#     filter(tka2 == 0) %>%
#     group_by(sex_tka_adj, age_group_tka_adj, oa) %>%
#     summarise(OA_count = n()) %>%
#     ungroup() %>%
#     group_by(sex_tka_adj, age_group_tka_adj) %>%
#     arrange(desc(oa)) %>%
#     summarise(OA_share = sum(OA_count)/OA_count[1])
#
#   oashares$calibration <- NA
#
#   oashares$calibration[oashares$sex_tka_adj == "Females" &
#                          oashares$age_group_tka_adj == "< 45" ] <- 1
#
#   oashares$calibration[oashares$sex_tka_adj == "Females" &
#                          oashares$age_group_tka_adj == "45-54" ] <- pin$Live[which(pin$Parameter == "pcal_f4554")]
#
#   oashares$calibration[oashares$sex_tka_adj == "Females" &
#                          oashares$age_group_tka_adj == "55-64" ] <- pin$Live[which(pin$Parameter == "pcal_f5564")]
#
#   oashares$calibration[oashares$sex_tka_adj == "Females" &
#                          oashares$age_group_tka_adj == "65-74" ] <- pin$Live[which(pin$Parameter == "pcal_f6574")]
#
#   oashares$calibration[oashares$sex_tka_adj == "Females" &
#                          oashares$age_group_tka_adj == "75+" ] <- pin$Live[which(pin$Parameter == "pcal_f75")]
#
#
#   oashares$calibration[oashares$sex_tka_adj == "Males" &
#                          oashares$age_group_tka_adj == "< 45" ] <- 1
#
#   oashares$calibration[oashares$sex_tka_adj == "Males" &
#                          oashares$age_group_tka_adj == "45-54" ] <- pin$Live[which(pin$Parameter == "pcal_m4554")]
#
#   oashares$calibration[oashares$sex_tka_adj == "Males" &
#                          oashares$age_group_tka_adj == "55-64" ] <- pin$Live[which(pin$Parameter == "pcal_m5564")]
#
#   oashares$calibration[oashares$sex_tka_adj == "Males" &
#                          oashares$age_group_tka_adj == "65-74" ] <- pin$Live[which(pin$Parameter == "pcal_m6574")]
#
#   oashares$calibration[oashares$sex_tka_adj == "Males" &
#                          oashares$age_group_tka_adj == "75+" ] <- pin$Live[which(pin$Parameter == "pcal_m75")]
#
#   # find OA share and calibration values for each individual
#   am_curr <-left_join(am_curr,
#                       oashares,
#                       by = dplyr::join_by(sex_tka_adj == sex_tka_adj,
#                                           age_group_tka_adj == age_group_tka_adj))
#
#   # zero for anyone without OA, who is dead or who has already had two TKA
#   am_curr$OA_share <-  am_curr$oa * am_curr$OA_share
#   am_curr$OA_share <- (1-am_curr$dead) * am_curr$OA_share # % only alive have TKA
#   am_curr$OA_share <- (1-am_curr$tka2) * am_curr$OA_share
#
#   # set the TKA rate to represent the risk
#   am_curr$tkai <- am_curr$TKR_annual_pop_risk
#
#   # summary of annual risk, after adjusting for OA status
#   summ_tka_risk_post <- am_curr %>%
#     group_by(age_cat, sex) %>%
#     summarise(mean_tka_risk_post = mean(tkai))
#
#   # modify the TKA rate to represent the risk for those with OA
#   am_curr$tkai <- am_curr$tkai * am_curr$OA_share
#
#   # zero risk for anyone without OA, who is dead or who has already had two TKA
#   am_curr$tkai <-  am_curr$oa * am_curr$tkai
#   am_curr$tkai <- (1-am_curr$dead) * am_curr$tkai # % only alive have TKA
#   am_curr$tkai <- (1-am_curr$tka2) * am_curr$tkai
#
#   # Add calibration factor
#   am_curr$tkai <- am_curr$tkai * am_curr$calibration
#
#   # summary of annual risk, after calibration
#   summ_tka_risk_adjustment <- am_curr %>%
#     group_by(age_cat, sex) %>%
#     summarise(mean_tka_risk_adjustment = mean(tkai))
#
#   comparison <- merge(summ_tka_risk_pre,summ_tka_risk_post, by = c("age_cat","sex"))
#   comparison <- merge(comparison,summ_tka_risk_adjustment, by = c("age_cat","sex"))
#
#   comparison$mean_tka_risk_pre <- round(comparison$mean_tka_risk_pre, 4)
#   comparison$mean_tka_risk_post <- round(comparison$mean_tka_risk_post, 4)
#   comparison$mean_tka_risk_adjustment <- round(comparison$mean_tka_risk_adjustment, 4)
#
#   # calculate change in quality of life
#   # tka_dqol_test = pin.c15_cons + pin.c15_male.*am_curr.male + pin.c15_ccount.*am_curr.ccount + pin.c15_bmi3.*am_curr.bmi3539 + pin.c15_bmi4.*am_curr.bmi40 + pin.c15_mhc.*am_curr.mhc + pin.c15_age3.*am_curr.age5564 + pin.c15_age4.*am_curr.age6574 + pin.c15_age5.*am_curr.age75 + pin.c15_sf6d.*am_curr.sf6d + pin.c15_kl3.*am_curr.kl3 + pin.c15_kl4.*am_curr.kl4 + pin.c15_comp.*am_curr.comp;
#   am_curr$tka_dqol <- cycle.coefficents$c15_cons +
#     cycle.coefficents$c15_male * am_curr$male +
#     cycle.coefficents$c15_ccount * am_curr$ccount +
#     cycle.coefficents$c15_bmi3 * am_curr$bmi3539 +
#     cycle.coefficents$c15_bmi4 * am_curr$bmi40 +
#     cycle.coefficents$c15_mhc * am_curr$mhc +
#     cycle.coefficents$c15_age3 * am_curr$age5564 +
#     cycle.coefficents$c15_age4 * am_curr$age6574 +
#     cycle.coefficents$c15_age5 * am_curr$age75 +
#     cycle.coefficents$c15_sf6d * am_curr$sf6d +
#     cycle.coefficents$c15_kl3 * am_curr$kl3 +
#     cycle.coefficents$c15_kl4 * am_curr$kl4 +
#     cycle.coefficents$c15_comp * am_curr$comp
#
#   # identify people who will benefit from surgery
#   am_curr$tka_ben <- am_curr$tka_dqol > cycle.coefficents$p_tka_qolmid
#
#   # count those only with OA and alive
#   am_curr$tka_ben <- am_curr$tka_ben * am_curr$oa *(1-am_curr$dead)
#
#   # Find the proportion of people who are above the benefit threshold and are
#   # eligible (i.e. have OA and are not dead) compared to those just are eligible
#   tka_benshare <- sum(am_curr$tka_ben) / sum((am_curr$oa *(1-am_curr$dead)))
#
#   # mean used a this give a single value,
#   # each individual has a 'p_ffs_adj' but it is the same value so
#   # mean = the adjustment value selected for the population
#   # assumption here the adjustment is the same for everyone, this will
#   # not work if there is any sort of subpopulation level adjustment values used
#   # in the future
#
#   ffs_adj2 <- 1 - mean(cycle.coefficents$p_ffs_adj, na.rm = TRUE) *(1 - tka_benshare)
#   ffs_adj2 <- ffs_adj2 / tka_benshare
#   ffs_adj2 <- ffs_adj2 / mean(cycle.coefficents$p_ffs_adj, na.rm = TRUE)
#
#   # drop the base rate
#   # goal here is to reduce the baseline rate of TKA to allow for the
#   # increase in the TKA rate for those who benefit, see next line
#   # this should balance out so there is the same number of annual ops
#   # just changes who has them
#
#   summary.data <- am_curr %>%
#     group_by(oa, dead, tka_ben) %>%
#     summarise(mean_tkai = mean(tkai))
#
#   # adjust the TKA rate based on the 'p_ffs_adj' variable
#   # default is 1, check with Chris S to see what this is to
#   # be used for
#   am_curr$tkai <- cycle.coefficents$p_ffs_adj * am_curr$tkai
#
#   # testing for fit for surgery - increase for those who benefit
#   am_curr$tkai <- am_curr$tkai * (ffs_adj2 ^ am_curr$tka_ben)
#
#   # # determine events based on TKA probability
#   tkai_rand <- runif(nrow(am_curr),0,1)
#   am_curr$tkai <- ifelse(am_curr$tkai > tkai_rand,1,0)
#
#   # summary of annual risk, after adjustment
#   summ_tka_risk_count <- am_curr %>%
#     group_by(age_cat, sex) %>%
#     summarise(tka_count = sum(tkai),
#               count_tka_risk_greater_than_0 = sum(kl_score>0),
#               sum_pop = n())
#
#
#   summary.data.tka <- am_curr %>%
#     group_by(oa, dead, tka_ben) %>%
#     summarise(tka_count = sum(tkai))
#
#   comparison <- merge(comparison,summ_tka_risk_count, by = c("age_cat", "sex"))
#
#   comparison$year <- min(am_curr$year)
#
#   #print(comparison)
#
#   #### record outcomes and impact on SF6D
#   # records is a TKA happened in the cycle
#   am_new$tka <- am_curr$tkai
#   # if no prior TKA and a record is a TKA, then tka1 = 1
#   am_new$tka1 <- am_curr$tka1 + (am_curr$tkai * (1-am_curr$tka1))
#   # if a tka is recorded and there is a prior tka (ie am_curr$tka1 == 1), then record tka2
#   am_new$tka2 <- am_curr$tka2 + (am_curr$tkai * am_curr$tka1)
#
#   # this operates as a counter, effectively years since the TKA
#   am_new$agetka1 <- am_curr$agetka1 + am_curr$tka1
#   am_new$agetka2 <- am_curr$agetka2 + am_curr$tka2
#
#   # decrement to represent pre-surgery decline observed in the data,
#   am_curr$sf6d <- am_curr$sf6d + am_curr$tkai * cycle.coefficents$p_tka_qol
#
#   # Recalc sf6d delta after pre-surgery decline impact
#   am_curr$tka_dqol <- cycle.coefficents$c15_cons +
#     cycle.coefficents$c15_male * am_curr$male +
#     cycle.coefficents$c15_ccount * am_curr$ccount +
#     cycle.coefficents$c15_bmi3 * am_curr$bmi3539 +
#     cycle.coefficents$c15_bmi4 * am_curr$bmi40 +
#     cycle.coefficents$c15_mhc * am_curr$mhc +
#     cycle.coefficents$c15_age3 * am_curr$age5564 +
#     cycle.coefficents$c15_age4 * am_curr$age6574 +
#     cycle.coefficents$c15_age5 * am_curr$age75 +
#     cycle.coefficents$c15_sf6d * am_curr$sf6d +
#     cycle.coefficents$c15_kl3 * am_curr$kl3 +
#     cycle.coefficents$c15_kl4 * am_curr$kl4 +
#     cycle.coefficents$c15_comp * am_curr$comp
#
#   # delta calculated previously, associated with capacity to benefit section
#   am_curr$d_sf6d  <- am_curr$d_sf6d  + (am_curr$tkai * am_curr$tka_dqol)
#
#   # setup flag for individual above the threshold based on final TKA impact
#   am_curr$tka_ben_above_threshold <- ifelse((am_curr$tkai * am_curr$tka_dqol) > cycle.coefficents$p_tka_qolmid,
#                                             1,0)
#   am_new$tka_ben_above_threshold <- am_curr$tka_ben_above_threshold
#   # record the impact of TKA on SF6D for those in the cycle with a TKA
#   am_curr$tka_dqol_in_cycle <- (am_curr$tkai * am_curr$tka_dqol)
#   am_new$tka_dqol_in_cycle <- am_curr$tka_dqol_in_cycle
#   # clean up scaling factor data
#   am_curr$age_group_tka_adj <- NULL
#   am_curr$sex_tka_adj <- NULL
#
#   # bundle am_curr and am_new for export
#   export_data <- list(am_curr = am_curr,
#                       am_new = am_new,
#                       summ_tka_risk = comparison)
#
#   return(export_data)
#
#
# }
