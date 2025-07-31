#' Calculate Quality-Adjusted Life Years (QALYs)
#'
#' This function calculates the health utility (SF-6D) for each individual
#' based on their current health state, including KL grade, BMI, and
#' comorbidities.
#'
#' @param attribute_matrix The main data frame of the simulation population.
#' @param utility_params A list of parameters defining the utility decrements
#'   for various health states.
#'
#' @return The updated attribute_matrix with the `d_sf6d` column populated with
#'   the total utility decrement for the cycle.
#'
calculate_qaly <- function(attribute_matrix, utility_params) {
  # --- Initialize d_sf6d ---
  # This column represents the change in utility for the current cycle.
  if (!"d_sf6d" %in% names(attribute_matrix)) {
    attribute_matrix$d_sf6d <- 0
  }
  attribute_matrix$d_sf6d <- 0


  # --- 1. Decrement from KL Grade ---
  # Apply utility decrements for different Kellgren-Lawrence grades.
  # Note: This assumes KL grades are mutually exclusive columns (kl2, kl3, kl4).
  if ("kl2" %in% names(attribute_matrix)) {
    attribute_matrix$d_sf6d <- attribute_matrix$d_sf6d -
      (attribute_matrix$kl2 * utility_params$kl_grades$kl2)
  }
  if ("kl3" %in% names(attribute_matrix)) {
    attribute_matrix$d_sf6d <- attribute_matrix$d_sf6d -
      (attribute_matrix$kl3 * utility_params$kl_grades$kl3)
  }
  if ("kl4" %in% names(attribute_matrix)) {
    attribute_matrix$d_sf6d <- attribute_matrix$d_sf6d -
      (attribute_matrix$kl4 * utility_params$kl_grades$kl4)
  }

  # --- 2. Decrement from BMI ---
  # This is a linear decrement based on BMI value.
  attribute_matrix$d_sf6d <- attribute_matrix$d_sf6d +
    (attribute_matrix$d_bmi * utility_params$c14$c14_bmi)


  # --- 3. Decrement from TKA Revision ---
  if ("revi" %in% names(attribute_matrix)) {
    attribute_matrix$d_sf6d <- attribute_matrix$d_sf6d -
      (attribute_matrix$revi * utility_params$c14_rev)
  }

  # --- 4. Decrement from TKA Complication ---
  if ("comp" %in% names(attribute_matrix) &&
    "tka_complication" %in% names(utility_params)) {
    attribute_matrix$d_sf6d <- attribute_matrix$d_sf6d -
      (attribute_matrix$comp * utility_params$tka_complication)
  }

  # --- 5. Decrement from Comorbidities ---
  if (!is.null(utility_params$comorbidities)) {
    for (comorbidity in names(utility_params$comorbidities)) {
      col_name <- paste0("has_", comorbidity)
      if (col_name %in% names(attribute_matrix)) {
        decrement <- utility_params$comorbidities[[comorbidity]]
        attribute_matrix$d_sf6d <- attribute_matrix$d_sf6d -
          (attribute_matrix[[col_name]] * decrement)
      }
    }
  }

  attribute_matrix
}
