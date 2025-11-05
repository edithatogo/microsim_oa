# Tutorial 3 Solutions: Longitudinal Disease Progression Modeling
# ============================================================

This file contains complete solutions and working code for Tutorial 3 exercises.

## Setup and Data Loading

```r
# Load required packages
library(tidyverse)
library(survival)
library(lme4)
library(ggplot2)
library(scales)
library(survminer)
library(forecast)
library(aus_oa_public)

# Set seed for reproducibility
set.seed(12345)

# Load longitudinal health data
# Note: This uses synthetic data generated for the tutorial
longitudinal_data <- readRDS("data/longitudinal_health_data.rds")

# Alternative: Generate synthetic data if file doesn't exist
if (!file.exists("data/longitudinal_health_data.rds")) {
  source("scripts/generate_longitudinal_data.R")
  longitudinal_data <- generate_longitudinal_data(n_patients = 5000, n_visits = 10)
  saveRDS(longitudinal_data, "data/longitudinal_health_data.rds")
}

# Display data structure
cat("Dataset dimensions:", dim(longitudinal_data), "\n")
cat("Column names:", paste(names(longitudinal_data), collapse = ", "), "\n")
```

## Exercise 1: Loading and Exploring Longitudinal Data

### 1.1 Load Longitudinal Health Data

```r
# Load required packages
library(tidyverse)
library(survival)
library(lme4)
library(ggplot2)
library(scales)
library(aus_oa_public)
set.seed(12345)

# Load longitudinal health data
longitudinal_data <- readRDS("data/longitudinal_health_data.rds")

# Alternative: Load from CSV
# longitudinal_data <- read_csv("data/longitudinal_health_data.csv")
```

### 1.2 Examine Longitudinal Data Structure

```r
# View dataset dimensions and structure
dim(longitudinal_data)
str(longitudinal_data)
summary(longitudinal_data)

# Check number of observations per patient
patient_counts <- longitudinal_data %>%
  group_by(patient_id) %>%
  summarise(n_visits = n()) %>%
  count(n_visits)

print("Observations per patient:")
print(patient_counts)

# Check time span
time_span <- longitudinal_data %>%
  group_by(patient_id) %>%
  summarise(
    first_visit = min(visit_date),
    last_visit = max(visit_date),
    total_span = as.numeric(last_visit - first_visit) / 365.25
  )

cat("\nTime span summary (years):\n")
summary(time_span$total_span)
```

### 1.3 Data Quality Assessment

```r
# Check for missing values over time
missing_patterns <- longitudinal_data %>%
  group_by(visit_number) %>%
  summarise(
    total_obs = n(),
    missing_pain = sum(is.na(pain_score)),
    missing_function = sum(is.na(functional_score)),
    missing_qol = sum(is.na(qol_score))
  ) %>%
  mutate(
    pct_missing_pain = missing_pain / total_obs * 100,
    pct_missing_function = missing_function / total_obs * 100,
    pct_missing_qol = missing_qol / total_obs * 100
  )

print("Missing data patterns by visit:")
print(missing_patterns)

# Check for irregular visit intervals
visit_intervals <- longitudinal_data %>%
  arrange(patient_id, visit_date) %>%
  group_by(patient_id) %>%
  mutate(
    prev_visit = lag(visit_date),
    interval_days = as.numeric(visit_date - prev_visit)
  ) %>%
  filter(!is.na(interval_days))

cat("\nVisit interval summary (days):\n")
summary(visit_intervals$interval_days)
```

## Exercise 2: Basic Longitudinal Patterns

### 2.1 Disease Progression Trajectories

```r
# Overall disease progression trends
progression_trends <- longitudinal_data %>%
  group_by(visit_number) %>%
  summarise(
    mean_pain = mean(pain_score, na.rm = TRUE),
    mean_function = mean(functional_score, na.rm = TRUE),
    mean_qol = mean(qol_score, na.rm = TRUE),
    mean_disease_severity = mean(disease_severity, na.rm = TRUE),
    n = n()
  )

print("Disease progression trends by visit:")
print(progression_trends)

# Individual patient trajectories (sample)
sample_patients <- sample(unique(longitudinal_data$patient_id), 10)

sample_trajectories <- longitudinal_data %>%
  filter(patient_id %in% sample_patients) %>%
  select(patient_id, visit_number, pain_score, functional_score, qol_score)

print("Sample patient trajectories:")
head(sample_trajectories, 20)
```

### 2.2 Treatment Response Patterns

```r
# Treatment response analysis
treatment_response <- longitudinal_data %>%
  group_by(treatment_status, visit_number) %>%
  summarise(
    mean_pain = mean(pain_score, na.rm = TRUE),
    mean_function = mean(functional_score, na.rm = TRUE),
    mean_qol = mean(qol_score, na.rm = TRUE),
    n = n()
  )

print("Treatment response patterns:")
print(treatment_response)

# Treatment switching patterns
treatment_changes <- longitudinal_data %>%
  arrange(patient_id, visit_date) %>%
  group_by(patient_id) %>%
  mutate(
    prev_treatment = lag(treatment_status),
    treatment_change = treatment_status != prev_treatment & !is.na(prev_treatment)
  ) %>%
  summarise(
    total_changes = sum(treatment_change, na.rm = TRUE),
    first_treatment = first(treatment_status),
    final_treatment = last(treatment_status)
  )

cat("\nTreatment switching summary:\n")
summary(treatment_changes$total_changes)
```

### 2.3 Comorbidity Impact on Progression

```r
# Comorbidity impact analysis
comorbidity_impact <- longitudinal_data %>%
  group_by(comorbidity_count, visit_number) %>%
  summarise(
    mean_pain = mean(pain_score, na.rm = TRUE),
    mean_function = mean(functional_score, na.rm = TRUE),
    mean_qol = mean(qol_score, na.rm = TRUE),
    n = n()
  )

print("Comorbidity impact on progression:")
print(comorbidity_impact)

# Comorbidity progression correlation
comorbidity_correlations <- longitudinal_data %>%
  group_by(patient_id) %>%
  summarise(
    baseline_comorbidities = first(comorbidity_count),
    final_comorbidities = last(comorbidity_count),
    comorbidity_change = final_comorbidities - baseline_comorbidities,
    pain_change = last(pain_score) - first(pain_score),
    function_change = last(functional_score) - first(functional_score)
  )

print("Comorbidity correlations with disease progression:")
cor(comorbidity_correlations[, c("comorbidity_change", "pain_change", "function_change")],
    use = "complete.obs")
```

## Exercise 3: Survival Analysis

### 3.1 Time-to-Progression Analysis

```r
# Prepare survival data
survival_data <- longitudinal_data %>%
  group_by(patient_id) %>%
  summarise(
    progression_time = min(visit_number[disease_progression == 1], na.rm = TRUE),
    progressed = any(disease_progression == 1),
    baseline_age = first(age),
    baseline_severity = first(disease_severity),
    baseline_comorbidities = first(comorbidity_count),
    treatment_started = any(treatment_status == "Active")
  ) %>%
  mutate(
    progression_time = ifelse(is.infinite(progression_time), max(longitudinal_data$visit_number), progression_time)
  )

print("Survival data summary:")
summary(survival_data)

# Kaplan-Meier survival curve
km_fit <- survfit(Surv(progression_time, progressed) ~ 1, data = survival_data)
print("Kaplan-Meier estimate:")
print(km_fit)
```

### 3.2 Cox Proportional Hazards Model

```r
# Cox proportional hazards model
cox_model <- coxph(
  Surv(progression_time, progressed) ~
    baseline_age + baseline_severity + baseline_comorbidities + treatment_started,
  data = survival_data
)

print("Cox proportional hazards model:")
summary(cox_model)

# Calculate hazard ratios
hazard_ratios <- exp(coef(cox_model))
print("Hazard ratios:")
print(hazard_ratios)

# Model diagnostics
cox_zph <- cox.zph(cox_model)
print("Proportional hazards test:")
print(cox_zph)
```

### 3.3 Stratified Survival Analysis

```r
# Stratified analysis by age groups
survival_data <- survival_data %>%
  mutate(
    age_group = cut(baseline_age,
                   breaks = c(18, 50, 70, Inf),
                   labels = c("Young", "Middle", "Older"))
  )

# Kaplan-Meier by age group
km_by_age <- survfit(Surv(progression_time, progressed) ~ age_group, data = survival_data)
print("Survival by age group:")
print(km_by_age)

# Cox model with interactions
cox_interaction <- coxph(
  Surv(progression_time, progressed) ~
    baseline_age * treatment_started + baseline_severity + baseline_comorbidities,
  data = survival_data
)

print("Cox model with interaction:")
summary(cox_interaction)
```

## Exercise 4: Mixed Effects Models

### 4.1 Linear Mixed Effects for Pain Scores

```r
# Prepare data for mixed effects modeling
mixed_data <- longitudinal_data %>%
  select(patient_id, visit_number, pain_score, functional_score, qol_score,
         age, comorbidity_count, treatment_status) %>%
  na.omit()

# Linear mixed effects model for pain
pain_lme <- lmer(
  pain_score ~ visit_number + age + comorbidity_count + treatment_status +
               (1 + visit_number | patient_id),
  data = mixed_data
)

print("Linear mixed effects model for pain:")
summary(pain_lme)

# Random effects
print("Random effects:")
ranef(pain_lme)
```

### 4.2 Functional Status Mixed Model

```r
# Mixed effects model for functional status
function_lme <- lmer(
  functional_score ~ visit_number + age + comorbidity_count + treatment_status +
                    (1 + visit_number | patient_id),
  data = mixed_data
)

print("Mixed effects model for functional status:")
summary(function_lme)

# Compare fixed vs random effects
print("Fixed effects comparison:")
fixef(pain_lme)
fixef(function_lme)
```

### 4.3 Quality of Life Trajectory Modeling

```r
# Mixed effects model for quality of life
qol_lme <- lmer(
  qol_score ~ visit_number + age + comorbidity_count + treatment_status +
             (1 + visit_number | patient_id),
  data = mixed_data
)

print("Mixed effects model for quality of life:")
summary(qol_lme)

# Model comparison
cat("\nModel comparison (AIC):\n")
cat("Pain model AIC:", AIC(pain_lme), "\n")
cat("Function model AIC:", AIC(function_lme), "\n")
cat("QoL model AIC:", AIC(qol_lme), "\n")
```

## Exercise 5: Time-Series Analysis

### 5.1 Disease Severity Time Series

```r
# Aggregate disease severity by time
severity_ts <- longitudinal_data %>%
  group_by(visit_number) %>%
  summarise(
    mean_severity = mean(disease_severity, na.rm = TRUE),
    sd_severity = sd(disease_severity, na.rm = TRUE),
    n = n()
  )

print("Disease severity time series:")
print(severity_ts)

# Time series decomposition
severity_ts_data <- ts(severity_ts$mean_severity, frequency = 4)  # Quarterly data
severity_decomp <- decompose(severity_ts_data)

print("Time series decomposition:")
print(severity_decomp$trend)
```

### 5.2 Autoregressive Models

```r
# Simple ARIMA model for disease severity
library(forecast)

# Fit ARIMA model
severity_arima <- auto.arima(severity_ts$mean_severity)
print("ARIMA model for disease severity:")
summary(severity_arima)

# Forecast future values
severity_forecast <- forecast(severity_arima, h = 4)
print("Severity forecast:")
print(severity_forecast)

# Model diagnostics
checkresiduals(severity_arima)
```

### 5.3 Seasonal Patterns Analysis

```r
# Add seasonal component
longitudinal_data <- longitudinal_data %>%
  mutate(
    month = month(visit_date),
    season = case_when(
      month %in% c(12, 1, 2) ~ "Summer",
      month %in% c(3, 4, 5) ~ "Autumn",
      month %in% c(6, 7, 8) ~ "Winter",
      month %in% c(9, 10, 11) ~ "Spring"
    )
  )

# Seasonal analysis
seasonal_analysis <- longitudinal_data %>%
  group_by(season, visit_number) %>%
  summarise(
    mean_pain = mean(pain_score, na.rm = TRUE),
    mean_function = mean(functional_score, na.rm = TRUE),
    n = n()
  )

print("Seasonal patterns in health outcomes:")
print(seasonal_analysis)
```

## Exercise 6: Trajectory Analysis

### 6.1 Patient Trajectory Clustering

```r
# Prepare trajectory data
trajectory_data <- longitudinal_data %>%
  select(patient_id, visit_number, pain_score, functional_score, qol_score) %>%
  na.omit() %>%
  pivot_wider(
    names_from = visit_number,
    values_from = c(pain_score, functional_score, qol_score),
    names_prefix = "visit_"
  )

# K-means clustering on pain trajectories
pain_trajectory_cols <- grep("^pain_score_visit_", names(trajectory_data), value = TRUE)
pain_trajectories <- trajectory_data[, pain_trajectory_cols] %>%
  na.omit()

# Determine optimal number of clusters
wss <- sapply(1:6, function(k) {
  kmeans(pain_trajectories, centers = k, nstart = 10)$tot.withinss
})

# Perform clustering
set.seed(12345)
pain_clusters <- kmeans(pain_trajectories, centers = 3, nstart = 10)

trajectory_data$pain_trajectory_group <- pain_clusters$cluster

print("Trajectory cluster centers:")
print(pain_clusters$centers)
```

### 6.2 Trajectory Group Characteristics

```r
# Trajectory group analysis
trajectory_characteristics <- longitudinal_data %>%
  left_join(trajectory_data[, c("patient_id", "pain_trajectory_group")], by = "patient_id") %>%
  filter(!is.na(pain_trajectory_group)) %>%
  group_by(pain_trajectory_group) %>%
  summarise(
    n_patients = n_distinct(patient_id),
    mean_age = mean(age, na.rm = TRUE),
    pct_female = mean(sex == "Female", na.rm = TRUE) * 100,
    mean_comorbidities = mean(comorbidity_count, na.rm = TRUE),
    pct_treated = mean(treatment_status == "Active", na.rm = TRUE) * 100,
    mean_baseline_pain = mean(pain_score[visit_number == 1], na.rm = TRUE),
    mean_final_pain = mean(pain_score[visit_number == max(visit_number)], na.rm = TRUE)
  )

print("Trajectory group characteristics:")
print(trajectory_characteristics)
```

### 6.3 Trajectory Visualization

```r
# Trajectory visualization data
trajectory_viz <- longitudinal_data %>%
  left_join(trajectory_data[, c("patient_id", "pain_trajectory_group")], by = "patient_id") %>%
  filter(!is.na(pain_trajectory_group))

# Plot trajectories by group
trajectory_plot <- ggplot(trajectory_viz,
                         aes(x = visit_number, y = pain_score,
                             group = patient_id, color = factor(pain_trajectory_group))) +
  geom_line(alpha = 0.3) +
  stat_smooth(aes(group = pain_trajectory_group), method = "loess", size = 1.5) +
  labs(
    title = "Pain Score Trajectories by Group",
    x = "Visit Number",
    y = "Pain Score",
    color = "Trajectory Group"
  ) +
  theme_minimal()

print(trajectory_plot)
```

## Exercise 7: Predictive Modeling

### 7.1 Disease Progression Prediction

```r
# Prepare prediction data
prediction_data <- longitudinal_data %>%
  group_by(patient_id) %>%
  mutate(
    future_progression = lead(disease_progression, 2),  # Predict 2 visits ahead
    future_pain = lead(pain_score, 2),
    future_function = lead(functional_score, 2)
  ) %>%
  filter(!is.na(future_progression)) %>%
  select(patient_id, visit_number, pain_score, functional_score, qol_score,
         disease_severity, comorbidity_count, treatment_status,
         future_progression, future_pain, future_function)

# Logistic regression for progression prediction
progression_model <- glm(
  future_progression ~ pain_score + functional_score + qol_score +
                      disease_severity + comorbidity_count + treatment_status,
  data = prediction_data,
  family = binomial
)

print("Disease progression prediction model:")
summary(progression_model)

# Model evaluation
progression_pred <- predict(progression_model, type = "response")
progression_pred_class <- ifelse(progression_pred > 0.5, 1, 0)

progression_confusion <- table(
  Actual = prediction_data$future_progression,
  Predicted = progression_pred_class
)

print("Progression prediction confusion matrix:")
print(progression_confusion)
```

### 7.2 Pain Score Forecasting

```r
# Linear regression for pain prediction
pain_prediction_model <- lm(
  future_pain ~ pain_score + functional_score + qol_score +
               disease_severity + comorbidity_count + treatment_status,
  data = prediction_data
)

print("Pain score prediction model:")
summary(pain_prediction_model)

# Model performance
pain_pred <- predict(pain_prediction_model)
pain_rmse <- sqrt(mean((prediction_data$future_pain - pain_pred)^2, na.rm = TRUE))
pain_mae <- mean(abs(prediction_data$future_pain - pain_pred), na.rm = TRUE)

cat("\nPain prediction performance:\n")
cat("RMSE:", round(pain_rmse, 3), "\n")
cat("MAE:", round(pain_mae, 3), "\n")
```

### 7.3 Risk Stratification

```r
# Risk stratification using predicted probabilities
risk_data <- prediction_data %>%
  mutate(
    progression_risk = progression_pred,
    risk_category = case_when(
      progression_risk < 0.2 ~ "Low",
      progression_risk < 0.5 ~ "Medium",
      TRUE ~ "High"
    )
  )

# Risk category analysis
risk_analysis <- risk_data %>%
  group_by(risk_category) %>%
  summarise(
    n_patients = n_distinct(patient_id),
    mean_actual_progression = mean(future_progression),
    mean_predicted_risk = mean(progression_risk),
    mean_current_pain = mean(pain_score, na.rm = TRUE),
    pct_treated = mean(treatment_status == "Active") * 100
  )

print("Risk stratification analysis:")
print(risk_analysis)
```

## Exercise 8: Advanced Longitudinal Visualizations

### 8.1 Spaghetti Plots

```r
# Spaghetti plot for pain trajectories
spaghetti_plot <- ggplot(longitudinal_data %>% sample_n(100),
                        aes(x = visit_number, y = pain_score, group = patient_id)) +
  geom_line(alpha = 0.3, color = "steelblue") +
  stat_smooth(method = "loess", color = "red", size = 1.5, se = FALSE) +
  labs(
    title = "Individual Pain Trajectories (Sample)",
    x = "Visit Number",
    y = "Pain Score"
  ) +
  theme_minimal()

print(spaghetti_plot)
```

### 8.2 Longitudinal Profile Plots

```r
# Longitudinal profile plot
profile_data <- longitudinal_data %>%
  group_by(visit_number) %>%
  summarise(
    mean_pain = mean(pain_score, na.rm = TRUE),
    mean_function = mean(functional_score, na.rm = TRUE),
    mean_qol = mean(qol_score, na.rm = TRUE),
    se_pain = sd(pain_score, na.rm = TRUE) / sqrt(n()),
    se_function = sd(functional_score, na.rm = TRUE) / sqrt(n()),
    se_qol = sd(qol_score, na.rm = TRUE) / sqrt(n())
  )

profile_plot <- ggplot(profile_data, aes(x = visit_number)) +
  geom_line(aes(y = mean_pain, color = "Pain"), size = 1) +
  geom_line(aes(y = mean_function, color = "Function"), size = 1) +
  geom_line(aes(y = mean_qol, color = "QoL"), size = 1) +
  geom_ribbon(aes(ymin = mean_pain - se_pain, ymax = mean_pain + se_pain),
              alpha = 0.2, fill = "red") +
  geom_ribbon(aes(ymin = mean_function - se_function, ymax = mean_function + se_function),
              alpha = 0.2, fill = "blue") +
  geom_ribbon(aes(ymin = mean_qol - se_qol, ymax = mean_qol + se_qol),
              alpha = 0.2, fill = "green") +
  labs(
    title = "Longitudinal Health Outcomes Profile",
    x = "Visit Number",
    y = "Score",
    color = "Outcome"
  ) +
  theme_minimal()

print(profile_plot)
```

### 8.3 Survival Curves Visualization

```r
# Survival curves plot
library(survminer)

survival_plot <- ggsurvplot(
  km_by_age,
  data = survival_data,
  risk.table = TRUE,
  conf.int = TRUE,
  palette = "jco",
  title = "Disease Progression Survival by Age Group",
  xlab = "Time (visits)",
  ylab = "Survival Probability"
)

print(survival_plot)
```

## Data Generation Script

```r
# generate_longitudinal_data.R
# Script to generate synthetic longitudinal health data for Tutorial 3

generate_longitudinal_data <- function(n_patients = 5000, n_visits = 10) {
  library(tidyverse)

  # Set seed for reproducibility
  set.seed(12345)

  # Generate patient IDs
  patients <- 1:n_patients

  # Generate baseline characteristics
  baseline_data <- data.frame(
    patient_id = patients,
    age = rnorm(n_patients, mean = 55, sd = 15),
    sex = sample(c("Male", "Female"), n_patients, replace = TRUE, prob = c(0.4, 0.6)),
    comorbidity_count = rpois(n_patients, lambda = 2),
    baseline_severity = rbeta(n_patients, shape1 = 2, shape2 = 5) * 10
  )

  # Generate longitudinal data
  longitudinal_data <- data.frame()

  for (patient in patients) {
    patient_baseline <- baseline_data[baseline_data$patient_id == patient, ]

    for (visit in 1:n_visits) {
      # Time-varying effects
      time_effect <- visit * 0.1
      age_effect <- patient_baseline$age * 0.01
      comorbidity_effect <- patient_baseline$comorbidity_count * 0.2

      # Treatment status (changes over time)
      treatment_prob <- min(0.3 + visit * 0.05, 0.8)
      treatment_status <- sample(c("None", "Active"), 1,
                               prob = c(1 - treatment_prob, treatment_prob))

      # Generate health outcomes with correlation and progression
      base_pain <- patient_baseline$baseline_severity + time_effect + age_effect + comorbidity_effect
      pain_score <- rnorm(1, mean = base_pain, sd = 1.5)
      pain_score <- max(0, min(10, pain_score))

      functional_score <- 10 - pain_score * 0.7 + rnorm(1, 0, 1)
      functional_score <- max(0, min(10, functional_score))

      qol_score <- functional_score * 0.8 + rnorm(1, 0, 1.2)
      qol_score <- max(0, min(10, qol_score))

      disease_severity <- patient_baseline$baseline_severity + time_effect * 2 + rnorm(1, 0, 0.5)
      disease_severity <- max(0, min(10, disease_severity))

      # Disease progression event (cumulative probability)
      progression_prob <- 0.05 + visit * 0.02 + disease_severity * 0.03
      disease_progression <- rbinom(1, 1, min(progression_prob, 0.9))

      # Visit date (approximately every 3 months)
      visit_date <- as.Date("2020-01-01") + months((visit - 1) * 3) + rnorm(1, 0, 14)

      # Combine patient data
      visit_data <- data.frame(
        patient_id = patient,
        visit_number = visit,
        visit_date = visit_date,
        age = patient_baseline$age,
        sex = patient_baseline$sex,
        comorbidity_count = patient_baseline$comorbidity_count,
        treatment_status = treatment_status,
        pain_score = round(pain_score, 1),
        functional_score = round(functional_score, 1),
        qol_score = round(qol_score, 1),
        disease_severity = round(disease_severity, 1),
        disease_progression = disease_progression
      )

      longitudinal_data <- bind_rows(longitudinal_data, visit_data)
    }
  }

  # Add some missing data (realistic pattern)
  missing_prob <- 0.05
  longitudinal_data$pain_score <- ifelse(runif(nrow(longitudinal_data)) < missing_prob,
                                       NA, longitudinal_data$pain_score)
  longitudinal_data$functional_score <- ifelse(runif(nrow(longitudinal_data)) < missing_prob,
                                             NA, longitudinal_data$functional_score)
  longitudinal_data$qol_score <- ifelse(runif(nrow(longitudinal_data)) < missing_prob,
                                      NA, longitudinal_data$qol_score)

  return(longitudinal_data)
}

# Generate data if script is run directly
if (sys.nframe() == 0) {
  cat("Generating longitudinal health data...\n")
  data <- generate_longitudinal_data()
  saveRDS(data, "data/longitudinal_health_data.rds")
  cat("Data saved to data/longitudinal_health_data.rds\n")
}
```

## Summary Statistics and Validation

```r
# Summary statistics for the generated data
cat("=== Longitudinal Health Data Summary ===\n")
cat("Total observations:", nrow(longitudinal_data), "\n")
cat("Total patients:", n_distinct(longitudinal_data$patient_id), "\n")
cat("Average visits per patient:", mean(table(longitudinal_data$patient_id)), "\n")

# Variable summaries
cat("\n=== Variable Summaries ===\n")
summary(longitudinal_data[, c("pain_score", "functional_score", "qol_score", "disease_severity")])

# Missing data summary
cat("\n=== Missing Data Summary ===\n")
colSums(is.na(longitudinal_data))

# Progression events
cat("\n=== Disease Progression ===\n")
table(longitudinal_data$disease_progression)

# Treatment distribution
cat("\n=== Treatment Distribution ===\n")
table(longitudinal_data$treatment_status)

# Age distribution
cat("\n=== Age Distribution ===\n")
summary(longitudinal_data$age)

# Comorbidity distribution
cat("\n=== Comorbidity Distribution ===\n")
table(longitudinal_data$comorbidity_count)
```

---

*This solutions file provides complete working code for all Tutorial 3 exercises on longitudinal disease progression modeling.*</content>
<parameter name="filePath">\\wsl.localhost\Ubuntu\home\doughnut\github\aus_oa_public\tutorials\tutorial_03_longitudinal_modeling\solutions\tutorial_03_solutions.R
