#' Update BMI for one cycle (Optimized with data.table)
#'
#' This function updates the Body Mass Index (BMI) for each individual in the
#' attribute matrix for a single simulation cycle. This version is optimized
#' for performance using the data.table package.
#'
#' @param am_curr A data.table representing the attribute matrix for the current
#'   cycle.
#' @param cycle.coefficents A list containing the regression coefficients.
#' @param BMI_cust A data.frame containing calibration factors.
#'
#' @return The updated attribute matrix (am_curr) with a new 'd_bmi' column.
#' @export
library(data.table)

BMI_mod_fcn <- function(am_curr, cycle.coefficents, BMI_cust) {
  
  # Ensure am_curr is a data.table
  if (!is.data.table(am_curr)) {
    setDT(am_curr)
  }
  
  # --- Pre-calculate BMI components ---
  am_curr[, BMI_under30 := ifelse(bmi <= 30, bmi, 30)]
  am_curr[, BMI_over30 := ifelse(bmi > 30, bmi - 30, 0)]
  
  # --- Vectorized BMI Progression Calculation ---
  
  # Initialize d_bmi
  am_curr[, d_bmi := 0.0]
  
  # Create logical indices for each population segment
  is_male_under50 <- am_curr$sex == "[1] Male" & am_curr$age < 50
  is_male_over50 <- am_curr$sex == "[1] Male" & am_curr$age >= 50
  is_female_under50 <- am_curr$sex == "[2] Female" & am_curr$age < 50
  is_female_over50_highSES <- am_curr$sex == "[2] Female" & am_curr$age >= 50 & am_curr$year12 == 1
  is_female_over50_lowSES <- am_curr$sex == "[2] Female" & am_curr$age >= 50 & am_curr$year12 == 0
  
  # Get calibration factors once
  calib_c1 <- as.numeric(BMI_cust$proportion_reduction[BMI_cust$covariate_set == "c1"])
  calib_c2 <- as.numeric(BMI_cust$proportion_reduction[BMI_cust$covariate_set == "c2"])
  calib_c3 <- as.numeric(BMI_cust$proportion_reduction[BMI_cust$covariate_set == "c3"])
  calib_c4 <- as.numeric(BMI_cust$proportion_reduction[BMI_cust$covariate_set == "c4"])
  calib_c5 <- as.numeric(BMI_cust$proportion_reduction[BMI_cust$covariate_set == "c5"])
  
  # Apply calculations to each segment using the logical indices
  am_curr[is_male_under50, d_bmi := (
    cycle.coefficents$c1_cons +
      cycle.coefficents$c1_year12 * year12 +
      cycle.coefficents$c1_age * age +
      cycle.coefficents$c1_bmi * bmi
  ) * calib_c1]
  
  am_curr[is_male_over50, d_bmi := (
    cycle.coefficents$c2_cons +
      cycle.coefficents$c2_year12 * year12 +
      cycle.coefficents$c2_age * age +
      cycle.coefficents$c2_bmi * bmi
  ) * calib_c2]
  
  am_curr[is_female_under50, d_bmi := (
    cycle.coefficents$c3_cons +
      cycle.coefficents$c3_age * age +
      cycle.coefficents$c3_bmi_low * BMI_under30 +
      cycle.coefficents$c3_bmi_high * BMI_over30
  ) * calib_c3]
  
  am_curr[is_female_over50_highSES, d_bmi := (
    cycle.coefficents$c4_cons +
      cycle.coefficents$c4_age * age +
      cycle.coefficents$c4_bmi_low * BMI_under30 +
      cycle.coefficents$c4_bmi_high * BMI_over30
  ) * calib_c4]
  
  am_curr[is_female_over50_lowSES, d_bmi := (
    cycle.coefficents$c5_cons +
      cycle.coefficents$c5_age * age +
      cycle.coefficents$c5_bmi_low * BMI_under30 +
      cycle.coefficents$c5_bmi_high * BMI_over30
  ) * calib_c5]
  
  # --- Clean up temporary columns ---
  am_curr[, `:=`(BMI_under30 = NULL, BMI_over30 = NULL)]
  
  return(am_curr)
}