# CHOOSE PROBABILISTIC OR DETERMINISTIC RUN AND EXECUTE
library(foreach)
library(doParallel)

number_of_sims <-
  sim_setup$spec[sim_setup$param == "Number of simulations"] %>% as.integer()
loop_vector <- 1:number_of_sims

# Check if parallel execution is enabled in the scenario config
run_parallel <- sim_setup$spec[sim_setup$param == "Parallelize"] %>% as.logical()

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
    
    # Run the simulation
    # The run_simulation function is now available from the sourced script
    run_simulation()
  }
  
  # Stop the cluster
  stopCluster(cl)
  
} else {
  # --- Sequential Execution ---
  
  cat(paste("\nRunning", number_of_sims, "simulations sequentially...\n"))
  
  sim_storage <- list()
  for (ii in loop_vector) {
    seed <- ii
    print(paste0("Running simulation ", ii))
    
    # Sourcing the script will run the simulation
    source(here("scripts", "02_AUS_OA_Run_model_v2.R"))
    
    # The result 'am_all' is created in the global environment by the script
    sim_storage <- c(sim_storage, list(am_all))
  }
}

cat("\n--- All simulations complete ---\n")