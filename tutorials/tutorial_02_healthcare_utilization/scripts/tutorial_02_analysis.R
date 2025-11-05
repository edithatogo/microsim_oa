#' Tutorial 2: Healthcare Utilization Analysis
#'
#' This script demonstrates comprehensive healthcare utilization analysis
#' using synthetic Australian healthcare data. It covers utilization patterns,
#' cost analysis, access disparities, and cost-effectiveness evaluation.
#'
#' @author AUS-OA Development Team
#' @date `r Sys.Date()`

# Setup -------------------------------------------------------------------

# Load required packages
library(tidyverse)
library(scales)
library(ggthemes)
library(aus_oa_public)
set.seed(12345)

# Data Acquisition -------------------------------------------------------

message("Step 1: Acquiring healthcare utilization data...")

# In a real scenario, you would use:
# healthcare_data <- acquire_aihw_medicare_data(year = 2022)

# For this tutorial, we'll create synthetic healthcare data
healthcare_data <- data.frame(
  person_id = 1:50000,
  age = sample(18:85, 50000, replace = TRUE),
  sex = sample(c("Male", "Female"), 50000, replace = TRUE, prob = c(0.49, 0.51)),
  state = sample(c("NSW", "VIC", "QLD", "SA", "WA", "TAS", "NT", "ACT"),
                 50000, replace = TRUE),
  socioeconomic_score = rnorm(50000, mean = 50, sd = 15),
  income_level = rnorm(50000, mean = 60000, sd = 25000),
  rural_urban = sample(c("Urban", "Rural"), 50000, replace = TRUE, prob = c(0.7, 0.3)),
  osteoarthritis = NA,
  comorbidities = rpois(50000, lambda = 1.5),
  gp_visits = NA,
  specialist_visits = NA,
  hospital_admissions = NA,
  total_cost = NA
)

# Generate osteoarthritis status
healthcare_data <- healthcare_data %>%
  mutate(
    oa_prob = plogis(-3 + 0.05 * (age - 50) + 0.02 * socioeconomic_score +
                    0.3 * (sex == "Female") + 0.1 * comorbidities),
    osteoarthritis = rbinom(n(), 1, oa_prob)
  )

# Generate healthcare utilization based on risk factors
healthcare_data <- healthcare_data %>%
  mutate(
    # GP visits (primary care)
    gp_base = 2 + 0.02 * (age - 50) + 0.5 * osteoarthritis + 0.1 * comorbidities,
    gp_rural_adjust = ifelse(rural_urban == "Rural", 0.8, 1.2),
    gp_visits = rpois(n(), lambda = gp_base * gp_rural_adjust),

    # Specialist visits
    specialist_base = 0.5 + 1.5 * osteoarthritis + 0.2 * comorbidities,
    specialist_visits = rpois(n(), lambda = specialist_base),

    # Hospital admissions
    hospital_base = 0.1 + 0.3 * osteoarthritis + 0.05 * (age - 65) + 0.1 * comorbidities,
    hospital_rural_adjust = ifelse(rural_urban == "Rural", 1.3, 0.9),
    hospital_admissions = rpois(n(), lambda = hospital_base * hospital_rural_adjust),

    # Healthcare costs
    gp_cost = gp_visits * 50,  # $50 per GP visit
    specialist_cost = specialist_visits * 150,  # $150 per specialist visit
    hospital_cost = hospital_admissions * 5000,  # $5000 per admission
    medication_cost = osteoarthritis * 800 + comorbidities * 200,  # Annual medication costs
    total_cost = gp_cost + specialist_cost + hospital_cost + medication_cost
  )

message("Healthcare utilization data generated. Dataset contains ", nrow(healthcare_data), " records.")

# Basic Utilization Analysis ---------------------------------------------

message("\nStep 2: Basic utilization analysis...")

# Overall utilization statistics
utilization_summary <- healthcare_data %>%
  summarise(
    total_patients = n(),
    mean_gp_visits = mean(gp_visits, na.rm = TRUE),
    mean_specialist_visits = mean(specialist_visits, na.rm = TRUE),
    mean_hospitalizations = mean(hospital_admissions, na.rm = TRUE),
    mean_total_cost = mean(total_cost, na.rm = TRUE),
    median_total_cost = median(total_cost, na.rm = TRUE),
    pct_with_any_utilization = mean(gp_visits > 0 | specialist_visits > 0 | hospital_admissions > 0) * 100
  )

cat("\nOverall Utilization Summary:\n")
print(utilization_summary)

# Service utilization patterns
service_patterns <- healthcare_data %>%
  mutate(
    utilization_pattern = case_when(
      gp_visits > 0 & specialist_visits == 0 & hospital_admissions == 0 ~ "GP Only",
      gp_visits == 0 & specialist_visits > 0 & hospital_admissions == 0 ~ "Specialist Only",
      gp_visits == 0 & specialist_visits == 0 & hospital_admissions > 0 ~ "Hospital Only",
      gp_visits > 0 & specialist_visits > 0 & hospital_admissions == 0 ~ "GP + Specialist",
      gp_visits > 0 & specialist_visits == 0 & hospital_admissions > 0 ~ "GP + Hospital",
      gp_visits == 0 & specialist_visits > 0 & hospital_admissions > 0 ~ "Specialist + Hospital",
      gp_visits > 0 & specialist_visits > 0 & hospital_admissions > 0 ~ "All Services",
      TRUE ~ "No Utilization"
    )
  ) %>%
  count(utilization_pattern) %>%
  mutate(percentage = n / sum(n) * 100) %>%
  arrange(desc(n))

cat("\nService Utilization Patterns:\n")
print(service_patterns)

# Demographic Utilization Analysis ---------------------------------------

message("\nStep 3: Demographic utilization analysis...")

# Utilization by age groups
age_utilization <- healthcare_data %>%
  mutate(
    age_group = cut(age,
                   breaks = c(18, 35, 50, 65, 80, Inf),
                   labels = c("18-34", "35-49", "50-64", "65-79", "80+"))
  ) %>%
  group_by(age_group) %>%
  summarise(
    n = n(),
    mean_gp_visits = mean(gp_visits, na.rm = TRUE),
    mean_specialist_visits = mean(specialist_visits, na.rm = TRUE),
    mean_hospitalizations = mean(hospital_admissions, na.rm = TRUE),
    mean_total_cost = mean(total_cost, na.rm = TRUE),
    utilization_rate = mean(gp_visits > 0 | specialist_visits > 0 | hospital_admissions > 0) * 100
  ) %>%
  arrange(age_group)

cat("\nUtilization by Age Group:\n")
print(age_utilization)

# Utilization by sex
sex_utilization <- healthcare_data %>%
  group_by(sex) %>%
  summarise(
    n = n(),
    mean_gp_visits = mean(gp_visits, na.rm = TRUE),
    mean_specialist_visits = mean(specialist_visits, na.rm = TRUE),
    mean_hospitalizations = mean(hospital_admissions, na.rm = TRUE),
    mean_total_cost = mean(total_cost, na.rm = TRUE),
    utilization_rate = mean(gp_visits > 0 | specialist_visits > 0 | hospital_admissions > 0) * 100
  )

cat("\nUtilization by Sex:\n")
print(sex_utilization)

# Geographic utilization analysis
state_utilization <- healthcare_data %>%
  group_by(state) %>%
  summarise(
    n = n(),
    mean_gp_visits = mean(gp_visits, na.rm = TRUE),
    mean_specialist_visits = mean(specialist_visits, na.rm = TRUE),
    mean_hospitalizations = mean(hospital_admissions, na.rm = TRUE),
    mean_total_cost = mean(total_cost, na.rm = TRUE),
    utilization_rate = mean(gp_visits > 0 | specialist_visits > 0 | hospital_admissions > 0) * 100
  ) %>%
  arrange(desc(mean_total_cost))

cat("\nUtilization by State:\n")
print(state_utilization)

# Cost Analysis ----------------------------------------------------------

message("\nStep 4: Cost analysis...")

# Cost distribution analysis
cost_distribution <- healthcare_data %>%
  summarise(
    mean_cost = mean(total_cost, na.rm = TRUE),
    median_cost = median(total_cost, na.rm = TRUE),
    sd_cost = sd(total_cost, na.rm = TRUE),
    min_cost = min(total_cost, na.rm = TRUE),
    max_cost = max(total_cost, na.rm = TRUE),
    cost_skewness = (mean_cost - median_cost) / sd_cost,
    pct_zero_cost = mean(total_cost == 0, na.rm = TRUE) * 100
  )

cat("\nCost Distribution Analysis:\n")
print(cost_distribution)

# Cost percentiles
cost_percentiles <- quantile(healthcare_data$total_cost,
                           probs = c(0.1, 0.25, 0.5, 0.75, 0.9, 0.95, 0.99),
                           na.rm = TRUE)
cat("\nCost Percentiles:\n")
print(cost_percentiles)

# High-cost patient analysis
high_cost_threshold <- quantile(healthcare_data$total_cost, 0.9, na.rm = TRUE)
high_cost_patients <- healthcare_data %>%
  filter(total_cost >= high_cost_threshold) %>%
  summarise(
    count = n(),
    pct_of_total = (count / nrow(healthcare_data)) * 100,
    total_cost_high_users = sum(total_cost, na.rm = TRUE),
    pct_of_total_cost = (total_cost_high_users / sum(healthcare_data$total_cost, na.rm = TRUE)) * 100,
    mean_age = mean(age, na.rm = TRUE),
    pct_female = mean(sex == "Female", na.rm = TRUE) * 100,
    mean_comorbidities = mean(comorbidities, na.rm = TRUE),
    pct_osteoarthritis = mean(osteoarthritis, na.rm = TRUE) * 100
  )

cat("\nHigh-Cost Patients Analysis (Top 10%):\n")
print(high_cost_patients)

# Access and Disparity Analysis ------------------------------------------

message("\nStep 5: Access and disparity analysis...")

# Socioeconomic access analysis
socioeconomic_analysis <- healthcare_data %>%
  mutate(
    socioeconomic_group = cut(socioeconomic_score,
                             breaks = quantile(socioeconomic_score, probs = c(0, 0.33, 0.67, 1), na.rm = TRUE),
                             labels = c("Low", "Medium", "High")),
    has_access = gp_visits > 0 | specialist_visits > 0 | hospital_admissions > 0
  ) %>%
  group_by(socioeconomic_group) %>%
  summarise(
    n = n(),
    access_rate = mean(has_access, na.rm = TRUE) * 100,
    mean_cost = mean(total_cost, na.rm = TRUE),
    mean_visits = mean(gp_visits + specialist_visits, na.rm = TRUE),
    mean_hospitalizations = mean(hospital_admissions, na.rm = TRUE)
  )

cat("\nSocioeconomic Access Analysis:\n")
print(socioeconomic_analysis)

# Rural vs urban analysis
rural_urban_analysis <- healthcare_data %>%
  mutate(has_access = gp_visits > 0 | specialist_visits > 0 | hospital_admissions > 0) %>%
  group_by(rural_urban) %>%
  summarise(
    n = n(),
    access_rate = mean(has_access, na.rm = TRUE) * 100,
    mean_gp_visits = mean(gp_visits, na.rm = TRUE),
    mean_specialist_visits = mean(specialist_visits, na.rm = TRUE),
    mean_hospitalizations = mean(hospital_admissions, na.rm = TRUE),
    mean_total_cost = mean(total_cost, na.rm = TRUE)
  )

cat("\nRural vs Urban Analysis:\n")
print(rural_urban_analysis)

# Cost-Effectiveness Analysis --------------------------------------------

message("\nStep 6: Cost-effectiveness analysis...")

# Basic cost-effectiveness for OA treatment
cea_data <- healthcare_data %>%
  filter(osteoarthritis == 1) %>%
  mutate(
    treatment_effectiveness = rnorm(n(), mean = 0.7, sd = 0.2),  # Simulated effectiveness
    treatment_cost = 2000,  # Annual treatment cost
    qaly_gain = treatment_effectiveness * 0.15,  # Quality of life improvement
    baseline_cost = total_cost,
    total_cost_with_treatment = total_cost + treatment_cost,
    incremental_cost = treatment_cost,
    incremental_qaly = qaly_gain
  )

cea_results <- cea_data %>%
  summarise(
    total_patients = n(),
    mean_baseline_cost = mean(baseline_cost, na.rm = TRUE),
    mean_treatment_cost = mean(treatment_cost),
    mean_qaly_gain = mean(qaly_gain),
    mean_total_cost_with_treatment = mean(total_cost_with_treatment),
    icer = mean(incremental_cost) / mean(incremental_qaly),  # Incremental cost-effectiveness ratio
    net_monetary_benefit = mean(qaly_gain) * 50000 - mean(incremental_cost)  # Assuming $50k per QALY threshold
  )

cat("\nCost-Effectiveness Analysis for OA Treatment:\n")
print(cea_results)

# Data Visualization -----------------------------------------------------

message("\nStep 7: Creating visualizations...")

# Set up theme
theme_set(theme_minimal())

# 1. Cost distribution by age group
cost_age_plot <- healthcare_data %>%
  mutate(age_group = cut(age, breaks = c(18, 35, 50, 65, 80, Inf),
                        labels = c("18-34", "35-49", "50-64", "65-79", "80+"))) %>%
  ggplot(aes(x = age_group, y = total_cost)) +
  geom_boxplot(fill = "steelblue", alpha = 0.7) +
  scale_y_log10(labels = dollar) +
  labs(
    title = "Healthcare Costs by Age Group",
    x = "Age Group",
    y = "Total Cost (log scale)"
  )

print(cost_age_plot)

# 2. Service utilization by state
state_utilization_plot <- state_utilization %>%
  ggplot(aes(x = reorder(state, utilization_rate), y = utilization_rate)) +
  geom_bar(stat = "identity", fill = "steelblue", alpha = 0.7) +
  geom_text(aes(label = sprintf("%.1f%%", utilization_rate)), hjust = -0.1) +
  coord_flip() +
  labs(
    title = "Healthcare Utilization Rate by State",
    x = "State",
    y = "Utilization Rate (%)"
  ) +
  scale_y_continuous(limits = c(0, max(state_utilization$utilization_rate) * 1.2))

print(state_utilization_plot)

# 3. Cost vs utilization scatter plot
cost_utilization_plot <- ggplot(healthcare_data,
                               aes(x = gp_visits + specialist_visits, y = total_cost)) +
  geom_point(alpha = 0.6, color = "steelblue") +
  geom_smooth(method = "lm", color = "red") +
  scale_y_log10(labels = dollar) +
  labs(
    title = "Healthcare Costs vs Service Utilization",
    x = "Total Visits (GP + Specialist)",
    y = "Total Cost (log scale)"
  )

print(cost_utilization_plot)

# 4. Rural vs urban cost comparison
rural_urban_plot <- ggplot(healthcare_data, aes(x = rural_urban, y = total_cost, fill = rural_urban)) +
  geom_boxplot(alpha = 0.7) +
  scale_y_log10(labels = dollar) +
  labs(
    title = "Healthcare Costs: Rural vs Urban",
    x = "Location",
    y = "Total Cost (log scale)",
    fill = "Location"
  ) +
  scale_fill_brewer(palette = "Set2")

print(rural_urban_plot)

# Save Results -----------------------------------------------------------

message("\nStep 8: Saving results...")

# Create results directory if it doesn't exist
if (!dir.exists("results")) {
  dir.create("results")
}

# Save key results
utilization_results <- list(
  utilization_summary = utilization_summary,
  service_patterns = service_patterns,
  age_utilization = age_utilization,
  sex_utilization = sex_utilization,
  state_utilization = state_utilization,
  cost_distribution = cost_distribution,
  cost_percentiles = cost_percentiles,
  high_cost_patients = high_cost_patients,
  socioeconomic_analysis = socioeconomic_analysis,
  rural_urban_analysis = rural_urban_analysis,
  cea_results = cea_results,
  timestamp = Sys.time()
)

saveRDS(utilization_results, "results/tutorial_02_results.rds")

# Save plots
ggsave("results/cost_age_plot.png", cost_age_plot, width = 8, height = 6)
ggsave("results/state_utilization_plot.png", state_utilization_plot, width = 8, height = 6)
ggsave("results/cost_utilization_plot.png", cost_utilization_plot, width = 8, height = 6)
ggsave("results/rural_urban_plot.png", rural_urban_plot, width = 8, height = 6)

message("Results saved to 'results/' directory")

# Summary Report ---------------------------------------------------------

message("\nStep 9: Generating summary report...")

summary_report <- sprintf("
TUTORIAL 2: HEALTHCARE UTILIZATION ANALYSIS
===========================================

EXECUTION SUMMARY
-----------------
Generated on: %s
Dataset size: %d records
Analysis completed successfully

KEY FINDINGS
------------
1. Overall Utilization Rate: %.1f%%
2. Mean Annual Cost: $%.0f (Median: $%.0f)
3. High-Cost Patients (Top 10%%): %d patients (%.1f%% of total)
4. High-Cost Patients Cost Share: %.1f%% of total healthcare costs
5. Rural-Urban Cost Difference: Rural patients have %.0f%% higher costs
6. Cost-Effectiveness: ICER = $%.0f per QALY for OA treatment

UTILIZATION PATTERNS
--------------------
- GP Only: %.1f%% of patients
- GP + Specialist: %.1f%% of patients
- Hospital Admissions: %.1f%% of patients
- No Utilization: %.1f%% of patients

DEMOGRAPHIC VARIATIONS
----------------------
- Age 65+: %.0f%% higher utilization than age 18-34
- Females: %.0f%% higher costs than males
- Rural Areas: %.0f%% higher hospitalization rates

COST DISTRIBUTION
-----------------
- 10th Percentile: $%.0f
- 50th Percentile: $%.0f
- 90th Percentile: $%.0f
- 95th Percentile: $%.0f
- Cost Skewness: %.2f

ACCESS DISPARITIES
------------------
- Low SES Access Rate: %.1f%%
- High SES Access Rate: %.1f%%
- Rural Access Rate: %.1f%%
- Urban Access Rate: %.1f%%

POLICY IMPLICATIONS
-------------------
1. Focus on high-cost patients (top 10%% account for %.1f%% of costs)
2. Address rural-urban disparities in healthcare access
3. Target preventive care for high-risk demographic groups
4. Consider cost-effectiveness thresholds for treatment programs

DATA SOURCES
------------
- Synthetic data mimicking AIHW Medicare and PBS data
- Population: 50,000 Australian adults
- Time period: Annual healthcare utilization
- Geographic coverage: All Australian states/territories

ANALYSIS METHODS
----------------
- Healthcare utilization pattern analysis
- Cost distribution and percentile analysis
- Demographic stratification
- Access disparity assessment
- Cost-effectiveness evaluation
- Geographic variation analysis

NEXT STEPS
----------
- Tutorial 3: Longitudinal disease progression modeling
- Tutorial 4: Geographic health disparities analysis
- Advanced analysis: Predictive modeling for high-cost patients
",
  format(Sys.time(), "%Y-%m-%d %H:%M:%S"),
  nrow(healthcare_data),
  utilization_summary$pct_with_any_utilization,
  utilization_summary$mean_total_cost,
  utilization_summary$median_total_cost,
  high_cost_patients$count,
  high_cost_patients$pct_of_total,
  high_cost_patients$pct_of_total_cost,
  (rural_urban_analysis$mean_total_cost[rural_urban_analysis$rural_urban == "Rural"] /
   rural_urban_analysis$mean_total_cost[rural_urban_analysis$rural_urban == "Urban"] - 1) * 100,
  cea_results$icer,
  service_patterns$percentage[service_patterns$utilization_pattern == "GP Only"],
  service_patterns$percentage[service_patterns$utilization_pattern == "GP + Specialist"],
  mean(healthcare_data$hospital_admissions > 0) * 100,
  service_patterns$percentage[service_patterns$utilization_pattern == "No Utilization"],
  (age_utilization$utilization_rate[age_utilization$age_group == "80+"] /
   age_utilization$utilization_rate[age_utilization$age_group == "18-34"] - 1) * 100,
  (sex_utilization$mean_total_cost[sex_utilization$sex == "Female"] /
   sex_utilization$mean_total_cost[sex_utilization$sex == "Male"] - 1) * 100,
  (rural_urban_analysis$mean_hospitalizations[rural_urban_analysis$rural_urban == "Rural"] /
   rural_urban_analysis$mean_hospitalizations[rural_urban_analysis$rural_urban == "Urban"] - 1) * 100,
  cost_percentiles["10%"],
  cost_percentiles["50%"],
  cost_percentiles["90%"],
  cost_percentiles["95%"],
  cost_distribution$cost_skewness,
  socioeconomic_analysis$access_rate[socioeconomic_analysis$socioeconomic_group == "Low"],
  socioeconomic_analysis$access_rate[socioeconomic_analysis$socioeconomic_group == "High"],
  rural_urban_analysis$access_rate[rural_urban_analysis$rural_urban == "Rural"],
  rural_urban_analysis$access_rate[rural_urban_analysis$rural_urban == "Urban"],
  high_cost_patients$pct_of_total_cost
)

cat(summary_report)

# Write summary to file
writeLines(summary_report, "results/tutorial_02_summary.txt")

message("\nTutorial 2 completed successfully!")
message("Results saved to 'results/' directory")
message("Summary report: 'results/tutorial_02_summary.txt'")</content>
<parameter name="filePath">\\wsl.localhost\Ubuntu\home\doughnut\github\aus_oa_public\tutorials\tutorial_02_healthcare_utilization\scripts\tutorial_02_analysis.R
