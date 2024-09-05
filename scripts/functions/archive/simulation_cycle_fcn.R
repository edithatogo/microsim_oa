# goal: top level simulation function for the OA model
# note: version 1, largely replicating the original matlab code by C. Schilling


simulation_cycle_fcn <- function(am_curr, cycle.coefficents, am_new,
                                 age_edges, bmi_edges,
                                 am,
                                 mort_update_counter, lt,
                                 eq_cust) {
  

  # extract relevant equation modification data
  BMI_cust <- eq_cust[["BMI"]]
  TKR_cust <- eq_cust[["TKR"]]
  OA_cust <- eq_cust[["OA"]]
  
  ############################## update BMI in cycle 
  am_curr <- BMI_mod_fcn(am_curr, cycle.coefficents, BMI_cust)
  
  
  # am_new.bmi = am_curr.bmi + d_bmi;
  # update BMI data using delta
  am_new$bmi <- am_curr$bmi + am_curr$d_bmi
  #max(d_bmi)
  log_print("Summary of change in BMI", console = FALSE)
  log_print(summary(am_curr$d_bmi), console = FALSE, hide_notes = TRUE)
  
  # d_sf6d = d_sf6d + d_bmi.*pin.c14_bmi;
  # add impact of BMI delta to SF6D
  am_curr$d_sf6d <- am_curr$d_sf6d + (am_curr$d_bmi * cycle.coefficents$c14_bmi)
  
  log_print("Summary of change in sf6d - BMI", console = FALSE, hide_notes = TRUE)
  log_print(summary(am_curr$d_sf6d), console = FALSE, hide_notes = TRUE)
  
  ############################## update OA incidence 
  
  # % OA incidence - based on HILDA analysis
  # oai = exp(pin.c6_cons + pin.c6_year12.*am_curr.year12 + pin.c6_sex.*am_curr.female + ...
  #           pin.c6_age1.* am_curr.age044 + pin.c6_age2.*am_curr.age4554 + pin.c6_age3.*am_curr.age5564 + pin.c6_age4.*am_curr.age6574 + pin.c6_age5.*am_curr.age75 + ...
  #           pin.c6_bmi0.*am_curr.bmi024 + pin.c6_bmi1.*am_curr.bmi2529 + pin.c6_bmi2.*am_curr.bmi3034 + pin.c6_bmi3.*am_curr.bmi3539 + pin.c6_bmi4.*am_curr.bmi40);
  # oai = (1 - am_curr.oa).*oai;  #% only have an initialisation probability if don't already have OA
  # oai = (1 - am_curr.dead).*oai;  #% only have an initialisation probability if not dead
  # oai =  oai./(1+oai);  % logistic 
  # oai = (1+oai).^0.25 - 1;  % HILDA analysis is over 4 years - need to reduce to annual
  # am_curr.oai = oai;
  # oai_rows = am_curr.oai > rand(n,1);
  # am_new.oa = oai_rows + am_curr.oa;
  # am_new.kl2 = oai_rows + am_curr.kl2;
  # d_sf6d = d_sf6d + oai_rows*pin.c14_kl2;
  
  OA_update_data <- OA_update(am_curr,am_new, cycle.coefficents, OA_cust)
  
  # extract data.tables from output list
  am_curr <- OA_update_data[["am_curr"]]
  am_new <- OA_update_data[["am_new"]]
  
  # note: change in sf6d calculated in the OA_update function
  log_print("Summary of change in sf6d - OA_update", console = FALSE, hide_notes = TRUE)
  log_print(summary(am_curr$d_sf6d), console = FALSE, hide_notes = TRUE)
  
  ############################## update personal charactistics (agecat, bmicat)
  
  # % Update groupings for categorising output
  # age_cat = discretize(am_new.age, age_edges);
  # am_new.age_cat = age_cat;
  # am_new.age044 = am_new.age_cat == 1;
  # am_new.age4554 = am_new.age_cat == 2;
  # am_new.age5564 = am_new.age_cat == 3;
  # am_new.age6574 = am_new.age_cat == 4;
  # am_new.age75 = am_new.age_cat == 5;
  
  am_new$age_cat <- cut(am_new$age, breaks = age_edges, include.lowest = TRUE)
  
  am_new$age044 <- ifelse(am_new$age_cat == levels(am_new$age_cat)[1],1,0)
  am_new$age4554 <- ifelse(am_new$age_cat == levels(am_new$age_cat)[2],1,0)
  am_new$age5564 <- ifelse(am_new$age_cat == levels(am_new$age_cat)[3],1,0)
  am_new$age6574 <- ifelse(am_new$age_cat == levels(am_new$age_cat)[4],1,0)
  am_new$age75 <- ifelse(am_new$age_cat == levels(am_new$age_cat)[5],1,0)
  
  # bmi_cat = discretize(am_new.bmi,bmi_edges);
  # am_new.bmi_cat = bmi_cat;
  # am_new.bmi024 = am_new.bmi_cat == 1;
  # am_new.bmi2529 = am_new.bmi_cat == 2;
  # am_new.bmi3034 = am_new.bmi_cat == 3;
  # am_new.bmi3539 = am_new.bmi_cat == 4;
  # am_new.bmi40 = am_new.bmi_cat == 5;
  
  am_new$bmi_cat <- cut(am_new$bmi, breaks = bmi_edges, include.lowest = TRUE)
  
  am_new$bmi024 <- ifelse(am_new$bmi_cat == levels(am_new$bmi_cat)[1],1,0)
  am_new$bmi2529 <- ifelse(am_new$bmi_cat == levels(am_new$bmi_cat)[2],1,0)
  am_new$bmi3034 <- ifelse(am_new$bmi_cat == levels(am_new$bmi_cat)[3],1,0)
  am_new$bmi3539 <- ifelse(am_new$bmi_cat == levels(am_new$bmi_cat)[4],1,0)
  am_new$bmi40 <- ifelse(am_new$bmi_cat == levels(am_new$bmi_cat)[5],1,0)
  
  
  ############################## update comorbidies (cci, mental health)
  
  # % Comorbidities
  
  # cci = pin.c10_1.*am_curr.age4554 + pin.c10_2.*am_curr.age4554 + pin.c10_3.*am_curr.age5564 + pin.c10_4.*am_curr.age6574 + pin.c10_5.*am_curr.age75;   
  # cci = (1 - am_curr.dead).* cci;
  # am_curr.cci = cci;
  # cci_rows = am_curr.cci > rand(n,1);
  # am_new.ccount = cci_rows + am_curr.ccount;
  # d_sf6d = d_sf6d + cci_rows*pin.c14_ccount;
  
  am_curr$cci <- cycle.coefficents$c10_1 * am_curr$age4554 +
    cycle.coefficents$c10_2 * am_curr$age4554 +
    cycle.coefficents$c10_3 * am_curr$age5564 +
    cycle.coefficents$c10_4 * am_curr$age6574 +
    cycle.coefficents$c10_5 * am_curr$age75 
  
  am_curr$cci = (1 - am_curr$dead) * am_curr$cci;
  cci_rand <- runif(nrow(am_curr),0,1)
  am_curr$cci <- ifelse(am_curr$cci > cci_rand,1,0)
  am_new$ccount <- cci_rand + am_curr$ccount;
  
  am_curr$d_sf6d <- am_curr$d_sf6d + (am_curr$cci * cycle.coefficents$c14_ccount)
  
  log_print("Number of new comorbidity cases", console = FALSE, hide_notes = TRUE)
  log_print(sum(am_curr$cci), console = FALSE, hide_notes = TRUE)
  log_print("Summary of change in sf6d - CCI", console = FALSE, hide_notes = TRUE)
  log_print(summary(am_curr$d_sf6d), console = FALSE, hide_notes = TRUE)
  
  # % Mental health condition
  # mhci = pin.c12_male.*am_curr.male + pin.c12_female.*am_curr.female;
  # am_curr.mhci = mhci;
  # mhci_rows = am_curr.mhci > rand(n,1);
  # am_new.mhc = am_curr.mhc + mhci_rows;
  # d_sf6d = d_sf6d + mhci_rows*pin.c14_mhc;
  
  am_curr$mhci <- cycle.coefficents$c12_male * am_curr$male +
    cycle.coefficents$c12_female * am_curr$female
  
  # note death exception excluded from Chris' code, check if this was intention
  # am_curr$mhci <- (1 - am_curr$dead) * am_curr$mhci;
  mhci_rand <- runif(nrow(am_curr),0,1)
  am_curr$mhci <- ifelse(am_curr$mhci > mhci_rand,1,0)
  am_new$mhc <- mhci_rand + am_curr$mhc;
  am_curr$d_sf6d <- am_curr$d_sf6d + (am_curr$mhci * cycle.coefficents$c14_mhc)
  
  log_print("Summary of change in sf6d - Mental health", console = FALSE, hide_notes = TRUE)
  log_print(summary(am_curr$d_sf6d), console = FALSE, hide_notes = TRUE)
  
  ############################## update TKA status (TKA, complications, revision, inpatient rehab)
  # % TKA
  # tkai = pin.c9_age.*am_curr.age + pin.c9_age2.*am_curr.age.*am_curr.age + pin.c9_drugoa.*am_curr.drugoa + pin.c9_ccount.*am_curr.ccount ...
  # + pin.c9_mhc.*am_curr.mhc + pin.c9_tkr.*am_curr.tka1;
  # tkai = -exp(tkai).*pin.c9_cons;
  # tkai = 1-exp(tkai);
  # tkai = ((1+tkai).^0.2)-1; #% Sharm's paper is 5 year risk - reduce to annual   
  

  TKA_update_data <- TKA_update_fcn(am_curr,am_new, cycle.coefficents, TKR_cust)
  
  # extract data.tables from output list
  am_curr <- TKA_update_data[["am_curr"]]
  am_new <- TKA_update_data[["am_new"]]
  
  summ_tka_risk <- TKA_update_data[["summ_tka_risk"]]
  
  # % TKA complication
  # compi = pin.c16_cons + pin.c16_male.*am_curr.male + pin.c16_ccount.*am_curr.ccount + pin.c16_bmi3.*am_curr.bmi3539 + pin.c16_bmi4.*am_curr.bmi40 + pin.c16_mhc.*am_curr.mhc + pin.c16_age3.*am_curr.age5564 + pin.c16_age4.*am_curr.age6574 + pin.c16_age5.*am_curr.age75 + pin.c16_sf6d.*am_curr.sf6d + pin.c16_kl3.*am_curr.kl3 + pin.c16_kl4.*am_curr.kl4;
  # compi = exp(compi);
  # compi = compi./(1+compi);
  # compi = compi.*am_new.tka; % only have complication if have TKA
  # compi = (1-am_curr.dead).*compi; % only alive have complication
  # am_curr.comp = compi;
  # compi_rows = am_curr.comp > rand(n,1);
  # am_new.comp = compi_rows;
  
  #% TKA complication
  am_curr$compi <- cycle.coefficents$c16_cons +
    cycle.coefficents$c16_male * am_curr$male +
    cycle.coefficents$c16_ccount * am_curr$ccount +
    cycle.coefficents$c16_bmi3 * am_curr$bmi3539 +
    cycle.coefficents$c16_bmi4 * am_curr$bmi40 +
    cycle.coefficents$c16_mhc * am_curr$mhc +
    cycle.coefficents$c16_age3 * am_curr$age5564 +
    cycle.coefficents$c16_age4 * am_curr$age6574 +
    cycle.coefficents$c16_age5 * am_curr$age75 +
    cycle.coefficents$c16_sf6d * am_curr$sf6d +
    cycle.coefficents$c16_kl3 * am_curr$kl3 +
    cycle.coefficents$c16_kl4 * am_curr$kl4
  
  am_curr$compi <- exp(am_curr$compi)
  am_curr$compi <-  am_curr$compi / (1+ am_curr$compi)
  am_curr$compi <-  am_curr$compi * am_new$tka # % only have complication if have TKA
  am_curr$compi <- (1-am_curr$dead) * am_curr$compi #; % only alive have complication
  
  compi_rand <- runif(nrow(am_curr),0,1)
  am_curr$compi <- ifelse(am_curr$compi > compi_rand,1,0)
  
  ##### note name of following variable is different 'comp' vs 'compi'
  am_new$comp <- am_curr$compi
  
  # NOTE: No impact on SF6D here. Likely due to insufficent data, but should be noted.
  
  # % TKA inpatient rehabiliation 
  # ir = pin.c17_cons + pin.c17_male.*am_curr.male + pin.c17_ccount.*am_curr.ccount + pin.c17_bmi3.*am_curr.bmi3539 + pin.c17_bmi4.*am_curr.bmi40 + pin.c17_mhc.*am_curr.mhc + pin.c17_age3.*am_curr.age5564 + pin.c17_age4.*am_curr.age6574 + pin.c17_age5.*am_curr.age75 + pin.c17_sf6d.*am_curr.sf6d + pin.c17_kl3.*am_curr.kl3 + pin.c17_kl4.*am_curr.kl4 + pin.c17_comp.*am_curr.comp;
  # ir = exp(ir);
  # ir = ir./(1+ir);
  # ir = ir.*am_new.tka; % only have rehab if have TKA
  # ir = (1-am_curr.dead).*ir; % only alive have rehab
  # am_curr.ir = ir;
  # ir_rows = am_curr.ir > rand(n,1);
  # am_new.ir = ir_rows;
  
  am_curr$ir <- cycle.coefficents$c17_cons +
    cycle.coefficents$c17_male * am_curr$male +
    cycle.coefficents$c17_ccount * am_curr$ccount +
    cycle.coefficents$c17_bmi3 * am_curr$bmi3539 +
    cycle.coefficents$c17_bmi4 * am_curr$bmi40 +
    cycle.coefficents$c17_mhc * am_curr$mhc +
    cycle.coefficents$c17_age3 * am_curr$age5564 +
    cycle.coefficents$c17_age4 * am_curr$age6574 +
    cycle.coefficents$c17_age5 * am_curr$age75 +
    cycle.coefficents$c17_sf6d * am_curr$sf6d +
    cycle.coefficents$c17_kl3 * am_curr$kl3 +
    cycle.coefficents$c17_kl4 * am_curr$kl4 +
    cycle.coefficents$c17_comp * am_curr$comp
  
  am_curr$ir <- exp(am_curr$ir)
  am_curr$ir <- am_curr$ir / (1+am_curr$ir)
  am_curr$ir <- am_curr$ir * am_new$tka #; % only have rehab if have TKA
  am_curr$ir <- (1-am_curr$dead) * am_curr$ir #; % only alive have rehab
  
  ir_rand <- runif(nrow(am_curr),0,1)
  am_curr$ir <- ifelse(am_curr$ir > ir_rand,1,0)
  am_new$ir <- am_curr$ir
  
  # % TKA Revision
  # rev_lambda = exp(pin.c13_const + pin.c13_male.*am_curr.male + pin.c13_bmi2.*am_curr.bmi3034 + pin.c13_bmi3.*am_curr.bmi3539 + pin.c13_bmi4.*am_curr.bmi40);
  # rev_gamma = exp(pin.c13_gamma);
  # revi = 1-exp(rev_lambda.*((am_curr.agetka1-1).^rev_gamma - am_curr.agetka1.^rev_gamma));
  # revi = (1-am_curr.dead).*revi; % only alive have revision
  # revi = am_curr.tka1.*revi; % only revision if have TKA
  # revi = (1-am_curr.rev1).* revi; % only allow one revision (at this stage)
  # am_curr.revi = revi;
  # revi_rows = am_curr.revi > rand(n,1);
  # am_new.rev = revi_rows;
  # am_new.rev1 = am_new.rev1 + revi_rows;
  # am_new.agetka1 = am_new.agetka1.*(1-revi_rows);
  # d_sf6d = d_sf6d + revi_rows.*pin.c14_rev;
  
  am_curr$rev_lambda <- exp(cycle.coefficents$c13_const +
                              cycle.coefficents$c13_male *am_curr$male +
                              cycle.coefficents$c13_bmi2 *am_curr$bmi3034 +
                              cycle.coefficents$c13_bmi3 *am_curr$bmi3539 +
                              cycle.coefficents$c13_bmi4 *am_curr$bmi40)
  
  am_curr$rev_gamma <- exp(cycle.coefficents$c13_gamma)
  
  # goal of the second section of this appears to be to get the risk of revision assocated with the most
  # year post surgery. This is done by getting the scaling factor for time t and t-1 and then subtracting the two.
  # this is them multiplied by lambda to get the risk of revision at time t.
  am_curr$revi <- 1-exp(am_curr$rev_lambda * ((am_curr$agetka1-1) ^ am_curr$rev_gamma - am_curr$agetka1 ^ am_curr$rev_gamma))
  
  # for individals where the agetka1 = 0 the above equation isn't assessable and returns a NaN.
  # as the risk of revision in these individuals is 0 we set all NaN to 0.
  am_curr$revi <- ifelse(is.nan(am_curr$revi),0,am_curr$revi)
  
  am_curr$revi <- (1 - am_curr$dead) * am_curr$revi #; % only alive have revision
  am_curr$revi <- am_curr$tka1 * am_curr$revi # % only revision if have TKA
  am_curr$revi <- (1 - am_curr$rev1) * am_curr$revi # % only allow one revision (at this stage)
  
  revi_rand <- runif(nrow(am_curr),0,1)
  am_curr$revi <- ifelse(am_curr$revi > revi_rand,1,0)
  am_new$rev <- am_curr$revi
  am_new$rev1 <- am_new$rev1 + am_curr$revi
  
  am_new$agetka1 <- am_new$agetka1 * (1 - am_curr$revi)
  
  am_curr$d_sf6d <- am_curr$d_sf6d + am_curr$revi * cycle.coefficents$c14_rev
  
  log_print("Summary of change in sf6d - revision", console = FALSE, hide_notes = TRUE)
  log_print(summary(am_curr$d_sf6d), console = FALSE, hide_notes = TRUE)
  
  # % HRQOL progression or prediction (tbc)
  # am_new.sf6d = am_curr.sf6d + d_sf6d;
  
  am_new$sf6d <- am_curr$sf6d + am_curr$d_sf6d
  
  log_print("Summary of overall change in sf6d", console = FALSE, hide_notes = TRUE)
  log_print(summary(am_curr$d_sf6d), console = FALSE, hide_notes = TRUE)
  
  # % Adjust mortality rate for BMI/SEP and implement
  # hr_mort = 1 + am_curr.bmi2529.*pin.hr_BMI_mort + am_curr.bmi3034.*pin.hr_BMI_mort^2 + ...
  # am_curr.bmi3539.*pin.hr_BMI_mort^3 + am_curr.bmi40.*pin.hr_BMI_mort^4; 
  # hr_mort = hr_mort.*(1-am_curr.year12).*pin.hr_SEP_mort;
  # qx = qx.*hr_mort;
  # qx = (1 - am_curr.dead).*qx; % only die once
  # am_curr.qx = qx;
  # dead_rows = am_curr.qx > rand(n,1);
  # am_new.dead = am_curr.dead + dead_rows; 
  # am_new.sf6d = (1-am_new.dead).*am_new.sf6d;
  
  
  ############################## Determine mortality in the cycle
  
  # % Mortality
  # qx(j) = lt.male_sep1_bmi0(am_curr.age(j)).*am_curr.male(j) + ...
  # lt.female_sep1_bmi0(am_curr.age(j)).*(1-am_curr.male(j));
  # end
  
  
  
  for(mort_update_counter in 1:nrow(am)){
    
    am_curr$qx[mort_update_counter] <- lt$male_sep1_bmi0[am_curr$age[mort_update_counter]] * am_curr$male[mort_update_counter] +
      lt$female_sep1_bmi0[am_curr$age[mort_update_counter]] * (1-am_curr$male[mort_update_counter])
  }
  
  # % Adjust mortality rate for BMI/SEP and implement
  # hr_mort = 1 + am_curr.bmi2529.*pin.hr_BMI_mort + am_curr.bmi3034.*pin.hr_BMI_mort^2 + ...
  # am_curr.bmi3539.*pin.hr_BMI_mort^3 + am_curr.bmi40.*pin.hr_BMI_mort^4; 
  # hr_mort = hr_mort.*(1-am_curr.year12).*pin.hr_SEP_mort;
  # qx = qx.*hr_mort;
  # qx = (1 - am_curr.dead).*qx; % only die once
  # am_curr.qx = qx;
  # dead_rows = am_curr.qx > rand(n,1);
  # am_new.dead = am_curr.dead + dead_rows; 
  # am_new.sf6d = (1-am_new.dead).*am_new.sf6d;
  
  am_curr$hr_mort <- 1 +
    am_curr$bmi2529 * cycle.coefficents$hr_BMI_mort +
    am_curr$bmi3034 * cycle.coefficents$hr_BMI_mort ^ 2 +
    am_curr$bmi3539 * cycle.coefficents$hr_BMI_mort ^ 3 +
    am_curr$bmi40 * cycle.coefficents$hr_BMI_mort ^ 4
  
  am_curr$hr_mort <- am_curr$hr_mort *(1-am_curr$year12) * cycle.coefficents$hr_SEP_mort
  am_curr$qx <- am_curr$qx * am_curr$hr_mort 
  am_curr$qx <- (1 - am_curr$dead) * am_curr$qx #only die once
  
  dead_rand <- runif(nrow(am_curr),0,1)
  am_curr$dead_rand <- ifelse(am_curr$qx > dead_rand,1,0)
  am_new$dead <- am_curr$dead + am_curr$dead_rand

  log_print("Count of deaths in cycle", console = FALSE, hide_notes = TRUE)
  log_print(sum(am_curr$dead_rand), console = FALSE, hide_notes = TRUE)

  # zero SF6D for dead people 
  am_new$sf6d <- (1-am_new$dead) * am_new$sf6d
  
  ############################## Update age and QALYs at end of cycle
  
  # % Age the cohort, so long as they are alive
  #am_new.age = min(am_curr.age + 1.*(1-am_new.dead),100);
  
  am_new$age <- am_curr$age + (1 *(1-am_new$dead))
  am_new$age <- ifelse(am_curr$age >= 100, 100, am_new$age)                           

  # % Update QALYs
  # am_new.qaly = am_curr.qaly + am_new.sf6d;
  
  # NOTE: this is a running total of QALYs, not QALYs in the cycle
  am_new$qaly <- am_curr$qaly + am_curr$sf6d
  
  
  log_print("Sum of QALYs within simulation.", console = FALSE, hide_notes = TRUE)
  log_print(sum(am_new$qaly), console = FALSE, hide_notes = TRUE)
  
  # bundle am_curr and am_new for export
  export_data <- list(am_curr = am_curr,
                      am_new = am_new,
                      summ_tka_risk = summ_tka_risk)
  
  return(export_data)
  
  
}