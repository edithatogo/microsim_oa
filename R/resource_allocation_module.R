#' Resource Allocation Module
#'
#' This module implements comprehensive resource allocation modeling for the
#' Australian healthcare system within the AUS-OA microsimulation framework.
#'
#' Key Features:
#' - Hospital capacity modeling by type (public/private, metro/regional)
#' - Regional capacity variations and referral patterns
#' - Dynamic capacity allocation based on demand
#' - Resource utilization tracking
#' - Capacity constraint impacts on wait times and outcomes
#' - Integration with existing waiting list and pathways modules
#'
#' Australian Healthcare Context:
#' - Public hospitals: Government-funded, universal access, capacity constraints
#' - Private hospitals: Fee-for-service, faster access, capacity varies by region
#' - Regional variations: Metro areas have more capacity, rural areas have less
#' - Referral patterns: Complex patients may be referred to specialized centers

#' Define Hospital Types and Capacity Structure
#'
#' @return List of hospital types with their characteristics
define_hospital_types <- function() {
  hospital_types <- list(
    public_metro = list(
      name = "Public Metropolitan",
      capacity_modifier = 1.2, # 20% more capacity than baseline
      specialization_level = "comprehensive",
      referral_acceptance = 0.9, # High acceptance rate
      cost_modifier = 1.0, # Baseline costs
      quality_modifier = 1.0 # Baseline quality
    ),
    public_regional = list(
      name = "Public Regional",
      capacity_modifier = 0.8, # 20% less capacity than baseline
      specialization_level = "general",
      referral_acceptance = 0.7, # Moderate acceptance
      cost_modifier = 0.95, # Slightly lower costs
      quality_modifier = 0.98 # Slightly lower quality
    ),
    private_metro = list(
      name = "Private Metropolitan",
      capacity_modifier = 1.1, # 10% more capacity
      specialization_level = "specialized",
      referral_acceptance = 0.6, # Selective acceptance
      cost_modifier = 1.5, # Higher costs
      quality_modifier = 1.05 # Higher quality
    ),
    private_regional = list(
      name = "Private Regional",
      capacity_modifier = 0.6, # 40% less capacity
      specialization_level = "limited",
      referral_acceptance = 0.4, # Low acceptance
      cost_modifier = 1.3, # Moderate costs
      quality_modifier = 1.02 # Slightly higher quality
    )
  )

  return(hospital_types)
}

#' Calculate Regional Capacity Distribution
#'
#' @param total_capacity Total healthcare capacity in the system
#' @param regional_params Parameters for regional distribution
#' @return Capacity allocation by region and hospital type
calculate_regional_capacity <- function(total_capacity, regional_params) {
  # Regional population distribution (approximate Australian distribution)
  regional_distribution <- list(
    metro = regional_params$metro_population_proportion$live, # ~70% in metro areas
    regional = regional_params$regional_population_proportion$live # ~30% in regional areas
  )

  # Hospital type distribution within regions
  hospital_distribution <- list(
    metro = list(
      public = regional_params$metro_public_hospital_proportion$live, # ~60% public in metro
      private = regional_params$metro_private_hospital_proportion$live # ~40% private in metro
    ),
    regional = list(
      public = regional_params$regional_public_hospital_proportion$live, # ~80% public in regional
      private = regional_params$regional_private_hospital_proportion$live # ~20% private in regional
    )
  )

  # Calculate capacity by region and type
  capacity_allocation <- list()

  for (region in names(regional_distribution)) {
    region_capacity <- total_capacity * regional_distribution[[region]]

    for (hospital_type in names(hospital_distribution[[region]])) {
      type_proportion <- hospital_distribution[[region]][[hospital_type]]
      type_capacity <- region_capacity * type_proportion

      key <- paste(region, hospital_type, sep = "_")
      capacity_allocation[[key]] <- type_capacity
    }
  }

  return(capacity_allocation)
}

#' Model Referral Patterns and Acceptance
#'
#' @param patients Patient data with clinical characteristics
#' @param hospital_types Hospital type definitions
#' @param referral_params Referral pattern parameters
#' @return Referral decisions and acceptance rates
model_referral_patterns <- function(patients, hospital_types, referral_params) {
  # Initialize referral outcomes
  patients$referral_needed <- FALSE
  patients$referral_accepted <- FALSE
  patients$final_hospital_type <- patients$care_pathway # Default to current pathway

  # Identify patients who may need referral (complex cases)
  complex_criteria <- list(
    high_comorbidity = patients$ccount >= referral_params$complex_case_threshold$live,
    advanced_age = patients$age >= referral_params$elderly_threshold$live,
    previous_complications = !is.na(patients$comp) & patients$comp > 0
  )

  # Patients needing referral if they meet any complex criteria
  patients$referral_needed <- apply(
    do.call(cbind, complex_criteria),
    1,
    any,
    na.rm = TRUE
  )

  # Model referral acceptance based on hospital type and patient characteristics
  referral_patients <- which(patients$referral_needed)

  if (length(referral_patients) > 0) {
    for (i in referral_patients) {
      current_pathway <- patients$care_pathway[i]
      hospital_key <- paste0(current_pathway, "_", patients$region[i])

      # Get acceptance rate for this hospital type
      acceptance_rate <- hospital_types[[hospital_key]]$referral_acceptance

      # Adjust acceptance based on patient complexity
      complexity_factor <- 1.0
      if (patients$ccount[i] >= 3) {
        complexity_factor <- referral_params$high_complexity_penalty$live
      }

      adjusted_acceptance <- acceptance_rate * complexity_factor

      # Determine if referral is accepted
      patients$referral_accepted[i] <- runif(1) < adjusted_acceptance

      # Update final hospital assignment
      if (patients$referral_accepted[i]) {
        # Successful referral - patient gets specialized care
        patients$final_hospital_type[i] <- paste0("specialized_", current_pathway)
      } else {
        # Referral denied - patient stays in current system
        patients$final_hospital_type[i] <- current_pathway
      }
    }
  }

  return(patients)
}

#' Calculate Capacity Utilization and Constraints
#'
#' @param patients Patient demand data
#' @param capacity_allocation Hospital capacity by type
#' @param hospital_types Hospital type definitions
#' @return Capacity utilization metrics and constraint impacts
calculate_capacity_utilization <- function(patients, capacity_allocation, hospital_types) {
  # Aggregate demand by hospital type
  demand_by_type <- table(patients$final_hospital_type)
  demand_by_type <- as.list(demand_by_type)

  # Calculate utilization rates
  utilization <- list()

  for (type_key in names(capacity_allocation)) {
    capacity <- capacity_allocation[[type_key]]
    demand <- demand_by_type[[type_key]]

    if (is.null(demand)) demand <- 0

    utilization_rate <- demand / capacity

    # Apply hospital-specific capacity modifier
    hospital_info <- hospital_types[[type_key]]
    if (!is.null(hospital_info)) {
      effective_capacity <- capacity * hospital_info$capacity_modifier
      utilization_rate <- demand / effective_capacity
    }

    utilization[[type_key]] <- list(
      capacity = capacity,
      demand = demand,
      utilization_rate = utilization_rate,
      is_constrained = utilization_rate > 1.0,
      constraint_severity = max(0, utilization_rate - 1.0)
    )
  }

  return(utilization)
}

#' Model Capacity Constraint Impacts
#'
#' @param patients Patient data
#' @param utilization Capacity utilization metrics
#' @param constraint_params Parameters for constraint impacts
#' @return Updated patient data with constraint effects
model_capacity_constraints <- function(patients, utilization, constraint_params) {
  # Initialize constraint impact variables
  patients$capacity_delay <- 0
  patients$capacity_quality_impact <- 1.0
  patients$capacity_cost_impact <- 1.0

  # Apply constraint impacts based on hospital type utilization
  for (i in 1:nrow(patients)) {
    hospital_type <- patients$final_hospital_type[i]

    if (hospital_type %in% names(utilization)) {
      util_info <- utilization[[hospital_type]]

      if (util_info$is_constrained) {
        # Calculate delay impact
        delay_months <- util_info$constraint_severity *
          constraint_params$delay_per_capacity_unit$live
        patients$capacity_delay[i] <- delay_months

        # Calculate quality impact
        quality_reduction <- util_info$constraint_severity *
          constraint_params$quality_impact_per_capacity_unit$live
        patients$capacity_quality_impact[i] <- max(0.8, 1.0 - quality_reduction)

        # Calculate cost impact
        cost_increase <- util_info$constraint_severity *
          constraint_params$cost_impact_per_capacity_unit$live
        patients$capacity_cost_impact[i] <- 1.0 + cost_increase
      }
    }
  }

  return(patients)
}

#' Generate Resource Allocation Summary
#'
#' @param utilization Capacity utilization metrics
#' @param patients Patient data with constraint impacts
#' @param referral_summary Referral pattern summary
#' @return Comprehensive resource allocation summary
generate_resource_allocation_summary <- function(utilization, patients, referral_summary) {
  summary <- list(
    timestamp = Sys.time(),
    overall_metrics = list(
      total_capacity_utilization = mean(sapply(utilization, function(x) x$utilization_rate)),
      constrained_hospitals = sum(sapply(utilization, function(x) x$is_constrained)),
      total_referrals_needed = sum(patients$referral_needed, na.rm = TRUE),
      referrals_accepted = sum(patients$referral_accepted, na.rm = TRUE),
      referral_success_rate = mean(patients$referral_accepted[patients$referral_needed], na.rm = TRUE)
    ),
    hospital_utilization = utilization,
    regional_analysis = list(
      metro_utilization = mean(sapply(
        utilization[grepl("metro", names(utilization))],
        function(x) x$utilization_rate
      )),
      regional_utilization = mean(sapply(
        utilization[grepl("regional", names(utilization))],
        function(x) x$utilization_rate
      ))
    ),
    constraint_impacts = list(
      average_delay_months = mean(patients$capacity_delay, na.rm = TRUE),
      average_quality_impact = mean(patients$capacity_quality_impact, na.rm = TRUE),
      average_cost_impact = mean(patients$capacity_cost_impact, na.rm = TRUE),
      patients_affected_by_constraints = sum(patients$capacity_delay > 0, na.rm = TRUE)
    )
  )

  return(summary)
}

#' Main Resource Allocation Module Function
#'
#' @param patients Patient attribute matrix
#' @param resource_params Resource allocation parameters from configuration
#' @return List containing updated patient data and resource allocation summary
resource_allocation_module <- function(patients, resource_params) {
  # Step 1: Define hospital types and characteristics
  hospital_types <- define_hospital_types()

  # Step 2: Calculate regional capacity distribution
  total_capacity <- resource_params$total_system_capacity$live
  capacity_allocation <- calculate_regional_capacity(total_capacity, resource_params$regional)

  # Step 3: Model referral patterns
  patients <- model_referral_patterns(patients, hospital_types, resource_params$referral)

  # Step 4: Calculate capacity utilization
  utilization <- calculate_capacity_utilization(patients, capacity_allocation, hospital_types)

  # Step 5: Model capacity constraint impacts
  patients <- model_capacity_constraints(patients, utilization, resource_params$constraints)

  # Step 6: Generate comprehensive summary
  referral_summary <- list(
    total_referrals = sum(patients$referral_needed),
    accepted_referrals = sum(patients$referral_accepted),
    acceptance_rate = mean(patients$referral_accepted[patients$referral_needed], na.rm = TRUE)
  )

  resource_summary <- generate_resource_allocation_summary(utilization, patients, referral_summary)

  result <- list(
    patients = patients,
    hospital_types = hospital_types,
    capacity_allocation = capacity_allocation,
    utilization = utilization,
    resource_summary = resource_summary
  )

  return(result)
}
