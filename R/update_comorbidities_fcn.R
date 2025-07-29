# R/update_comorbidities_fcn.R

#' Update Comorbidities and their Impact
#'
#' This function updates the prevalence of specified comorbidities and calculates
#' their associated impact on QALYs and costs for a single cycle. It only runs
#' if comorbidity modeling is enabled in the configuration.
#'
#' @param attribute_matrix The main data frame of the simulation population.
#' @param comorbidity_params A list of parameters for the comorbidities,
#'   loaded from a config file. Should contain an `enabled` flag and a list
#'   of `conditions`.
#'
#' @return The updated attribute_matrix with new comorbidity statuses, QALY
#'   decrements, and costs.
#'
update_comorbidities <- function(attribute_matrix, comorbidity_params) {
  
  # --- Guard Clauses ---
  if (is.null(comorbidity_params) || !isTRUE(comorbidity_params$enabled)) {
    return(attribute_matrix)
  }
  
  if (is.null(comorbidity_params$conditions) || length(comorbidity_params$conditions) == 0) {
    warning("Comorbidity modeling is enabled, but no conditions are defined in the config.")
    return(attribute_matrix)
  }
  
  # --- Initialize Cost Column ---
  if (!"comorbidity_cost" %in% names(attribute_matrix)) {
    attribute_matrix$comorbidity_cost <- 0
  }
  # Reset cost at the start of the cycle to avoid double counting
  attribute_matrix$comorbidity_cost <- 0
  
  
  # --- Update Comorbidities and their Impact ---
  
  for (comorbidity in names(comorbidity_params$conditions)) {
    
    params <- comorbidity_params$conditions[[comorbidity]]
    col_name <- paste0("has_", comorbidity)
    
    # Add the comorbidity column if it doesn't exist
    if (!col_name %in% names(attribute_matrix)) {
      attribute_matrix[[col_name]] <- 0
    }
    
    # --- 1. Update Incidence ---
    # Apply the annual incidence rate to those who don't have the condition yet
    incidence_rate <- params$annual_incidence_rate
    
    # Identify individuals at risk (alive and don't have the condition)
    at_risk_indices <- which(attribute_matrix$alive == 1 & attribute_matrix[[col_name]] == 0)
    
    if (length(at_risk_indices) > 0) {
      # Generate random numbers and identify new cases
      new_cases <- runif(length(at_risk_indices)) < incidence_rate
      new_case_indices <- at_risk_indices[new_cases]
      
      # Update the attribute matrix for new cases
      attribute_matrix[new_case_indices, col_name] <- 1
    }
    
    # --- 2. Calculate Impact ---
    # Identify all individuals who have the condition this cycle (pre-existing + new)
    has_condition_indices <- which(attribute_matrix$alive == 1 & attribute_matrix[[col_name]] == 1)
    
    if (length(has_condition_indices) > 0) {
      # Add the annual cost for those with the condition
      attribute_matrix[has_condition_indices, "comorbidity_cost"] <- attribute_matrix[has_condition_indices, "comorbidity_cost"] + params$annual_cost
      
      # Add the QALY decrement for those with the condition
      attribute_matrix[has_condition_indices, "d_sf6d"] <- attribute_matrix[has_condition_indices, "d_sf6d"] - params$qaly_decrement
    }
  }
  
  return(attribute_matrix)
}