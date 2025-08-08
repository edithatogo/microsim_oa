# CHOOSE PROBABILISTIC OR DETERMINISTIC RUN AND EXECUTE
source(here::here("scripts", "00a_AUS_OA_Setup.R"))
library(foreach)
library(doParallel)

# Load configs if not already in environment
if (!exists("simulation_config")) {
  source(here::here("R", "config_loader.R"))
  simulation_config <- load_config(here::here("config", "simulation.yaml"))
  model_parameters <- load_config(here::here("config", "coefficients.yaml"))
  comorbidity_parameters <- load_config(here::here("config", "comorbidities.yaml"))
  intervention_parameters <- load_config(here::here("config", "interventions.yaml"))
}

number_of_sims <- as.integer(get_param_value("number_of_simulations"))
loop_vector <- 1:number_of_sims

# Check if parallel execution is enabled in the scenario config
run_parallel <- FALSE

if (run_parallel) {
  # --- Parallel Execution ---

  # Set up the parallel backend
  num_cores <- detectCores() - 1 # Leave one core free
  cl <- makeCluster(num_cores)
  registerDoParallel(cl)

  cat(paste("\nRunning", number_of_sims, "simulations in parallel on", num_cores, "cores...\n"))

  sim_storage <- foreach(
    ii = loop_vector,
    .packages = c("here", "readxl", "tidyverse", "arrow", "yaml", "data.table") # Add all required packages
  ) %dopar% {

    # Each worker needs to source the necessary files
    source(here("scripts", "02_AUS_OA_Run_model_v2.R"), local = TRUE)

    # Set the seed for reproducibility within the parallel task
    seed <- ii

    # Run the simulation, passing all config objects
    run_simulation(
      simulation_config = simulation_config,
      model_coefficients = model_parameters,
      comorbidity_params = comorbidity_parameters,
      intervention_params = intervention_parameters
    )
  }

  # Stop the cluster
  stopCluster(cl)

} else {
  # --- Sequential Execution ---

  cat(paste("\nRunning", number_of_sims, "simulations sequentially...\n"))

  sim_storage <- list()
  source(here("scripts", "02_AUS_OA_Run_model_v2.R"))
  for (ii in loop_vector) {
    seed <- ii
    print(paste0("Running simulation ", ii))

    # The result 'am_all' is created in the global environment by the script
    sim_storage <- c(sim_storage, list(run_simulation(
      simulation_config = simulation_config,
      model_coefficients = model_parameters,
      comorbidity_params = comorbidity_parameters,
      intervention_params = intervention_parameters
    )))
  }
}

cat("\n--- All simulations complete ---\n")
