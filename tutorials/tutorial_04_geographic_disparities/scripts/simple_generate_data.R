# Simple geographic data generation
set.seed(12345)

generate_geographic_data <- function(n_patients = 50000) {
  # Australian state information
  states_info <- data.frame(
    state = c("NSW", "VIC", "QLD", "SA", "WA", "TAS", "NT", "ACT"),
    population_weight = c(0.32, 0.26, 0.20, 0.07, 0.10, 0.02, 0.01, 0.02),
    center_lat = c(-33.5, -37.5, -22.5, -30.0, -25.0, -43.0, -19.0, -35.3),
    center_lon = c(151.0, 145.0, 144.0, 136.5, 122.0, 147.0, 133.0, 149.1),
    base_oa_prevalence = c(0.15, 0.14, 0.13, 0.16, 0.12, 0.17, 0.11, 0.13)
  )

  geographic_data <- data.frame()

  for (i in 1:nrow(states_info)) {
    state_info <- states_info[i, ]
    n_state <- round(n_patients * state_info$population_weight)

    # Generate basic data
    state_patients <- data.frame(
      patient_id = (nrow(geographic_data) + 1):(nrow(geographic_data) + n_state),
      state = state_info$state,
      latitude = state_info$center_lat + rnorm(n_state, 0, 2),
      longitude = state_info$center_lon + rnorm(n_state, 0, 2),
      age = sample(18:85, n_state, replace = TRUE),
      sex = sample(c("Male", "Female"), n_state, replace = TRUE, prob = c(0.48, 0.52))
    )

    # Remoteness
    remoteness_probs <- if (state_info$state %in% c("NSW", "VIC", "ACT")) {
      c(0.6, 0.3, 0.1)
    } else if (state_info$state %in% c("NT")) {
      c(0.2, 0.3, 0.5)
    } else {
      c(0.4, 0.4, 0.2)
    }

    state_patients$remoteness_area <- sample(
      c("Major Cities", "Regional", "Remote"),
      n_state, replace = TRUE, prob = remoteness_probs
    )

    # Urban/Rural
    state_patients$urban_rural <- ifelse(
      state_patients$remoteness_area == "Major Cities" & runif(n_state) < 0.9,
      "Urban", "Rural"
    )

    # Socioeconomic
    base_income <- 60000
    state_patients$household_income <- rnorm(n_state, mean = base_income, sd = 25000)

    state_patients$education_level <- sample(
      c("High School", "TAFE", "University"),
      n_state, replace = TRUE
    )

    state_patients$employment_status <- sample(
      c("Employed", "Unemployed", "Retired"),
      n_state, replace = TRUE
    )

    state_patients$seifa_score <- rnorm(n_state, mean = 1000, sd = 50)

    # Health outcomes
    oa_prob <- state_info$base_oa_prevalence +
               (state_patients$age - 50) * 0.005 +
               (state_patients$sex == "Female") * 0.05

    state_patients$osteoarthritis <- rbinom(n_state, 1, pmin(oa_prob, 0.8))

    state_patients$oa_severity <- ifelse(
      state_patients$osteoarthritis == 1,
      sample(c("Mild", "Moderate", "Severe"), n_state, replace = TRUE),
      "None"
    )

    # Healthcare access
    base_distance <- ifelse(state_patients$remoteness_area == "Major Cities", 5,
                           ifelse(state_patients$remoteness_area == "Regional", 25, 100))

    state_patients$distance_to_gp <- rgamma(n_state, shape = 2, scale = base_distance/2)
    state_patients$distance_to_specialist <- state_patients$distance_to_gp * rgamma(n_state, shape = 2, scale = 2)
    state_patients$distance_to_hospital <- state_patients$distance_to_gp * rgamma(n_state, shape = 1.5, scale = 3)

    # Healthcare utilization
    gp_base <- ifelse(state_patients$osteoarthritis == 1, 8, 4)
    distance_effect <- 1 / (1 + state_patients$distance_to_gp / 50)
    state_patients$gp_visits_year <- rpois(n_state, lambda = gp_base * distance_effect)

    specialist_base <- ifelse(state_patients$osteoarthritis == 1, 2, 0.5)
    state_patients$specialist_visits_year <- rpois(n_state, lambda = specialist_base * distance_effect)

    state_patients$hospitalizations_year <- rpois(n_state,
                                                lambda = ifelse(state_patients$osteoarthritis == 1, 0.1, 0.02))

    # Healthcare costs
    base_cost <- 2000 + (state_patients$osteoarthritis == 1) * 3000
    distance_cost_multiplier <- 1 + (state_patients$distance_to_gp / 100)
    state_patients$total_healthcare_cost <- rgamma(n_state, shape = 2,
                                                 scale = base_cost * distance_cost_multiplier / 2)

    geographic_data <- rbind(geographic_data, state_patients)
  }

  # Add missing data
  missing_prob <- 0.03
  n_rows <- nrow(geographic_data)
  geographic_data$household_income <- ifelse(runif(n_rows) < missing_prob,
                                           NA, geographic_data$household_income)
  geographic_data$distance_to_gp <- ifelse(runif(n_rows) < missing_prob,
                                         NA, geographic_data$distance_to_gp)

  return(geographic_data)
}

# Generate and save data
cat("Generating geographic health data...\n")
data <- generate_geographic_data()
saveRDS(data, "../data/geographic_health_data.rds")
cat("Data saved successfully!\n")
cat("Generated", nrow(data), "observations across", length(unique(data$state)), "states\n")
