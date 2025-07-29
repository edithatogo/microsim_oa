# R/apply_interventions_fcn.R

#' Apply Interventions to the Population
#'
#' This function applies one or more interventions to the attribute matrix.
#' Interventions are defined in a configuration file and can modify model
#' parameters or directly affect individuals' attributes.
#'
#' @param attribute_matrix The main data frame of the simulation population.
#' @param intervention_params A list of parameters for the interventions,
#'   loaded from a config file.
#' @param year The current simulation year.
#'
#' @return The updated attribute_matrix after applying the interventions.
#'
apply_interventions <- function(attribute_matrix, intervention_params, year) {
  
  # --- Guard Clauses ---
  if (is.null(intervention_params) || !isTRUE(intervention_params$enabled)) {
    return(attribute_matrix)
  }
  
  if (is.null(intervention_params$interventions) || length(intervention_params$interventions) == 0) {
    return(attribute_matrix)
  }
  
  
  # --- Loop Through Interventions ---
  
  for (intervention_name in names(intervention_params$interventions)) {
    
    intervention <- intervention_params$interventions[[intervention_name]]
    
    # Check if the intervention is active in the current year
    if (year >= intervention$start_year && year <= intervention$end_year) {
      
      cat(paste("Applying intervention:", intervention_name, "in year", year, "\n"))
      
      # --- Apply Intervention based on its type ---
      
      if (intervention$type == "bmi_reduction") {
        attribute_matrix <- apply_bmi_reduction(attribute_matrix, intervention)
      }
      
      # (Other intervention types can be added here)
      
    }
  }
  
  return(attribute_matrix)
}


# --- Specific Intervention Functions ---

#' Apply a BMI Reduction Intervention
#'
#' This function applies a simple BMI reduction to a target segment of the
#' population.
#'
#' @param attribute_matrix The attribute matrix.
#' @param intervention The parameters for the BMI reduction intervention.
#'
#' @return The updated attribute_matrix.
#'
apply_bmi_reduction <- function(attribute_matrix, intervention) {
  
  # Identify the target population
  # This is a simplified example; a real intervention would have more complex targeting
  target_indices <- which(attribute_matrix$alive == 1)
  
  # Apply the reduction
  reduction_amount <- intervention$parameters$reduction_amount
  attribute_matrix[target_indices, "bmi"] <- attribute_matrix[target_indices, "bmi"] - reduction_amount
  
  # Ensure BMI does not fall below a minimum value
  attribute_matrix$bmi <- pmax(15, attribute_matrix$bmi)
  
  return(attribute_matrix)
}