# R/apply_interventions_fcn.R

#' Apply Interventions to the Population
#'
#' This function applies one or more interventions to the attribute matrix.
#' Interventions are defined in a configuration file and can modify model
#' parameters or directly affect individuals' attributes.
#'
#' @param attribute_matrix The main data frame of the simulation population.
#' @param intervention_params A list of parameters for the interventions.
#' @param year The current simulation year.
#'
#' @return The updated attribute_matrix after applying the interventions.
#' @export
apply_interventions <- function(attribute_matrix, intervention_params, year) {
  # --- Guard Clauses ---
  if (is.null(intervention_params) || !isTRUE(intervention_params$enabled)) {
    return(attribute_matrix)
  }

  if (is.null(intervention_params$interventions) ||
    length(intervention_params$interventions) == 0) {
    return(attribute_matrix)
  }

  # --- Loop Through Interventions ---
  for (intervention_name in names(intervention_params$interventions)) {
    intervention <- intervention_params$interventions[[intervention_name]]

    # Check if the intervention is active in the current year
    if (year >= intervention$start_year && year <= intervention$end_year) {
      cat(paste(
        "Applying intervention:",
        intervention_name,
        "in year",
        year,
        "\n"
      ))

      # --- Apply Intervention based on its type ---
      if (intervention$type == "bmi_modification") {
        attribute_matrix <-
          apply_bmi_modification(attribute_matrix, intervention)
      } else if (intervention$type == "qaly_and_cost_modification") {
        attribute_matrix <-
          apply_qaly_cost_modification(attribute_matrix, intervention)
      } else if (intervention$type == "tka_risk_modification") {
        attribute_matrix <-
          apply_tka_risk_modification(attribute_matrix, intervention)
      }
      # (Other intervention types can be added here)
    }
  }

  attribute_matrix
}


# --- Helper Function to Identify Target Population ---

#' Get Indices of the Target Population for an Intervention
#'
#' @param am The attribute matrix.
#' @param target_def A list defining the target population criteria.
#'
#' @return A logical vector indicating which rows of the attribute matrix
#'   belong to the target population.
#' @export
get_target_indices <- function(am, target_def) {
  # Start with everyone
  indices <- rep(TRUE, nrow(am))

  # Filter by age
  if (!is.null(target_def$min_age)) {
    indices <- indices & (am$age >= target_def$min_age)
  }
  if (!is.null(target_def$max_age)) {
    indices <- indices & (am$age <= target_def$max_age)
  }

  # Filter by sex
  if (!is.null(target_def$sex)) {
    indices <- indices & (am$sex == target_def$sex)
  }

  # Filter by SES (year12)
  if (!is.null(target_def$year12)) {
    indices <- indices & (am$year12 == target_def$year12)
  }

  # Filter by KL grade
  if (!is.null(target_def$min_kl_grade)) {
    # Assumes kl_grade is a single column. If not, this needs adjustment.
    # Let's find the max KL grade for each person first.
    kl_cols <- c("kl0", "kl1", "kl2", "kl3", "kl4")
    kl_data <- am[, kl_cols[kl_cols %in% names(am)]]
    am$current_kl_grade <- apply(kl_data * col(kl_data), 1, max)

    indices <- indices & (am$current_kl_grade >= target_def$min_kl_grade)
  }

  indices
}


# --- Specific Intervention Functions ---

#' Apply a BMI Modification Intervention
#' @param am The attribute matrix.
#' @param intervention The intervention to apply.
#' @return The updated attribute matrix.
#' @export
apply_bmi_modification <- function(am, intervention) {
  target_indices <- get_target_indices(am, intervention$target_population)

  # Apply uptake rate - only a portion of the target pop is affected
  affected_indices <-
    target_indices & (runif(nrow(am)) < intervention$parameters$uptake_rate)

  # Apply the BMI change
  am[affected_indices, "bmi"] <-
    am[affected_indices, "bmi"] + intervention$parameters$bmi_change
  am$bmi <- pmax(15, am$bmi) # Ensure BMI doesn't fall below a minimum

  am
}

#' Apply a QALY and Cost Modification Intervention
#' @param am The attribute matrix.
#' @param intervention The intervention to apply.
#' @return The updated attribute matrix.
#' @export
apply_qaly_cost_modification <- function(am, intervention) {
  target_indices <- get_target_indices(am, intervention$target_population)
  affected_indices <-
    target_indices & (runif(nrow(am)) < intervention$parameters$uptake_rate)

  # Apply the QALY gain
  am[affected_indices, "d_sf6d"] <-
    am[affected_indices, "d_sf6d"] + intervention$parameters$qaly_gain

  # Add the cost
  # We need a new column to track intervention costs
  if (!"intervention_cost" %in% names(am)) {
    am$intervention_cost <- 0
  }
  am[affected_indices, "intervention_cost"] <-
    am[affected_indices, "intervention_cost"] + intervention$parameters$annual_cost

  am
}

#' Apply a TKA Risk Modification Intervention
#' @param am The attribute matrix.
#' @param intervention The intervention to apply.
#' @return The updated attribute matrix.
#' @export
apply_tka_risk_modification <- function(am, intervention) {
  target_indices <- get_target_indices(am, intervention$target_population)
  affected_indices <-
    target_indices & (runif(nrow(am)) < intervention$parameters$uptake_rate)

  # Apply the TKA risk multiplier
  # This assumes that the TKA risk is stored in a column named 'tkai'
  if ("tkai" %in% names(am)) {
    am[affected_indices, "tkai"] <-
      am[affected_indices, "tkai"] * intervention$parameters$tka_risk_multiplier
  } else {
    warning(
      "Column 'tkai' not found in the attribute matrix. TKA risk modification not applied."
    )
  }

  am
}
