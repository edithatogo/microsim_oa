#' Calculate Costs for a Simulation Cycle
#'
#' This function calculates various costs for each individual in the attribute
#' matrix based on events that occurred in the current cycle (e.g., TKA,
#' revision) and ongoing states (e.g., having OA).
#'
#' @param am_new A data.table representing the attribute matrix with the
#'   latest events for the current cycle.
#' @param costs_config A list containing the cost parameters from the model
#'   configuration file.
#'
#' @return The `am_new` data.table with new columns for the costs incurred
#'   during the cycle (e.g., `cycle_cost_total`, `cycle_cost_oop`).
#' @export
calculate_costs_fcn <- function(am_new, costs_config) {
  
  # Initialize cycle costs to 0
  am_new[, cycle_cost_total := 0]
  am_new[, cycle_cost_oop := 0]
  am_new[, cycle_cost_prod := 0]
  am_new[, cycle_cost_informal := 0]
  
  # --- Event-Based Costs ---
  
  # Primary TKA cost
  # Note: `tka` is 1 if a TKA happened in this cycle. `tka1` is the state of ever having a TKA.
  # We assume `revi` (revision) is mutually exclusive with a new primary TKA in the same cycle.
  am_new[tka == 1 & revi == 0, cycle_cost_total := cycle_cost_total + costs_config$tka_primary$total]
  am_new[tka == 1 & revi == 0, cycle_cost_oop := cycle_cost_oop + costs_config$tka_primary$out_of_pocket]
  
  # Revision TKA cost
  am_new[revi == 1, cycle_cost_total := cycle_cost_total + costs_config$tka_revision$total]
  am_new[revi == 1, cycle_cost_oop := cycle_cost_oop + costs_config$tka_revision$out_of_pocket]
  
  # Inpatient rehab cost (assume it happens after any TKA)
  am_new[tka == 1, cycle_cost_total := cycle_cost_total + costs_config$inpatient_rehab$total]
  am_new[tka == 1, cycle_cost_oop := cycle_cost_oop + costs_config$inpatient_rehab$out_of_pocket]
  
  # --- State-Based (Annual) Costs ---
  
  # Annual management cost for everyone with OA who is alive
  am_new[oa == 1 & dead == 0, cycle_cost_total := cycle_cost_total + costs_config$oa_annual_management$total]
  am_new[oa == 1 & dead == 0, cycle_cost_oop := cycle_cost_oop + costs_config$oa_annual_management$out_of_pocket]
  
  # Productivity and informal care costs for everyone with OA who is alive
  am_new[oa == 1 & dead == 0, cycle_cost_prod := cycle_cost_prod + costs_config$productivity_loss$value]
  am_new[oa == 1 & dead == 0, cycle_cost_informal := cycle_cost_informal + costs_config$informal_care$value]
  
  # Add comorbidity costs (calculated in the comorbidity update function)
  if ("comorbidity_cost" %in% names(am_new)) {
    am_new[dead == 0, cycle_cost_total := cycle_cost_total + comorbidity_cost]
  }
  
  return(am_new)
}
