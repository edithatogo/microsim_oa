# generate_geographic_data.R
# Script to generate synthetic geographic health data for Tutorial 4

generate_geographic_data <- function(n_patients = 50000) {
  library(tidyverse)

  # Set seed for reproducibility
  set.seed(12345)

  # Australian state and territory information
  states_info <- data.frame(
    state = c("NSW", "VIC", "QLD", "SA", "WA", "TAS", "NT", "ACT"),
    state_name = c("New South Wales", "Victoria", "Queensland", "South Australia",
                   "Western Australia", "Tasmania", "Northern Territory", "Australian Capital Territory"),
    population_weight = c(0.32, 0.26, 0.20, 0.07, 0.10, 0.02, 0.01, 0.02),
    # Approximate geographic centers (latitude, longitude)
    center_lat = c(-33.5, -37.5, -22.5, -30.0, -25.0, -43.0, -19.0, -35.3),
    center_lon = c(151.0, 145.0, 144.0, 136.5, 122.0, 147.0, 133.0, 149.1),
    # State-specific characteristics
    base_oa_prevalence = c(0.15, 0.14, 0.13, 0.16, 0.12, 0.17, 0.11, 0.13),
    income_multiplier = c(1.1, 1.2, 0.9, 0.95, 1.05, 0.85, 0.8, 1.3)
  )

  # Generate patient data by state
  geographic_data <- data.frame()

  for (i in 1:nrow(states_info)) {
    state_info <- states_info[i, ]

    # Number of patients for this state
    n_state <- round(n_patients * state_info$population_weight)

    # Generate geographic coordinates with some spread
    lat_spread <- rnorm(n_state, 0, 2)  # Spread around state center
    lon_spread <- rnorm(n_state, 0, 2)

    state_patients <- data.frame(
      patient_id = (nrow(geographic_data) + 1):(nrow(geographic_data) + n_state),
      state = state_info$state,
      latitude = state_info$center_lat + lat_spread,
      longitude = state_info$center_lon + lon_spread
    )

    # Demographic data
    state_patients$age <- sample(18:85, n_state, replace = TRUE)

    # Sex distribution (slightly more females for OA realism)
    state_patients$sex <- sample(c("Male", "Female"), n_state,
                               replace = TRUE, prob = c(0.48, 0.52))

    # Remoteness classification based on state and random variation
    remoteness_probs <- case_when(
      state_info$state %in% c("NSW", "VIC", "ACT") ~ c(0.6, 0.3, 0.1),  # More major cities
      state_info$state %in% c("QLD", "WA") ~ c(0.4, 0.4, 0.2),          # Mixed
      state_info$state %in% c("SA", "TAS") ~ c(0.3, 0.5, 0.2),          # More regional
      TRUE ~ c(0.2, 0.3, 0.5)                                            # NT more remote
    )

    state_patients$remoteness_area <- sample(
      c("Major Cities", "Regional", "Remote"),
      n_state, replace = TRUE, prob = remoteness_probs
    )

    # Urban/Rural classification
    urban_probs <- case_when(
      state_patients$remoteness_area == "Major Cities" ~ 0.9,
      state_patients$remoteness_area == "Regional" ~ 0.6,
      TRUE ~ 0.2
    )

    state_patients$urban_rural <- ifelse(
      runif(n_state) < urban_probs,
      "Urban", "Rural"
    )

    # Socioeconomic factors
    base_income <- 60000 * state_info$income_multiplier
    income_variation <- case_when(
      state_patients$remoteness_area == "Major Cities" ~ 1.2,
      state_patients$remoteness_area == "Regional" ~ 0.9,
      TRUE ~ 0.7
    )

    state_patients$household_income <- rnorm(n_state,
                                           mean = base_income * income_variation,
                                           sd = 25000)

    # Education level
    education_probs <- case_when(
      state_patients$remoteness_area == "Major Cities" ~ c(0.3, 0.4, 0.3),
      state_patients$remoteness_area == "Regional" ~ c(0.4, 0.4, 0.2),
      TRUE ~ c(0.5, 0.3, 0.2)
    )

    state_patients$education_level <- sample(
      c("High School", "TAFE", "University"),
      n_state, replace = TRUE, prob = education_probs
    )

    # Employment status
    employment_probs <- case_when(
      state_patients$age < 25 ~ c(0.1, 0.8, 0.1),
      state_patients$age > 65 ~ c(0.7, 0.1, 0.2),
      TRUE ~ c(0.05, 0.9, 0.05)
    )

    state_patients$employment_status <- sample(
      c("Employed", "Unemployed", "Retired"),
      n_state, replace = TRUE, prob = employment_probs
    )

    # SEIFA score (socioeconomic index)
    seifa_base <- case_when(
      state_patients$remoteness_area == "Major Cities" ~ 1050,
      state_patients$remoteness_area == "Regional" ~ 1000,
      TRUE ~ 950
    )

    state_patients$seifa_score <- rnorm(n_state, mean = seifa_base, sd = 50)

    # Health outcomes
    # OA prevalence with geographic variation
    oa_prob <- state_info$base_oa_prevalence +
               (state_patients$age - 50) * 0.005 +
               (state_patients$sex == "Female") * 0.05 +
               (state_patients$remoteness_area == "Remote") * 0.03

    state_patients$osteoarthritis <- rbinom(n_state, 1, pmin(oa_prob, 0.8))

    # OA severity for those with OA
    severity_probs <- case_when(
      state_patients$remoteness_area == "Major Cities" ~ c(0.4, 0.4, 0.2),
      state_patients$remoteness_area == "Regional" ~ c(0.3, 0.4, 0.3),
      TRUE ~ c(0.2, 0.3, 0.5)
    )

    state_patients$oa_severity <- ifelse(
      state_patients$osteoarthritis == 1,
      sample(c("Mild", "Moderate", "Severe"), n_state, replace = TRUE, prob = severity_probs),
      "None"
    )

    # Healthcare access - distance to services
    base_distance <- case_when(
      state_patients$remoteness_area == "Major Cities" ~ 5,
      state_patients$remoteness_area == "Regional" ~ 25,
      TRUE ~ 100
    )

    state_patients$distance_to_gp <- rgamma(n_state, shape = 2, scale = base_distance/2)
    state_patients$distance_to_specialist <- state_patients$distance_to_gp * rgamma(n_state, shape = 2, scale = 2)
    state_patients$distance_to_hospital <- state_patients$distance_to_gp * rgamma(n_state, shape = 1.5, scale = 3)

    # Healthcare utilization
    # GP visits
    gp_visit_base <- case_when(
      state_patients$osteoarthritis == 1 ~ 8,
      TRUE ~ 4
    )

    distance_effect <- 1 / (1 + state_patients$distance_to_gp / 50)
    state_patients$gp_visits_year <- rpois(n_state,
                                         lambda = gp_visit_base * distance_effect * (1 + runif(n_state, -0.2, 0.2)))

    # Specialist visits
    specialist_base <- ifelse(state_patients$osteoarthritis == 1, 2, 0.5)
    state_patients$specialist_visits_year <- rpois(n_state,
                                                 lambda = specialist_base * distance_effect)

    # Hospitalizations
    hosp_prob <- ifelse(state_patients$osteoarthritis == 1, 0.1, 0.02)
    state_patients$hospitalizations_year <- rpois(n_state, lambda = hosp_prob)

    # Healthcare costs
    base_cost <- 2000 + (state_patients$osteoarthritis == 1) * 3000
    distance_cost_multiplier <- 1 + (state_patients$distance_to_gp / 100)
    state_patients$total_healthcare_cost <- rgamma(n_state,
                                                 shape = 2,
                                                 scale = base_cost * distance_cost_multiplier / 2)

    # Combine with main dataset
    geographic_data <- bind_rows(geographic_data, state_patients)
  }

  # Add some missing data (realistic pattern)
  missing_prob <- 0.03
  geographic_data$household_income <- ifelse(runif(nrow(geographic_data)) < missing_prob,
                                           NA, geographic_data$household_income)
  geographic_data$education_level <- ifelse(runif(nrow(geographic_data)) < missing_prob,
                                          NA, geographic_data$education_level)
  geographic_data$distance_to_gp <- ifelse(runif(nrow(geographic_data)) < missing_prob,
                                         NA, geographic_data$distance_to_gp)

  # Ensure coordinates are within reasonable bounds
  geographic_data$latitude <- pmax(-45, pmin(-10, geographic_data$latitude))
  geographic_data$longitude <- pmax(110, pmin(155, geographic_data$longitude))

  return(geographic_data)
}

# Generate data if script is run directly
if (sys.nframe() == 0) {
  cat("Generating geographic health data...\n")
  data <- generate_geographic_data()
  saveRDS(data, "data/geographic_health_data.rds")
  cat("Data saved successfully!\n")
  cat("Generated", nrow(data), "observations across", length(unique(data$state)), "states\n")
}</content>
<parameter name="filePath">\\wsl.localhost\Ubuntu\home\doughnut\github\aus_oa_public\tutorials\tutorial_04_geographic_disparities\scripts\generate_geographic_data.R
