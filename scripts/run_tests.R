# AUS-OA TEST SCRIPT
# This file runs the entire AUS-OA model for a specific test scenario.

# Set the scenario name
scenario <- "test_scenario"

# 1. SETUP THE MODEL
# This script loads required packages, specifies graph options, and prompts the
# user to select the input files.
# In this test script, we will manually specify the input file.
source(here::here("scripts", "00a_AUS_OA_Setup.R"), local = TRUE)
file_path <- here::here("input", "scenarios", "ausoa_input_public.xlsx")
scenario_list <- read_excel(file_path, sheet = "Simulation inputs")
scenario_selection <- scenario_list[1, ]

# 2. PRE-PROCESSING
# This script prepares the synthetic population and the attribute matrix. It
# also calls the script to prepare the validation data if necessary.
source(here("scripts", "00b_AUS_OA_Pre-process.R"))

# 3. RUN MODEL
ptm <- proc.time()
source(here("scripts", "00c_AUS_OA_Run_model_outer.R"))
proc.time() - ptm

# Save the model output to a csv file
Z <- as_tibble(sim_storage[[1]]) %>%
  relocate(year, id, age, sex) %>%
  arrange(id, year)

# Create a directory for the test results
test_output_dir <- here("output", "test_results")
if (!dir.exists(test_output_dir)) {
  dir.create(test_output_dir)
}

new_filename <-
  paste0(test_output_dir, "/AUS-OA_Raw_results_", scenario, ".csv")
write_csv(Z, new_filename)

print(paste("Test results saved to:", new_filename))
