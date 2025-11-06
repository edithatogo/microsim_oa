#' Simulation Cycle Function
#'
#' The main function that advances the osteoarthritis simulation by one cycle.
#' Updates the population attributes based on transition probabilities, 
#' event occurrences, and health economic calculations for the AUS-OA model.
#'
#' @param am_curr Current attribute matrix containing individual characteristics
#' @param cycle.coefficents List of coefficients for the current simulation cycle
#' @param am_new The new attribute matrix to be updated (output frame)
#' @param age_edges Age-based stratification boundaries for risk calculations
#' @param bmi_edges BMI-based stratification boundaries for risk calculations
#' @param am Original attribute matrix for reference calculations
#' @param mort_update_counter Mortality update counter for tracking
#' @param lt Lookup table for various simulation parameters
#' @param eq_cust Custom equation parameters for the cycle
#' @param tka_time_trend Time trend component for TKA procedures
#'
#' @return Updated attribute matrix with new values for the next simulation cycle
#' @export
#'
#' @examples
#' # Create a small test population
#' test_pop <- data.frame(
#'   id = 1:100,
#'   age = sample(50:80, 100, replace = TRUE),
#'   sex = sample(c(0, 1), 100, replace = TRUE),
#'   bmi = rnorm(100, mean = 28, sd = 5),
#'   kl_score = sample(0:4, 100, replace = TRUE, prob = c(0.3, 0.25, 0.2, 0.15, 0.1)),
#'   tka = sample(c(0, 1), 100, replace = TRUE, prob = c(0.95, 0.05)),
#'   stringsAsFactors = FALSE
#' )
#' 
#' # Create minimal coefficients list
#' coeffs <- list(
#'   live = 0.99,  # Survival probability
#'   pain = list(live = 0.95),  # Pain progression coefficient
#'   function = list(live = 0.90)  # Function score coefficient
#' )
#' 
#' # Create a simple lookup table
#' lookup_table <- list(
#'   age_intervals = c(50, 60, 70, 80, 90),
#'   bmi_intervals = c(18, 25, 30, 35, 40)
#' )
#' 
#' # Run one simulation cycle
#' # result <- simulation_cycle_fcn(
#' #   am_curr = test_pop,
#' #   cycle.coefficents = coeffs,
#' #   am_new = test_pop,  # Using same for simplicity
#' #   age_edges = c(50, 70, 85),
#' #   bmi_edges = c(20, 30, 40),
#' #   am = test_pop,
#' #   mort_update_counter = 0,
#' #   lt = lookup_table,
#' #   eq_cust = NULL,
#' #   tka_time_trend = 0
#' # )

simulation_cycle_fcn <- function(am_curr, cycle.coefficents, am_new,
                                 age_edges, bmi_edges,
                                 am,
                                 mort_update_counter, lt,
                                 eq_cust,
                                 tka_time_trend) {
  print(paste("Start of cycle, nrow(am_curr):", nrow(am_curr)))

  # --- Pre-emptive Initialization ---
  # Ensure critical columns exist before any calculations. This prevents
  # "object not found" errors in downstream functions.
  if (!"pain" %in% names(am_curr)) am_curr$pain <- 0
  if (!"function_score" %in% names(am_curr)) am_curr$function_score <- 0
  if (!"tka" %in% names(am_curr)) am_curr$tka <- 0
  if (!"d_sf6d" %in% names(am_curr)) am_curr$d_sf6d <- 0

  # Unpack the 'live' value from each coefficient
  live_coeffs <- lapply(cycle.coefficents, function(x) {
    if (is.list(x) && "live" %in% names(x)) {
      return(x$live)
    } else if (is.list(x)) {
      # Handle nested lists of coefficients
      return(lapply(x, function(y) {
        if (is.list(y) && "live" %in% names(y)) {
          return(y$live)
        }
        return(y)
      }))
    }
    return(x)
  })

  # extract relevant equation modification data
  BMI_cust <- eq_cust[["BMI"]]
  TKR_cust <- eq_cust[["TKR"]]
  OA_cust <- eq_cust[["OA"]]

  ############################## update BMI in cycle
  am_curr <- bmi_mod_fcn(am_curr, live_coeffs, BMI_cust)
  print(paste("After bmi_mod_fcn, nrow(am_curr):", nrow(am_curr)))


  # am_new.bmi = am_curr.bmi + d_bmi;
  # update BMI data using delta - optimized with data.table
  am_new[, bmi := am_curr$bmi + am_curr$d_bmi]

  # add impact of BMI delta to SF6D - This is now handled by calculate_qaly()
  # am_curr$d_sf6d <- am_curr$d_sf6d + (am_curr$d_bmi * live_coeffs$c14$c14_bmi)

  ############################## update personal charactistics (agecat, bmicat)
  # These need to be calculated on am_curr before being passed to OA and TKA functions

  # Convert to data.table for efficient operations
  setDT(am_curr)
  setDT(am_new)

  # Create age categories efficiently
  am_curr[, age_cat := cut(age, breaks = age_edges, include.lowest = TRUE)]
  am_curr[, `:=`(
    age044 = as.integer(age_cat == levels(age_cat)[1]),
    age4554 = as.integer(age_cat == levels(age_cat)[2]),
    age5564 = as.integer(age_cat == levels(age_cat)[3]),
    age6574 = as.integer(age_cat == levels(age_cat)[4]),
    age75 = as.integer(age_cat == levels(age_cat)[5])
  )]

  # Create BMI categories efficiently
  am_curr[, bmi_cat := cut(bmi, breaks = bmi_edges, include.lowest = TRUE)]
  am_curr[, `:=`(
    bmi024 = as.integer(bmi_cat == levels(bmi_cat)[1]),
    bmi2529 = as.integer(bmi_cat == levels(bmi_cat)[2]),
    bmi3034 = as.integer(bmi_cat == levels(bmi_cat)[3]),
    bmi3539 = as.integer(bmi_cat == levels(bmi_cat)[4]),
    bmi40 = as.integer(bmi_cat == levels(bmi_cat)[5])
  )]

  ############################## update OA incidence

  # % OA incidence - based on HILDA analysis

  OA_update_data <- OA_update(am_curr, am_new, live_coeffs, OA_cust)

  # extract data.tables from output list
  am_curr <- OA_update_data[["am_curr"]]
  am_new <- OA_update_data[["am_new"]]
  print(paste("After OA_update, nrow(am_curr):", nrow(am_curr)))

  # note: change in sf6d calculated in the OA_update function


  ############################## update comorbidies (cci, mental health)

  # % Comorbidities
  am_curr <- update_comorbidities(am_curr, live_coeffs$comorbidities)
  print(paste("After update_comorbidities, nrow(am_curr):", nrow(am_curr)))

  # Initialize PROs columns before TKA function, as they are used as predictors
  # Note: This is a temporary fix. The simulation logic should be reviewed
  # to ensure PROs are updated at the correct point in the cycle.
  if (!"pain" %in% names(am_curr)) am_curr$pain <- 0
  if (!"function_score" %in% names(am_curr)) am_curr$function_score <- 0
  if (!"tka" %in% names(am_curr)) am_curr$tka <- 0


  ############################## update TKA status (TKA, complications, revision, inpatient rehab)
  # % TKA

  # % Waiting List Dynamics - Advanced Queue Management Integration
  # Model patient prioritization, capacity constraints, and wait time impacts
  # Only integrate waiting list module if waiting list coefficients are available
  if (!is.null(live_coeffs$waiting_list)) {
    # Functions are loaded via package namespace, no need to source

    # Integrate waiting list module with simulation cycle
    waiting_list_integration_result <- integrate_waiting_list_module(am_curr, am_new, live_coeffs)

    # Extract updated matrices and waiting list summary
    am_curr <- waiting_list_integration_result$am_curr
    am_new <- waiting_list_integration_result$am_new
    waiting_list_summary <- waiting_list_integration_result$waiting_list_summary
  } else {
    # Use basic waiting list modeling if advanced module not available
    waiting_list_summary <- list(total_waiting = 0, average_wait_time = 0, capacity_utilization = 0)
  }

  TKA_update_data <- TKA_update_fcn(am_curr, am_new, live_coeffs, TKR_cust, NULL,
                                   implant_survival_data = NULL, default_implant_type = "standard")

  # extract data.tables from output list
  am_curr <- TKA_update_data[["am_curr"]]
  am_new <- TKA_update_data[["am_new"]]
  print(paste("After TKA_update_fcn, nrow(am_curr):", nrow(am_curr)))

  summ_tka_risk <- TKA_update_data[["summ_tka_risk"]]

  # % TKA complication - Advanced PJI Module Integration
  # Replace basic complication modeling with advanced PJI module
  # Only integrate PJI module if PJI coefficients are available
  if (!is.null(live_coeffs$pji_risk)) {
    # Functions are loaded via package namespace, no need to source

    # Integrate PJI module with simulation cycle
    pji_integration_result <- integrate_pji_module(am_curr, am_new, live_coeffs)

    # Extract updated matrices and PJI summary
    am_curr <- pji_integration_result$am_curr
    am_new <- pji_integration_result$am_new
    pji_summary <- pji_integration_result$pji_summary
  } else {
    # Use basic complication modeling if PJI module not available
    pji_summary <- list(total_cost = 0, total_qaly_impact = 0, incident_cases = 0)
  }

  # Keep backward compatibility with existing comp variable
  # PJI cases are now represented in the comp variable
  am_curr$compi <- am_new$comp

  # % TKA DVT complication - Advanced DVT Module Integration
  # Integrate DVT module with simulation cycle
  # Functions are loaded via package namespace, no need to source

  # Integrate DVT module with simulation cycle
  dvt_integration_result <- integrate_dvt_module(am_curr, am_new, live_coeffs)

  # Extract updated matrices and DVT summary
  am_curr <- dvt_integration_result$am_curr
  am_new <- dvt_integration_result$am_new
  dvt_summary <- dvt_integration_result$dvt_summary

  # % Public-Private Healthcare Pathways Integration
  # Model differences between public and private healthcare pathways
  # Only integrate pathways module if pathways coefficients are available
  if (!is.null(live_coeffs$pathways)) {
    # Functions are loaded via package namespace, no need to source

    # Integrate public-private pathways module with simulation cycle
    pathways_integration_result <- integrate_public_private_pathways_module(am_curr, am_new, live_coeffs, cycle.coefficents$cycle_number)

    # Extract updated matrices and pathways summary
    am_curr <- pathways_integration_result$am_curr
    am_new <- pathways_integration_result$am_new
    pathways_summary <- pathways_integration_result$integration_summary
  } else {
    # Use basic pathways modeling if advanced module not available
    pathways_summary <- list(total_cost_impact = 0, total_qaly_impact = 0, pathway_distribution = list())
  }

  # % Resource Allocation Integration
  # Model hospital capacity, regional variations, and referral patterns
  # Only integrate resource allocation module if resource coefficients are available
  if (!is.null(live_coeffs$resource_allocation)) {
    # Functions are loaded via package namespace, no need to source

    # Integrate resource allocation module with simulation cycle
    resource_integration_result <- integrate_resource_allocation_module(am_curr, am_new, live_coeffs, cycle.coefficents$cycle_number)

    # Extract updated matrices and resource allocation summary
    am_curr <- resource_integration_result$am_curr
    am_new <- resource_integration_result$am_new
    resource_summary <- resource_integration_result$resource_summary
  } else {
    # Use basic resource modeling if advanced module not available
    resource_summary <- list(total_cost_impact = 0, total_qaly_impact = 0, capacity_utilization = list())
  }

  # % TKA inpatient rehabiliation

  # Ensure all required coefficients are present, defaulting to 0 if missing
  required_coeffs_ir <- c(
    "c17_cons", "c17_male", "c17_ccount", "c17_bmi3", "c17_bmi4", "c17_mhc",
    "c17_age3", "c17_age4", "c17_age5", "c17_sf6d", "c17_kl3", "c17_kl4", "c17_comp"
  )
  for (coeff in required_coeffs_ir) {
    if (is.null(live_coeffs$c17[[coeff]])) {
      live_coeffs$c17[[coeff]] <- 0
    }
  }

  ir_prob <- live_coeffs$c17$c17_cons +
    live_coeffs$c17$c17_male * am_curr$male +
    live_coeffs$c17$c17_ccount * am_curr$ccount +
    live_coeffs$c17$c17_bmi3 * am_curr$bmi3539 +
    live_coeffs$c17$c17_bmi4 * am_curr$bmi40 +
    live_coeffs$c17$c17_mhc * am_curr$mhc +
    live_coeffs$c17$c17_age3 * am_curr$age5564 +
    live_coeffs$c17$c17_age4 * am_curr$age6574 +
    live_coeffs$c17$c17_age5 * am_curr$age75 +
    live_coeffs$c17$c17_sf6d * am_curr$sf6d +
    live_coeffs$c17$c17_kl3 * am_curr$kl3 +
    live_coeffs$c17$c17_kl4 * am_curr$kl4 +
    live_coeffs$c17$c17_comp * am_curr$comp

  ir_prob <- exp(ir_prob)
  ir_prob <- ir_prob / (1 + ir_prob)
  ir_prob <- ir_prob * am_new$tka # ; % only have rehab if have TKA
  ir_prob <- (1 - am_curr$dead) * ir_prob # ; % only alive have rehab

  ir_rand <- runif(nrow(am_curr), 0, 1)
  am_curr$ir <- ifelse(ir_prob > ir_rand, 1, 0)
  am_new$ir <- am_curr$ir

  # TKA revision
  if (!"public" %in% names(am_new)) am_new$public <- 0
  if (!"rev1" %in% names(am_new)) am_new$rev1 <- 0
  if (!"agetka1" %in% names(am_new)) am_new$agetka1 <- 0
  am_new <- calculate_revision_risk_fcn(am_new, live_coeffs$revision_model)

  # TKA revision utility is now handled by calculate_qaly()
  # revi_util <- am_new$revi * live_coeffs$utilities$revision
  # if (length(revi_util) > 0) {
  #   am_curr$d_sf6d <- am_curr$d_sf6d + revi_util
  # }


  # % HRQOL progression or prediction (tbc)
  print(paste("Before calculate_qaly, nrow(am_curr):", nrow(am_curr)))
  am_curr <- calculate_qaly(am_curr, live_coeffs)
  am_new$sf6d <- am_curr$sf6d + am_curr$d_sf6d


  ############################## Update PROs for the cycle
  am_new <- update_pros_fcn(am_new, live_coeffs)


  ############################## Calculate Costs for the cycle
  am_new <- calculate_costs_fcn(am_new, live_coeffs$costs)



  ############################## Determine mortality in the cycle

  # % Mortality
  am_curr[, qx := ifelse(male == 1, lt$male_sep1_bmi0[age], lt$female_sep1_bmi0[age])]

  # % Adjust mortality rate for BMI/SEP and implement

  # Calculate the hazard ratio for mortality in a temporary variable
  hr_mort_calc <- (1 +
    am_curr$bmi2529 * live_coeffs$hr$hr_BMI_mort +
    am_curr$bmi3034 * live_coeffs$hr$hr_BMI_mort^2 +
    am_curr$bmi3539 * live_coeffs$hr$hr_BMI_mort^3 +
    am_curr$bmi40 * live_coeffs$hr$hr_BMI_mort^4) *
    (1 - am_curr$year12) * live_coeffs$hr$hr_SEP_mort

  # Defensive check: If the calculation results in a zero-length or non-numeric vector
  # (e.g., due to missing coefficients or filtered data), default to 1.0 (no effect).
  if (length(hr_mort_calc) == 0) {
    am_curr$hr_mort <- rep(1.0, nrow(am_curr))
    if (isTRUE(getOption("ausoa.warn_zero_length_hr_mort", FALSE))) {
      warning("Calculated 'hr_mort' was zero-length. Defaulted to 1.0. Check input data and coefficients.")
    }
  } else {
    am_curr$hr_mort <- hr_mort_calc
  }

  am_curr$qx <- am_curr$qx * am_curr$hr_mort
  am_curr$qx <- (1 - am_curr$dead) * am_curr$qx # only die once

  dead_rand <- runif(nrow(am_curr), 0, 1)
  am_curr$dead_rand <- ifelse(am_curr$qx > dead_rand, 1, 0)
  am_new$dead <- am_curr$dead + am_curr$dead_rand


  # zero SF6D for dead people
  am_new$sf6d <- (1 - am_new$dead) * am_new$sf6d

  ############################## Update age and QALYs at end of cycle

  # % Age the cohort, so long as they are alive


  am_new$age <- am_curr$age + (1 * (1 - am_new$dead))
  am_new$age[am_new$age > 100] <- 100

  # % Update QALYs

  # NOTE: this is a running total of QALYs, not QALYs in the cycle
  am_new$qaly <- am_curr$qaly + am_curr$sf6d

  # bundle am_curr and am_new for export
  export_data <- list(
    am_curr = am_curr,
    am_new = am_new,
    summ_tka_risk = summ_tka_risk,
    pji_summary = pji_summary,
    dvt_summary = dvt_summary,
    waiting_list_summary = waiting_list_summary,
    pathways_summary = pathways_summary,
    resource_summary = resource_summary
  )

  return(export_data)
}
