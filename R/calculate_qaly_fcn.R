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
#' @export
calculate_qaly <- function(attribute_matrix, utility_params) {
  # Ensure the attribute_matrix is a data.table for efficient operations
  setDT(attribute_matrix)

  d_sf6d <- NULL # Avoid NOTE about no visible binding for global variable

  # --- Initialize d_sf6d ---
  # This column represents the change in utility for the current cycle.
  if (!"d_sf6d" %in% names(attribute_matrix)) {
    attribute_matrix[, d_sf6d := 0]
  }
  attribute_matrix[, d_sf6d := 0]

  # Helper function to safely calculate decrements
  # This avoids errors if a column is missing or calculations yield empty results
  safe_decrement <- function(data, col_name, decrement_value) {
    if (col_name %in% names(data)) {
      # Ensure the column is numeric before multiplication
      if (is.numeric(data[[col_name]]) && is.numeric(decrement_value)) {
        return(data[[col_name]] * decrement_value)
      }
    }
    # Return a vector of zeros if the column doesn't exist or isn't numeric
    return(rep(0, nrow(data)))
  }


  # --- 1. Decrement from KL Grade ---
  # Apply utility decrements for different Kellgren-Lawrence grades.
  attribute_matrix[, d_sf6d := d_sf6d - safe_decrement(attribute_matrix, "kl2", utility_params$utilities$kl_grades$kl2)]
  attribute_matrix[, d_sf6d := d_sf6d - safe_decrement(attribute_matrix, "kl3", utility_params$utilities$kl_grades$kl3)]
  attribute_matrix[, d_sf6d := d_sf6d - safe_decrement(attribute_matrix, "kl4", utility_params$utilities$kl_grades$kl4)]


  # --- 2. Decrement from BMI ---
  # This is a linear decrement based on BMI value.
  if (!is.null(utility_params$c14) && !is.null(utility_params$c14$c14_bmi)) {
    # Ensure d_bmi exists and is numeric, otherwise treat as 0
    if (!"d_bmi" %in% names(attribute_matrix) || !is.numeric(attribute_matrix$d_bmi)) {
      attribute_matrix[, d_bmi := 0]
    }
    # The calculation for BMI is an increment, so we add it
    attribute_matrix[, d_sf6d := d_sf6d + safe_decrement(attribute_matrix, "d_bmi", utility_params$c14$c14_bmi)]
  }


  # --- 3. Decrement from TKA Revision ---
  attribute_matrix[, d_sf6d := d_sf6d - safe_decrement(attribute_matrix, "revi", utility_params$utilities$c14_rev)]


  # --- 4. Decrement from TKA Complication ---
  if ("tka_complication" %in% names(utility_params$utilities)) {
    attribute_matrix[, d_sf6d := d_sf6d - safe_decrement(attribute_matrix, "comp", utility_params$utilities$tka_complication)]
  }


  # --- 5. Decrement from Comorbidities ---
  if (!is.null(utility_params$utilities$comorbidities)) {
    for (comorbidity in names(utility_params$utilities$comorbidities)) {
      col_name <- paste0("has_", comorbidity)
      decrement_value <- utility_params$utilities$comorbidities[[comorbidity]]
      attribute_matrix[, d_sf6d := d_sf6d - safe_decrement(attribute_matrix, col_name, decrement_value)]
    }
  }

  attribute_matrix
}
