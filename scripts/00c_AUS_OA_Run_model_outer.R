# CHOOSE PROBABILISTIC OR DETERMINISTIC RUN AND EXECUTE

number_of_sims <-
  sim_setup$spec[sim_setup$param == "Number of simulations"] %>% as.integer()
loop_vector <- 1:number_of_sims

if (parallel == TRUE) {
  # Setup parallelized for loop (just change dopar to do to turn off parallel)
  p_load(foreach, doParallel)


  ## Set number of cores to use
  num_cores <- detectCores() # How many cores are on your computer?
  cores <- sim_setup$spec[sim_setup$param == "Cores"] %>% as.integer()
  if (cores <= num_cores) {
    num_cores <- cores
  } else {
    print("Number of cores requested is greater than available cores.
            Using all available cores - 1.")
    num_cores <- detectCores() - 1
  }

  if (num_cores > number_of_sims) {
    num_cores <- number_of_sims
  }

  cl <- makeCluster(num_cores)
  registerDoParallel(cl)
  # Run the model
  sim_storage <-
    foreach(
      ii = 1:number_of_sims,
      .combine = "c",
      .packages = c("here", "readxl", "tidyverse", "logr", "arrow")
    ) %dopar% {
      seed <- ii
      scenario <- scenario
      input_file <- input_file
      source(here("scripts", "02_AUS_OA_Run_model.R"))

      # Return the results along with the seed used
      return(list(am_all))
    } # end foreach
  stopCluster(cl)
  registerDoSEQ()
} else {
  p_load(foreach, doParallel)
  # Run the model
  sim_storage <-
    foreach(
      ii = 1:number_of_sims,
      .combine = "c",
      .packages = c("here", "readxl", "tidyverse", "logr", "arrow")
    ) %do% {
      seed <- ii
      scenario <- scenario
      input_file <- input_file
      print(paste0("Running simulation ", ii))
      source(here("scripts", "02_AUS_OA_Run_model.R"))
      # Return the results along with the seed used
      return(list(am_all))
    } # end foreach
}
