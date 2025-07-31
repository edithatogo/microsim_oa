# AUS-OA simulation in R (V2 - YAML Configuration)

# This script can be sourced by other scripts (like a sensitivity analysis)
# and can accept a custom coefficients object.

# --- 0. Define a function to run the simulation ---
# This makes it easier to call from other scripts.
run_simulation <- function(simulation_config, model_coefficients, comorbidity_params, intervention_params, custom_coeffs = NULL, seed = NULL) {
  
  # --- 1. Load Packages ---
  source(here::here("R", "initialize_kl_grades_fcn.R"))
  source(here::here("R", "simulation_cycle_fcn.R"))
  source(here::here("R", "BMI_mod_fcn.R"))
  source(here::here("R", "apply_coefficient_customisations_fcn.R"))
  
  # --- 2. Set Up Simulation Environment ---
  sim_params <- simulation_config$simulation
  run_modes <- simulation_config$run_modes
  
  if (run_modes$calibration_mode) {
    print("Using supplied coefficients for calibration mode, probabilistic mode off")
    run_modes$probabilistic <- FALSE
  }
  
  if (!is.null(seed)) {
    set.seed(seed)
  }
  
  # --- 3. Prepare Data ---
  start_year <- sim_params$start_year
  am_file <- here::here("input", "population", paste0("am_", start_year, ".parquet"))
  am <- as.data.frame(arrow::read_parquet(am_file))
  
  # Create the 'male' binary indicator column from the 'sex' column
  am$male <- ifelse(am$sex == "[1] Male", 1, 0)
  am$female <- 1 - am$male
  
  # Initialize the 'dead' column
  am$dead <- 0
  
  # Initialize columns that may be missing from the initial data
  if (!"tka1" %in% names(am)) am$tka1 <- 0
  if (!"tka2" %in% names(am)) am$tka2 <- 0
  if (!"kl2" %in% names(am)) am$kl2 <- 0
  if (!"kl3" %in% names(am)) am$kl3 <- 0
  if (!"kl4" %in% names(am)) am$kl4 <- 0
  if (!"pain" %in% names(am)) am$pain <- 0
  if (!"function_score" %in% names(am)) am$function_score <- 0
  if (!"agetka1" %in% names(am)) am$agetka1 <- 0
  if (!"agetka2" %in% names(am)) am$agetka2 <- 0
  if (!"tka" %in% names(am)) am$tka <- 0
  if (!"oa" %in% names(am)) am$oa <- 0
  if (!"drugoa" %in% names(am)) am$drugoa <- 0
  if (!"qaly" %in% names(am)) am$qaly <- 0
  
  bmi_edges <- c(0, 25, 30, 35, 40, 100)
  age_edges <- c(min(am$age) - 1, 45, 55, 65, 75, 150)
  
  # --- 4. Prepare Coefficients ---
  if (!is.null(custom_coeffs)) {
    # Use the custom coefficients passed to the function
    model_coefficients_to_use <- custom_coeffs
  } else {
    # Load the base coefficients from the file
    model_coefficients_to_use <- model_coefficients
  }
  
  # Helper function to recursively extract 'live' or 'value'
  extract_live_values <- function(x) {
    if (is.list(x)) {
      if ("live" %in% names(x)) {
        return(x$live)
      } else if ("value" %in% names(x)) {
        return(x$value)
      } else {
        return(lapply(x, extract_live_values))
      }
    } else {
      return(x)
    }
  }

  # The entire config is nested under a 'coefficients' key.
  # We extract the live/value parameters first.
  cycle.coefficents <- extract_live_values(model_coefficients_to_use$coefficients)
  
  # Then, we re-attach the full, structured cost and utility lists, as they are
  # needed in their original form by some functions.
  cycle.coefficents$costs <- model_coefficients_to_use$coefficients$costs
  cycle.coefficents$utilities <- model_coefficients_to_use$coefficients$utilities
  
  # --- 5. Prepare Other Inputs ---
  input_file <- here::here(simulation_config$paths$input_file)
  lt <- read_excel(input_file,
                   sheet = simulation_config$life_tables$sheet,
                   range = simulation_config$life_tables$range
  )
  tka_time_trend <- read_excel(input_file,
                               sheet = simulation_config$tka_utilisation$sheet,
                               range = simulation_config$tka_utilisation$range
  )
  
  if (run_modes$calibration_mode) {
    eq_cust <- simulation_config$calibration
  } else {
    eq_cust <- list(
      BMI = data.frame(covariate_set = c("c1", "c2", "c3", "c4", "c5"), proportion_reduction = c(1, 1, 1, 1, 1)),
      OA = data.frame(covariate_set = "cons", proportion_reduction = 1),
      TKR = data.frame(
        covariate_set = c("c9_cons", "c9_age", "c9_age2", "c9_drugoa", "c9_ccount", "c9_mhc", "c9_tkr", "c9_kl2hr", "c9_kl3hr", "c9_kl4hr", "c9_pain", "c9_function"),
        proportion_reduction = c(1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1)
      )
    )
  }
  
  # --- 6. Initialize KL Grades ---
  am$oa <- as.numeric(am$oa)
  am <- initialize_kl_grades(am, cycle.coefficents$utilities, cycle.coefficents$initial_kl_grades)
  
  # --- 7. Run Simulation Loop ---
  am_all <- am
  am_curr <- am
  am_new <- am
  
  num_years <- sim_params$length_years
  for (i in 2:(num_years + 1)) {
    print(paste("Year:", i))
    
    am_curr$d_sf6d <- 0
    am_curr$d_bmi <- 0
    am_new$year <- am_curr$year + 1
    
    print(paste("Calling simulation_cycle_fcn for year", am_new$year[1]))
    simulation_output_data <- simulation_cycle_fcn(
      am_curr = am_curr,
      cycle.coefficents = cycle.coefficents,
      am_new = am_new,
      age_edges = age_edges,
      bmi_edges = bmi_edges,
      am = am,
      mort_update_counter = 1,
      lt = lt,
      eq_cust = eq_cust,
      tka_time_trend = tka_time_trend
    )
    print(paste("Returned from simulation_cycle_fcn for year", am_new$year[1]))
    
    am_curr <- simulation_output_data[["am_curr"]]
    am_new <- simulation_output_data[["am_new"]]
    
    if (!run_modes$probabilistic) {
      arrow::write_parquet(
        am_new,
        here::here("input", "population", paste0("am_", am_new$year[1], ".parquet"))
      )
    }
    
    am_all <- rbind(am_all, am_new)
    am_curr <- am_new
  }
  
  # --- 8. Post-processing ---
  # The cost calculation is now inside the simulation cycle.
  # We just need to return the final results.
  
  if (sim_params$set_seed) {
    am_all$seed <- seed
  }
  
  return(am_all)
}

# --- 9. Execute the simulation ---
# This part only runs if the script is sourced directly, not from another script
# that calls run_simulation() with parameters.
if (sys.nframe() == 0) {
  # Load configs if running standalone
  simulation_config <- load_config(here::here("config", "simulation.yaml"))
  model_parameters <- load_config(here::here("config", "coefficients.yaml"))
  comorbidity_parameters <- load_config(here::here("config", "comorbidities.yaml"))
  intervention_parameters <- load_config(here::here("config", "interventions.yaml"))
  
  am_all <- run_simulation(simulation_config, model_parameters, comorbidity_parameters, intervention_parameters, seed = 123)
}