#' Data Generation Script for Tutorial 1
#'
#' This script generates synthetic health survey data for the basic
#' population health modeling tutorial. The data mimics the structure
#' and characteristics of real Australian health surveys.
#'
#' @author AUS-OA Development Team
#' @date `r Sys.Date()`

# Setup -------------------------------------------------------------------

library(tidyverse)
set.seed(12345)

# Generate Base Population Data ------------------------------------------

message("Generating synthetic health survey data...")

# Population size
n_patients <- 50000

# Base demographic data
population_data <- data.frame(
  person_id = 1:n_patients,
  age = sample(18:85, n_patients, replace = TRUE),
  sex = sample(c("Male", "Female"), n_patients, replace = TRUE,
               prob = c(0.49, 0.51)),
  state = sample(c("NSW", "VIC", "QLD", "SA", "WA", "TAS", "NT", "ACT"),
                 n_patients, replace = TRUE,
                 prob = c(0.32, 0.26, 0.20, 0.07, 0.10, 0.02, 0.01, 0.02))
)

# Health Metrics ---------------------------------------------------------

# BMI distribution (slightly skewed towards higher values)
population_data$bmi <- rnorm(n_patients, mean = 27, sd = 5)
population_data$bmi <- pmax(15, pmin(60, population_data$bmi))  # Realistic bounds

# Physical activity levels
population_data$physical_activity <- sample(
  c("Low", "Moderate", "High"),
  n_patients,
  replace = TRUE,
  prob = c(0.4, 0.4, 0.2)
)

# Smoking status
population_data$smoking_status <- sample(
  c("Never", "Former", "Current"),
  n_patients,
  replace = TRUE,
  prob = c(0.6, 0.3, 0.1)
)

# Number of comorbidities (Poisson distribution)
population_data$comorbidities <- rpois(n_patients, lambda = 1.5)
population_data$comorbidities <- pmin(10, population_data$comorbidities)  # Cap at 10

# Osteoarthritis Status --------------------------------------------------

message("Generating osteoarthritis status based on risk factors...")

# Logistic regression coefficients (based on real epidemiological data)
base_risk <- -3.0
age_coefficient <- 0.05
bmi_coefficient <- 0.02
female_coefficient <- 0.3
comorbidity_coefficient <- 0.1

# Calculate OA probability for each individual
population_data <- population_data %>%
  mutate(
    # Standardized age (centered at 50)
    age_std = age - 50,

    # Calculate log-odds
    log_odds = base_risk +
               age_coefficient * age_std +
               bmi_coefficient * bmi +
               female_coefficient * (sex == "Female") +
               comorbidity_coefficient * comorbidities,

    # Convert to probability
    oa_probability = plogis(log_odds),

    # Generate OA status
    osteoarthritis = rbinom(n(), 1, oa_probability)
  )

# Pain Scores ------------------------------------------------------------

message("Generating pain scores...")

population_data <- population_data %>%
  mutate(
    # Base pain score (Beta distribution)
    base_pain = rbeta(n(), 1, 5) * 10,  # Low baseline pain

    # OA-related pain increase
    oa_pain_increase = osteoarthritis * rbeta(n(), 2, 3) * 8,  # Additional pain for OA

    # Total pain score
    pain_score = pmin(10, base_pain + oa_pain_increase),

    # Round to 1 decimal place
    pain_score = round(pain_score, 1)
  )

# Healthcare Utilization -------------------------------------------------

message("Generating healthcare utilization data...")

population_data <- population_data %>%
  mutate(
    # GP visits per year (based on OA status and age)
    gp_visits = rpois(n(),
                     lambda = 3 + 2 * osteoarthritis + 0.05 * (age - 50)),

    # Specialist visits
    specialist_visits = rpois(n(),
                             lambda = 0.5 + 1.5 * osteoarthritis),

    # Hospital admissions
    hospital_admissions = rpois(n(),
                               lambda = 0.1 + 0.3 * osteoarthritis +
                                       0.02 * (age - 50)),

    # Total healthcare costs (simplified model)
    healthcare_cost = 200 * gp_visits +
                     300 * specialist_visits +
                     5000 * hospital_admissions +
                     1000 * osteoarthritis  # OA management costs
  )

# Quality of Life Measures -----------------------------------------------

message("Generating quality of life measures...")

population_data <- population_data %>%
  mutate(
    # EQ-5D utility score (simplified)
    eq5d_score = 0.85 - 0.1 * osteoarthritis - 0.005 * pain_score -
                0.01 * comorbidities - 0.001 * (age - 50),

    # Clamp to valid range
    eq5d_score = pmax(0, pmin(1, eq5d_score)),

    # Round to 3 decimal places
    eq5d_score = round(eq5d_score, 3),

    # Physical functioning score (0-100)
    physical_functioning = 85 - 15 * osteoarthritis -
                          0.5 * pain_score - 0.3 * comorbidities,

    physical_functioning = pmax(0, pmin(100, physical_functioning)),
    physical_functioning = round(physical_functioning, 0)
  )

# Treatment Data ---------------------------------------------------------

message("Generating treatment data...")

population_data <- population_data %>%
  mutate(
    # Treatment status
    on_treatment = osteoarthritis * rbinom(n(), 1, 0.7),  # 70% of OA patients treated

    # Treatment type
    treatment_type = ifelse(on_treatment == 1,
                           sample(c("NSAIDs", "Paracetamol", "Opioids",
                                   "Physiotherapy", "Surgery"),
                                  n(), replace = TRUE,
                                  prob = c(0.4, 0.3, 0.1, 0.15, 0.05)),
                           NA),

    # Treatment effectiveness (simplified)
    treatment_effectiveness = ifelse(on_treatment == 1,
                                    rbeta(n(), 3, 2),  # Generally positive
                                    NA),

    treatment_effectiveness = round(treatment_effectiveness, 2)
  )

# Data Validation and Cleaning -------------------------------------------

message("Performing data validation...")

# Check for missing values
missing_summary <- sapply(population_data, function(x) sum(is.na(x)))
cat("\nMissing values summary:\n")
print(missing_summary[missing_summary > 0])

# Check data ranges
cat("\nData range validation:\n")
cat("Age range:", range(population_data$age), "\n")
cat("BMI range:", range(population_data$bmi), "\n")
cat("Pain score range:", range(population_data$pain_score), "\n")
cat("EQ-5D range:", range(population_data$eq5d_score), "\n")

# Summary Statistics -----------------------------------------------------

message("Generating summary statistics...")

data_summary <- list(
  total_records = nrow(population_data),
  oa_prevalence = mean(population_data$osteoarthritis) * 100,
  mean_age = mean(population_data$age),
  age_sd = sd(population_data$age),
  sex_distribution = table(population_data$sex) / nrow(population_data) * 100,
  state_distribution = table(population_data$state) / nrow(population_data) * 100,
  mean_bmi = mean(population_data$bmi),
  bmi_sd = sd(population_data$bmi),
  mean_pain = mean(population_data$pain_score),
  treatment_rate = mean(population_data$on_treatment, na.rm = TRUE) * 100,
  generation_timestamp = Sys.time()
)

cat("\nDataset Summary:\n")
cat("Total records:", data_summary$total_records, "\n")
cat("OA prevalence:", sprintf("%.1f%%", data_summary$oa_prevalence), "\n")
cat("Mean age:", sprintf("%.1f (SD: %.1f)", data_summary$mean_age, data_summary$age_sd), "\n")
cat("Sex distribution:\n")
print(data_summary$sex_distribution)
cat("Mean BMI:", sprintf("%.1f (SD: %.1f)", data_summary$mean_bmi, data_summary$bmi_sd), "\n")
cat("Mean pain score:", sprintf("%.1f", data_summary$mean_pain), "\n")
cat("Treatment rate:", sprintf("%.1f%%", data_summary$treatment_rate), "\n")

# Save Data --------------------------------------------------------------

message("Saving generated data...")

# Create data directory if it doesn't exist
if (!dir.exists("data")) {
  dir.create("data")
}

# Save main dataset
saveRDS(population_data, "data/health_survey_data.rds")

# Save summary statistics
saveRDS(data_summary, "data/data_summary.rds")

# Save as CSV for external analysis
write_csv(population_data, "data/health_survey_data.csv")

# Save metadata
metadata <- list(
  description = "Synthetic Australian health survey data for AUS-OA tutorial",
  variables = names(population_data),
  generation_script = "generate_tutorial_data.R",
  generation_date = Sys.time(),
  sample_size = nrow(population_data),
  oa_prevalence = data_summary$oa_prevalence,
  notes = c(
    "Data generated to mimic AIHW National Health Survey structure",
    "OA status based on epidemiological risk factors",
    "Pain scores correlated with OA status",
    "Healthcare utilization based on OA status and age",
    "All monetary values in AUD"
  )
)

saveRDS(metadata, "data/dataset_metadata.rds")

message("Data generation completed successfully!")
message("Files saved:")
message("- data/health_survey_data.rds (R data format)")
message("- data/health_survey_data.csv (CSV format)")
message("- data/data_summary.rds (summary statistics)")
message("- data/dataset_metadata.rds (metadata)")

# Clean up workspace
rm(list = ls())
gc()

message("Workspace cleaned. Data generation complete.")
