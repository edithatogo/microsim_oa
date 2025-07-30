# scripts/profile_simulation.R

#' Profile the Core Simulation Cycle
#'
#' This script uses the `profvis` package to profile a single run of the
#' `simulation_cycle_fcn`. This helps identify performance bottlenecks in the
#' core logic of the model.
#'
#' The results are saved to an interactive HTML file in the `output/profiling`
#' directory.

library(profvis)
library(here)
library(yaml)
library(tidyverse)
library(readxl)
library(arrow)

# --- 1. Load All Necessary Functions and Configs ---
source(here("R", "config_loader.R"))
source(here("R", "initialize_kl_grades_fcn.R"))
source(here("R", "simulation_cycle_fcn.R"))
source(here("R", "BMI_mod_fcn.R"))
source(here("R", "OA_update_fcn.R"))
source(here("R", "TKA_update_fcn.R"))
source(here("R", "calculate_revision_risk_fcn.R"))
source(here("R", "update_pros_fcn.R"))
source(here("R", "calculate_costs_fcn.R"))


# Load configurations
config <- list(
  simulation = load_config(here("config", "simulation.yaml")),
  coefficients = load_config(here("config", "coefficients.yaml")),
  comorbidities = load_config(here("config", "comorbidities.yaml")),
  interventions = load_config(here("config", "interventions.yaml"))
)

# --- 2. Prepare Inputs for a Single Cycle ---
# This section mimics the setup from `02_AUS_OA_Run_model_v2.R`

# Load base population
start_year <- config$simulation$start_year
am_file <- file.path("input", "population", paste0("am_", start_year, ".parquet"))
am <- as.data.frame(arrow::read_parquet(am_file))

# Define edges
bmi_edges <- c(0, 25, 30, 35, 40, 100)
age_edges <- c(min(am$age) - 1, 45, 55, 65, 75, 150)

# Prepare coefficients
all_coeffs <- unlist(config$coefficients)
live_coeffs <- all_coeffs[grep("\\.live$|\\.value$", names(all_coeffs))]
names(live_coeffs) <- gsub("\\.live$|\\.value$", "", names(live_coeffs))
names(live_coeffs) <- gsub(".*\\.", "", names(live_coeffs))
cycle.coefficents <- as.list(live_coeffs)
cycle.coefficents <- lapply(cycle.coefficents, as.numeric)
cycle.coefficents$costs <- config$coefficients$costs
cycle.coefficents$utilities <- config$coefficients$utilities
cycle.coefficents$revision_model <- config$coefficients$revision_model


# Prepare other inputs
lt <- read_excel(here("input", "scenarios", "ausoa_input_public.xlsx"), sheet = "Life tables male")
tka_time_trend <- read_excel(here("input", "scenarios", "ausoa_input_public.xlsx"), sheet = "TKA time trend")
eq_cust <- list(
  BMI = data.frame(covariate_set = c("c1", "c2", "c3", "c4", "c5"), proportion_reduction = c(1, 1, 1, 1, 1)),
  OA = data.frame(covariate_set = "cons", proportion_reduction = 1),
  TKR = data.frame(proportion_reduction = 1)
)

# Initialize attribute matrices for the cycle
am <- initialize_kl_grades(am, cycle.coefficents)
am_curr <- am
am_new <- am
am_curr$d_sf6d <- 0
am_curr$d_bmi <- 0
am_new$year <- am_curr$year + 1


# --- 3. Run the Profiler ---
cat("Starting profiler... This may take a moment.\n")

profiling_results <- profvis({
  
  # Run a single simulation cycle
  simulation_cycle_fcn(
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
  
})

# --- 4. Save the Results ---
output_dir <- here("output", "profiling")
if (!dir.exists(output_dir)) {
  dir.create(output_dir)
}
output_file <- file.path(output_dir, "simulation_cycle_profile.html")

htmlwidgets::saveWidget(profiling_results, output_file)

cat(paste("Profiling complete. Results saved to:", output_file, "\n"))