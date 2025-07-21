# AUS-OA simulation in R (V2 - YAML Configuration)

# --- 1. Load Configuration and Packages ---
# In the new architecture, all parameters are loaded from YAML files.
# The 'ausoa' package should be loaded, which makes all model functions available.
# library(ausoa) # Uncomment when running as a full package
config <- load_config("config")

# --- 2. Set Up Simulation Environment ---
# Extract simulation settings from the config object
sim_params <- config$simulation
run_modes <- config$run_modes

if (run_modes$calibration_mode) {
  print("Using supplied coefficients for calibration mode, probabilistic mode off")
  run_modes$probabilistic <- FALSE
}

# Set seed if required
if (sim_params$set_seed) {
  set.seed(seed) # 'seed' is passed from the outer loop
}

# --- 3. Prepare Data ---
# Load the base population attribute matrix
start_year <- sim_params$start_year
am_file <- file.path("input", "population", paste0("am_", start_year, ".parquet"))
am <- arrow::read_parquet(am_file)

# Define age and BMI category edges (could also be moved to config)
bmi_edges <- c(0, 25, 30, 35, 40, 100)
age_edges <- c(min(am$age) - 1, 45, 55, 65, 75, 150)

# --- 4. Prepare Coefficients ---
# The setup_coefficents_v2.R script is replaced by logic that processes the
# 'coefficients' section of the config object.
# This is a simplified version for demonstration. A full implementation would
# handle the probabilistic draws here.
all_coeffs <- unlist(config$coefficients)
cycle.coefficents <- as.data.frame(as.list(all_coeffs[grep("\\.live$", names(all_coeffs))]))
names(cycle.coefficents) <- gsub("\\.live$", "", names(cycle.coefficents))


# --- 5. Prepare Other Inputs ---
# Life tables and TKA trends are now part of the config object
lt <- config$life_tables
tka_time_trend <- config$tka_utilisation

# Calibration modifiers would also be in the config
# For now, we replicate the old logic
if (run_modes$calibration_mode) {
  # In a real scenario, this would come from config$calibration
  print("Calibration mode is on, but modifiers are not yet implemented in YAML.")
  # eq_cust <- config$calibration
} else {
  # Create a placeholder for eq_cust
  eq_cust <- list(
    BMI = data.frame(proportion_reduction = 1),
    OA = data.frame(proportion_reduction = 1),
    TKR = data.frame(proportion_reduction = 1)
  )
}


# --- 6. Run Simulation Loop ---
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
    am = am, # Note: review usage
    mort_update_counter = 1, # Note: review usage
    lt = lt,
    eq_cust = eq_cust,
    TKA_time_trend = tka_time_trend,
    pin = cycle.coefficents # 'pin' was the old name for coefficients
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

# --- 7. Post-processing (Costs) ---
# Costs are now read from the config file
am_all$tkacost <- am_all$tka * cycle.coefficents$chs_tkacost_public *
  (1 - am_all$phi) + am_all$tka * cycle.coefficents$chs_tkacost_private *
    am_all$phi
am_all$revcost <- am_all$rev * cycle.coefficents$chs_revcost_public *
  (1 - am_all$phi) + am_all$rev * cycle.coefficents$chs_revcost_private *
    am_all$phi
am_all$rehabcost <- am_all$ir *
  cycle.coefficents$chs_inpatient_rehabcost_public *
  (1 - am_all$phi) + am_all$ir *
    cycle.coefficents$chs_inpatient_rehabcost_private * am_all$phi
am_all$oacost <- am_all$oa * cycle.coefficents$chs_oa_annualcost *
  (1 - am_all$tka1)

am_all$totalcost <- am_all$tkacost + am_all$revcost +
  am_all$rehabcost + am_all$oacost

if (sim_params$set_seed) {
  am_all$seed <- seed
}
