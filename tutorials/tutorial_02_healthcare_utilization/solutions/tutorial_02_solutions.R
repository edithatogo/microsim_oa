#' Tutorial 2 Solutions: Healthcare Utilization Analysis
#'
#' Complete solutions for Tutorial 2 exercises on healthcare utilization analysis.
#' This script provides comprehensive solutions for all tutorial exercises.
#'
#' @author AUS-OA Development Team

# Setup -------------------------------------------------------------------

library(tidyverse)
library(scales)
library(ggthemes)
library(aus_oa_public)
set.seed(12345)

# Exercise 1: Loading and Exploring Healthcare Data -----------------------

# Solution 1.1: Load healthcare utilization data
healthcare_data <- readRDS("data/healthcare_utilization_data.rds")

# Solution 1.2: Examine dataset structure
dim(healthcare_data)
str(healthcare_data)
summary(healthcare_data)

# Solution 1.3: Check for missing values
colSums(is.na(healthcare_data))
colMeans(is.na(healthcare_data)) * 100

# Solution 1.4: Data quality assessment
healthcare_data %>%
  summarise(
    negative_costs = sum(total_cost < 0, na.rm = TRUE),
    zero_cost_high_utilization = sum(total_cost == 0 &
                                    (gp_visits > 5 | specialist_visits > 2 | hospital_admissions > 0), na.rm = TRUE),
    extremely_high_costs = sum(total_cost > 100000, na.rm = TRUE)
  )

# Exercise 2: Basic Utilization Analysis ----------------------------------

# Solution 2.1: Overall utilization statistics
utilization_summary <- healthcare_data %>%
  summarise(
    total_patients = n(),
    mean_gp_visits = mean(gp_visits, na.rm = TRUE),
    mean_specialist_visits = mean(specialist_visits, na.rm = TRUE),
    mean_hospitalizations = mean(hospital_admissions, na.rm = TRUE),
    mean_total_cost = mean(total_cost, na.rm = TRUE),
    median_total_cost = median(total_cost, na.rm = TRUE),
    pct_with_any_utilization = mean(gp_visits > 0 | specialist_visits > 0 | hospital_admissions > 0, na.rm = TRUE) * 100
  )

print(utilization_summary)

# Solution 2.2: Service utilization patterns
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

print(service_patterns)

# Solution 2.3: High utilizer analysis
high_cost_threshold <- quantile(healthcare_data$total_cost, 0.9, na.rm = TRUE)
high_utilizers <- healthcare_data %>%
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

print(high_utilizers)

# Exercise 3: Demographic Utilization Analysis ---------------------------

# Solution 3.1: Utilization by age groups
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
    utilization_rate = mean(gp_visits > 0 | specialist_visits > 0 | hospital_admissions > 0, na.rm = TRUE) * 100
  ) %>%
  arrange(age_group)

print(age_utilization)

# Solution 3.2: Utilization by sex
sex_utilization <- healthcare_data %>%
  group_by(sex) %>%
  summarise(
    n = n(),
    mean_gp_visits = mean(gp_visits, na.rm = TRUE),
    mean_specialist_visits = mean(specialist_visits, na.rm = TRUE),
    mean_hospitalizations = mean(hospital_admissions, na.rm = TRUE),
    mean_total_cost = mean(total_cost, na.rm = TRUE),
    utilization_rate = mean(gp_visits > 0 | specialist_visits > 0 | hospital_admissions > 0, na.rm = TRUE) * 100
  )

print(sex_utilization)

# Solution 3.3: Geographic utilization analysis
state_utilization <- healthcare_data %>%
  group_by(state) %>%
  summarise(
    n = n(),
    mean_gp_visits = mean(gp_visits, na.rm = TRUE),
    mean_specialist_visits = mean(specialist_visits, na.rm = TRUE),
    mean_hospitalizations = mean(hospital_admissions, na.rm = TRUE),
    mean_total_cost = mean(total_cost, na.rm = TRUE),
    utilization_rate = mean(gp_visits > 0 | specialist_visits > 0 | hospital_admissions > 0, na.rm = TRUE) * 100
  ) %>%
  arrange(desc(mean_total_cost))

print(state_utilization)

# Exercise 4: Cost Analysis ----------------------------------------------

# Solution 4.1: Cost distribution analysis
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

print(cost_distribution)

# Solution 4.2: Cost percentiles
cost_percentiles <- quantile(healthcare_data$total_cost,
                           probs = c(0.1, 0.25, 0.5, 0.75, 0.9, 0.95, 0.99),
                           na.rm = TRUE)
print(cost_percentiles)

# Solution 4.3: Cost components breakdown
cost_components <- healthcare_data %>%
  summarise(
    mean_gp_cost = mean(gp_visits * 50, na.rm = TRUE),
    mean_specialist_cost = mean(specialist_visits * 150, na.rm = TRUE),
    mean_hospital_cost = mean(hospital_admissions * 5000, na.rm = TRUE),
    mean_medication_cost = mean(200 * comorbidities + ifelse(osteoarthritis == 1, 800, 0), na.rm = TRUE),
    mean_total_calculated = mean_gp_cost + mean_specialist_cost + mean_hospital_cost + mean_medication_cost,
    mean_total_actual = mean(total_cost, na.rm = TRUE)
  )

print(cost_components)

# Solution 4.4: Cost drivers correlation
cost_correlations <- healthcare_data %>%
  select(total_cost, age, comorbidities, osteoarthritis, gp_visits,
         specialist_visits, hospital_admissions) %>%
  cor(use = "complete.obs")

print(cost_correlations["total_cost", ])

# Exercise 5: Access and Disparity Analysis ------------------------------

# Solution 5.1: Socioeconomic access analysis
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

print(socioeconomic_analysis)

# Solution 5.2: Rural vs urban analysis
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

print(rural_urban_analysis)

# Solution 5.3: Disparity index calculation
disparity_analysis <- healthcare_data %>%
  mutate(
    age_group = cut(age, breaks = c(18, 50, 70, Inf), labels = c("Young", "Middle", "Older")),
    income_group = cut(income_level, breaks = quantile(income_level, c(0, 0.5, 1), na.rm = TRUE),
                      labels = c("Low", "High")),
    has_access = gp_visits > 0 | specialist_visits > 0 | hospital_admissions > 0
  ) %>%
  group_by(age_group, sex, income_group) %>%
  summarise(
    mean_cost = mean(total_cost, na.rm = TRUE),
    utilization_rate = mean(has_access, na.rm = TRUE) * 100,
    n = n()
  ) %>%
  ungroup()

# Calculate disparity ratios
max_cost <- max(disparity_analysis$mean_cost, na.rm = TRUE)
min_cost <- min(disparity_analysis$mean_cost, na.rm = TRUE)
cost_disparity_ratio <- max_cost / min_cost

cat("Cost Disparity Ratio:", round(cost_disparity_ratio, 2), "\n")

# Exercise 6: Cost-Effectiveness Analysis --------------------------------

# Solution 6.1: Basic CEA for OA treatment
cea_data <- healthcare_data %>%
  filter(osteoarthritis == 1) %>%
  mutate(
    treatment_effectiveness = rnorm(n(), mean = 0.7, sd = 0.2),
    treatment_cost = 2000,
    qaly_gain = treatment_effectiveness * 0.15,
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
    icer = mean(incremental_cost) / mean(incremental_qaly),
    net_monetary_benefit = mean(qaly_gain) * 50000 - mean(incremental_cost)
  )

print(cea_results)

# Solution 6.2: Intervention impact analysis
intervention_analysis <- healthcare_data %>%
  mutate(
    intervention_group = rbinom(n(), 1, 0.5),
    reduced_hospitalizations = hospital_admissions * (1 - 0.2 * intervention_group),
    intervention_cost = 500 * intervention_group,
    cost_savings = (hospital_admissions - reduced_hospitalizations) * 5000,
    net_cost = intervention_cost - cost_savings
  ) %>%
  group_by(intervention_group) %>%
  summarise(
    n = n(),
    mean_hospitalizations_original = mean(hospital_admissions),
    mean_hospitalizations_reduced = mean(reduced_hospitalizations),
    mean_intervention_cost = mean(intervention_cost),
    mean_cost_savings = mean(cost_savings),
    mean_net_cost = mean(net_cost),
    roi = mean(cost_savings) / mean(intervention_cost)
  )

print(intervention_analysis)

# Exercise 7: Advanced Visualizations ------------------------------------

# Solution 7.1: Cost distribution by age group
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
  ) +
  theme_minimal()

print(cost_age_plot)

# Solution 7.2: Service utilization heatmap
service_heatmap_data <- healthcare_data %>%
  mutate(age_group = cut(age, breaks = c(18, 35, 50, 65, 80, Inf),
                        labels = c("18-34", "35-49", "50-64", "65-79", "80+"))) %>%
  group_by(age_group, sex) %>%
  summarise(
    gp_rate = mean(gp_visits > 0),
    specialist_rate = mean(specialist_visits > 0),
    hospital_rate = mean(hospital_admissions > 0)
  ) %>%
  gather(service_type, utilization_rate, gp_rate:hospital_rate)

service_heatmap <- ggplot(service_heatmap_data,
                         aes(x = age_group, y = service_type, fill = utilization_rate)) +
  geom_tile() +
  facet_wrap(~sex) +
  scale_fill_gradient(low = "white", high = "steelblue") +
  labs(
    title = "Healthcare Service Utilization by Age and Sex",
    x = "Age Group",
    y = "Service Type",
    fill = "Utilization Rate"
  ) +
  theme_minimal()

print(service_heatmap)

# Solution 7.3: Geographic utilization map
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
  scale_y_continuous(limits = c(0, max(state_utilization$utilization_rate) * 1.2)) +
  theme_minimal()

print(state_utilization_plot)

# Solution 7.4: Rural vs urban cost comparison
rural_urban_plot <- ggplot(healthcare_data, aes(x = rural_urban, y = total_cost, fill = rural_urban)) +
  geom_boxplot(alpha = 0.7) +
  scale_y_log10(labels = dollar) +
  labs(
    title = "Healthcare Costs: Rural vs Urban",
    x = "Location",
    y = "Total Cost (log scale)",
    fill = "Location"
  ) +
  scale_fill_brewer(palette = "Set2") +
  theme_minimal()

print(rural_urban_plot)

# Solution 7.5: Cost-effectiveness acceptability curve
cea_curve_data <- data.frame(
  threshold = seq(0, 100000, by = 5000),
  probability = sapply(seq(0, 100000, by = 5000),
                      function(x) mean(cea_data$icer < x, na.rm = TRUE))
)

cea_curve_plot <- ggplot(cea_curve_data, aes(x = threshold, y = probability)) +
  geom_line(color = "steelblue", size = 1) +
  geom_vline(xintercept = 50000, linetype = "dashed", color = "red") +
  annotate("text", x = 55000, y = 0.5, label = "Common threshold\n($50,000/QALY)",
           color = "red", hjust = 0) +
  labs(
    title = "Cost-Effectiveness Acceptability Curve",
    x = "Willingness to Pay Threshold ($/QALY)",
    y = "Probability Cost-Effective"
  ) +
  scale_x_continuous(labels = dollar) +
  theme_minimal()

print(cea_curve_plot)

# Exercise 8: Export Results ----------------------------------------------

# Solution 8.1: Create results directory
if (!dir.exists("results")) {
  dir.create("results")
}

# Solution 8.2: Save comprehensive results
utilization_results <- list(
  utilization_summary = utilization_summary,
  service_patterns = service_patterns,
  high_utilizers = high_utilizers,
  age_utilization = age_utilization,
  sex_utilization = sex_utilization,
  state_utilization = state_utilization,
  cost_distribution = cost_distribution,
  cost_percentiles = cost_percentiles,
  cost_components = cost_components,
  cost_correlations = cost_correlations,
  socioeconomic_analysis = socioeconomic_analysis,
  rural_urban_analysis = rural_urban_analysis,
  disparity_analysis = disparity_analysis,
  cea_results = cea_results,
  intervention_analysis = intervention_analysis,
  timestamp = Sys.time()
)

saveRDS(utilization_results, "results/tutorial_02_complete_results.rds")

# Solution 8.3: Save all plots
ggsave("results/cost_age_plot.png", cost_age_plot, width = 8, height = 6)
ggsave("results/service_heatmap.png", service_heatmap, width = 10, height = 6)
ggsave("results/state_utilization_plot.png", state_utilization_plot, width = 8, height = 6)
ggsave("results/rural_urban_plot.png", rural_urban_plot, width = 8, height = 6)
ggsave("results/cea_curve_plot.png", cea_curve_plot, width = 8, height = 6)

# Solution 8.4: Generate comprehensive summary report
summary_report <- sprintf("
TUTORIAL 2: HEALTHCARE UTILIZATION ANALYSIS - COMPLETE SOLUTIONS
================================================================

EXECUTION SUMMARY
-----------------
Completed on: %s
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

COST COMPONENTS
---------------
- GP Visits: $%.0f average
- Specialist Visits: $%.0f average
- Hospital Admissions: $%.0f average
- Medications: $%.0f average

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

COST-EFFECTIVENESS ANALYSIS
---------------------------
- Treatment Cost: $%.0f per patient
- QALY Gain: %.2f per patient
- ICER: $%.0f per QALY
- Net Monetary Benefit: $%.0f per patient

INTERVENTION IMPACT
-------------------
- Hospitalization Reduction: %.0f%%
- Intervention Cost: $%.0f per patient
- Cost Savings: $%.0f per patient
- ROI: %.1f

POLICY IMPLICATIONS
-------------------
1. Focus on high-cost patients (top 10%% account for %.1f%% of costs)
2. Address rural-urban disparities in healthcare access
3. Target preventive care for high-risk demographic groups
4. Consider cost-effectiveness thresholds for treatment programs
5. Implement interventions to reduce hospitalization rates

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
- Intervention impact modeling

RECOMMENDATIONS FOR FURTHER ANALYSIS
-----------------------------------
1. Longitudinal analysis of utilization patterns
2. Machine learning for high-cost patient prediction
3. Advanced cost-effectiveness modeling
4. Geographic information system (GIS) analysis
5. Patient satisfaction and quality of care analysis

NEXT STEPS
----------
- Tutorial 3: Longitudinal disease progression modeling
- Tutorial 4: Geographic health disparities analysis
- Advanced analysis: Predictive modeling for healthcare costs
",
  format(Sys.time(), "%Y-%m-%d %H:%M:%S"),
  nrow(healthcare_data),
  utilization_summary$pct_with_any_utilization,
  utilization_summary$mean_total_cost,
  utilization_summary$median_total_cost,
  high_utilizers$count,
  high_utilizers$pct_of_total,
  high_utilizers$pct_of_total_cost,
  (rural_urban_analysis$mean_total_cost[rural_urban_analysis$rural_urban == "Rural"] /
   rural_urban_analysis$mean_total_cost[rural_urban_analysis$rural_urban == "Urban"] - 1) * 100,
  cea_results$icer,
  service_patterns$percentage[service_patterns$utilization_pattern == "GP Only"],
  service_patterns$percentage[service_patterns$utilization_pattern == "GP + Specialist"],
  mean(healthcare_data$hospital_admissions > 0) * 100,
  service_patterns$percentage[service_patterns$utilization_pattern == "No Utilization"],
  cost_components$mean_gp_cost,
  cost_components$mean_specialist_cost,
  cost_components$mean_hospital_cost,
  cost_components$mean_medication_cost,
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
  cea_results$mean_treatment_cost,
  cea_results$mean_qaly_gain,
  cea_results$icer,
  cea_results$net_monetary_benefit,
  (intervention_analysis$mean_hospitalizations_original[intervention_analysis$intervention_group == 1] -
   intervention_analysis$mean_hospitalizations_reduced[intervention_analysis$intervention_group == 1]) /
  intervention_analysis$mean_hospitalizations_original[intervention_analysis$intervention_group == 1] * 100,
  intervention_analysis$mean_intervention_cost[intervention_analysis$intervention_group == 1],
  intervention_analysis$mean_cost_savings[intervention_analysis$intervention_group == 1],
  intervention_analysis$roi[intervention_analysis$intervention_group == 1],
  high_utilizers$pct_of_total_cost
)

# Solution 8.5: Write summary to file
writeLines(summary_report, "results/tutorial_02_complete_summary.txt")

message("All exercises completed successfully!")
message("Results saved to 'results/' directory")
message("Summary report: 'results/tutorial_02_complete_summary.txt'")</content>
<parameter name="filePath">\\wsl.localhost\Ubuntu\home\doughnut\github\aus_oa_public\tutorials\tutorial_02_healthcare_utilization\solutions\tutorial_02_solutions.R
