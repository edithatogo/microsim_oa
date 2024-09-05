OA_update <- function(am_curr, pin) {
 
  # OA incidence - based on HILDA analysis
  am_curr$oai <- exp(pin$Live[which(pin$Parameter == "c6_cons")] +
                       pin$Live[which(pin$Parameter == "c6_year12")] * am_curr$year12 +
                       pin$Live[which(pin$Parameter == "c6_sex")] * am_curr$female +
                       pin$Live[which(pin$Parameter == "c6_age1")] *  am_curr$age044 +
                       pin$Live[which(pin$Parameter == "c6_age2")] * am_curr$age4554 +
                       pin$Live[which(pin$Parameter == "c6_age3")] * am_curr$age5564 +
                       pin$Live[which(pin$Parameter == "c6_age4")] * am_curr$age6574 +
                       pin$Live[which(pin$Parameter == "c6_age5")] * am_curr$age75 +
                       pin$Live[which(pin$Parameter == "c6_bmi0")] * am_curr$bmi024 +
                       pin$Live[which(pin$Parameter == "c6_bmi1")] * am_curr$bmi2529 +
                       pin$Live[which(pin$Parameter == "c6_bmi2")] * am_curr$bmi3034 +
                       pin$Live[which(pin$Parameter == "c6_bmi3")] * am_curr$bmi3539 +
                       pin$Live[which(pin$Parameter == "c6_bmi4")] * am_curr$bmi40)
  
  
  am_curr$oai <- (1 - am_curr$oa) * am_curr$oai  #% only have an initialisation probability if don't already have OA
  am_curr$oai <- (1 - am_curr$dead)*am_curr$oai  #% only have an initialisation probability if not dead
  am_curr$oai <-  am_curr$oai/(1+am_curr$oai)  #% logistic 
  am_curr$oai <- (1+am_curr$oai) ^ 0.25 - 1
  
  oai_rand <- runif(nrow(am_curr),0,1)
  am_curr$oai <- ifelse(am_curr$oai > oai_rand,1,0)
  
  am_curr$d_sf6d <- am_curr$d_sf6d + (am_curr$oai * pin$Live[which(pin$Parameter == "c14_kl2")])
  
  
  
 
  
  
  am_curr$oap = exp(pin$Live[which(pin$Parameter == "c7_cons")] +
                      pin$Live[which(pin$Parameter == "c7_sex")] * am_curr$female +
                      pin$Live[which(pin$Parameter == "c7_age3")] * am_curr$age5564 +
                      pin$Live[which(pin$Parameter == "c7_age4")] * am_curr$age6574 +
                      pin$Live[which(pin$Parameter == "c7_age5")] * am_curr$age75 +
                      pin$Live[which(pin$Parameter == "c7_bmi0")] * am_curr$bmi024 +
                      pin$Live[which(pin$Parameter == "c7_bmi1")] * am_curr$bmi2529 +
                      pin$Live[which(pin$Parameter == "c7_bmi2")] * am_curr$bmi3034 +
                      pin$Live[which(pin$Parameter == "c7_bmi3")] * am_curr$bmi3539 +
                      pin$Live[which(pin$Parameter == "c7_bmi4")] * am_curr$bmi40)
  
  am_curr$oap = am_curr$kl2 * am_curr$oap  #% only have a progression probability if already have KL2
  am_curr$oap = (1 - am_curr$dead) * am_curr$oap  #% only have an progression probability if not dead
  am_curr$oap =  am_curr$oap / (1+am_curr$oap) # % logistic 
  am_curr$oap = (1+am_curr$oap) ^ 0.25 - 1  #% OAI analysis is over 4 years - need to reduce to annual
  
  
  oap_rand <- runif(nrow(am_curr),0,1)
  am_curr$oai <- ifelse(am_curr$oai > oai_rand,1,0)
  
  am_curr$d_sf6d <- am_curr$d_sf6d + (am_curr$oai * pin$Live[which(pin$Parameter == "c14_kl3")])
  
  

  
  
  am_curr$oap34 = exp(pin$Live[which(pin$Parameter == "c8_cons")] +
                        pin$Live[which(pin$Parameter == "c8_sex")] * am_curr$female +
                        pin$Live[which(pin$Parameter == "c8_age3")] * am_curr$age5564 +
                        pin$Live[which(pin$Parameter == "c8_age4")] * am_curr$age6574 +
                        pin$Live[which(pin$Parameter == "c8_age5")] * am_curr$age75 +
                        pin$Live[which(pin$Parameter == "c8_bmi0")] * am_curr$bmi024 +
                        pin$Live[which(pin$Parameter == "c8_bmi1")] * am_curr$bmi2529 +
                        pin$Live[which(pin$Parameter == "c8_bmi2")] * am_curr$bmi3034 +
                        pin$Live[which(pin$Parameter == "c8_bmi3")] * am_curr$bmi3539 +
                        pin$Live[which(pin$Parameter == "c8_bmi4")] * am_curr$bmi40)
  
  am_curr$oap34 = am_curr$kl3 * am_curr$oap34  #% only have a progression probability if already have KL3
  am_curr$oap34 = (1 - am_curr$dead)* am_curr$oap34  #% only have an progression probability if not dead
  am_curr$oap34 =  am_curr$oap34 / (1+am_curr$oap34)  #% logistic 
  am_curr$oap34 = (1+am_curr$oap34) ^ 0.25 - 1  #% OAI analysis is over 4 years - need to reduce to annual
  
  oap34_rand <- runif(nrow(am_curr),0,1)
  am_curr$oap34 <- ifelse(am_curr$oap34 > oai_rand,1,0)
  
  am_curr$d_sf6d <- am_curr$d_sf6d + (am_curr$oap34 * pin$Live[which(pin$Parameter == "c14_kl4")])
  
  # am_new.kl_score = 2.*am_new.kl2 + 3.*am_new.kl3 + 4.*am_new.kl4;
  
  return(am_curr)
  
}