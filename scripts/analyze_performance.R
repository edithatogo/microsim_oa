# scripts/analyze_performance.R

# This script uses the profvis package to profile the main simulation function
# and identify performance bottlenecks.

# --- 1. Load necessary packages and functions ---
library(profvis)
library(here)
source(here("scripts", "00a_AUS_OA_Setup.R"))
source(here("scripts", "02_AUS_OA_Run_model_v2.R"))

# --- 2. Load configuration files ---
simulation_config <- load_config("config/simulation.yaml")
model_parameters <- load_config("config/coefficients.yaml")
comorbidity_parameters <- load_config("config/comorbidities.yaml")
intervention_parameters <- load_config("config/interventions.yaml")

# --- 3. Run the simulation with profiling ---
# We wrap the call to run_simulation() in profvis() to generate the
# performance visualization.
profvis({
  run_simulation(
    simulation_config = simulation_config,
    model_coefficients = model_parameters,
    comorbidity_params = comorbidity_parameters,
    intervention_params = intervention_parameters
  )
})
