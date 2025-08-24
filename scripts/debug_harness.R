# scripts/debug_harness.R
# A minimal script to reproduce and diagnose the simulation cycle error.

# --- 1. Setup: Load libraries and source functions ---
# We are deliberately avoiding loading the full 'ausoa' package to isolate the functions.
library(here)
library(yaml)
library(data.table)

# Source the functions we need to test, in the correct order of dependency.
source(here::here("R", "config_loader.R"))
source(here::here("R", "apply_coefficient_customisations_fcn.R"))
source(here::here("R", "utils.R")) # Contains calculate_qaly, bmi_mod_fcn, etc.
source(here::here("R", "OA_update_fcn.R"))
source(here::here("R", "TKA_update_fcn.R"))
source(here::here("R", "update_comorbidities_fcn.R"))
source(here::here("R", "update_pros_fcn.R"))
source(here::here("R", "calculate_revision_risk_fcn.R"))
source(here::here("R", "calculate_costs_fcn.R"))
source(here::here("R", "simulation_cycle_fcn.R"))


# --- 2. Data Loading: Mimic the test environment ---
config_path <- here::here("config")
initial_am_path <- here::here("am_curr_before_oa.rds")

if (!dir.exists(config_path) || !file.exists(initial_am_path)) {
  stop("Required config or data files are missing.")
}

# Load model parameters and initial population state
params <- load_config(config_path)
am_initial <- readRDS(initial_am_path)

# Use a small, predictable subset for the test
am_test_input <- am_initial[1:50, ]
am_test_input[, public := 0]

# Ensure key columns are numeric to prevent downstream errors
cols_to_convert <- c(
  "age", "bmi", "oa", "kl2", "kl3", "kl4", "dead", "tka", "tka1", "tka2",
  "agetka1", "agetka2", "rev1", "revi", "pain", "function_score", "qaly",
  "year", "d_bmi", "drugoa", "age044", "age4554", "age5564", "age6574",
  "age75", "male", "female", "bmi024", "bmi2529", "bmi3034", "bmi3539",
  "bmi40", "ccount", "mhc", "comp", "ir", "public", "sf6d", "d_sf6d"
)
for (col in cols_to_convert) {
  if (col %in% names(am_test_input)) {
    am_test_input[[col]] <- as.numeric(as.character(am_test_input[[col]]))
  }
}
if ("year12" %in% names(am_test_input)) {
  am_test_input$year12 <- as.numeric(as.character(am_test_input$year12))
}


# --- 3. Execution: Run the simulation cycle ---
# Create mock inputs as done in the original test
am_new <- am_test_input
age_edges <- params$simulation_setup$age_edges
bmi_edges <- params$simulation_setup$bmi_edges
lt <- data.frame(
  male_sep1_bmi0 = rep(0.001, 101),
  female_sep1_bmi0 = rep(0.0008, 101),
  row.names = 0:100
)
eq_cust <- list(
  BMI = data.frame(covariate_set = "c1", proportion_reduction = 1),
  TKR = data.frame(),
  OA = data.frame(covariate_set = "c6", proportion_reduction = 1)
)
tka_time_trend <- data.frame(Year = 2023, female4554 = 1, male4554 = 1)

# Unpack the 'live' coefficients, just as the main function does
live_coeffs <- lapply(params$coefficients, function(x) {
    if (is.list(x) && "live" %in% names(x)) return(x$live)
    if (is.list(x)) {
      return(lapply(x, function(y) {
        if (is.list(y) && "live" %in% names(y)) return(y$live)
        return(y)
      }))
    }
    return(x)
})

# --- 4. Diagnosis: Inspect the problematic object and run the function ---
cat("\n--- DEBUGGING ---")
cat("\nStructure of live_coeffs$utilities:")
str(live_coeffs$utilities)
cat("\n------------------\n\n")

# Now, call the function that was failing
# We wrap it in a tryCatch to get a clean error message without halting the script
tryCatch({
  cat("Calling simulation_cycle_fcn...\n")
  results_list <- simulation_cycle_fcn(
    am_curr = am_test_input,
    cycle.coefficents = params$coefficients,
    am_new = am_new,
    age_edges = age_edges,
    bmi_edges = bmi_edges,
    am = am_test_input,
    mort_update_counter = 1,
    lt = lt,
    eq_cust = eq_cust,
    tka_time_trend = tka_time_trend
  )
  cat("SUCCESS: simulation_cycle_fcn ran without error.\n")
  # Further inspection could go here if needed
  # str(results_list$am_curr)

}, error = function(e) {
  cat("\n--- ERROR CAUGHT ---")
  print(e)
  cat("\n---------------------\n")
})
