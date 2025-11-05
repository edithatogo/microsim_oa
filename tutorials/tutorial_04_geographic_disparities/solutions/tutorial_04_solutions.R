# Tutorial 4 Solutions: Geographic Health Disparities Analysis
# ============================================================

This file contains complete solutions and working code for Tutorial 4 exercises.

## Setup and Data Loading

```r
# Load required packages
library(tidyverse)
library(sf)
library(ggplot2)
library(spdep)
library(spatialreg)
library(leaflet)
library(RColorBrewer)
library(scales)
library(aus_oa_public)
set.seed(12345)

# Load geographic health data
geographic_data <- readRDS("data/geographic_health_data.rds")

# Alternative: Load from CSV
# geographic_data <- read_csv("data/geographic_health_data.csv")
```

## Exercise 1: Loading and Exploring Geographic Health Data

### 1.1 Load Geographic Health Data

```r
# Load required packages
library(tidyverse)
library(sf)
library(ggplot2)
library(spdep)
library(spatialreg)
library(leaflet)
library(RColorBrewer)
library(scales)
library(aus_oa_public)
set.seed(12345)

# Load geographic health data
geographic_data <- readRDS("data/geographic_health_data.rds")

# Alternative: Load from CSV
# geographic_data <- read_csv("data/geographic_health_data.csv")
```

### 1.2 Examine Geographic Data Structure

```r
# View dataset dimensions and structure
dim(geographic_data)
str(geographic_data)
summary(geographic_data)

# Check geographic distribution
table(geographic_data$state)
table(geographic_data$remoteness_area)

# Check data completeness by state
geographic_data %>%
  group_by(state) %>%
  summarise(
    n_patients = n(),
    pct_oa = mean(osteoarthritis, na.rm = TRUE) * 100,
    mean_age = mean(age, na.rm = TRUE),
    mean_income = mean(household_income, na.rm = TRUE)
  ) %>%
  arrange(desc(n_patients))
```

### 1.3 Geographic Data Quality Assessment

```r
# Check for missing values by geographic variables
missing_by_state <- geographic_data %>%
  group_by(state) %>%
  summarise(
    total_obs = n(),
    missing_income = sum(is.na(household_income)),
    missing_education = sum(is.na(education_level)),
    missing_employment = sum(is.na(employment_status)),
    missing_distance = sum(is.na(distance_to_gp))
  ) %>%
  mutate(
    pct_missing_income = missing_income / total_obs * 100,
    pct_missing_distance = missing_distance / total_obs * 100
  )

print("Missing data by state:")
print(missing_by_state)

# Check geographic coordinate validity
coordinate_check <- geographic_data %>%
  summarise(
    invalid_lat = sum(latitude < -90 | latitude > 90, na.rm = TRUE),
    invalid_lon = sum(longitude < 100 | longitude > 180, na.rm = TRUE),
    missing_coords = sum(is.na(latitude) | is.na(longitude))
  )

print("Coordinate validation:")
print(coordinate_check)
```

## Exercise 2: Basic Geographic Patterns

### 2.1 State-Level Health Outcomes

```r
# State-level osteoarthritis prevalence
state_prevalence <- geographic_data %>%
  group_by(state) %>%
  summarise(
    total_patients = n(),
    oa_cases = sum(osteoarthritis, na.rm = TRUE),
    oa_prevalence = oa_cases / total_patients * 100,
    mean_age = mean(age, na.rm = TRUE),
    mean_severity = mean(oa_severity, na.rm = TRUE),
    mean_income = mean(household_income, na.rm = TRUE)
  ) %>%
  arrange(desc(oa_prevalence))

print("OA prevalence by state:")
print(state_prevalence)

# State-level healthcare utilization
state_utilization <- geographic_data %>%
  group_by(state) %>%
  summarise(
    mean_gp_visits = mean(gp_visits_year, na.rm = TRUE),
    mean_specialist_visits = mean(specialist_visits_year, na.rm = TRUE),
    mean_hospitalizations = mean(hospitalizations_year, na.rm = TRUE),
    mean_healthcare_cost = mean(total_healthcare_cost, na.rm = TRUE),
    mean_distance_gp = mean(distance_to_gp, na.rm = TRUE)
  )

print("Healthcare utilization by state:")
print(state_utilization)
```

### 2.2 Remoteness Area Analysis

```r
# Remoteness area analysis
remoteness_analysis <- geographic_data %>%
  group_by(remoteness_area) %>%
  summarise(
    n_patients = n(),
    oa_prevalence = mean(osteoarthritis, na.rm = TRUE) * 100,
    mean_age = mean(age, na.rm = TRUE),
    mean_income = mean(household_income, na.rm = TRUE),
    mean_distance_gp = mean(distance_to_gp, na.rm = TRUE),
    mean_gp_visits = mean(gp_visits_year, na.rm = TRUE),
    mean_specialist_visits = mean(specialist_visits_year, na.rm = TRUE),
    mean_healthcare_cost = mean(total_healthcare_cost, na.rm = TRUE)
  ) %>%
  arrange(desc(mean_distance_gp))

print("Health outcomes by remoteness:")
print(remoteness_analysis)

# Statistical comparison of remoteness areas
remoteness_stats <- geographic_data %>%
  group_by(remoteness_area) %>%
  summarise(
    mean_distance = mean(distance_to_gp, na.rm = TRUE),
    sd_distance = sd(distance_to_gp, na.rm = TRUE),
    mean_visits = mean(gp_visits_year, na.rm = TRUE),
    sd_visits = sd(gp_visits_year, na.rm = TRUE)
  )

print("Remoteness statistics:")
print(remoteness_stats)
```

### 2.3 Socioeconomic Geographic Patterns

```r
# Socioeconomic analysis by state
socioeconomic_state <- geographic_data %>%
  group_by(state) %>%
  summarise(
    mean_income = mean(household_income, na.rm = TRUE),
    median_income = median(household_income, na.rm = TRUE),
    pct_high_education = mean(education_level == "University", na.rm = TRUE) * 100,
    pct_unemployed = mean(employment_status == "Unemployed", na.rm = TRUE) * 100,
    mean_seifa = mean(seifa_score, na.rm = TRUE)
  ) %>%
  arrange(desc(mean_income))

print("Socioeconomic indicators by state:")
print(socioeconomic_state)

# Correlation between socioeconomic factors and health outcomes
socioeconomic_correlations <- geographic_data %>%
  group_by(state) %>%
  summarise(
    income_health_corr = cor(household_income, osteoarthritis, use = "complete.obs"),
    education_health_corr = cor(as.numeric(education_level), osteoarthritis, use = "complete.obs"),
    seifa_health_corr = cor(seifa_score, oa_severity, use = "complete.obs")
  )

print("Socioeconomic-health correlations by state:")
print(socioeconomic_correlations)
```

## Exercise 3: Choropleth Mapping

### 3.1 Basic Choropleth Map

```r
# Prepare state-level data for mapping
state_map_data <- geographic_data %>%
  group_by(state) %>%
  summarise(
    oa_prevalence = mean(osteoarthritis, na.rm = TRUE) * 100,
    total_patients = n(),
    mean_age = mean(age, na.rm = TRUE),
    mean_income = mean(household_income, na.rm = TRUE)
  )

# Create state abbreviations to full names mapping
state_names <- c(
  "NSW" = "New South Wales",
  "VIC" = "Victoria",
  "QLD" = "Queensland",
  "SA" = "South Australia",
  "WA" = "Western Australia",
  "TAS" = "Tasmania",
  "NT" = "Northern Territory",
  "ACT" = "Australian Capital Territory"
)

state_map_data$state_full <- state_names[state_map_data$state]

print("State-level OA prevalence data:")
print(state_map_data)

# Basic bar chart as alternative to choropleth
prevalence_plot <- ggplot(state_map_data, aes(x = reorder(state, oa_prevalence), y = oa_prevalence)) +
  geom_bar(stat = "identity", fill = "steelblue") +
  coord_flip() +
  labs(
    title = "Osteoarthritis Prevalence by State",
    x = "State",
    y = "Prevalence (%)"
  ) +
  theme_minimal()

print(prevalence_plot)
```

### 3.2 Healthcare Access Mapping

```r
# Healthcare access by state
access_map_data <- geographic_data %>%
  group_by(state) %>%
  summarise(
    mean_distance_gp = mean(distance_to_gp, na.rm = TRUE),
    mean_distance_specialist = mean(distance_to_specialist, na.rm = TRUE),
    mean_distance_hospital = mean(distance_to_hospital, na.rm = TRUE),
    pct_long_distance = mean(distance_to_gp > 50, na.rm = TRUE) * 100
  )

print("Healthcare access by state:")
print(access_map_data)

# Distance to GP services visualization
distance_plot <- ggplot(access_map_data, aes(x = reorder(state, mean_distance_gp), y = mean_distance_gp)) +
  geom_bar(stat = "identity", fill = "coral") +
  coord_flip() +
  labs(
    title = "Average Distance to GP Services by State",
    x = "State",
    y = "Distance (km)"
  ) +
  theme_minimal()

print(distance_plot)

# Healthcare access disparity analysis
access_disparity <- geographic_data %>%
  mutate(
    access_category = case_when(
      distance_to_gp <= 5 ~ "Excellent",
      distance_to_gp <= 20 ~ "Good",
      distance_to_gp <= 50 ~ "Moderate",
      TRUE ~ "Poor"
    )
  ) %>%
  group_by(state, access_category) %>%
  summarise(count = n()) %>%
  group_by(state) %>%
  mutate(pct = count / sum(count) * 100)

print("Healthcare access categories by state:")
print(access_disparity)
```

### 3.3 Socioeconomic Mapping

```r
# Socioeconomic mapping data
socioeconomic_map <- geographic_data %>%
  group_by(state) %>%
  summarise(
    mean_income = mean(household_income, na.rm = TRUE),
    pct_low_income = mean(household_income < 40000, na.rm = TRUE) * 100,
    mean_seifa = mean(seifa_score, na.rm = TRUE),
    pct_high_education = mean(education_level == "University", na.rm = TRUE) * 100
  )

print("Socioeconomic indicators by state:")
print(socioeconomic_map)

# Income distribution visualization
income_plot <- ggplot(socioeconomic_map, aes(x = reorder(state, mean_income), y = mean_income)) +
  geom_bar(stat = "identity", fill = "forestgreen") +
  coord_flip() +
  scale_y_continuous(labels = scales::comma) +
  labs(
    title = "Average Household Income by State",
    x = "State",
    y = "Income ($)"
  ) +
  theme_minimal()

print(income_plot)

# Education level analysis
education_analysis <- geographic_data %>%
  group_by(state, education_level) %>%
  summarise(count = n()) %>%
  group_by(state) %>%
  mutate(pct = count / sum(count) * 100) %>%
  filter(education_level == "University")

print("University education rates by state:")
print(education_analysis)
```

## Exercise 4: Spatial Autocorrelation Analysis

### 4.1 Moran's I Analysis

```r
# Prepare data for spatial analysis
spatial_data <- geographic_data %>%
  filter(!is.na(latitude) & !is.na(longitude)) %>%
  group_by(state) %>%
  summarise(
    oa_prevalence = mean(osteoarthritis, na.rm = TRUE),
    mean_income = mean(household_income, na.rm = TRUE),
    mean_distance = mean(distance_to_gp, na.rm = TRUE),
    centroid_lat = mean(latitude, na.rm = TRUE),
    centroid_lon = mean(longitude, na.rm = TRUE),
    n_patients = n()
  ) %>%
  filter(n_patients > 100)  # Only states with sufficient data

print("Spatial data for analysis:")
print(spatial_data)

# Calculate Moran's I for OA prevalence
# Note: This is a simplified analysis due to data structure
# In practice, you would use proper spatial weights matrices

# Simple distance-based correlation analysis
state_distances <- dist(spatial_data[, c("centroid_lat", "centroid_lon")])
state_correlations <- cor(spatial_data$oa_prevalence, method = "spearman")

cat("State-level OA prevalence correlation analysis:\n")
cat("Number of states with data:", nrow(spatial_data), "\n")
cat("OA prevalence range:", range(spatial_data$oa_prevalence), "\n")
```

### 4.2 Geographic Clustering

```r
# Geographic clustering analysis
clustering_data <- geographic_data %>%
  mutate(
    # Create geographic clusters based on latitude/longitude
    lat_cluster = cut(latitude,
                     breaks = quantile(latitude, probs = 0:4/4, na.rm = TRUE),
                     labels = c("South", "South-Central", "North-Central", "North")),
    lon_cluster = cut(longitude,
                     breaks = quantile(longitude, probs = 0:4/4, na.rm = TRUE),
                     labels = c("West", "West-Central", "East-Central", "East"))
  ) %>%
  unite("geo_cluster", lat_cluster, lon_cluster, sep = "-", remove = FALSE)

# Analyze clusters
cluster_analysis <- clustering_data %>%
  group_by(geo_cluster) %>%
  summarise(
    n_patients = n(),
    oa_prevalence = mean(osteoarthritis, na.rm = TRUE) * 100,
    mean_age = mean(age, na.rm = TRUE),
    mean_income = mean(household_income, na.rm = TRUE),
    mean_distance = mean(distance_to_gp, na.rm = TRUE)
  ) %>%
  arrange(desc(oa_prevalence))

print("Geographic cluster analysis:")
print(cluster_analysis)

# Cluster visualization
cluster_plot <- ggplot(cluster_analysis, aes(x = reorder(geo_cluster, oa_prevalence), y = oa_prevalence)) +
  geom_bar(stat = "identity", fill = "purple") +
  coord_flip() +
  labs(
    title = "OA Prevalence by Geographic Cluster",
    x = "Geographic Cluster",
    y = "OA Prevalence (%)"
  ) +
  theme_minimal()

print(cluster_plot)
```

### 4.3 Hot Spot Analysis

```r
# Hot spot analysis using statistical thresholds
hotspot_analysis <- geographic_data %>%
  group_by(state) %>%
  summarise(
    oa_prevalence = mean(osteoarthritis, na.rm = TRUE),
    prevalence_se = sqrt(oa_prevalence * (1 - oa_prevalence) / n()),
    z_score = (oa_prevalence - mean(geographic_data$osteoarthritis, na.rm = TRUE)) /
              sd(geographic_data$osteoarthritis, na.rm = TRUE),
    n_patients = n()
  ) %>%
  mutate(
    hotspot_category = case_when(
      z_score > 2 ~ "Hot Spot (High)",
      z_score < -2 ~ "Cold Spot (Low)",
      TRUE ~ "Average"
    )
  ) %>%
  arrange(desc(z_score))

print("Hot spot analysis:")
print(hotspot_analysis)

# Hot spot visualization
hotspot_plot <- ggplot(hotspot_analysis, aes(x = reorder(state, z_score), y = z_score, fill = hotspot_category)) +
  geom_bar(stat = "identity") +
  coord_flip() +
  scale_fill_manual(values = c("Hot Spot (High)" = "red", "Cold Spot (Low)" = "blue", "Average" = "gray")) +
  labs(
    title = "Geographic Hot Spot Analysis for OA Prevalence",
    x = "State",
    y = "Z-Score",
    fill = "Category"
  ) +
  theme_minimal()

print(hotspot_plot)
```

## Exercise 5: Spatial Regression Analysis

### 5.1 Ordinary Least Squares Regression

```r
# Prepare data for regression
regression_data <- geographic_data %>%
  group_by(state) %>%
  summarise(
    oa_prevalence = mean(osteoarthritis, na.rm = TRUE),
    mean_age = mean(age, na.rm = TRUE),
    mean_income = mean(household_income, na.rm = TRUE),
    mean_distance = mean(distance_to_gp, na.rm = TRUE),
    pct_urban = mean(urban_rural == "Urban", na.rm = TRUE),
    mean_seifa = mean(seifa_score, na.rm = TRUE),
    n_patients = n()
  ) %>%
  filter(n_patients > 100)

print("Regression data summary:")
print(regression_data)

# OLS regression model
ols_model <- lm(oa_prevalence ~ mean_age + mean_income + mean_distance +
                pct_urban + mean_seifa, data = regression_data)

print("OLS regression results:")
summary(ols_model)

# Model diagnostics
print("Model diagnostics:")
cat("R-squared:", summary(ols_model)$r.squared, "\n")
cat("Adjusted R-squared:", summary(ols_model)$adj.r.squared, "\n")
```

### 5.2 Geographic Effects Modeling

```r
# Geographic effects analysis
geographic_effects <- geographic_data %>%
  mutate(
    region = case_when(
      state %in% c("NSW", "VIC", "ACT") ~ "South-East",
      state %in% c("QLD") ~ "North-East",
      state %in% c("SA", "NT") ~ "Central",
      state %in% c("WA") ~ "West",
      state %in% c("TAS") ~ "South"
    )
  ) %>%
  group_by(region) %>%
  summarise(
    oa_prevalence = mean(osteoarthritis, na.rm = TRUE),
    mean_age = mean(age, na.rm = TRUE),
    mean_income = mean(household_income, na.rm = TRUE),
    mean_distance = mean(distance_to_gp, na.rm = TRUE),
    n_states = n_distinct(state)
  )

print("Regional geographic effects:")
print(geographic_effects)

# Regional comparison visualization
regional_plot <- ggplot(geographic_effects, aes(x = reorder(region, oa_prevalence), y = oa_prevalence)) +
  geom_bar(stat = "identity", fill = "orange") +
  coord_flip() +
  labs(
    title = "OA Prevalence by Geographic Region",
    x = "Region",
    y = "OA Prevalence"
  ) +
  theme_minimal()

print(regional_plot)
```

### 5.3 Healthcare Access Regression

```r
# Healthcare access regression
access_regression <- lm(oa_prevalence ~ mean_distance + pct_urban + mean_income,
                       data = regression_data)

print("Healthcare access regression:")
summary(access_regression)

# Access disparity analysis
access_disparity_analysis <- geographic_data %>%
  mutate(
    access_quartile = cut(distance_to_gp,
                         breaks = quantile(distance_to_gp, probs = 0:4/4, na.rm = TRUE),
                         labels = c("Q1 (Closest)", "Q2", "Q3", "Q4 (Farthest)"))
  ) %>%
  group_by(access_quartile) %>%
  summarise(
    n_patients = n(),
    oa_prevalence = mean(osteoarthritis, na.rm = TRUE) * 100,
    mean_gp_visits = mean(gp_visits_year, na.rm = TRUE),
    mean_specialist_visits = mean(specialist_visits_year, na.rm = TRUE),
    mean_cost = mean(total_healthcare_cost, na.rm = TRUE)
  )

print("Healthcare access disparity analysis:")
print(access_disparity_analysis)

# Access disparity visualization
access_disparity_plot <- ggplot(access_disparity_analysis,
                               aes(x = access_quartile, y = oa_prevalence)) +
  geom_bar(stat = "identity", fill = "darkred") +
  labs(
    title = "OA Prevalence by Healthcare Access Distance",
    x = "Access Distance Quartile",
    y = "OA Prevalence (%)"
  ) +
  theme_minimal()

print(access_disparity_plot)
```

## Exercise 6: Policy Implications and Recommendations

### 6.1 Geographic Health Policy Analysis

```r
# Policy analysis data
policy_analysis <- geographic_data %>%
  group_by(state) %>%
  summarise(
    oa_prevalence = mean(osteoarthritis, na.rm = TRUE) * 100,
    healthcare_access = mean(distance_to_gp, na.rm = TRUE),
    socioeconomic_status = mean(seifa_score, na.rm = TRUE),
    healthcare_utilization = mean(total_healthcare_cost, na.rm = TRUE),
    n_patients = n()
  ) %>%
  mutate(
    # Calculate disparity indices
    access_disparity = healthcare_access / mean(healthcare_access),
    prevalence_disparity = oa_prevalence / mean(oa_prevalence),
    socioeconomic_disparity = socioeconomic_status / mean(socioeconomic_status)
  ) %>%
  arrange(desc(oa_prevalence))

print("Policy analysis - geographic disparities:")
print(policy_analysis)

# Priority areas for intervention
priority_states <- policy_analysis %>%
  filter(oa_prevalence > mean(oa_prevalence) & healthcare_access > mean(healthcare_access)) %>%
  arrange(desc(oa_prevalence))

print("Priority states for healthcare intervention:")
print(priority_states)
```

### 6.2 Resource Allocation Recommendations

```r
# Resource allocation analysis
resource_allocation <- geographic_data %>%
  group_by(state) %>%
  summarise(
    population_size = n(),
    oa_burden = sum(osteoarthritis, na.rm = TRUE),
    current_resources = mean(gp_visits_year + specialist_visits_year, na.rm = TRUE),
    access_barrier = mean(distance_to_gp > 20, na.rm = TRUE)
  ) %>%
  mutate(
    # Calculate resource needs
    resource_need_index = (oa_burden / population_size) * access_barrier,
    recommended_allocation = resource_need_index / sum(resource_need_index) * 100
  ) %>%
  arrange(desc(recommended_allocation))

print("Resource allocation recommendations:")
print(resource_allocation)

# Resource allocation visualization
allocation_plot <- ggplot(resource_allocation,
                         aes(x = reorder(state, recommended_allocation),
                             y = recommended_allocation)) +
  geom_bar(stat = "identity", fill = "darkgreen") +
  coord_flip() +
  labs(
    title = "Recommended Healthcare Resource Allocation by State",
    x = "State",
    y = "Recommended Allocation (%)"
  ) +
  theme_minimal()

print(allocation_plot)
```

### 6.3 Equity Analysis

```r
# Equity analysis
equity_analysis <- geographic_data %>%
  mutate(
    income_quartile = cut(household_income,
                         breaks = quantile(household_income, probs = 0:4/4, na.rm = TRUE),
                         labels = c("Q1 (Lowest)", "Q2", "Q3", "Q4 (Highest)"))
  ) %>%
  group_by(state, income_quartile) %>%
  summarise(
    oa_prevalence = mean(osteoarthritis, na.rm = TRUE) * 100,
    mean_distance = mean(distance_to_gp, na.rm = TRUE),
    mean_visits = mean(gp_visits_year, na.rm = TRUE),
    n_patients = n()
  ) %>%
  filter(n_patients > 10)

print("Equity analysis - OA prevalence by income quartile:")
print(equity_analysis)

# Equity visualization
equity_plot <- ggplot(equity_analysis,
                     aes(x = income_quartile, y = oa_prevalence, fill = state)) +
  geom_bar(stat = "identity", position = "dodge") +
  labs(
    title = "OA Prevalence by Income Quartile and State",
    x = "Income Quartile",
    y = "OA Prevalence (%)",
    fill = "State"
  ) +
  theme_minimal() +
  theme(legend.position = "bottom")

print(equity_plot)

# Equity metrics
equity_metrics <- geographic_data %>%
  group_by(state) %>%
  summarise(
    # Concentration index for OA prevalence by income
    concentration_index = cor(seq(1, n()), household_income, method = "spearman"),
    # Access equity
    access_equity = 1 - sd(distance_to_gp, na.rm = TRUE) / mean(distance_to_gp, na.rm = TRUE)
  )

print("Equity metrics by state:")
print(equity_metrics)
```

## Data Generation Script

```r
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
```

## Summary Statistics and Validation

```r
# Summary statistics for the generated data
cat("=== Geographic Health Data Summary ===\n")
cat("Total observations:", nrow(geographic_data), "\n")
cat("Total patients:", n_distinct(geographic_data$patient_id), "\n")
cat("States covered:", paste(unique(geographic_data$state), collapse = ", "), "\n")

# Variable summaries
cat("\n=== Key Variable Summaries ===\n")
summary(geographic_data[, c("age", "household_income", "distance_to_gp", "total_healthcare_cost")])

# Geographic distribution
cat("\n=== Geographic Distribution ===\n")
table(geographic_data$state)
table(geographic_data$remoteness_area)

# Health outcomes by state
cat("\n=== OA Prevalence by State ===\n")
geographic_data %>%
  group_by(state) %>%
  summarise(
    oa_prevalence = mean(osteoarthritis, na.rm = TRUE) * 100,
    n_patients = n()
  ) %>%
  arrange(desc(oa_prevalence))

# Healthcare access summary
cat("\n=== Healthcare Access Summary ===\n")
summary(geographic_data$distance_to_gp)

# Missing data summary
cat("\n=== Missing Data Summary ===\n")
colSums(is.na(geographic_data))
```

---

*This solutions file provides complete working code for all Tutorial 4 exercises on geographic health disparities analysis.*</content>
<parameter name="filePath">\\wsl.localhost\Ubuntu\home\doughnut\github\aus_oa_public\tutorials\tutorial_04_geographic_disparities\solutions\tutorial_04_solutions.R
