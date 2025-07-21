#' Update BMI for one cycle
#'
#' This function updates the Body Mass Index (BMI) for each individual in the
#' attribute matrix for a single simulation cycle. The update rules are based on
#' regression coefficients that differ by sex, age, and socioeconomic status.
#'
#' @param am_curr A data.frame or data.table representing the attribute matrix
#'   of the population for the current cycle. It must contain columns for 'bmi',
#'   'sex', 'age', and 'year12'.
#' @param cycle.coefficents A list or data.frame containing the regression
#'   coefficients for the BMI progression model.
#' @param BMI_cust A data.frame containing calibration factors to be applied
#'   to the BMI change.
#'
#' @return The updated attribute matrix (am_curr) with a new 'd_bmi' column
#'   representing the change in BMI for the cycle.
#' @export
#'
#' @examples
#' # This is a simplified example and will not run without the full model setup.
#' # am_sample <- data.frame(
#' #   bmi = 25,
#' #   sex = "[1] Male",
#' #   age = 45,
#' #   year12 = 1,
#' #   d_bmi = 0
#' # )
#' # coeffs <- list(c1_cons = 0.1, c1_year12 = -0.05, c1_age = 0.01, c1_bmi = 0.02)
#' # bmi_calib <- data.frame(covariate_set = "c1", proportion_reduction = 1.0)
#' # updated_am <- BMI_mod_fcn(am_sample, coeffs, bmi_calib)
BMI_mod_fcn <- function(am_curr, cycle.coefficents, BMI_cust) {
  # suppliment for coefficients https://www.ncbi.nlm.nih.gov/pmc/articles/PMC6475338/bin/bmjopen-2018-026525supp001.pdf
  # from Hayes A, Tan EJ, Killedar A, Lung T. Socioeconomic inequalities in obesity: modelling future trends in Australia. BMJ Open. 2019 Mar 30;9(3):e026525. doi: 10.1136/bmjopen-2018-026525. PMID: 30928953; PMCID: PMC6475338.

  # Calculation for females require BMI to be broken into the number 30 or below (BMI_under30) and the number over 30 (BMI_over30)
  # unsual way of calculating but how the eq was designed

  am_curr$BMI_under30 <- ifelse(am_curr$bmi <= 30, am_curr$bmi, 30)
  am_curr$BMI_over30 <- ifelse(am_curr$bmi > 30, am_curr$bmi - 30, 0)

  # BMI progression loop
  # males under 50

  am_curr$d_bmi <- ifelse(am_curr$sex == "[1] Male" & am_curr$age < 50,
    cycle.coefficents$c1_cons +
      cycle.coefficents$c1_year12 * am_curr$year12 +
      cycle.coefficents$c1_age * am_curr$age +
      cycle.coefficents$c1_bmi * am_curr$bmi,
    am_curr$d_bmi
  )

  # apply calibration effect
  am_curr$d_bmi <- ifelse(am_curr$sex == "[1] Male" & am_curr$age < 50,
    am_curr$d_bmi * as.numeric(BMI_cust$proportion_reduction[which(BMI_cust$covariate_set == "c1")]),
    am_curr$d_bmi
  )


  # males over 50
  am_curr$d_bmi <- ifelse(am_curr$sex == "[1] Male" & am_curr$age >= 50,
    cycle.coefficents$c2_cons +
      cycle.coefficents$c2_year12 * am_curr$year12 +
      cycle.coefficents$c2_age * am_curr$age +
      cycle.coefficents$c2_bmi * am_curr$bmi,
    am_curr$d_bmi
  )

  am_curr$d_bmi <- ifelse(am_curr$sex == "[1] Male" & am_curr$age >= 50,
    am_curr$d_bmi * as.numeric(BMI_cust$proportion_reduction[which(BMI_cust$covariate_set == "c2")]),
    am_curr$d_bmi
  )


  # women under 50
  am_curr$d_bmi <- ifelse(am_curr$sex == "[2] Female" & am_curr$age < 50,
    cycle.coefficents$c3_cons +
      cycle.coefficents$c3_age * am_curr$age +
      cycle.coefficents$c3_bmi_low * am_curr$BMI_under30 +
      cycle.coefficents$c3_bmi_high * am_curr$BMI_over30,
    am_curr$d_bmi
  )

  am_curr$d_bmi <- ifelse(am_curr$sex == "[2] Female" & am_curr$age < 50,
    am_curr$d_bmi * as.numeric(BMI_cust$proportion_reduction[which(BMI_cust$covariate_set == "c3")]),
    am_curr$d_bmi
  )

  # High SES women over 50
  am_curr$d_bmi <- ifelse(am_curr$sex == "[2] Female" & am_curr$age >= 50 & am_curr$year12 == 1,
    cycle.coefficents$c4_cons +
      cycle.coefficents$c4_age * am_curr$age +
      cycle.coefficents$c4_bmi_low * am_curr$BMI_under30 +
      cycle.coefficents$c4_bmi_high * am_curr$BMI_over30,
    am_curr$d_bmi
  )

  am_curr$d_bmi <- ifelse(am_curr$sex == "[2] Female" & am_curr$age >= 50 & am_curr$year12 == 1,
    am_curr$d_bmi * as.numeric(BMI_cust$proportion_reduction[which(BMI_cust$covariate_set == "c4")]),
    am_curr$d_bmi
  )

  # Low SES women over 50
  am_curr$d_bmi <- ifelse(am_curr$sex == "[2] Female" & am_curr$age >= 50 & am_curr$year12 == 0,
    cycle.coefficents$c5_cons +
      cycle.coefficents$c5_age * am_curr$age +
      cycle.coefficents$c5_bmi_low * am_curr$BMI_under30 +
      cycle.coefficents$c5_bmi_high * am_curr$BMI_over30,
    am_curr$d_bmi
  )

  am_curr$d_bmi <- ifelse(am_curr$sex == "[2] Female" & am_curr$age >= 50 & am_curr$year12 == 0,
    am_curr$d_bmi * as.numeric(BMI_cust$proportion_reduction[which(BMI_cust$covariate_set == "c5")]),
    am_curr$d_bmi
  )

  # remove the two BMI columns before reuturning the data
  am_curr$BMI_under30 <- NULL
  am_curr$BMI_over30 <- NULL

  return(am_curr)
}
