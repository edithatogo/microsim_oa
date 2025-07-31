# scripts/manage_scenarios.R

library(readxl)
library(here)

# Define the path to the scenario file
scenario_file_path <- here("input", "scenarios", "ausoa_input_public.xlsx")

# Function to read all scenarios from the Excel file
get_all_scenarios <- function() {
  read_excel(scenario_file_path, sheet = "Simulation inputs")
}
