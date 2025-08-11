# scripts/profile_simulation.R

library(here)
library(readxl)
library(dplyr)
library(purrr)

# Source the necessary scripts
source(here("R", "config_loader.R"))
source(here("scripts", "02_AUS_OA_Run_model_v2.R"))

# Define the output file for the profiling data
prof_out_file <- here("output", "log", "profiling_output.out")

# Start the profiler
Rprof(prof_out_file)

# Construct absolute paths to config files
sim_config_path <- here("inst", "config", "simulation.yaml")
coeffs_path <- here("inst", "config", "coefficients.yaml")
comorb_path <- here("inst", "config", "comorbidities.yaml")
interv_path <- here("inst", "config", "interventions.yaml")

# Print paths for debugging
print(paste("Project base directory:", here()))
print(paste("Attempting to load simulation config from:", sim_config_path))
if (!file.exists(sim_config_path)) {
  stop("Simulation config file does not exist at the specified path.")
}
simulation_config <- load_config(sim_config_path)
print("Simulation config loaded successfully.")

model_parameters <- list() # Bypassing coefficient loading for now

print(paste("Attempting to load comorbidity parameters from:", comorb_path))
if (!file.exists(comorb_path)) {
  stop("Comorbidities file does not exist at the specified path.")
}
comorbidity_parameters <- load_config(comorb_path)
print("Comorbidity parameters loaded successfully.")

print(paste("Attempting to load intervention parameters from:", interv_path))
if (!file.exists(interv_path)) {
  stop("Interventions file does not exist at the specified path.")
}
intervention_parameters <- load_config(interv_path)
print("Intervention parameters loaded successfully.")

# Extend the simulation duration for more meaningful profiling
# The input file from simulation.yaml is complete and should be used.
simulation_config$simulation$length_years <- 50

# Run the simulation
seed <- 123
tryCatch({
  run_simulation(simulation_config, model_parameters, comorbidity_parameters, intervention_parameters)
}, error = function(e) {
  print(e)
  traceback()
})

# Stop the profiler
Rprof(NULL)

# Analyze the profiling data and print the results
prof_summary <- summaryRprof(prof_out_file)
print(prof_summary)
