#' Update Total Knee Arthroplasty (TKA) Status (Version 2)
#'
#' This function models the probability of an individual undergoing a primary or
#' secondary Total Knee Arthroplasty (TKA) in a given cycle. It calculates an
#' initial risk based on individual characteristics and then adjusts this risk
#' based on secular trends for different age and sex groups.
#'
#' @param am_curr A data.frame representing the attribute matrix for the current
#'   cycle.
#' @param am_new A data.frame representing the attribute matrix for the next
#'   cycle, which will be updated by this function.
#' @param pin A data.frame of parameter inputs (not currently used in this
#'   version of the function, but may be kept for API consistency).
#' @param TKA_time_trend A data.frame containing the secular trend scaling
#'   factors for TKA risk by year, sex, and age group.
#' @param OA_cust A data.frame with customisation factors for OA coefficients,
#'   which are unusually applied to TKA coefficients here. This is flagged for
#'   review in the code.
#' @param cycle.coefficents A list or data.frame of model coefficients for the
#'   TKA initiation equation.
#'
#' @return A list containing three elements:
#'   \item{am_curr}{The `am_curr` data.frame with intermediate calculations.}
#'   \item{am_new}{The `am_new` data.frame with updated TKA status (`tka`, `tka1`,
#'   `tka2`, `agetka1`, `agetka2`).}
#'   \item{summ_tka_risk}{A placeholder value (currently `1`).}
#' @export
TKA_update_fcn <- function(am_curr,
                           am_new,
                           pin,
                           TKA_time_trend,
                           OA_cust,
                           TKR_cust,
                           cycle.coefficents) {

  # setup categorical variables
  am_curr$age_group_tka_adj <- cut(am_curr$age,
                                 breaks = c(0, 44, 54, 64, 74, 1000),
                                 labels = c("< 45", "45-54", "55-64", "65-74", "75+"))
  am_curr$sex_tka_adj <- ifelse(am_curr$sex == "[1] Male", "Males", "Females")

  # NOTE: The following section uses OA_cust to customize TKA coefficients.
  # This seems unusual. Flagging for review.
  cycle.coefficents$c9 <- apply_coefficient_customisations(cycle.coefficents$c9, TKR_cust, "c9", "c9")

  am_curr$tka_initiation_prob <- cycle.coefficents$c9$c9_cons +
    cycle.coefficents$c9$c9_age * am_curr$age +
    cycle.coefficents$c9$c9_age2 * (am_curr$age^2) +
    cycle.coefficents$c9$c9_drugoa * am_curr$drugoa +
    cycle.coefficents$c9$c9_ccount * am_curr$ccount +
    cycle.coefficents$c9$c9_mhc * am_curr$mhc +
    cycle.coefficents$c9$c9_tkr * am_curr$tka1 +
    cycle.coefficents$c9$c9_kl2hr * am_curr$kl2 +
    cycle.coefficents$c9$c9_kl3hr * am_curr$kl3 +
    cycle.coefficents$c9$c9_kl4hr * am_curr$kl4 +
    cycle.coefficents$c9$c9_pain * am_curr$pain +
    cycle.coefficents$c9$c9_function * am_curr$function_score

  # risk is a 5 year value so divided by 5 to get annual risk
  am_curr$tka_initiation_prob <- am_curr$tka_initiation_prob / 5

  # divide by 100 to get proportion for comparison with
  am_curr$tka_initiation_prob <- am_curr$tka_initiation_prob / 100

  # zero risk for anyone without OA, who is dead or who has already had two TKA
  am_curr$tka_initiation_prob <- am_curr$oa * am_curr$tka_initiation_prob
  am_curr$tka_initiation_prob <- (1 - am_curr$dead) * am_curr$tka_initiation_prob # only alive have TKA
  am_curr$tka_initiation_prob <- (1 - am_curr$tka2) * am_curr$tka_initiation_prob

  # apply secular scaling
  am_curr$current_scaling_factor <- 1
  current_year <- am_curr$year[1]
  year_index <- which(TKA_time_trend$Year == current_year)

  if (length(year_index) > 0) {
    # Females
    am_curr$current_scaling_factor[which(am_curr$sex == "[2] Female" & am_curr$age4554 == 1)] <-
      TKA_time_trend$female4554[year_index]
    am_curr$current_scaling_factor[which(am_curr$sex == "[2] Female" & am_curr$age5564 == 1)] <-
      TKA_time_trend$female5564[year_index]
    am_curr$current_scaling_factor[which(am_curr$sex == "[2] Female" & am_curr$age6574 == 1)] <-
      TKA_time_trend$female6574[year_index]
    am_curr$current_scaling_factor[which(am_curr$sex == "[2] Female" & am_curr$age75 == 1)]   <-
      TKA_time_trend$female75[year_index]
    # Males
    am_curr$current_scaling_factor[which(am_curr$sex == "[1] Male" & am_curr$age4554 == 1)] <-
      TKA_time_trend$male4554[year_index]
    am_curr$current_scaling_factor[which(am_curr$sex == "[1] Male" & am_curr$age5564 == 1)] <-
      TKA_time_trend$male5564[year_index]
    am_curr$current_scaling_factor[which(am_curr$sex == "[1] Male" & am_curr$age6574 == 1)] <-
      TKA_time_trend$male6574[year_index]
    am_curr$current_scaling_factor[which(am_curr$sex == "[1] Male" & am_curr$age75 == 1)]   <-
      TKA_time_trend$male75[year_index]
  }

  am_curr$tka_initiation_prob <- am_curr$tka_initiation_prob * am_curr$current_scaling_factor

  # determine events based on TKA probability
  tka_initiation_rand <- runif(nrow(am_curr), 0, 1)
  am_curr$tka_initiation_prob <- ifelse(am_curr$tka_initiation_prob > tka_initiation_rand, 1, 0)

  # records is a TKA happened in the cycle
  am_new$tka <- pmax(am_curr$tka, am_curr$tka_initiation_prob, na.rm = TRUE)
  # if no prior TKA and a record is a TKA, then tka1 = 1
  am_new$tka1 <- am_curr$tka1 + (am_curr$tka_initiation_prob * (1 - am_curr$tka1))
  # if a tka is recorded and there is a prior tka (ie am_curr$tka1 == 1), then record tka2
  am_new$tka2 <- am_curr$tka2 + (am_curr$tka_initiation_prob * am_curr$tka1)

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
