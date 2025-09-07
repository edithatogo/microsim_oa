# scripts/00_PREP_v2_config.R

# This script reads the ausoa_input_public.xlsx file and creates
# the new configuration files for the v2 development branch.

library(readxl)
library(yaml)
library(readr)
library(here)
library(arrow)  # Add arrow for Parquet support

# Define paths
excel_file <- here("input", "scenarios", "ausoa_input_public.xlsx")
config_dir <- here("config")

# Read data from Excel sheets
coefficients_df <- read_excel(excel_file, sheet = "Parameter inputs")
life_tables_df <- read_excel(excel_file, sheet = "Life tables 2013")
simulation_setup_df <- read_excel(excel_file, sheet = "Simulation inputs", col_names = FALSE)
tka_utilisation_df <- read_excel(excel_file, sheet = "TKA utilisation")

# Write data to CSV, Parquet and YML files
write_csv(coefficients_df, file.path(config_dir, "coefficients.csv"))
write_parquet(coefficients_df, file.path(config_dir, "coefficients.parquet"))

write_csv(life_tables_df, file.path(config_dir, "life_tables_2013.csv"))
write_parquet(life_tables_df, file.path(config_dir, "life_tables_2013.parquet"))

write_csv(tka_utilisation_df, file.path(config_dir, "tka_utilisation.csv"))
write_parquet(tka_utilisation_df, file.path(config_dir, "tka_utilisation.parquet"))

# Convert simulation_setup_df to a list and then to YAML
simulation_setup_list <- as.list(setNames(simulation_setup_df$...2, simulation_setup_df$...1))
write_yaml(simulation_setup_list, file.path(config_dir, "simulation_setup.yml"))

print("Configuration files for v2 development have been created successfully.")
