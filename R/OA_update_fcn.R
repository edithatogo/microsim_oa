#' Update Osteoarthritis (OA) Status
#'
#' This function models the initiation and progression of osteoarthritis (OA) for
#' one simulation cycle. It calculates the probability of developing OA (KL grade 2)
#' and progressing to KL grades 3 and 4 based on various risk factors.
#'
#' @param am_curr A data.frame representing the attribute matrix for the current
#'   cycle. It contains the state of the population before the update.
#' @param am_new A data.frame representing the attribute matrix for the next
#'   cycle. This is where the updated OA status will be stored.
#' @param cycle.coefficents A list or data.frame of model coefficients for the
#'   OA initiation and progression equations, which also contains the SF-6D
#'   utility decrements.
#' @param OA_cust A data.frame with customisation factors for OA coefficients.
#'
#' @return A list containing two data.frames:
#'   \item{am_curr}{The input `am_curr` with intermediate calculations and an
#'   updated `sf6d_change` column.}
#'   \item{am_new}{The `am_new` data.frame with updated OA status (`oa`, `kl2`,
#'   `kl3`, `kl4`, `kl_score`).}
#' @export
#'
OA_update <- function(am_curr, am_new, cycle.coefficents, OA_cust) {
  
  am_curr$sf6d_change <- 0
  turn.out.inloop.summary <- FALSE
  
  # Customize OA age coefficients
  cycle.coefficents <- apply_coefficent_customisations(cycle.coefficents, OA_cust, "c6", "c6")

  # OA initiation
  am_curr$oa_initiation_prob <- exp(cycle.coefficents$c6_cons +
    cycle.coefficents$c6_year12 * am_curr$year12 +
    cycle.coefficents$c6_age1m * am_curr$age044 * am_curr$male +
    cycle.coefficents$c6_age2m * am_curr$age4554 * am_curr$male +
    cycle.coefficents$c6_age3m * am_curr$age5564 * am_curr$male +
    cycle.coefficents$c6_age4m * am_curr$age6574 * am_curr$male +
    cycle.coefficents$c6_age5m * am_curr$age75 * am_curr$male +
    cycle.coefficents$c6_age1f * am_curr$age044 * (1 - am_curr$male) +
    cycle.coefficents$c6_age2f * am_curr$age4554 * (1 - am_curr$male) +
    cycle.coefficents$c6_age3f * am_curr$age5564 * (1 - am_curr$male) +
    cycle.coefficents$c6_age4f * am_curr$age6574 * (1 - am_curr$male) +
    cycle.coefficents$c6_age5f * am_curr$age75 * (1 - am_curr$male) +
    cycle.coefficents$c6_bmi0 * am_curr$bmi024 +
    cycle.coefficents$c6_bmi1 * am_curr$bmi2529 +
    cycle.coefficents$c6_bmi2 * am_curr$bmi3034 +
    cycle.coefficents$c6_bmi3 * am_curr$bmi3539 +
    cycle.coefficents$c6_bmi4 * am_curr$bmi40)

  am_curr$oa_initiation_prob <- (1 - am_curr$oa) * am_curr$oa_initiation_prob # only have an initialisation probability if don't already have OA
  am_curr$oa_initiation_prob <- (1 - am_curr$dead) * am_curr$oa_initiation_prob # only have an initialisation probability if not dead
  am_curr$oa_initiation_prob <- am_curr$oa_initiation_prob / (1 + am_curr$oa_initiation_prob) # logistic
  am_curr$oa_initiation_prob <- (1 + am_curr$oa_initiation_prob)^0.25 - 1


  if (turn.out.inloop.summary == TRUE) {
    summary_risk <- am_curr %>%
      filter(age_cat != "[14,45]") %>%
      group_by(sex, age_cat) %>%
      summarise(mean.annual.oa.risk.percent = mean(oa_initiation_prob) * 100)
  }

  oa_initiation_rand <- runif(nrow(am_curr), 0, 1)
  # am_curr$oa_initiation_prob_risk <- am_curr$oa_initiation_prob
  am_curr$oa_initiation_prob <- ifelse(am_curr$oa_initiation_prob > oa_initiation_rand, 1, 0)

  if (turn.out.inloop.summary == TRUE) {
    summary_events <- am_curr %>%
      filter(age_cat != "[14,45]") %>%
      group_by(sex, age_cat) %>%
      summarise(mean.annual.oa.event.percent = mean(oa_initiation_prob) * 100)

    summary_risk.overall <- merge(summary_risk, summary_events, by = c("sex", "age_cat"))

    print(summary_risk.overall)
  }

  am_new$oa <- am_curr$oa_initiation_prob + am_curr$oa
  am_new$kl2 <- am_curr$oa_initiation_prob + am_curr$kl2

  am_curr$sf6d_change <- am_curr$sf6d_change + ifelse(length(am_curr$oa_initiation_prob) > 0, (am_curr$oa_initiation_prob * cycle.coefficents$c14_kl2), 0)

  # update medication status, if newly OA test if the also get meds,
  # should only happen when a person is newly OA
  # 0.56 from Hilda data 2013 per C. Schilling

  med_rand <- runif(nrow(am_curr), 0, 1)

  am_curr$drugoa <- ifelse(am_curr$oa_initiation_prob == 1,
    as.numeric(0.56 > med_rand),
    am_curr$drugoa
  )

  # log_print("Number of new KL2 individuals", console = FALSE, hide_notes = TRUE)
  # log_print(sum(am_curr$oa_initiation_prob), console = FALSE, hide_notes = TRUE)

  # OA progression KL2 to 3 - based on OAI analysis


  # OA progression from KL2 to KL3
  am_curr$oa_progression_prob <- exp(cycle.coefficents$c7_cons +
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
  am_curr$oa_progression_prob <- am_curr$kl2 * am_curr$oa_progression_prob # only have a progression probability if already have KL2
  am_curr$oa_progression_prob <- (1 - am_curr$dead) * am_curr$oa_progression_prob # only have an progression probability if not dead
  am_curr$oa_progression_prob <- am_curr$oa_progression_prob / (1 + am_curr$oa_progression_prob) # logistic
  am_curr$oa_progression_prob <- (1 + am_curr$oa_progression_prob)^0.25 - 1 # OAI analysis is over 4 years - need to reduce to annual


  oa_progression_rand <- runif(nrow(am_curr), 0, 1)
  am_curr$oa_progression_prob <- ifelse(am_curr$oa_progression_prob > oa_progression_rand, 1, 0)

  am_curr$sf6d_change <- am_curr$sf6d_change + ifelse(length(am_curr$oa_progression_prob) > 0, (am_curr$oa_progression_prob * cycle.coefficents$c14_kl3), 0)

  am_new$kl3 <- am_curr$oa_progression_prob + am_curr$kl3
  am_new$kl2 <- am_curr$kl2 - am_curr$oa_progression_prob

  # log_print("Number of new KL3 individuals", console = FALSE, hide_notes = TRUE)
  # log_print(sum(am_curr$oa_progression_prob), console = FALSE, hide_notes = TRUE)


  # OA progression KL 3 and 4
  am_curr$oa_progression_kl3_kl4_prob <- exp(cycle.coefficents$c8_cons +
    cycle.coefficents$c8_sex * am_curr$female +
    cycle.coefficents$c8_age3 * am_curr$age5564 +
    cycle.coefficents$c8_age4 * am_curr$age6574 +
    cycle.coefficents$c8_age5 * am_curr$age75 +
    cycle.coefficents$c8_bmi0 * am_curr$bmi024 +
    cycle.coefficents$c8_bmi1 * am_curr$bmi2529 +
    cycle.coefficents$c8_bmi2 * am_curr$bmi3034 +
    cycle.coefficents$c8_bmi3 * am_curr$bmi3539 +
    cycle.coefficents$c8_bmi4 * am_curr$bmi40)

  am_curr$oa_progression_kl3_kl4_prob <- am_curr$kl3 * am_curr$oa_progression_kl3_kl4_prob # only have a progression probability if already have KL3
  am_curr$oa_progression_kl3_kl4_prob <- (1 - am_curr$dead) * am_curr$oa_progression_kl3_kl4_prob # only have an progression probability if not dead
  am_curr$oa_progression_kl3_kl4_prob <- am_curr$oa_progression_kl3_kl4_prob / (1 + am_curr$oa_progression_kl3_kl4_prob) # logistic
  am_curr$oa_progression_kl3_kl4_prob <- (1 + am_curr$oa_progression_kl3_kl4_prob)^0.25 - 1 # OAI analysis is over 4 years - need to reduce to annual

  oa_progression_kl3_kl4_rand <- runif(nrow(am_curr), 0, 1)
  am_curr$oa_progression_kl3_kl4_prob <- ifelse(am_curr$oa_progression_kl3_kl4_prob > oa_initiation_rand, 1, 0)

  am_curr$sf6d_change <- am_curr$sf6d_change + ifelse(length(am_curr$oa_progression_kl3_kl4_prob) > 0, (am_curr$oa_progression_kl3_kl4_prob * cycle.coefficents$c14_kl4), 0)

  am_new$kl4 <- am_curr$oa_progression_kl3_kl4_prob + am_curr$kl4
  am_new$kl3 <- am_curr$kl3 - am_curr$oa_progression_kl3_kl4_prob



  am_new$kl_score <- (2 * am_new$kl2) + (3 * am_new$kl3) + (4 * am_new$kl4)


  # bundle am_curr and am_new for export
  export_data <- list(
    am_curr = am_curr,
    am_new = am_new
  )

  return(export_data)
}
