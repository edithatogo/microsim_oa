# Simple data generation script
library(tidyverse)

generate_longitudinal_data <- function(n_patients = 5000, n_visits = 10) {
  set.seed(12345)

  patients <- 1:n_patients
  baseline_data <- data.frame(
    patient_id = patients,
    age = rnorm(n_patients, mean = 55, sd = 15),
    sex = sample(c("Male", "Female"), n_patients, replace = TRUE, prob = c(0.4, 0.6)),
    comorbidity_count = rpois(n_patients, lambda = 2),
    baseline_severity = rbeta(n_patients, shape1 = 2, shape2 = 5) * 10
  )

  longitudinal_data <- data.frame()

  for (patient in patients) {
    patient_baseline <- baseline_data[baseline_data$patient_id == patient, ]

    for (visit in 1:n_visits) {
      time_effect <- visit * 0.1
      age_effect <- patient_baseline$age * 0.01
      comorbidity_effect <- patient_baseline$comorbidity_count * 0.2

      treatment_prob <- min(0.3 + visit * 0.05, 0.8)
      treatment_status <- sample(c("None", "Active"), 1,
                               prob = c(1 - treatment_prob, treatment_prob))

      base_pain <- patient_baseline$baseline_severity + time_effect + age_effect + comorbidity_effect
      pain_score <- rnorm(1, mean = base_pain, sd = 1.5)
      pain_score <- max(0, min(10, pain_score))

      functional_score <- 10 - pain_score * 0.7 + rnorm(1, 0, 1)
      functional_score <- max(0, min(10, functional_score))

      qol_score <- functional_score * 0.8 + rnorm(1, 0, 1.2)
      qol_score <- max(0, min(10, qol_score))

      disease_severity <- patient_baseline$baseline_severity + time_effect * 2 + rnorm(1, 0, 0.5)
      disease_severity <- max(0, min(10, disease_severity))

      progression_prob <- 0.05 + visit * 0.02 + disease_severity * 0.03
      disease_progression <- rbinom(1, 1, min(progression_prob, 0.9))

      visit_date <- as.Date("2020-01-01") + months((visit - 1) * 3) + rnorm(1, 0, 14)

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

  missing_prob <- 0.05
  longitudinal_data$pain_score <- ifelse(runif(nrow(longitudinal_data)) < missing_prob,
                                       NA, longitudinal_data$pain_score)
  longitudinal_data$functional_score <- ifelse(runif(nrow(longitudinal_data)) < missing_prob,
                                             NA, longitudinal_data$functional_score)
  longitudinal_data$qol_score <- ifelse(runif(nrow(longitudinal_data)) < missing_prob,
                                      NA, longitudinal_data$qol_score)

  return(longitudinal_data)
}

# Generate and save data
cat("Generating longitudinal health data...\n")
data <- generate_longitudinal_data()
saveRDS(data, "data/longitudinal_health_data.rds")
cat("Data saved successfully!\n")
