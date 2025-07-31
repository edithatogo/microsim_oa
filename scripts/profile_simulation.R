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

# Load configs
simulation_config <- load_config("config/simulation.yaml")
model_parameters <- load_config("config/coefficients.yaml")
comorbidity_parameters <- load_config("config/comorbidities.yaml")
intervention_parameters <- load_config("config/interventions.yaml")

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
