OA_update <- function(am_curr, am_new, cycle.coefficents, OA_cust) {
  # browser()
  turn.out.inloop.summary <-FALSE
  OA_cust$proportion_reduction <- as.numeric(OA_cust$proportion_reduction)
  
  # Customize OA age coefficients
  
  cycle.coefficents$c6_cons <- cycle.coefficents$c6_cons * as.numeric(OA_cust$proportion_reduction[which(OA_cust$covariate_set == "c6_cons")])
  cycle.coefficents$c6_age1m <- cycle.coefficents$c6_age1m * as.numeric(OA_cust$proportion_reduction[which(OA_cust$covariate_set == "c6_age1m")])
  cycle.coefficents$c6_age2m <- cycle.coefficents$c6_age2m * as.numeric(OA_cust$proportion_reduction[which(OA_cust$covariate_set == "c6_age2m")])
  cycle.coefficents$c6_age3m <- cycle.coefficents$c6_age3m * as.numeric(OA_cust$proportion_reduction[which(OA_cust$covariate_set == "c6_age3m")])
  cycle.coefficents$c6_age4m <- cycle.coefficents$c6_age4m * as.numeric(OA_cust$proportion_reduction[which(OA_cust$covariate_set == "c6_age4m")])
  cycle.coefficents$c6_age5m <- cycle.coefficents$c6_age5m * as.numeric(OA_cust$proportion_reduction[which(OA_cust$covariate_set == "c6_age5m")])
  cycle.coefficents$c6_age1f <- cycle.coefficents$c6_age1f * as.numeric(OA_cust$proportion_reduction[which(OA_cust$covariate_set == "c6_age1f")])
  cycle.coefficents$c6_age2f <- cycle.coefficents$c6_age2f * as.numeric(OA_cust$proportion_reduction[which(OA_cust$covariate_set == "c6_age2f")])
  cycle.coefficents$c6_age3f <- cycle.coefficents$c6_age3f * as.numeric(OA_cust$proportion_reduction[which(OA_cust$covariate_set == "c6_age3f")])
  cycle.coefficents$c6_age4f <- cycle.coefficents$c6_age4f * as.numeric(OA_cust$proportion_reduction[which(OA_cust$covariate_set == "c6_age4f")])
  cycle.coefficents$c6_age5f <- cycle.coefficents$c6_age5f * as.numeric(OA_cust$proportion_reduction[which(OA_cust$covariate_set == "c6_age5f")])
  
  # OA initiation
  am_curr$oai <- exp(cycle.coefficents$c6_cons +
                         cycle.coefficents$c6_year12 * am_curr$year12 +
                         cycle.coefficents$c6_age1m * am_curr$age044 * am_curr$male +
                         cycle.coefficents$c6_age2m * am_curr$age4554 * am_curr$male +
                         cycle.coefficents$c6_age3m * am_curr$age5564 * am_curr$male +
                         cycle.coefficents$c6_age4m * am_curr$age6574 * am_curr$male +
                         cycle.coefficents$c6_age5m * am_curr$age75 * am_curr$male +
                         cycle.coefficents$c6_age1f * am_curr$age044 * (1-am_curr$male) +
                         cycle.coefficents$c6_age2f * am_curr$age4554 * (1-am_curr$male) +
                         cycle.coefficents$c6_age3f * am_curr$age5564 * (1-am_curr$male) +
                         cycle.coefficents$c6_age4f * am_curr$age6574 * (1-am_curr$male) +
                         cycle.coefficents$c6_age5f * am_curr$age75 * (1-am_curr$male) +
                         cycle.coefficents$c6_bmi0 * am_curr$bmi024 +
                         cycle.coefficents$c6_bmi1 * am_curr$bmi2529 +
                         cycle.coefficents$c6_bmi2 * am_curr$bmi3034 +
                         cycle.coefficents$c6_bmi3 * am_curr$bmi3539 +
                         cycle.coefficents$c6_bmi4 * am_curr$bmi40)
  
  am_curr$oai <- (1 - am_curr$oa) * am_curr$oai  #% only have an initialisation probability if don't already have OA
  am_curr$oai <- (1 - am_curr$dead) * am_curr$oai  #% only have an initialisation probability if not dead
  am_curr$oai <-  am_curr$oai/(1+am_curr$oai)  #% logistic
  am_curr$oai <- (1+am_curr$oai) ^ 0.25 - 1
  
  
  if(turn.out.inloop.summary == TRUE){
    summary_risk <- am_curr %>%
      filter(age_cat != "[14,45]") %>%
      group_by(sex, age_cat) %>%
      summarise(mean.annual.oa.risk.percent = mean(oai) * 100)
  }
  
  oai_rand <- runif(nrow(am_curr),0,1)
  #am_curr$oai_risk <- am_curr$oai 
  am_curr$oai <- ifelse(am_curr$oai > oai_rand,1,0)
  
  if(turn.out.inloop.summary == TRUE){
    summary_events <- am_curr %>%
      filter(age_cat != "[14,45]") %>%
      group_by(sex, age_cat) %>%
      summarise(mean.annual.oa.event.percent = mean(oai) * 100)
    
    summary_risk.overall <- merge(summary_risk,summary_events, by = c("sex", "age_cat") )
    
    print(summary_risk.overall)
  }
  
  am_new$oa <- am_curr$oai + am_curr$oa
  am_new$kl2 <- am_curr$oai + am_curr$kl2
  
  am_curr$d_sf6d <- am_curr$d_sf6d + (am_curr$oai * pin$Live[which(pin$Parameter == "c14_kl2")])
  
  # update medication status, if newly OA test if the also get meds,
  # should only happen when a person is newly OA 
  # 0.56 from Hilda data 2013 per C. Schilling
  
  med_rand <- runif(nrow(am_curr),0,1)
  
  am_curr$drugoa <- ifelse(am_curr$oai == 1, 
                           as.numeric(0.56 > med_rand),
                           am_curr$drugoa)
  
  #log_print("Number of new KL2 individuals", console = FALSE, hide_notes = TRUE)
  #log_print(sum(am_curr$oai), console = FALSE, hide_notes = TRUE)
  
  # % OA progression KL2 to 3 - based on OAI analysis
  
  
  # OA progression from KL2 to KL3 
  am_curr$oap <- exp(cycle.coefficents$c7_cons +
                       cycle.coefficents$c7_sex * am_curr$female +
                       cycle.coefficents$c7_age3 * am_curr$age5564 +
                       cycle.coefficents$c7_age4 * am_curr$age6574 +
                       cycle.coefficents$c7_age5 * am_curr$age75 +
                       cycle.coefficents$c7_bmi0 * am_curr$bmi024 +
                       cycle.coefficents$c7_bmi1 * am_curr$bmi2529 +
                       cycle.coefficents$c7_bmi2 * am_curr$bmi3034 +
                       cycle.coefficents$c7_bmi3 * am_curr$bmi3539 +
                       cycle.coefficents$c7_bmi4 * am_curr$bmi40)
  
  
  # note: not "1- am_curr$kl2" because a person must be KL2 progress to KL3
  am_curr$oap <- am_curr$kl2 * am_curr$oap  #% only have a progression probability if already have KL2
  am_curr$oap <- (1 - am_curr$dead) * am_curr$oap  #% only have an progression probability if not dead
  am_curr$oap <-  am_curr$oap / (1+am_curr$oap) # % logistic
  am_curr$oap <- (1+am_curr$oap) ^ 0.25 - 1  #% OAI analysis is over 4 years - need to reduce to annual
  
  
  oap_rand <- runif(nrow(am_curr),0,1)
  am_curr$oap <- ifelse(am_curr$oap > oap_rand,1,0)
  
  am_curr$d_sf6d <- am_curr$d_sf6d + (am_curr$oap * pin$Live[which(pin$Parameter == "c14_kl3")])
  
  am_new$kl3 <- am_curr$oap + am_curr$kl3
  am_new$kl2 <- am_curr$kl2 - am_curr$oap
  
  #log_print("Number of new KL3 individuals", console = FALSE, hide_notes = TRUE)
  #log_print(sum(am_curr$oap), console = FALSE, hide_notes = TRUE)
  
  
  # OA progression KL 3 and 4
  am_curr$oap34 <- exp(cycle.coefficents$c8_cons +
                       cycle.coefficents$c8_sex * am_curr$female +
                       cycle.coefficents$c8_age3 * am_curr$age5564 +
                       cycle.coefficents$c8_age4 * am_curr$age6574 +
                       cycle.coefficents$c8_age5 * am_curr$age75 +
                       cycle.coefficents$c8_bmi0 * am_curr$bmi024 +
                       cycle.coefficents$c8_bmi1 * am_curr$bmi2529 +
                       cycle.coefficents$c8_bmi2 * am_curr$bmi3034 +
                       cycle.coefficents$c8_bmi3 * am_curr$bmi3539 +
                       cycle.coefficents$c8_bmi4 * am_curr$bmi40)
  
  am_curr$oap34 <- am_curr$kl3 * am_curr$oap34  #% only have a progression probability if already have KL3
  am_curr$oap34 <- (1 - am_curr$dead)* am_curr$oap34  #% only have an progression probability if not dead
  am_curr$oap34 <-  am_curr$oap34 / (1+am_curr$oap34)  #% logistic
  am_curr$oap34 <- (1+am_curr$oap34) ^ 0.25 - 1  #% OAI analysis is over 4 years - need to reduce to annual
  
  oap34_rand <- runif(nrow(am_curr),0,1)
  am_curr$oap34 <- ifelse(am_curr$oap34 > oai_rand,1,0)
  
  am_curr$d_sf6d <- am_curr$d_sf6d + (am_curr$oap34 * pin$Live[which(pin$Parameter == "c14_kl4")])
  
  am_new$kl4 <- am_curr$oap34 + am_curr$kl4
  am_new$kl3 <- am_curr$kl3 - am_curr$oap34
  
  
  
  am_new$kl_score <- (2 * am_new$kl2) + (3 * am_new$kl3) + (4 * am_new$kl4)
  
  
  # bundle am_curr and am_new for export
  export_data <- list(am_curr = am_curr,
                      am_new = am_new)
  
  return(export_data)
  
}