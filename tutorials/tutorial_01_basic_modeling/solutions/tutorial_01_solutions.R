#' Tutorial 1 Solutions
#'
#' This script contains complete solutions for Tutorial 1 exercises.
#' Use this as a reference after attempting the exercises yourself.
#'
#' @author AUS-OA Development Team

# Setup -------------------------------------------------------------------

library(tidyverse)
library(aus_oa_public)
library(scales)
library(ggthemes)
set.seed(12345)

# Exercise 1: Data Loading and Basic Exploration --------------------------

# Solution 1.1: Load the health survey data
health_data <- readRDS("data/health_survey_data.rds")

# Solution 1.2: Examine the dataset structure
str(health_data)
summary(health_data)

# Solution 1.3: Check for missing values
colSums(is.na(health_data))

# Solution 1.4: View first few rows
head(health_data, 10)

# Exercise 2: Osteoarthritis Prevalence Analysis --------------------------

# Solution 2.1: Calculate overall OA prevalence
overall_prevalence <- health_data %>%
  summarise(
    total_patients = n(),
    oa_cases = sum(osteoarthritis),
    prevalence_pct = (oa_cases / total_patients) * 100
  )

print(overall_prevalence)

# Solution 2.2: Prevalence by age groups
age_prevalence <- health_data %>%
  mutate(
    age_group = cut(age,
                   breaks = c(18, 35, 50, 65, 80, Inf),
                   labels = c("18-34", "35-49", "50-64", "65-79", "80+"))
  ) %>%
  group_by(age_group) %>%
  summarise(
    total = n(),
    oa_cases = sum(osteoarthritis),
    prevalence = (oa_cases / total) * 100
  ) %>%
  arrange(age_group)

print(age_prevalence)

# Solution 2.3: Prevalence by sex and state
sex_state_prevalence <- health_data %>%
  group_by(sex, state) %>%
  summarise(
    total = n(),
    oa_cases = sum(osteoarthritis),
    prevalence = (oa_cases / total) * 100,
    .groups = "drop"
  ) %>%
  arrange(state, sex)

print(sex_state_prevalence)

# Exercise 3: Risk Factor Analysis ----------------------------------------

# Solution 3.1: BMI categories and OA prevalence
bmi_analysis <- health_data %>%
  mutate(
    bmi_category = cut(bmi,
                      breaks = c(-Inf, 18.5, 25, 30, Inf),
                      labels = c("Underweight", "Normal", "Overweight", "Obese"))
  ) %>%
  group_by(bmi_category) %>%
  summarise(
    total = n(),
    oa_cases = sum(osteoarthritis),
    prevalence = (oa_cases / total) * 100
  )

print(bmi_analysis)

# Solution 3.2: Comorbidities analysis
comorbidities_analysis <- health_data %>%
  mutate(
    comorbidity_group = cut(comorbidities,
                           breaks = c(-Inf, 0, 2, 5, Inf),
                           labels = c("None", "1-2", "3-5", "6+"))
  ) %>%
  group_by(comorbidity_group) %>%
  summarise(
    total = n(),
    oa_cases = sum(osteoarthritis),
    prevalence = (oa_cases / total) * 100
  )

print(comorbidities_analysis)

# Solution 3.3: Physical activity and OA
activity_analysis <- health_data %>%
  group_by(physical_activity) %>%
  summarise(
    total = n(),
    oa_cases = sum(osteoarthritis),
    prevalence = (oa_cases / total) * 100
  )

print(activity_analysis)

# Exercise 4: Statistical Modeling ----------------------------------------

# Solution 4.1: Prepare data for modeling
model_data <- health_data %>%
  mutate(
    high_bmi = bmi >= 30,
    older_age = age >= 65,
    female = sex == "Female"
  ) %>%
  select(osteoarthritis, age, high_bmi, female, comorbidities) %>%
  na.omit()

# Solution 4.2: Simple logistic regression
oa_model <- glm(osteoarthritis ~ age + high_bmi + female + comorbidities,
                data = model_data,
                family = binomial)

summary(oa_model)

# Solution 4.3: Calculate odds ratios
odds_ratios <- exp(coef(oa_model))
print(odds_ratios)

# Solution 4.4: Model predictions and evaluation
model_predictions <- predict(oa_model, type = "response")
predicted_classes <- ifelse(model_predictions > 0.5, 1, 0)

# Confusion matrix
confusion_matrix <- table(Actual = model_data$osteoarthritis,
                         Predicted = predicted_classes)
print(confusion_matrix)

# Model accuracy
accuracy <- sum(diag(confusion_matrix)) / sum(confusion_matrix)
cat("Model Accuracy:", round(accuracy * 100, 2), "%\n")

# Solution 4.5: ROC curve analysis
library(pROC)
roc_curve <- roc(model_data$osteoarthritis, model_predictions)
auc_value <- auc(roc_curve)

cat("AUC:", round(auc_value, 3), "\n")

# Exercise 5: Data Visualization ------------------------------------------

# Solution 5.1: Age distribution by OA status
age_plot <- ggplot(health_data, aes(x = age, fill = factor(osteoarthritis))) +
  geom_histogram(alpha = 0.7, bins = 30, position = "identity") +
  labs(
    title = "Age Distribution by Osteoarthritis Status",
    x = "Age",
    y = "Count",
    fill = "OA Status"
  ) +
  scale_fill_brewer(palette = "Set2", labels = c("No OA", "Has OA")) +
  theme_minimal()

print(age_plot)

# Solution 5.2: BMI distribution with categories
bmi_plot <- ggplot(health_data, aes(x = bmi)) +
  geom_histogram(bins = 30, fill = "steelblue", alpha = 0.7) +
  geom_vline(xintercept = 25, linetype = "dashed", color = "orange") +
  geom_vline(xintercept = 30, linetype = "dashed", color = "red") +
  labs(
    title = "BMI Distribution",
    x = "BMI",
    y = "Count"
  ) +
  annotate("text", x = 22, y = max(ggplot_build(bmi_plot)$data[[1]]$count) * 0.8,
           label = "Normal", color = "orange") +
  annotate("text", x = 27.5, y = max(ggplot_build(bmi_plot)$data[[1]]$count) * 0.8,
           label = "Overweight", color = "orange") +
  annotate("text", x = 32, y = max(ggplot_build(bmi_plot)$data[[1]]$count) * 0.8,
           label = "Obese", color = "red") +
  theme_minimal()

print(bmi_plot)

# Solution 5.3: Pain scores by OA status
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
  scale_fill_brewer(palette = "Set2") +
  theme_minimal()

print(pain_plot)

# Solution 5.4: Prevalence by state
state_plot <- health_data %>%
  group_by(state) %>%
  summarise(
    prevalence = mean(osteoarthritis) * 100,
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
  scale_y_continuous(limits = c(0, max(prevalence) * 1.2)) +
  theme_minimal()

print(state_plot)

# Solution 5.5: Correlation heatmap
correlation_data <- health_data %>%
  select(age, bmi, pain_score, comorbidities, osteoarthritis) %>%
  mutate(osteoarthritis = as.numeric(osteoarthritis))

correlation_matrix <- cor(correlation_data, use = "complete.obs")

# Simple correlation plot
corrplot::corrplot(correlation_matrix,
                   method = "color",
                   type = "upper",
                   addCoef.col = "black",
                   tl.col = "black",
                   tl.srt = 45)

# Exercise 6: Advanced Analysis -------------------------------------------

# Solution 6.1: Multiple regression with interactions
advanced_model <- glm(osteoarthritis ~ age * female + bmi + comorbidities +
                                     physical_activity + smoking_status,
                      data = health_data,
                      family = binomial)

summary(advanced_model)

# Solution 6.2: Predicted probabilities by age and sex
prediction_data <- expand.grid(
  age = seq(18, 85, by = 5),
  female = c(TRUE, FALSE),
  bmi = mean(health_data$bmi, na.rm = TRUE),
  comorbidities = mean(health_data$comorbidities, na.rm = TRUE),
  physical_activity = "Moderate",
  smoking_status = "Never"
)

prediction_data$predicted_prob <- predict(advanced_model,
                                        newdata = prediction_data,
                                        type = "response")

# Plot predictions
prediction_plot <- ggplot(prediction_data,
                         aes(x = age, y = predicted_prob * 100,
                             color = factor(female, labels = c("Male", "Female")))) +
  geom_line(size = 1) +
  labs(
    title = "Predicted OA Probability by Age and Sex",
    x = "Age",
    y = "Predicted Probability (%)",
    color = "Sex"
  ) +
  theme_minimal()

print(prediction_plot)

# Solution 6.3: Healthcare cost analysis
cost_analysis <- health_data %>%
  group_by(osteoarthritis) %>%
  summarise(
    mean_cost = mean(healthcare_cost),
    median_cost = median(healthcare_cost),
    sd_cost = sd(healthcare_cost),
    n = n()
  )

print(cost_analysis)

# Solution 6.4: Quality of life analysis
qol_analysis <- health_data %>%
  group_by(osteoarthritis) %>%
  summarise(
    mean_eq5d = mean(eq5d_score),
    mean_physical = mean(physical_functioning),
    n = n()
  )

print(qol_analysis)

# Exercise 7: Export Results ----------------------------------------------

# Solution 7.1: Create results directory
if (!dir.exists("results")) {
  dir.create("results")
}

# Solution 7.2: Save key results
results_summary <- list(
  overall_prevalence = overall_prevalence,
  age_prevalence = age_prevalence,
  sex_state_prevalence = sex_state_prevalence,
  bmi_analysis = bmi_analysis,
  comorbidities_analysis = comorbidities_analysis,
  activity_analysis = activity_analysis,
  model_summary = summary(oa_model),
  odds_ratios = odds_ratios,
  confusion_matrix = confusion_matrix,
  model_accuracy = accuracy,
  auc_value = auc_value,
  advanced_model_summary = summary(advanced_model),
  cost_analysis = cost_analysis,
  qol_analysis = qol_analysis,
  timestamp = Sys.time()
)

saveRDS(results_summary, "results/tutorial_01_complete_results.rds")

# Solution 7.3: Save plots
ggsave("results/age_distribution.png", age_plot, width = 8, height = 6)
ggsave("results/bmi_distribution.png", bmi_plot, width = 8, height = 6)
ggsave("results/pain_scores.png", pain_plot, width = 8, height = 6)
ggsave("results/state_prevalence.png", state_plot, width = 8, height = 6)
ggsave("results/prediction_plot.png", prediction_plot, width = 8, height = 6)

# Solution 7.4: Generate summary report
summary_report <- sprintf("
TUTORIAL 1: BASIC POPULATION HEALTH MODELING - COMPLETE SOLUTIONS
=================================================================

EXECUTION SUMMARY
-----------------
Completed on: %s
Dataset: %d records analyzed

KEY FINDINGS
------------
1. Overall OA Prevalence: %.1f%%
2. Age-related increase: Strong correlation observed
3. Sex differences: Women have higher prevalence
4. BMI impact: Higher BMI associated with increased risk
5. Model Performance: %.1f%% accuracy (AUC: %.3f)

TOP RISK FACTORS (Odds Ratios)
-------------------------------
- Age (per 10 years): %.2f
- High BMI (≥30): %.2f
- Female sex: %.2f
- Comorbidities: %.2f

HEALTHCARE IMPACT
-----------------
- OA patients have %.0f%% higher healthcare costs
- OA patients have %.2f lower EQ-5D scores
- OA patients have %.0f lower physical functioning scores

RECOMMENDATIONS
---------------
1. Target screening programs for high-risk groups
2. Promote preventive measures (weight management, exercise)
3. Focus on early intervention and management
4. Consider sex-specific approaches to prevention

DATA SOURCES
------------
- Synthetic Australian health survey data
- Population: %d Australian adults
- Age range: 18-85 years
- Geographic coverage: All Australian states/territories

ANALYSIS METHODS
----------------
- Descriptive statistics and prevalence analysis
- Logistic regression modeling
- Data visualization with ggplot2
- ROC curve analysis for model evaluation
- Healthcare cost and quality of life impact assessment
",
  format(Sys.time(), "%Y-%m-%d %H:%M:%S"),
  nrow(health_data),
  overall_prevalence$prevalence_pct,
  accuracy * 100,
  auc_value,
  odds_ratios["age"]^10,
  odds_ratios["high_bmiTRUE"],
  odds_ratios["femaleTRUE"],
  odds_ratios["comorbidities"],
  (cost_analysis$mean_cost[cost_analysis$osteoarthritis == 1] /
   cost_analysis$mean_cost[cost_analysis$osteoarthritis == 0] - 1) * 100,
  cost_analysis$mean_eq5d[cost_analysis$osteoarthritis == 0] -
  cost_analysis$mean_eq5d[cost_analysis$osteoarthritis == 1],
  cost_analysis$mean_physical[cost_analysis$osteoarthritis == 0] -
  cost_analysis$mean_physical[cost_analysis$osteoarthritis == 1],
  nrow(health_data)
)

# Solution 7.5: Write summary to file
writeLines(summary_report, "results/tutorial_01_complete_summary.txt")

message("All exercises completed successfully!")
message("Results saved to 'results/' directory")
message("Summary report: 'results/tutorial_01_complete_summary.txt'")
