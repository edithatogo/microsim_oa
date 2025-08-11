# Test Harness for QALY Calculation

# This script is designed to be run from the root of the project directory.
# It loads a sample of the population data and the necessary coefficients,
# then calls the calculate_qaly function to generate a "golden master"
# output for characterization testing.

# --- 1. Load Packages and Functions ---
library(here)
library(arrow)
library(yaml)
source(here("R", "calculate_qaly_fcn.R"))
source(here("R", "config_loader.R"))

# --- 2. Load Data ---
# Load the initial attribute matrix for a specific year
am_file <- here("input", "population", "mysim_public.csv")
if (!file.exists(am_file)) {
  stop("Required input file not found: ", am_file)
}
attribute_matrix <- read.csv(am_file)

# --- 3. Load Coefficients ---
# The QALY function requires the 'utility_params', which are part of the main
# coefficients file.
model_coefficients <- load_config(here("config", "coefficients.yaml"))
utility_params <- model_coefficients$coefficients

# --- 4. Run the Function Under Test ---
# Execute the function to get the result based on the current implementation.
# We are interested in the 'd_sf6d' column it produces.
result_matrix <- calculate_qaly(attribute_matrix, utility_params)

# --- 5. Save the "Golden Master" Output ---
# This file serves as the baseline for our characterization test.
# Any change in the output of calculate_qaly will cause a mismatch against this file.
output_dir <- here("tests", "testthat", "fixtures")
if (!dir.exists(output_dir)) {
  dir.create(output_dir, recursive = TRUE)
}
write.csv(result_matrix$d_sf6d,
          file.path(output_dir, "golden_master_qaly.csv"),
          row.names = FALSE)

print("Test harness executed successfully. Golden master file created.")
