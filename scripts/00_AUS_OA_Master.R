# AUS-OA MASTER FILE
# This file runs the entire AUS-OA model
rm(list = ls())
# 1. SETUP THE MODEL
# This script loads required packages, specifies graph options, and prompts the
# user to select the input files.
source(here::here("scripts", "00a_AUS_OA_Setup.R"))
#-------------------------------------------------------------------------------
# 2. PRE-PROCESSING
# This script prepares the synthetic population and the attribute matrix. It
# also calls the script to prepare the validation data if necessary.
source(here("scripts", "00b_AUS_OA_Pre-process.R"))
#-------------------------------------------------------------------------------
# 3. RUN MODEL
ptm <- proc.time()
source(here("scripts", "00c_AUS_OA_Run_model_outer.R"))
proc.time() - ptm

# Save the model output to a csv file
z_data <- as_tibble(sim_storage[[1]]) %>%
  relocate(year, id, age, sex) %>%
  arrange(id, year)

new_filename <-
  paste0(here("output", "raw_output"), "/AUS-OA_Raw_results_", scenario, ".csv")
write_csv(z_data, new_filename)

#-------------------------------------------------------------------------------
# 4. COMPILE MODEL STATISTICS
source(here("scripts", "03_AUS_OA_Model_stats.R"))
## Save the model stats to a csv file
stats_directory <- here("output", "model_stats")
new_filename <- paste0(
  stats_directory,
  "/AUS-OA_Results_", scenario, ".csv"
)
write_csv(model_stats, new_filename)
#-------------------------------------------------------------------------------
# 5. VALIDATE MODEL
## The following script runs a markdown file that compares the model results
## with data. It produces an html report and also saves the figures seperately.
p_load(rmarkdown)
rmd_file <- here("scripts", "04_AUS_OA_Validate_model.Rmd")
output_file <-
  here(
    "output", "log",
    paste0(
      "AUS_OA_Validation_", scenario,
      ".html"
    )
  )
render(rmd_file, output_format = "html_document", output_file = output_file)
#-------------------------------------------------------------------------------
# 6. SIMULATION RESULTS
rmd_file <- here("scripts", "05_AUS_OA_Results.Rmd")
output_file <-
  here(
    "output", "log",
    paste0(
      "AUS_OA_Simulation_results_", scenario,
      ".html"
    )
  )
render(rmd_file, output_format = "html_document", output_file = output_file)
