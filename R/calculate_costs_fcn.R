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
#'
#' @examples
#' # Create test data for cost calculation
#' test_data <- data.frame(
#'   tka = sample(c(0, 1), 100, replace = TRUE),
#'   revi = sample(c(0, 1), 100, replace = TRUE, prob = c(0.9, 0.1)),
#'   oa = rep(1, 100),
#'   dead = sample(c(0, 1), 100, replace = TRUE, prob = c(0.99, 0.01)),
#'   ir = sample(c(0, 1), 100, replace = TRUE),
#'   comp = sample(c(0, 1), 100, replace = TRUE, prob = c(0.8, 0.2)),
#'   comorbidity_cost = runif(100, 0, 10000),
#'   intervention_cost = runif(100, 0, 2000),
#'   stringsAsFactors = FALSE
#' )
#' 
#' # Create a simple cost configuration
#' cost_config <- list(
#'   costs = list(
#'     tka_primary = list(
#'       hospital_stay = list(value = 15000, perspective = "healthcare_system"),
#'       patient_gap = list(value = 2000, perspective = "patient")
#'     ),
#'     tka_revision = list(
#'       hospital_stay = list(value = 20000, perspective = "healthcare_system"),
#'       patient_gap = list(value = 2500, perspective = "patient")
#'     )
#'   )
#' )
#' 
#' # Calculate costs
#' # result <- calculate_costs_fcn(test_data, cost_config)

calculate_costs_fcn <- function(am_new, costs_config) {
  # Ensure am_new is a data.table
  setDT(am_new)

  # --- Defensive Checks for Cost Configuration ---
  # Ensure all cost components exist, defaulting to a structure with a value of 0
  # to prevent errors if a cost component is missing from the config.
  required_costs <- c(
    "tka_primary", "tka_revision", "inpatient_rehab",
    "oa_annual_management", "productivity_loss",
    "informal_care", "tka_complication"
  )
  for (cost_name in required_costs) {
    if (is.null(costs_config$costs[[cost_name]])) {
      costs_config$costs[[cost_name]] <- list(
        component = list(perspective = "none", value = 0)
      )
    }
  }

  # Appease R CMD check
  cycle_cost_healthcare <- cycle_cost_patient <- cycle_cost_societal <- NULL
  tka <- revi <- ir <- oa <- dead <- comp <- comorbidity_cost <- NULL
  intervention_cost <- cycle_cost_total <- NULL

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
    get_cost_sum(costs_config$costs$tka_primary, "healthcare_system")
  patient_tka_cost <- get_cost_sum(costs_config$costs$tka_primary, "patient")

  am_new[tka == 1 & revi == 0, cycle_cost_healthcare := cycle_cost_healthcare + healthcare_tka_cost]
  am_new[tka == 1 & revi == 0, cycle_cost_patient := cycle_cost_patient + patient_tka_cost]

  # 2. Revision TKA Cost
  healthcare_revision_cost <-
    get_cost_sum(costs_config$costs$tka_revision, "healthcare_system")
  patient_revision_cost <-
    get_cost_sum(costs_config$costs$tka_revision, "patient")

  am_new[revi == 1, cycle_cost_healthcare := cycle_cost_healthcare + healthcare_revision_cost]
  am_new[revi == 1, cycle_cost_patient := cycle_cost_patient + patient_revision_cost]

  # 3. Inpatient Rehab Cost
  healthcare_rehab_cost <-
    get_cost_sum(costs_config$costs$inpatient_rehab, "healthcare_system")
  patient_rehab_cost <-
    get_cost_sum(costs_config$costs$inpatient_rehab, "patient")

  am_new[ir == 1, cycle_cost_healthcare := cycle_cost_healthcare + healthcare_rehab_cost]
  am_new[ir == 1, cycle_cost_patient := cycle_cost_patient + patient_rehab_cost]

  # 4. Annual OA Management Cost
  healthcare_oa_cost <-
    get_cost_sum(costs_config$costs$oa_annual_management, "healthcare_system")
  patient_oa_cost <-
    get_cost_sum(costs_config$costs$oa_annual_management, "patient")

  am_new[oa == 1 & dead == 0, cycle_cost_healthcare := cycle_cost_healthcare + healthcare_oa_cost]
  am_new[oa == 1 & dead == 0, cycle_cost_patient := cycle_cost_patient + patient_oa_cost]

  # 5. Societal Costs (Productivity and Informal Care)
  # Enhanced productivity cost calculation based on PROs and workforce status
  am_new[, productivity_cost := 0]

  # Calculate productivity costs for working-age individuals with OA
  if ("pain" %in% names(am_new) && "function_score" %in% names(am_new)) {
    # Assume working age is 18-65 for productivity calculations
    working_age_indices <- which(am_new$age >= 18 & am_new$age <= 65 & am_new$oa == 1 & am_new$dead == 0)

    if (length(working_age_indices) > 0) {
      # Absenteeism: days off work based on pain and function scores
      # Higher pain and lower function = more absenteeism
      pain_factor <- am_new$pain[working_age_indices]
      function_factor <- 1 - am_new$function_score[working_age_indices] # invert so lower function = higher cost

      # Normalize and combine factors (simplified model)
      absenteeism_factor <- (pain_factor + function_factor) / 2

      # Presenteeism: reduced productivity while at work
      presenteeism_factor <- absenteeism_factor * 0.7 # Assume presenteeism is 70% of absenteeism impact

      # Calculate annual productivity cost
      # Assume average annual wage and working days
      avg_annual_wage <- 50000 # This should come from config
      working_days_per_year <- 220

      annual_absenteeism_cost <- avg_annual_wage * (absenteeism_factor / working_days_per_year) * 5 # 5 days max absenteeism
      annual_presenteeism_cost <- avg_annual_wage * presenteeism_factor * 0.3 # 30% productivity loss

      am_new$productivity_cost[working_age_indices] <- annual_absenteeism_cost + annual_presenteeism_cost
    }
  }

  # Fallback to simple productivity cost if PROs not available
  if (all(am_new$productivity_cost == 0)) {
    prod_cost <- get_cost_sum(costs_config$costs$productivity_loss, "societal")
    am_new[oa == 1 & dead == 0, productivity_cost := prod_cost]
  }

  informal_care_cost <- get_cost_sum(costs_config$costs$informal_care, "societal")

  am_new[, cycle_cost_societal := cycle_cost_societal + productivity_cost]
  am_new[oa == 1 & dead == 0, cycle_cost_societal := cycle_cost_societal + informal_care_cost]

  # 6. TKA Complication Cost
  healthcare_complication_cost <-
    get_cost_sum(costs_config$costs$tka_complication, "healthcare_system")
  patient_complication_cost <-
    get_cost_sum(costs_config$costs$tka_complication, "patient")

  am_new[comp == 1, cycle_cost_healthcare := cycle_cost_healthcare + healthcare_complication_cost]
  am_new[comp == 1, cycle_cost_patient := cycle_cost_patient + patient_complication_cost]

  # 7. Comorbidity Costs
  # These are added directly to the healthcare cost perspective for simplicity.
  if ("comorbidity_cost" %in% names(am_new)) {
    am_new[dead == 0, cycle_cost_healthcare := cycle_cost_healthcare + comorbidity_cost]
  }

  # 8. Intervention Costs
  if ("intervention_cost" %in% names(am_new)) {
    am_new[dead == 0, cycle_cost_healthcare := cycle_cost_healthcare + intervention_cost]
  }

  # --- Calculate Total Cost ---
  am_new[, cycle_cost_total := cycle_cost_healthcare + cycle_cost_patient + cycle_cost_societal]

  am_new
}
