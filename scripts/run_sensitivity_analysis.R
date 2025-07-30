# scripts/run_sensitivity_analysis.R

#' Run a One-Way Sensitivity Analysis
#'
#' This script orchestrates a one-way sensitivity analysis by systematically
#' varying a single model parameter, running the full simulation for each
#' variation, and saving the results.

library(here)
library(yaml)
library(tidyverse)

# --- Source the simulation runner ---
# This also sources all the other necessary model functions.
source(here("scripts", "02_AUS_OA_Run_model_v2.R"))

# --- 1. Load Configuration ---
sensitivity_config <- read_yaml(here("config", "sensitivity_analysis.yaml"))
model_coeffs_base <- read_yaml(here("config", "coefficients.yaml"))

if (!isTRUE(sensitivity_config$enabled)) {
  stop("Sensitivity analysis is not enabled in config/sensitivity_analysis.yaml")
}

# --- 2. Helper Function to Update Nested List ---

#' Set a value in a nested list using a vector of keys.
#'
#' @param l The list to modify.
#' @param keys A character vector representing the path to the element.
#' @param value The new value to set.
#' @return The modified list.
set_nested_value <- function(l, keys, value) {
  # This is a recursive function. If there's only one key left, we set the value.
  # Otherwise, we call the function again on the next level of the list.
  if (length(keys) == 1) {
    l[[keys]] <- value
  } else {
    l[[keys[1]]] <- set_nested_value(l[[keys[1]]], keys[-1], value)
  }
  return(l)
}


# --- 3. Set Up and Run Analysis Loop ---
param_path <- sensitivity_config$parameter_path
variations <- sensitivity_config$variations
path_parts <- strsplit(param_path, "\\.")[[1]]

output_dir <- here("output", "sensitivity_analysis", param_path)
if (!dir.exists(output_dir)) {
  dir.create(output_dir, recursive = TRUE)
}

results_summary <- list()

for (i in seq_along(variations)) {
  
  variation_value <- variations[[i]]
  cat(paste("\n--- Running Sensitivity Analysis for", param_path, "=", variation_value, "---\n"))
  
  # --- Modify the Model Coefficients using the robust helper function ---
  model_coeffs_modified <- set_nested_value(model_coeffs_base, path_parts, variation_value)
  
  # --- Run the Full Simulation ---
  # The run_simulation function from 02_AUS_OA_Run_model_v2.R accepts the
  # modified coefficients object.
  simulation_results <- run_simulation(custom_coeffs = model_coeffs_modified)
  
  # --- Summarize and Store Results ---
  # A more detailed analysis would save more granular results.
  total_cost <- sum(simulation_results$cycle_cost_total, na.rm = TRUE)
  
  summary_row <- data.frame(
    parameter = param_path,
    value = variation_value,
    total_cost = total_cost
  )
  results_summary[[i]] <- summary_row
  
  cat(paste("Run", i, "complete. Total cost:", format(total_cost, scientific = FALSE, big.mark = ","), "\n"))
}

# --- 4. Collate and Save Final Results ---
final_results_df <- do.call(rbind, results_summary)
result_filename <- file.path(output_dir, "sensitivity_analysis_summary.csv")
write_csv(final_results_df, result_filename)

cat("\n--- Sensitivity Analysis Complete ---\n")
cat("Summary results saved to:", result_filename, "\n")
