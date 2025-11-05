#' Data Generation Script for Tutorial 2
#'
#' This script generates synthetic Australian healthcare utilization data
#' for the healthcare utilization analysis tutorial. The data mimics
#' Medicare, PBS, and hospital admission patterns.
#'
#' @author AUS-OA Development Team
#' @date `r Sys.Date()`

# Setup -------------------------------------------------------------------

library(tidyverse)
set.seed(12345)

# Generate Base Population Data ------------------------------------------

message("Generating synthetic healthcare utilization data...")

# Population size
n_patients <- 50000

# Base demographic data
healthcare_data <- data.frame(
  person_id = 1:n_patients,
  age = sample(18:85, n_patients, replace = TRUE),
  sex = sample(c("Male", "Female"), n_patients, replace = TRUE, prob = c(0.49, 0.51)),
  state = sample(c("NSW", "VIC", "QLD", "SA", "WA", "TAS", "NT", "ACT"),
                 n_patients, replace = TRUE,
                 prob = c(0.32, 0.26, 0.20, 0.07, 0.10, 0.02, 0.01, 0.02)),
  socioeconomic_score = rnorm(n_patients, mean = 50, sd = 15),
  income_level = rnorm(n_patients, mean = 60000, sd = 25000),
  rural_urban = sample(c("Urban", "Rural"), n_patients, replace = TRUE, prob = c(0.7, 0.3))
)

# Health Status -----------------------------------------------------------

message("Generating health status data...")

# Comorbidities
healthcare_data$comorbidities <- rpois(n_patients, lambda = 1.5)
healthcare_data$comorbidities <- pmin(10, healthcare_data$comorbidities)

# Osteoarthritis status
healthcare_data <- healthcare_data %>%
  mutate(
    oa_prob = plogis(-3 + 0.05 * (age - 50) + 0.02 * socioeconomic_score +
                    0.3 * (sex == "Female") + 0.1 * comorbidities),
    osteoarthritis = rbinom(n(), 1, oa_prob)
  )

# Healthcare Utilization -------------------------------------------------

message("Generating healthcare utilization patterns...")

# GP visits (primary care)
healthcare_data <- healthcare_data %>%
  mutate(
    gp_base_rate = 2 + 0.02 * (age - 50) + 0.5 * osteoarthritis + 0.1 * comorbidities,
    gp_rural_adjust = ifelse(rural_urban == "Rural", 0.8, 1.2),  # Rural patients may have less access
    gp_lambda = gp_base_rate * gp_rural_adjust,
    gp_visits = rpois(n(), lambda = gp_lambda)
  )

# Specialist visits
healthcare_data <- healthcare_data %>%
  mutate(
    specialist_base_rate = 0.5 + 1.5 * osteoarthritis + 0.2 * comorbidities +
                          0.01 * (age - 50),
    specialist_lambda = specialist_base_rate,
    specialist_visits = rpois(n(), lambda = specialist_lambda)
  )

# Hospital admissions
healthcare_data <- healthcare_data %>%
  mutate(
    hospital_base_rate = 0.1 + 0.3 * osteoarthritis + 0.05 * (age - 65) +
                        0.1 * comorbidities,
    hospital_rural_adjust = ifelse(rural_urban == "Rural", 1.3, 0.9),  # Rural patients may have higher admission rates
    hospital_lambda = hospital_base_rate * hospital_rural_adjust,
    hospital_admissions = rpois(n(), lambda = hospital_lambda)
  )

# Healthcare Costs -------------------------------------------------------

message("Calculating healthcare costs...")

# Cost parameters (approximate Australian healthcare costs in AUD)
gp_visit_cost <- 50
specialist_visit_cost <- 150
hospital_admission_cost <- 5000
medication_base_cost <- 200

healthcare_data <- healthcare_data %>%
  mutate(
    # Service costs
    gp_cost = gp_visits * gp_visit_cost,
    specialist_cost = specialist_visits * specialist_visit_cost,
    hospital_cost = hospital_admissions * hospital_admission_cost,

    # Medication costs (based on conditions)
    medication_cost = medication_base_cost * comorbidities +
                     ifelse(osteoarthritis == 1, 800, 0),  # OA-specific medications

    # Total healthcare costs
    total_cost = gp_cost + specialist_cost + hospital_cost + medication_cost,

    # Add some random variation to costs
    cost_variation = rnorm(n(), mean = 1, sd = 0.1),
    total_cost = total_cost * cost_variation,
    total_cost = pmax(0, total_cost)  # Ensure non-negative costs
  )

# Quality Metrics -------------------------------------------------------

message("Adding quality and outcome measures...")

healthcare_data <- healthcare_data %>%
  mutate(
    # Healthcare quality indicators
    preventive_care = rbinom(n(), 1, 0.6),  # Did patient receive preventive care?
    medication_adherence = rbeta(n(), 7, 2),  # Medication adherence score (0-1)

    # Health outcomes
    health_status = 85 - 5 * osteoarthritis - 2 * comorbidities -
                   0.1 * (age - 50) + rnorm(n(), 0, 5),
    health_status = pmax(0, pmin(100, health_status)),

    # Healthcare satisfaction (simplified)
    satisfaction_score = 75 + 5 * (gp_visits > 0) + 3 * (specialist_visits == 0) -
                        2 * hospital_admissions + rnorm(n(), 0, 10),
    satisfaction_score = pmax(0, pmin(100, satisfaction_score))
  )

# Data Validation and Quality Checks -------------------------------------

message("Performing data validation...")

# Check for unrealistic values
validation_checks <- healthcare_data %>%
  summarise(
    negative_costs = sum(total_cost < 0),
    zero_cost_high_utilization = sum(total_cost == 0 &
                                    (gp_visits > 5 | specialist_visits > 2 | hospital_admissions > 0)),
    extremely_high_costs = sum(total_cost > 100000),
    missing_values = sum(is.na(healthcare_data)),
    duplicate_ids = n() - n_distinct(person_id)
  )

cat("\nData Validation Results:\n")
print(validation_checks)

# Summary Statistics -----------------------------------------------------

message("Generating summary statistics...")

data_summary <- list(
  total_records = nrow(healthcare_data),
  mean_age = mean(healthcare_data$age),
  age_sd = sd(healthcare_data$age),
  sex_distribution = table(healthcare_data$sex) / nrow(healthcare_data) * 100,
  state_distribution = table(healthcare_data$state) / nrow(healthcare_data) * 100,
  rural_urban_distribution = table(healthcare_data$rural_urban) / nrow(healthcare_data) * 100,

  # Utilization statistics
  mean_gp_visits = mean(healthcare_data$gp_visits),
  mean_specialist_visits = mean(healthcare_data$specialist_visits),
  mean_hospital_admissions = mean(healthcare_data$hospital_admissions),
  pct_with_gp_visits = mean(healthcare_data$gp_visits > 0) * 100,
  pct_with_specialist_visits = mean(healthcare_data$specialist_visits > 0) * 100,
  pct_with_hospital_admissions = mean(healthcare_data$hospital_admissions > 0) * 100,

  # Cost statistics
  mean_total_cost = mean(healthcare_data$total_cost),
  median_total_cost = median(healthcare_data$total_cost),
  cost_sd = sd(healthcare_data$total_cost),
  pct_zero_cost = mean(healthcare_data$total_cost == 0) * 100,

  # Health status
  oa_prevalence = mean(healthcare_data$osteoarthritis) * 100,
  mean_comorbidities = mean(healthcare_data$comorbidities),
  mean_health_status = mean(healthcare_data$health_status),

  generation_timestamp = Sys.time()
)

cat("\nDataset Summary:\n")
cat("Total records:", data_summary$total_records, "\n")
cat("Mean age:", sprintf("%.1f (SD: %.1f)", data_summary$mean_age, data_summary$age_sd), "\n")
cat("OA prevalence:", sprintf("%.1f%%", data_summary$oa_prevalence), "\n")
cat("Mean GP visits:", sprintf("%.1f", data_summary$mean_gp_visits), "\n")
cat("Mean total cost: $", sprintf("%.0f", data_summary$mean_total_cost), "\n")
cat("Median total cost: $", sprintf("%.0f", data_summary$median_total_cost), "\n")

# Save Data --------------------------------------------------------------

message("Saving generated data...")

# Create data directory if it doesn't exist
if (!dir.exists("data")) {
  dir.create("data")
}

# Save main dataset
saveRDS(healthcare_data, "data/healthcare_utilization_data.rds")

# Save summary statistics
saveRDS(data_summary, "data/healthcare_data_summary.rds")

# Save as CSV for external analysis
write_csv(healthcare_data, "data/healthcare_utilization_data.csv")

# Save metadata
metadata <- list(
  description = "Synthetic Australian healthcare utilization data for AUS-OA tutorial",
  variables = names(healthcare_data),
  generation_script = "generate_healthcare_data.R",
  generation_date = Sys.time(),
  sample_size = nrow(healthcare_data),
  cost_parameters = list(
    gp_visit_cost = gp_visit_cost,
    specialist_visit_cost = specialist_visit_cost,
    hospital_admission_cost = hospital_admission_cost,
    medication_base_cost = medication_base_cost
  ),
  notes = c(
    "Data generated to mimic Australian Medicare and hospital data patterns",
    "Costs are in Australian dollars (approximate values)",
    "Utilization patterns based on epidemiological studies",
    "Rural-urban differences reflect Australian healthcare access patterns",
    "All monetary values are annual totals"
  )
)

saveRDS(metadata, "data/healthcare_dataset_metadata.rds")

message("Data generation completed successfully!")
message("Files saved:")
message("- data/healthcare_utilization_data.rds (R data format)")
message("- data/healthcare_utilization_data.csv (CSV format)")
message("- data/healthcare_data_summary.rds (summary statistics)")
message("- data/healthcare_dataset_metadata.rds (metadata)")

# Clean up workspace
rm(list = ls())
gc()

message("Workspace cleaned. Healthcare data generation complete.")</content>
<parameter name="filePath">\\wsl.localhost\Ubuntu\home\doughnut\github\aus_oa_public\tutorials\tutorial_02_healthcare_utilization\scripts\generate_healthcare_data.R
