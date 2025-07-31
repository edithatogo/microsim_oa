#' Calculate Costs for a Simulation Cycle
#'
#' This function calculates various costs for each individual in the attribute
#' matrix based on events that occurred in the current cycle and ongoing states.
#' It uses a detailed, component-based cost configuration.
#'
#' @param am_new A data.table representing the attribute matrix with the
#'   latest events for the current cycle.
#' @param costs_config A list containing the detailed cost parameters from the
#'   model configuration file.
#'
#' @return The `am_new` data.table with new columns for costs incurred
#'   during the cycle, broken down by perspective.
#' @export
calculate_costs_fcn <- function(am_new, costs_config) {
  # --- Helper Function to Sum Costs by Perspective ---
  get_cost_sum <- function(cost_event_config, perspective_filter) {
    total_cost <- 0

    # Loop through each component of the cost event (e.g., hospital, surgeon)
    for (component in names(cost_event_config)) {
      # Check if the component's perspective matches the filter
      if (cost_event_config[[component]]$perspective %in% perspective_filter) {
        total_cost <- total_cost + cost_event_config[[component]]$value
      }
    }
    total_cost
  }


  # --- Initialize Cycle Cost Columns ---
  am_new[, cycle_cost_healthcare := 0]
  am_new[, cycle_cost_patient := 0]
  am_new[, cycle_cost_societal := 0]


  # --- Calculate Costs for Each Event and State ---

  # 1. Primary TKA Cost
  healthcare_tka_cost <-
    get_cost_sum(costs_config$tka_primary, "healthcare_system")
  patient_tka_cost <- get_cost_sum(costs_config$tka_primary, "patient")

  am_new[tka == 1 & revi == 0, cycle_cost_healthcare := .SD$cycle_cost_healthcare + healthcare_tka_cost, .SDcols = "cycle_cost_healthcare"]
  am_new[tka == 1 & revi == 0, cycle_cost_patient := .SD$cycle_cost_patient + patient_tka_cost, .SDcols = "cycle_cost_patient"]

  # 2. Revision TKA Cost
  healthcare_revision_cost <-
    get_cost_sum(costs_config$tka_revision, "healthcare_system")
  patient_revision_cost <-
    get_cost_sum(costs_config$tka_revision, "patient")

  am_new[revi == 1, cycle_cost_healthcare := .SD$cycle_cost_healthcare + healthcare_revision_cost, .SDcols = "cycle_cost_healthcare"]
  am_new[revi == 1, cycle_cost_patient := .SD$cycle_cost_patient + patient_revision_cost, .SDcols = "cycle_cost_patient"]

  # 3. Inpatient Rehab Cost
  healthcare_rehab_cost <-
    get_cost_sum(costs_config$inpatient_rehab, "healthcare_system")
  patient_rehab_cost <-
    get_cost_sum(costs_config$inpatient_rehab, "patient")

  am_new[ir == 1, cycle_cost_healthcare := .SD$cycle_cost_healthcare + healthcare_rehab_cost, .SDcols = "cycle_cost_healthcare"]
  am_new[ir == 1, cycle_cost_patient := .SD$cycle_cost_patient + patient_rehab_cost, .SDcols = "cycle_cost_patient"]

  # 4. Annual OA Management Cost
  healthcare_oa_cost <-
    get_cost_sum(costs_config$oa_annual_management, "healthcare_system")
  patient_oa_cost <-
    get_cost_sum(costs_config$oa_annual_management, "patient")

  am_new[oa == 1 & dead == 0, cycle_cost_healthcare := .SD$cycle_cost_healthcare + healthcare_oa_cost, .SDcols = "cycle_cost_healthcare"]
  am_new[oa == 1 & dead == 0, cycle_cost_patient := .SD$cycle_cost_patient + patient_oa_cost, .SDcols = "cycle_cost_patient"]

  # 5. Societal Costs (Productivity and Informal Care)
  prod_cost <- get_cost_sum(costs_config$productivity_loss, "societal")
  informal_care_cost <-
    get_cost_sum(costs_config$informal_care, "societal")

  am_new[oa == 1 & dead == 0, cycle_cost_societal := .SD$cycle_cost_societal + prod_cost + informal_care_cost, .SDcols = "cycle_cost_societal"]

  # 6. TKA Complication Cost
  healthcare_complication_cost <-
    get_cost_sum(costs_config$tka_complication, "healthcare_system")
  patient_complication_cost <-
    get_cost_sum(costs_config$tka_complication, "patient")

  am_new[comp == 1, cycle_cost_healthcare := .SD$cycle_cost_healthcare + healthcare_complication_cost, .SDcols = "cycle_cost_healthcare"]
  am_new[comp == 1, cycle_cost_patient := .SD$cycle_cost_patient + patient_complication_cost, .SDcols = "cycle_cost_patient"]

  # 7. Comorbidity Costs
  # These are added directly to the healthcare cost perspective for simplicity.
  if ("comorbidity_cost" %in% names(am_new)) {
    am_new[dead == 0, cycle_cost_healthcare := .SD$cycle_cost_healthcare + .SD$comorbidity_cost, .SDcols = c("cycle_cost_healthcare", "comorbidity_cost")]
  }

  # 8. Intervention Costs
  if ("intervention_cost" %in% names(am_new)) {
    am_new[dead == 0, cycle_cost_healthcare := .SD$cycle_cost_healthcare + .SD$intervention_cost, .SDcols = c("cycle_cost_healthcare", "intervention_cost")]
  }

  # --- Calculate Total Cost ---
  am_new[, cycle_cost_total := .SD$cycle_cost_healthcare + .SD$cycle_cost_patient + .SD$cycle_cost_societal, .SDcols = c("cycle_cost_healthcare", "cycle_cost_patient", "cycle_cost_societal")]

  am_new
}
