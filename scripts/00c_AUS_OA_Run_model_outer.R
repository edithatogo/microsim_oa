# CHOOSE PROBABILISTIC OR DETERMINISTIC RUN AND EXECUTE

number_of_sims <-
  sim_setup$spec[sim_setup$param == "Number of simulations"] %>% as.integer()
loop_vector <- 1:number_of_sims

sim_storage <- list()
for (ii in loop_vector) {
  seed <- ii
  scenario <- scenario
  input_file <- input_file
  print(paste0("Running simulation ", ii))
  source(here("scripts", "02_AUS_OA_Run_model_v2.R"))
  # Return the results along with the seed used
  sim_storage <- c(sim_storage, list(am_all))
}
