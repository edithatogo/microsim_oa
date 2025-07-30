# AUS-OA simulation in R (V2 - YAML Configuration)

# This script can be sourced by other scripts (like a sensitivity analysis)
# and can accept a custom coefficients object.

# --- 0. Define a function to run the simulation ---
# This makes it easier to call from other scripts.
run_simulation <- function(custom_coeffs = NULL) {
  
  # --- 1. Load Configuration and Packages ---
  config <- load_config("config")
  source(here("R", "initialize_kl_grades_fcn.R"))
  source(here("R", "simulation_cycle_fcn.R"))
  
  # --- 2. Set Up Simulation Environment ---
  sim_params <- config$simulation
  run_modes <- config$run_modes
  
  if (run_modes$calibration_mode) {
    print("Using supplied coefficients for calibration mode, probabilistic mode off")
    run_modes$probabilistic <- FALSE
  }
  
  if (sim_params$set_seed) {
    set.seed(seed) # 'seed' is passed from the outer loop
  }
  
  # --- 3. Prepare Data ---
  start_year <- sim_params$start_year
  am_file <- file.path("input", "population", paste0("am_", start_year, ".parquet"))
  am <- as.data.frame(arrow::read_parquet(am_file))
  
  bmi_edges <- c(0, 25, 30, 35, 40, 100)
  age_edges <- c(min(am$age) - 1, 45, 55, 65, 75, 150)
  
  # --- 4. Prepare Coefficients ---
  if (!is.null(custom_coeffs)) {
    # Use the custom coefficients passed to the function
    model_coefficients <- custom_coeffs
  } else {
    # Load the base coefficients from the file
    model_coefficients <- config$coefficients
  }
  
  all_coeffs <- unlist(model_coefficients)
  live_coeffs <- all_coeffs[grep("\\.live$|\\.value$", names(all_coeffs))]
  names(live_coeffs) <- gsub("\\.live$|\\.value$", "", names(live_coeffs))
  names(live_coeffs) <- gsub(".*\\.", "", names(live_coeffs))
  cycle.coefficents <- as.list(live_coeffs)
  cycle.coefficents <- lapply(cycle.coefficents, as.numeric)
  
  # Also pass the full structured costs config
  cycle.coefficents$costs <- model_coefficients$costs
  cycle.coefficents$utilities <- model_coefficients$utilities
  
  # --- 5. Prepare Other Inputs ---
  input_file <- config$paths$input_file
  lt <- read_excel(input_file,
                   sheet = config$life_tables$sheet,
                   range = config$life_tables$range
  )
  tka_time_trend <- read_excel(input_file,
                               sheet = config$tka_utilisation$sheet,
                               range = config$tka_utilisation$range
  )
  
  if (run_modes$calibration_mode) {
    eq_cust <- config$calibration
  } else {
    eq_cust <- list(
      BMI = data.frame(covariate_set = c("c1", "c2", "c3", "c4", "c5"), proportion_reduction = c(1, 1, 1, 1, 1)),
      OA = data.frame(covariate_set = "cons", proportion_reduction = 1),
      TKR = data.frame(proportion_reduction = 1)
    )
  }
  
  # --- 6. Initialize KL Grades ---
  am <- initialize_kl_grades(am, cycle.coefficents)
  
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
      tka_time_trend = tka_time_trend,
      comorbidity_params = config$comorbidities,
      intervention_params = config$interventions
    )
    
    am_curr <- simulation_output_data[["am_curr"]]
    am_new <- simulation_output_data[["am_new"]]
    
    if (!run_modes$probabilistic) {
      arrow::write_parquet(
        am_new,
        file.path("input", "population", paste0("am_", am_new$year[1], ".parquet"))
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
  am_all <- run_simulation()
}
