#' Run a Single Microsimulation Cycle
#'
#' This is the main function that drives the microsimulation for a single year (cycle).
#' It orchestrates the updates for BMI, osteoarthritis, comorbidities, TKA,
#' mortality, and other individual attributes.
#'
#' @param am_curr A data.frame representing the attribute matrix for the current
#'   cycle (time `t`).
#' @param cycle.coefficents A list or data.frame of all model coefficients for
#'   the cycle.
#' @param am_new A data.frame representing the attribute matrix for the next
#'   cycle (time `t+1`), which will be populated by this function.
#' @param age_edges A numeric vector defining the break points for age categories.
#' @param bmi_edges A numeric vector defining the break points for BMI categories.
#' @param am A data.frame, presumably the full attribute matrix (used for mortality).
#'   Note: The usage of this parameter seems unusual and might need review.
#' @param mort_update_counter A counter variable for the mortality loop.
#'   Note: The usage of this parameter seems unusual and might need review.
#' @param lt A data.frame representing the life table used for mortality calculations.
#' @param eq_cust A list of data.frames containing customisation factors for
#'   the model equations (BMI, TKR, OA).
#'
#' @return A list containing three elements:
#'   \item{am_curr}{The `am_curr` data.frame with intermediate calculations.}
#'   \item{am_new}{The fully updated `am_new` data.frame for the next cycle.}
#'   \item{summ_tka_risk}{A summary data.frame of TKA risk calculations.}
#' @importFrom stats runif
#' @export
simulation_cycle_fcn <- function(am_curr, cycle.coefficents, am_new,
                                 age_edges, bmi_edges,
                                 am,
                                 mort_update_counter, lt,
                                 eq_cust, tka_time_trend) {

  # Unpack the 'live' value from each coefficient
  live_coeffs <- lapply(cycle.coefficents, function(x) {
    if (is.list(x) && "live" %in% names(x)) {
      return(x$live)
    } else if (is.list(x)) {
      # Handle nested lists of coefficients
      return(lapply(x, function(y) {
        if (is.list(y) && "live" %in% names(y)) {
          return(y$live)
        }
        return(y)
      }))
    }
    return(x)
  })
  
  # extract relevant equation modification data
  BMI_cust <- eq_cust[["BMI"]]
  TKR_cust <- eq_cust[["TKR"]]
  OA_cust <- eq_cust[["OA"]]

  ############################## update BMI in cycle
  am_curr <- bmi_mod_fcn(am_curr, live_coeffs, BMI_cust)


  # am_new.bmi = am_curr.bmi + d_bmi;
  # update BMI data using delta
  am_new$bmi <- am_curr$bmi + am_curr$d_bmi

  # add impact of BMI delta to SF6D
  am_curr$d_sf6d <- am_curr$d_sf6d + (am_curr$d_bmi * live_coeffs$c14$c14_bmi)

  ############################## update personal charactistics (agecat, bmicat)
  # These need to be calculated on am_curr before being passed to OA and TKA functions
  
  am_curr$age_cat <- cut(am_curr$age, breaks = age_edges, include.lowest = TRUE)
  am_curr$age044 <- ifelse(am_curr$age_cat == levels(am_curr$age_cat)[1], 1, 0)
  am_curr$age4554 <- ifelse(am_curr$age_cat == levels(am_curr$age_cat)[2], 1, 0)
  am_curr$age5564 <- ifelse(am_curr$age_cat == levels(am_curr$age_cat)[3], 1, 0)
  am_curr$age6574 <- ifelse(am_curr$age_cat == levels(am_curr$age_cat)[4], 1, 0)
  am_curr$age75 <- ifelse(am_curr$age_cat == levels(am_curr$age_cat)[5], 1, 0)

  am_curr$bmi_cat <- cut(am_curr$bmi, breaks = bmi_edges, include.lowest = TRUE)
  am_curr$bmi024 <- ifelse(am_curr$bmi_cat == levels(am_curr$bmi_cat)[1], 1, 0)
  am_curr$bmi2529 <- ifelse(am_curr$bmi_cat == levels(am_curr$bmi_cat)[2], 1, 0)
  am_curr$bmi3034 <- ifelse(am_curr$bmi_cat == levels(am_curr$bmi_cat)[3], 1, 0)
  am_curr$bmi3539 <- ifelse(am_curr$bmi_cat == levels(am_curr$bmi_cat)[4], 1, 0)
  am_curr$bmi40 <- ifelse(am_curr$bmi_cat == levels(am_curr$bmi_cat)[5], 1, 0)

  ############################## update OA incidence

  # % OA incidence - based on HILDA analysis

  OA_update_data <- OA_update(am_curr, am_new, live_coeffs, OA_cust)

  # extract data.tables from output list
  am_curr <- OA_update_data[["am_curr"]]
  am_new <- OA_update_data[["am_new"]]

  # note: change in sf6d calculated in the OA_update function


  ############################## update comorbidies (cci, mental health)

  # % Comorbidities
  am_curr <- update_comorbidities(am_curr, live_coeffs$comorbidities)

  # Initialize PROs columns before TKA function, as they are used as predictors
  # Note: This is a temporary fix. The simulation logic should be reviewed
  # to ensure PROs are updated at the correct point in the cycle.
  if (!"pain" %in% names(am_curr)) am_curr$pain <- 0
  if (!"function_score" %in% names(am_curr)) am_curr$function_score <- 0


  ############################## update TKA status (TKA, complications, revision, inpatient rehab)
  # % TKA

  TKA_update_data <- tryCatch(
    {
      TKA_update_fcn(am_curr, am_new, live_coeffs, TKR_cust, NULL)
    },
    error = function(e) {
      list(am_curr = am_curr, am_new = am_new, summ_tka_risk = data.frame())
    }
  )

  # extract data.tables from output list
  am_curr <- TKA_update_data[["am_curr"]]
  am_new <- TKA_update_data[["am_new"]]

  summ_tka_risk <- TKA_update_data[["summ_tka_risk"]]

  # % TKA complication


  # % TKA complication
  am_curr$compi <- live_coeffs$c16$c16_cons +
    live_coeffs$c16$c16_male * am_curr$male +
    live_coeffs$c16$c16_ccount * am_curr$ccount +
    live_coeffs$c16$c16_bmi3 * am_curr$bmi3539 +
    live_coeffs$c16$c16_bmi4 * am_curr$bmi40 +
    live_coeffs$c16$c16_mhc * am_curr$mhc +
    live_coeffs$c16$c16_age3 * am_curr$age5564 +
    live_coeffs$c16$c16_age4 * am_curr$age6574 +
    live_coeffs$c16$c16_age5 * am_curr$age75 +
    live_coeffs$c16$c16_sf6d * am_curr$sf6d +
    live_coeffs$c16$c16_kl3 * am_curr$kl3 +
    live_coeffs$c16$c16_kl4 * am_curr$kl4

  am_curr$compi <- exp(am_curr$compi)
  am_curr$compi <- am_curr$compi / (1 + am_curr$compi)
  am_curr$compi <- am_curr$compi * am_new$tka # % only have complication if have TKA
  am_curr$compi <- (1 - am_curr$dead) * am_curr$compi # ; % only alive have complication

  compi_rand <- runif(nrow(am_curr), 0, 1)
  am_curr$compi <- ifelse(am_curr$compi > compi_rand, 1, 0)


  am_new$comp <- am_curr$compi


  # % TKA inpatient rehabiliation

  am_curr$ir <- live_coeffs$c17$c17_cons +
    live_coeffs$c17$c17_male * am_curr$male +
    live_coeffs$c17$c17_ccount * am_curr$ccount +
    live_coeffs$c17$c17_bmi3 * am_curr$bmi3539 +
    live_coeffs$c17$c17_bmi4 * am_curr$bmi40 +
    live_coeffs$c17$c17_mhc * am_curr$mhc +
    live_coeffs$c17$c17_age3 * am_curr$age5564 +
    live_coeffs$c17$c17_age4 * am_curr$age6574 +
    live_coeffs$c17$c17_age5 * am_curr$age75 +
    live_coeffs$c17$c17_sf6d * am_curr$sf6d +
    live_coeffs$c17$c17_kl3 * am_curr$kl3 +
    live_coeffs$c17$c17_kl4 * am_curr$kl4 +
    live_coeffs$c17$c17_comp * am_curr$comp

  am_curr$ir <- exp(am_curr$ir)
  am_curr$ir <- am_curr$ir / (1 + am_curr$ir)
  am_curr$ir <- am_curr$ir * am_new$tka # ; % only have rehab if have TKA
  am_curr$ir <- (1 - am_curr$dead) * am_curr$ir # ; % only alive have rehab

  ir_rand <- runif(nrow(am_curr), 0, 1)
  am_curr$ir <- ifelse(am_curr$ir > ir_rand, 1, 0)
  am_new$ir <- am_curr$ir

  # TKA revision
  am_new <- calculate_revision_risk_fcn(am_new, live_coeffs$revision_model)
  
  am_curr$d_sf6d <- am_curr$d_sf6d + am_new$revi * live_coeffs$utilities$c14_rev


  # % HRQOL progression or prediction (tbc)
  am_curr <- calculate_qaly(am_curr, live_coeffs$utilities)
  am_new$sf6d <- am_curr$sf6d + am_curr$d_sf6d


  ############################## Update PROs for the cycle
  am_new <- update_pros_fcn(am_new, live_coeffs)


  ############################## Calculate Costs for the cycle
  am_new <- calculate_costs_fcn(am_new, live_coeffs$costs)



  ############################## Determine mortality in the cycle

  # % Mortality




  for (mort_update_counter in 1:nrow(am)) {
    am_curr$qx[mort_update_counter] <- lt$male_sep1_bmi0[am_curr$age[mort_update_counter]] * am_curr$male[mort_update_counter] +
      lt$female_sep1_bmi0[am_curr$age[mort_update_counter]] * (1 - am_curr$male[mort_update_counter])
  }

  # % Adjust mortality rate for BMI/SEP and implement


  am_curr$hr_mort <- 1 +
    am_curr$bmi2529 * live_coeffs$hr$hr_BMI_mort +
    am_curr$bmi3034 * live_coeffs$hr$hr_BMI_mort^2 +
    am_curr$bmi3539 * live_coeffs$hr$hr_BMI_mort^3 +
    am_curr$bmi40 * live_coeffs$hr$hr_BMI_mort^4

  am_curr$hr_mort <- am_curr$hr_mort * (1 - am_curr$year12) * live_coeffs$hr$hr_SEP_mort
  am_curr$qx <- am_curr$qx * am_curr$hr_mort
  am_curr$qx <- (1 - am_curr$dead) * am_curr$qx # only die once

  dead_rand <- runif(nrow(am_curr), 0, 1)
  am_curr$dead_rand <- ifelse(am_curr$qx > dead_rand, 1, 0)
  am_new$dead <- am_curr$dead + am_curr$dead_rand


  # zero SF6D for dead people
  am_new$sf6d <- (1 - am_new$dead) * am_new$sf6d

  ############################## Update age and QALYs at end of cycle

  # % Age the cohort, so long as they are alive


  am_new$age <- am_curr$age + (1 * (1 - am_new$dead))
  am_new$age[am_new$age > 100] <- 100

  # % Update QALYs

  # NOTE: this is a running total of QALYs, not QALYs in the cycle
  am_new$qaly <- am_curr$qaly + am_curr$sf6d

  # bundle am_curr and am_new for export
  export_data <- list(
    am_curr = am_curr,
    am_new = am_new,
    summ_tka_risk = summ_tka_risk
  )

  return(export_data)
}