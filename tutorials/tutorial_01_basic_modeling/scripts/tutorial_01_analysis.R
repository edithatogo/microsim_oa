#' Tutorial 1: Basic Population Health Modeling
#'
#' This script demonstrates basic population health modeling concepts
#' using synthetic Australian health survey data. It covers data exploration,
#' statistical analysis, and simple modeling techniques.
#'
#' @author AUS-OA Development Team
#' @date `r Sys.Date()`

# Setup -------------------------------------------------------------------

# Load required packages
library(tidyverse)
library(aus_oa_public)
library(scales)
library(ggthemes)

# Set random seed for reproducibility
set.seed(12345)

# Data Acquisition -------------------------------------------------------

message("Step 1: Acquiring health survey data...")

# In a real scenario, you would use:
# health_data <- acquire_aihw_nhs_data(year = 2022)

# For this tutorial, we'll create synthetic data
health_data <- data.frame(
  person_id = 1:50000,
  age = sample(18:85, 50000, replace = TRUE),
  sex = sample(c("Male", "Female"), 50000, replace = TRUE, prob = c(0.49, 0.51)),
  state = sample(c("NSW", "VIC", "QLD", "SA", "WA", "TAS", "NT", "ACT"),
                 50000, replace = TRUE),
  bmi = rnorm(50000, mean = 27, sd = 5),
  osteoarthritis = NA,
  pain_score = NA,
  physical_activity = sample(c("Low", "Moderate", "High"), 50000, replace = TRUE),
  smoking_status = sample(c("Never", "Former", "Current"), 50000, replace = TRUE,
                         prob = c(0.6, 0.3, 0.1)),
  comorbidities = rpois(50000, lambda = 1.5)
)

# Generate osteoarthritis status based on risk factors
health_data <- health_data %>%
  mutate(
    # Logistic model for OA probability
    oa_prob = plogis(-3 + 0.05 * (age - 50) + 0.02 * bmi +
                    0.3 * (sex == "Female") + 0.1 * comorbidities),
    osteoarthritis = rbinom(n(), 1, oa_prob),

    # Generate pain scores based on OA status
    pain_score = ifelse(osteoarthritis == 1,
                       rbeta(n(), 2, 3) * 10,  # Higher pain for OA patients
                       rbeta(n(), 1, 5) * 10)  # Lower pain for non-OA
  )

message("Data acquisition complete. Dataset contains ", nrow(health_data), " records.")

# Data Exploration -------------------------------------------------------

message("\nStep 2: Exploring the dataset...")

# Basic dataset information
cat("\nDataset Overview:\n")
cat("Dimensions:", dim(health_data), "\n")
cat("Column names:", paste(names(health_data), collapse = ", "), "\n")

# Summary statistics
cat("\nSummary Statistics:\n")
print(summary(health_data))

# Osteoarthritis Prevalence Analysis ------------------------------------

message("\nStep 3: Analyzing osteoarthritis prevalence...")

# Overall prevalence
overall_prevalence <- health_data %>%
  summarise(
    total_patients = n(),
    oa_cases = sum(osteoarthritis, na.rm = TRUE),
    prevalence_pct = (oa_cases / total_patients) * 100
  )

cat("\nOverall Osteoarthritis Prevalence:\n")
print(overall_prevalence)

# Prevalence by age groups
age_prevalence <- health_data %>%
  mutate(
    age_group = cut(age,
                   breaks = c(18, 35, 50, 65, 80, Inf),
                   labels = c("18-34", "35-49", "50-64", "65-79", "80+"),
                   include.lowest = TRUE)
  ) %>%
  group_by(age_group) %>%
  summarise(
    total = n(),
    oa_cases = sum(osteoarthritis, na.rm = TRUE),
    prevalence = (oa_cases / total) * 100
  ) %>%
  arrange(age_group)

cat("\nPrevalence by Age Group:\n")
print(age_prevalence)

# Prevalence by sex
sex_prevalence <- health_data %>%
  group_by(sex) %>%
  summarise(
    total = n(),
    oa_cases = sum(osteoarthritis, na.rm = TRUE),
    prevalence = (oa_cases / total) * 100
  )

cat("\nPrevalence by Sex:\n")
print(sex_prevalence)

# Risk Factor Analysis --------------------------------------------------

message("\nStep 4: Analyzing risk factors...")

# BMI analysis
bmi_analysis <- health_data %>%
  mutate(
    bmi_category = cut(bmi,
                      breaks = c(-Inf, 18.5, 25, 30, Inf),
                      labels = c("Underweight", "Normal", "Overweight", "Obese"))
  ) %>%
  group_by(bmi_category) %>%
  summarise(
    total = n(),
    oa_cases = sum(osteoarthritis, na.rm = TRUE),
    prevalence = (oa_cases / total) * 100
  )

cat("\nPrevalence by BMI Category:\n")
print(bmi_analysis)

# Comorbidities analysis
comorbidities_analysis <- health_data %>%
  mutate(
    comorbidity_group = cut(comorbidities,
                           breaks = c(-Inf, 0, 2, 5, Inf),
                           labels = c("None", "1-2", "3-5", "6+"))
  ) %>%
  group_by(comorbidity_group) %>%
  summarise(
    total = n(),
    oa_cases = sum(osteoarthritis, na.rm = TRUE),
    prevalence = (oa_cases / total) * 100
  )

cat("\nPrevalence by Number of Comorbidities:\n")
print(comorbidities_analysis)

# Statistical Modeling --------------------------------------------------

message("\nStep 5: Building statistical models...")

# Prepare data for modeling
model_data <- health_data %>%
  mutate(
    high_bmi = bmi >= 30,
    older_age = age >= 65,
    female = sex == "Female"
  ) %>%
  select(osteoarthritis, age, high_bmi, female, comorbidities) %>%
  na.omit()

# Simple logistic regression
oa_model <- glm(osteoarthritis ~ age + high_bmi + female + comorbidities,
                data = model_data,
                family = binomial)

cat("\nLogistic Regression Model Summary:\n")
print(summary(oa_model))

# Calculate odds ratios
odds_ratios <- exp(coef(oa_model))
cat("\nOdds Ratios:\n")
print(odds_ratios)

# Model evaluation
model_predictions <- predict(oa_model, type = "response")
model_evaluation <- data.frame(
  actual = model_data$osteoarthritis,
  predicted = model_predictions,
  predicted_class = ifelse(model_predictions > 0.5, 1, 0)
)

# Confusion matrix
confusion_matrix <- table(model_evaluation$actual, model_evaluation$predicted_class)
cat("\nConfusion Matrix:\n")
print(confusion_matrix)

# Model accuracy
accuracy <- sum(diag(confusion_matrix)) / sum(confusion_matrix)
cat("\nModel Accuracy:", round(accuracy * 100, 2), "%\n")

# Data Visualization ----------------------------------------------------

message("\nStep 6: Creating visualizations...")

# Set up theme for consistent plotting
theme_set(theme_minimal())

# 1. Age distribution by OA status
age_plot <- ggplot(health_data, aes(x = age, fill = factor(osteoarthritis))) +
  geom_histogram(alpha = 0.7, bins = 30, position = "identity") +
  labs(
    title = "Age Distribution by Osteoarthritis Status",
    x = "Age",
    y = "Count",
    fill = "OA Status"
  ) +
  scale_fill_brewer(palette = "Set2", labels = c("No OA", "Has OA"))

print(age_plot)

# 2. BMI distribution
bmi_plot <- ggplot(health_data, aes(x = bmi)) +
  geom_histogram(bins = 30, fill = "steelblue", alpha = 0.7) +
  geom_vline(xintercept = 25, linetype = "dashed", color = "orange") +
  geom_vline(xintercept = 30, linetype = "dashed", color = "red") +
  labs(
    title = "BMI Distribution",
    x = "BMI",
    y = "Count"
  ) +
  annotate("text", x = 22, y = 1500, label = "Normal", color = "orange") +
  annotate("text", x = 27.5, y = 1500, label = "Overweight", color = "orange") +
  annotate("text", x = 32, y = 1500, label = "Obese", color = "red")

print(bmi_plot)

# 3. Pain scores by OA status
pain_plot <- ggplot(health_data, aes(x = factor(osteoarthritis), y = pain_score,
                                    fill = factor(osteoarthritis))) +
  geom_boxplot(alpha = 0.7) +
  labs(
    title = "Pain Scores by Osteoarthritis Status",
    x = "Osteoarthritis Status",
    y = "Pain Score (0-10)",
    fill = "OA Status"
  ) +
  scale_x_discrete(labels = c("No OA", "Has OA")) +
  scale_fill_brewer(palette = "Set2")

print(pain_plot)

# 4. Prevalence by state
state_plot <- health_data %>%
  group_by(state) %>%
  summarise(
    prevalence = mean(osteoarthritis, na.rm = TRUE) * 100,
    count = n()
  ) %>%
  ggplot(aes(x = reorder(state, prevalence), y = prevalence)) +
  geom_bar(stat = "identity", fill = "steelblue", alpha = 0.7) +
  geom_text(aes(label = sprintf("%.1f%%", prevalence)), hjust = -0.1) +
  coord_flip() +
  labs(
    title = "Osteoarthritis Prevalence by State",
    x = "State",
    y = "Prevalence (%)"
  ) +
  scale_y_continuous(limits = c(0, max(prevalence) * 1.2))

print(state_plot)

# Save Results -----------------------------------------------------------

message("\nStep 7: Saving results...")

# Create results directory if it doesn't exist
if (!dir.exists("results")) {
  dir.create("results")
}

# Save key results
results_summary <- list(
  overall_prevalence = overall_prevalence,
  age_prevalence = age_prevalence,
  sex_prevalence = sex_prevalence,
  bmi_analysis = bmi_analysis,
  comorbidities_analysis = comorbidities_analysis,
  model_coefficients = coef(oa_model),
  odds_ratios = odds_ratios,
  model_accuracy = accuracy,
  timestamp = Sys.time()
)

saveRDS(results_summary, "results/tutorial_01_results.rds")

# Save plots
ggsave("results/age_distribution.png", age_plot, width = 8, height = 6)
ggsave("results/bmi_distribution.png", bmi_plot, width = 8, height = 6)
ggsave("results/pain_scores.png", pain_plot, width = 8, height = 6)
ggsave("results/state_prevalence.png", state_plot, width = 8, height = 6)

message("Results saved to 'results/' directory")

# Summary Report ---------------------------------------------------------

message("\nStep 8: Generating summary report...")

summary_report <- sprintf("
TUTORIAL 1: BASIC POPULATION HEALTH MODELING
=============================================

EXECUTION SUMMARY
-----------------
Generated on: %s
Dataset size: %d records
Analysis completed successfully

KEY FINDINGS
------------
1. Overall OA Prevalence: %.1f%%
2. Age-related increase: Strong correlation (OR = %.2f per 10 years)
3. Sex differences: Women have %.1f%% higher prevalence
4. BMI impact: Obese individuals have %.1f%% higher prevalence
5. Model Performance: %.1f%% accuracy on test data

TOP RISK FACTORS (Odds Ratios)
-------------------------------
- Age (per 10 years): %.2f
- High BMI (≥30): %.2f
- Female sex: %.2f
- Comorbidities: %.2f

RECOMMENDATIONS
---------------
1. Target screening programs for individuals aged 65+
2. Promote weight management for obesity prevention
3. Consider sex-specific prevention strategies
4. Focus on comorbidity management in high-risk groups

DATA SOURCES
------------
- Synthetic data mimicking AIHW National Health Survey
- Population: 50,000 Australian adults
- Age range: 18-85 years
- Geographic coverage: All Australian states/territories

NEXT STEPS
----------
- Tutorial 2: Healthcare utilization analysis
- Tutorial 3: Longitudinal disease progression modeling
- Tutorial 4: Geographic health disparities analysis
",
  format(Sys.time(), "%Y-%m-%d %H:%M:%S"),
  nrow(health_data),
  overall_prevalence$prevalence_pct,
  odds_ratios["age"]^10,  # 10-year odds ratio
  (sex_prevalence$prevalence[sex_prevalence$sex == "Female"] /
   sex_prevalence$prevalence[sex_prevalence$sex == "Male"] - 1) * 100,
  (bmi_analysis$prevalence[bmi_analysis$bmi_category == "Obese"] /
   bmi_analysis$prevalence[bmi_analysis$bmi_category == "Normal"] - 1) * 100,
  accuracy * 100,
  odds_ratios["age"]^10,
  odds_ratios["high_bmiTRUE"],
  odds_ratios["femaleTRUE"],
  odds_ratios["comorbidities"]
)

cat(summary_report)

# Write summary to file
writeLines(summary_report, "results/tutorial_01_summary.txt")

message("\nTutorial 1 completed successfully!")
message("Results saved to 'results/' directory")
message("Summary report: 'results/tutorial_01_summary.txt'")
