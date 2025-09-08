#' Resource Allocation Integration Module
#'
#' This module provides integration functions for the resource allocation
#' module within the AUS-OA simulation framework.
#'
#' Key Functions:
#' - integrate_resource_allocation_module(): Main integration function
#' - extract_resource_parameters(): Parameter extraction from config
#' - update_simulation_with_resources(): Update simulation state with resource effects
#' - summarize_resource_impacts(): Generate resource impact summaries

#' Extract Resource Allocation Parameters from Configuration
#'
#' @param config Configuration list containing coefficients
#' @return List of resource allocation parameters organized by category
extract_resource_parameters <- function(config) {
  # Extract resource allocation parameters from coefficients
  coeffs <- config$coefficients

  if (!"resource_allocation" %in% names(coeffs)) {
    stop("Resource allocation parameters not found in configuration")
  }

  resource_params <- coeffs$resource_allocation

  # Validate required sections
  required_sections <- c("regional", "referral", "constraints", "hospital_capacity", "referral_acceptance")
  missing_sections <- setdiff(required_sections, names(resource_params))

  if (length(missing_sections) > 0) {
    warning("Missing resource parameter sections: ", paste(missing_sections, collapse = ", "))
  }

  return(resource_params)
}

#' Update Simulation State with Resource Allocation Effects
#'
#' @param am_curr Current attribute matrix
#' @param resource_result Results from resource allocation module
#' @return Updated attribute matrix with resource effects applied
update_simulation_with_resources <- function(am_curr, resource_result) {
  # Extract patient data with resource allocation effects
  patients <- resource_result$patients

  # Update simulation variables based on resource allocation outcomes

  # Apply capacity delay impacts to wait times
  if ("capacity_delay" %in% names(patients)) {
    # Add capacity delays to existing wait times
    if (!"wait_time_months" %in% names(am_curr)) {
      am_curr$wait_time_months <- 0
    }
    am_curr$wait_time_months <- am_curr$wait_time_months + patients$capacity_delay
    # Also store the capacity delay separately
    am_curr$capacity_delay <- patients$capacity_delay
  }

  # Apply quality impacts
  if ("capacity_quality_impact" %in% names(patients)) {
    if (!"resource_quality_modifier" %in% names(am_curr)) {
      am_curr$resource_quality_modifier <- 1.0
    }
    am_curr$resource_quality_modifier <- am_curr$resource_quality_modifier * patients$capacity_quality_impact
    am_curr$capacity_quality_impact <- patients$capacity_quality_impact
  }

  # Apply cost impacts
  if ("capacity_cost_impact" %in% names(patients)) {
    if (!"resource_cost_modifier" %in% names(am_curr)) {
      am_curr$resource_cost_modifier <- 1.0
    }
    am_curr$resource_cost_modifier <- am_curr$resource_cost_modifier * patients$capacity_cost_impact
    am_curr$capacity_cost_impact <- patients$capacity_cost_impact
  }

  # Add hospital type and referral information
  am_curr$final_hospital_type <- patients$final_hospital_type
  am_curr$referral_needed <- patients$referral_needed
  am_curr$referral_accepted <- patients$referral_accepted

  return(am_curr)
}

#' Generate Resource Impact Summary
#'
#' @param resource_summary Raw summary from resource allocation module
#' @param simulation_cycle Current simulation cycle
#' @return Formatted summary for reporting
summarize_resource_impacts <- function(resource_summary, simulation_cycle) {
  summary <- list(
    cycle = simulation_cycle,
    timestamp = Sys.time(),
    capacity_utilization = list(
      overall_utilization = resource_summary$overall_metrics$total_capacity_utilization,
      constrained_hospitals = resource_summary$overall_metrics$constrained_hospitals,
      metro_utilization = resource_summary$regional_analysis$metro_utilization,
      regional_utilization = resource_summary$regional_analysis$regional_utilization
    ),
    referral_patterns = list(
      referrals_needed = resource_summary$overall_metrics$total_referrals_needed,
      referrals_accepted = resource_summary$overall_metrics$referrals_accepted,
      acceptance_rate = resource_summary$overall_metrics$referral_success_rate
    ),
    constraint_impacts = list(
      average_delay_months = resource_summary$constraint_impacts$average_delay_months,
      average_quality_impact = resource_summary$constraint_impacts$average_quality_impact,
      average_cost_impact = resource_summary$constraint_impacts$average_cost_impact,
      patients_affected = resource_summary$constraint_impacts$patients_affected_by_constraints
    ),
    hospital_details = resource_summary$hospital_utilization
  )

  return(summary)
}

#' Validate Resource Allocation Integration
#'
#' @param integration_result Result from integration function
#' @return Validation summary
validate_resource_integration <- function(integration_result) {
  validation <- list(
    has_resource_data = !is.null(integration_result$resource_result),
    has_resource_summary = !is.null(integration_result$resource_summary),
    resource_columns_present = all(c("final_hospital_type", "referral_needed", "capacity_delay") %in%
                                  names(integration_result$am_curr)),
    reasonable_utilization = (integration_result$resource_summary$capacity_utilization$overall_utilization >= 0 &&
                             integration_result$resource_summary$capacity_utilization$overall_utilization <= 2),
    valid_referral_rate = (integration_result$resource_summary$referral_patterns$acceptance_rate >= 0 &&
                          integration_result$resource_summary$referral_patterns$acceptance_rate <= 1),
    positive_delays = all(integration_result$am_curr$capacity_delay >= 0, na.rm = TRUE)
  )

  validation$overall_valid <- all(unlist(validation))

  return(validation)
}

#' Main Integration Function for Resource Allocation Module
#'
#' @param am_curr Current attribute matrix
#' @param am_new Next cycle attribute matrix
#' @param config Configuration list
#' @param simulation_cycle Current simulation cycle number
#' @return List containing updated matrices and integration summary
integrate_resource_allocation_module <- function(am_curr, am_new, config, simulation_cycle) {
  # Extract resource allocation parameters
  resource_params <- extract_resource_parameters(config)

  # Load the resource allocation module
  source("R/resource_allocation_module.R")

  # Prepare patient data for resource allocation modeling
  patients <- am_curr

  # Add region information if not present (default to metro for now)
  if (!"region" %in% names(patients)) {
    # Assign regions based on some criteria (could be enhanced with actual regional data)
    set.seed(123 + simulation_cycle)  # Reproducible but cycle-dependent
    patients$region <- sample(c("metro", "regional"),
                             nrow(patients),
                             replace = TRUE,
                             prob = c(0.7, 0.3))  # 70% metro, 30% regional
  }

  # Run the resource allocation module
  resource_result <- resource_allocation_module(patients, resource_params)

  # Update simulation state with resource allocation effects
  am_curr_updated <- update_simulation_with_resources(am_curr, resource_result)

  # Generate integration summary
  resource_summary <- summarize_resource_impacts(resource_result$resource_summary, simulation_cycle)

  # Update am_new with resource allocation information
  am_new$final_hospital_type <- am_curr_updated$final_hospital_type
  am_new$referral_needed <- am_curr_updated$referral_needed
  am_new$referral_accepted <- am_curr_updated$referral_accepted
  am_new$capacity_delay <- am_curr_updated$capacity_delay
  am_new$resource_quality_modifier <- am_curr_updated$resource_quality_modifier
  am_new$resource_cost_modifier <- am_curr_updated$resource_cost_modifier

  # Add integration metadata
  am_new$resource_allocation_run <- TRUE
  am_new$resource_allocation_cycle <- simulation_cycle

  result <- list(
    am_curr = am_curr_updated,
    am_new = am_new,
    resource_result = resource_result,
    resource_summary = resource_summary,
    parameters_used = resource_params
  )

  return(result)
}
