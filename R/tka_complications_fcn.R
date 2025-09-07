#' Calculate TKA Complications (PJI and DVT)
#'
#' This function calculates the risk and occurrence of post-operative complications
#' following total knee arthroplasty, including Periprosthetic Joint Infection (PJI)
#' and Deep Vein Thrombosis (DVT).
#'
#' @param am_curr A data.table representing the attribute matrix for the current cycle
#' @param am_new A data.table representing the attribute matrix for the next cycle
#' @param cycle_coefficients A list containing model coefficients
#' @return Updated am_new data.table with complication flags and utility impacts
#' @importFrom stats runif
#' @export
calculate_tka_complications <- function(am_curr, am_new, cycle_coefficients) {
  # Initialize complication columns if they don't exist
  if (!"pji" %in% names(am_new)) am_new$pji <- 0
  if (!"dvt" %in% names(am_new)) am_new$dvt <- 0
  if (!"comp" %in% names(am_new)) am_new$comp <- 0
  if (!"d_sf6d" %in% names(am_new)) am_new$d_sf6d <- 0

  # Only calculate complications for patients who received TKA this cycle
  tka_indices <- which(am_new$tka == 1)

  if (length(tka_indices) > 0) {
    # --- PJI (Periprosthetic Joint Infection) Risk Model ---
    # Literature-based risk factors for PJI
    base_pji_risk <- 0.015  # 1.5% base risk

    # Age modifier (older age increases risk)
    age_modifier <- ifelse(am_curr$age[tka_indices] > 75, 1.8,
                          ifelse(am_curr$age[tka_indices] > 65, 1.4, 1.0))

    # BMI modifier (obesity increases risk)
    bmi_modifier <- ifelse(am_curr$bmi[tka_indices] > 35, 2.0,
                          ifelse(am_curr$bmi[tka_indices] > 30, 1.6,
                                ifelse(am_curr$bmi[tka_indices] > 25, 1.2, 1.0)))

    # Comorbidity modifier
    comorbidity_modifier <- ifelse(am_curr$ccount[tka_indices] >= 3, 2.0,
                                  ifelse(am_curr$ccount[tka_indices] >= 1, 1.4, 1.0))

    # Diabetes modifier (significant risk factor for PJI)
    diabetes_modifier <- ifelse(am_curr$diabetes[tka_indices] == 1, 1.8, 1.0)

    # Calculate individual PJI risk
    pji_risk <- base_pji_risk * age_modifier * bmi_modifier *
                comorbidity_modifier * diabetes_modifier
    pji_risk <- pmin(pji_risk, 0.12)  # Cap at 12%

    # Determine PJI events
    pji_rand <- runif(length(tka_indices), 0, 1)
    pji_events <- pji_risk > pji_rand

    if (any(pji_events)) {
      am_new$pji[tka_indices[pji_events]] <- 1
      am_new$comp[tka_indices[pji_events]] <- 1
    }

    # --- DVT (Deep Vein Thrombosis) Risk Model ---
    base_dvt_risk <- 0.04  # 4% base risk without prophylaxis

    # Age modifier for DVT
    age_modifier_dvt <- ifelse(am_curr$age[tka_indices] > 75, 2.0,
                              ifelse(am_curr$age[tka_indices] > 65, 1.6, 1.0))

    # Obesity modifier
    obesity_modifier <- ifelse(am_curr$bmi[tka_indices] > 30, 1.8, 1.0)

    # Previous DVT/PE history (if available)
    prev_dvt_modifier <- ifelse(!is.na(am_curr$prev_dvt[tka_indices]) &
                               am_curr$prev_dvt[tka_indices] == 1, 2.5, 1.0)

    # Calculate individual DVT risk
    dvt_risk <- base_dvt_risk * age_modifier_dvt * obesity_modifier * prev_dvt_modifier
    dvt_risk <- pmin(dvt_risk, 0.18)  # Cap at 18%

    # Determine DVT events (independent of PJI)
    dvt_rand <- runif(length(tka_indices), 0, 1)
    dvt_events <- dvt_risk > dvt_rand

    if (any(dvt_events)) {
      am_new$dvt[tka_indices[dvt_events]] <- 1
      # Only mark as general complication if not already marked by PJI
      comp_indices <- tka_indices[dvt_events]
      am_new$comp[comp_indices] <- ifelse(am_new$pji[comp_indices] == 1, 1, 1)
    }

    # --- Utility/QALY Impact of Complications ---
    # PJI has severe, long-term impact
    pji_indices <- which(am_new$pji == 1)
    if (length(pji_indices) > 0) {
      # Severe disutility for PJI (infection, multiple surgeries, prolonged recovery)
      # Impact persists beyond initial cycle
      am_new$d_sf6d[pji_indices] <- am_new$d_sf6d[pji_indices] - 0.30
    }

    # DVT has moderate but shorter-term impact
    dvt_indices <- which(am_new$dvt == 1 & am_new$pji == 0)  # Don't double-count PJI patients
    if (length(dvt_indices) > 0) {
      # Moderate disutility for DVT (pain, mobility issues, anticoagulation)
      am_new$d_sf6d[dvt_indices] <- am_new$d_sf6d[dvt_indices] - 0.12
    }
  }

  return(am_new)
}
