#' Waiting List Dynamics Module
#'
#' This module implements advanced waiting list dynamics for the AUS-OA microsimulation model.
#' It models patient prioritization, queue management, capacity constraints, and wait time impacts
#' on clinical outcomes and costs.
#'
#' Key Features:
#' - Clinical prioritization based on urgency scores
#' - Queue management with capacity constraints
#' - Wait time impacts on outcomes (progression of OA, QALY loss)
#' - Different prioritization schemes (clinical need, age, socioeconomic factors)
#' - Public vs private pathway considerations
#'
#' Clinical References:
#' - Australian Orthopaedic Association guidelines
#' - NICE osteoarthritis guidelines
#' - Health system capacity modeling literature
#' - Wait time impact studies

#' Calculate Clinical Urgency Score for TKA Prioritization
#'
#' @param am_curr Current attribute matrix
#' @param prioritization_scheme Type of prioritization ("clinical", "age", "socioeconomic", "combined")
#' @return Data.table with urgency scores and prioritization rankings
calculate_urgency_score <- function(am_curr, prioritization_scheme = "clinical") {
  # Initialize urgency score
  am_curr$urgency_score <- 0
  am_curr$priority_rank <- 0

  # Identify patients needing TKA (OA patients who haven't had TKA yet)
  oa_patients <- which(am_curr$oa == 1 & am_curr$tka == 0 & am_curr$dead == 0)

  if (length(oa_patients) > 0) {
    if (prioritization_scheme == "clinical") {
      # Clinical prioritization based on pain, function, and OA severity
      am_curr$urgency_score[oa_patients] <- (
        am_curr$pain[oa_patients] * 0.4 +                    # Pain component (40%)
        (1 - am_curr$function_score[oa_patients]) * 0.3 +    # Function component (30%)
        (am_curr$kl3[oa_patients] + am_curr$kl4[oa_patients]) * 0.2 +  # OA severity (20%)
        am_curr$ccount[oa_patients] * 0.1                    # Comorbidities (10%)
      )

    } else if (prioritization_scheme == "age") {
      # Age-based prioritization (older patients first)
      am_curr$urgency_score[oa_patients] <- am_curr$age[oa_patients] / 100

    } else if (prioritization_scheme == "socioeconomic") {
      # Socioeconomic prioritization (lower SEP higher priority)
      if ("year12" %in% names(am_curr)) {
        am_curr$urgency_score[oa_patients] <- (1 - am_curr$year12[oa_patients]) * 0.6 +
          am_curr$ccount[oa_patients] * 0.4
      } else {
        am_curr$urgency_score[oa_patients] <- am_curr$ccount[oa_patients]
      }

    } else if (prioritization_scheme == "combined") {
      # Combined clinical and socioeconomic factors
      clinical_score <- (
        am_curr$pain[oa_patients] * 0.3 +
        (1 - am_curr$function_score[oa_patients]) * 0.3 +
        (am_curr$kl3[oa_patients] + am_curr$kl4[oa_patients]) * 0.2 +
        am_curr$ccount[oa_patients] * 0.2
      )

      socioeconomic_score <- ifelse("year12" %in% names(am_curr),
                                   (1 - am_curr$year12[oa_patients]), 0)

      am_curr$urgency_score[oa_patients] <- clinical_score * 0.7 + socioeconomic_score * 0.3
    }

    # Calculate priority rankings (higher score = higher priority)
    am_curr$priority_rank[oa_patients] <- rank(-am_curr$urgency_score[oa_patients],
                                              ties.method = "first")
  }

  return(am_curr)
}

#' Model Queue Management with Capacity Constraints
#'
#' @param am_curr Current attribute matrix with urgency scores
#' @param capacity_constraints List of capacity parameters
#' @return Updated attribute matrix with queue status and wait times
model_queue_management <- function(am_curr, capacity_constraints) {
  # Initialize queue-related columns
  if (!"queue_position" %in% names(am_curr)) am_curr$queue_position <- 0
  if (!"wait_time_months" %in% names(am_curr)) am_curr$wait_time_months <- 0
  if (!"treatment_delayed" %in% names(am_curr)) am_curr$treatment_delayed <- 0

  # Get patients on waiting list (OA patients needing TKA)
  waiting_patients <- which(am_curr$oa == 1 & am_curr$tka == 0 & am_curr$dead == 0)

  if (length(waiting_patients) > 0) {
    # Set queue positions based on priority rankings
    am_curr$queue_position[waiting_patients] <- am_curr$priority_rank[waiting_patients]

    # Calculate available capacity (surgeries per cycle)
    total_capacity <- capacity_constraints$total_capacity
    public_capacity <- total_capacity * capacity_constraints$public_proportion
    private_capacity <- total_capacity * (1 - capacity_constraints$public_proportion)

    # Determine how many patients can be treated this cycle
    n_waiting <- length(waiting_patients)

    if (n_waiting <= total_capacity) {
      # All patients can be treated
      treated_patients <- waiting_patients
      am_curr$wait_time_months[treated_patients] <- 0
      am_curr$treatment_delayed[treated_patients] <- 0
    } else {
      # Capacity constraint - prioritize by urgency
      treated_indices <- order(am_curr$priority_rank[waiting_patients])[1:total_capacity]
      treated_patients <- waiting_patients[treated_indices]
      untreated_patients <- waiting_patients[-treated_indices]

      # Treated patients
      am_curr$wait_time_months[treated_patients] <- 0
      am_curr$treatment_delayed[treated_patients] <- 0

      # Untreated patients experience delays
      am_curr$treatment_delayed[untreated_patients] <- 1

      # Estimate wait times for untreated patients (simplified model)
      # In a full implementation, this would track cumulative wait times
      am_curr$wait_time_months[untreated_patients] <- sample(3:24,
                                                           length(untreated_patients),
                                                           replace = TRUE)
    }

    # Mark treated patients for TKA in next cycle
    am_curr$scheduled_tka <- 0
    am_curr$scheduled_tka[treated_patients] <- 1
  }

  return(am_curr)
}

#' Calculate Wait Time Impacts on Outcomes
#'
#' @param am_curr Current attribute matrix with wait times
#' @param wait_time_coefficients Parameters for wait time impacts
#' @return Updated attribute matrix with wait time impacts
calculate_wait_time_impacts <- function(am_curr, wait_time_coefficients) {
  # Initialize impact columns
  if (!"wait_time_qaly_loss" %in% names(am_curr)) am_curr$wait_time_qaly_loss <- 0
  if (!"wait_time_cost" %in% names(am_curr)) am_curr$wait_time_cost <- 0
  if (!"oa_progression_due_to_delay" %in% names(am_curr)) am_curr$oa_progression_due_to_delay <- 0

  # Identify patients with treatment delays
  delayed_patients <- which(am_curr$treatment_delayed == 1 & am_curr$wait_time_months > 0)

  if (length(delayed_patients) > 0) {
    wait_months <- am_curr$wait_time_months[delayed_patients]

    # QALY loss due to delayed treatment
    # Based on pain and function deterioration during wait
    qaly_loss_per_month <- wait_time_coefficients$qaly_loss_per_month
    am_curr$wait_time_qaly_loss[delayed_patients] <- wait_months * qaly_loss_per_month

    # Additional healthcare costs during wait period
    cost_per_month <- wait_time_coefficients$additional_cost_per_month
    am_curr$wait_time_cost[delayed_patients] <- wait_months * cost_per_month

    # Risk of OA progression during wait
    progression_prob <- wait_time_coefficients$oa_progression_prob_per_month
    progression_risk <- 1 - (1 - progression_prob)^wait_months

    progression_rand <- runif(length(delayed_patients))
    progression_occurs <- progression_rand < progression_risk

    if (any(progression_occurs)) {
      progression_indices <- delayed_patients[progression_occurs]
      am_curr$oa_progression_due_to_delay[progression_indices] <- 1

      # OA progression impacts (KL grade advancement)
      am_curr$kl3[progression_indices] <- pmin(1, am_curr$kl3[progression_indices] +
                                               am_curr$kl4[progression_indices])
      am_curr$kl4[progression_indices] <- pmin(1, am_curr$kl4[progression_indices] + 0.5)
    }
  }

  return(am_curr)
}

#' Model Public vs Private Pathway Selection
#'
#' @param am_curr Current attribute matrix
#' @param pathway_coefficients Parameters for pathway selection
#' @return Updated attribute matrix with pathway assignments
model_pathway_selection <- function(am_curr, pathway_coefficients) {
  # Initialize pathway columns
  if (!"care_pathway" %in% names(am_curr)) am_curr$care_pathway <- "public"
  if (!"pathway_cost_multiplier" %in% names(am_curr)) am_curr$pathway_cost_multiplier <- 1.0

  # Identify patients scheduled for TKA
  scheduled_patients <- which(am_curr$scheduled_tka == 1)

  if (length(scheduled_patients) > 0) {
    # Pathway selection based on socioeconomic factors and clinical urgency
    for (i in scheduled_patients) {
      # Socioeconomic factors favoring private care
      socioeconomic_score <- 0
      if ("year12" %in% names(am_curr) && am_curr$year12[i] == 1) {
        socioeconomic_score <- socioeconomic_score + 0.3  # Higher education
      }
      if ("high_income" %in% names(am_curr) && am_curr$high_income[i] == 1) {
        socioeconomic_score <- socioeconomic_score + 0.4  # Higher income
      }

      # Clinical urgency favoring public care (higher urgency = more likely public)
      urgency_factor <- am_curr$urgency_score[i]

      # Combined probability of choosing private care
      private_prob <- pathway_coefficients$private_base_prob +
                     socioeconomic_score * pathway_coefficients$socioeconomic_weight -
                     urgency_factor * pathway_coefficients$urgency_weight

      private_prob <- max(0, min(1, private_prob))  # Bound between 0 and 1

      # Random selection
      if (runif(1) < private_prob) {
        am_curr$care_pathway[i] <- "private"
        am_curr$pathway_cost_multiplier[i] <- pathway_coefficients$private_cost_multiplier
      } else {
        am_curr$care_pathway[i] <- "public"
        am_curr$pathway_cost_multiplier[i] <- 1.0
      }
    }
  }

  return(am_curr)
}

#' Main Waiting List Module Function
#'
#' @param am_curr Current attribute matrix
#' @param am_new Next cycle attribute matrix
#' @param waiting_list_params Parameters from configuration
#' @return List containing updated matrices and waiting list summary
waiting_list_module <- function(am_curr, am_new, waiting_list_params) {
  # Extract parameters
  prioritization_scheme <- waiting_list_params$prioritization_scheme %||% "clinical"
  capacity_params <- waiting_list_params$capacity
  wait_time_params <- waiting_list_params$wait_time_impacts
  pathway_params <- waiting_list_params$pathways

  # Step 1: Calculate urgency scores and prioritization
  am_curr <- calculate_urgency_score(am_curr, prioritization_scheme)

  # Step 2: Model queue management with capacity constraints
  am_curr <- model_queue_management(am_curr, capacity_params)

  # Step 3: Calculate wait time impacts
  am_curr <- calculate_wait_time_impacts(am_curr, wait_time_params)

  # Step 4: Model pathway selection
  am_curr <- model_pathway_selection(am_curr, pathway_params)

  # Create waiting list summary
  waiting_list_summary <- list(
    total_waiting = sum(am_curr$oa == 1 & am_curr$tka == 0 & am_curr$dead == 0),
    scheduled_for_tka = sum(am_curr$scheduled_tka == 1),
    treatment_delayed = sum(am_curr$treatment_delayed == 1),
    average_wait_time = mean(am_curr$wait_time_months[am_curr$treatment_delayed == 1], na.rm = TRUE),
    total_qaly_loss_from_waits = sum(am_curr$wait_time_qaly_loss),
    total_wait_time_costs = sum(am_curr$wait_time_cost),
    oa_progressions_due_to_delay = sum(am_curr$oa_progression_due_to_delay),
    public_pathway_count = sum(am_curr$care_pathway == "public", na.rm = TRUE),
    private_pathway_count = sum(am_curr$care_pathway == "private", na.rm = TRUE),
    prioritization_scheme = prioritization_scheme
  )

  # Update am_new with waiting list status
  am_new$urgency_score <- am_curr$urgency_score
  am_new$queue_position <- am_curr$queue_position
  am_new$wait_time_months <- am_curr$wait_time_months
  am_new$treatment_delayed <- am_curr$treatment_delayed
  am_new$scheduled_tka <- am_curr$scheduled_tka
  am_new$wait_time_qaly_loss <- am_curr$wait_time_qaly_loss
  am_new$wait_time_cost <- am_curr$wait_time_cost
  am_new$oa_progression_due_to_delay <- am_curr$oa_progression_due_to_delay
  am_new$care_pathway <- am_curr$care_pathway
  am_new$pathway_cost_multiplier <- am_curr$pathway_cost_multiplier

  # Apply QALY impacts from wait times
  am_curr$d_sf6d <- am_curr$d_sf6d + am_curr$wait_time_qaly_loss

  result <- list(
    am_curr = am_curr,
    am_new = am_new,
    waiting_list_summary = waiting_list_summary
  )

  return(result)
}

`%||%` <- function(x, y) if (is.null(x)) y else x
