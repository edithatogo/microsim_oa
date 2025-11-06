# Test data helpers for ausoa package
# Provides standardized test fixtures for consistent testing

# Generate a basic test population
generate_test_population <- function(n = 100, seed = 123) {
  set.seed(seed)
  
  data.frame(
    id = 1:n,
    age = sample(40:85, n, replace = TRUE),
    sex = sample(c(0, 1), n, replace = TRUE),  # 0 = female, 1 = male
    bmi = rnorm(n, mean = 28, sd = 5),
    kl_score = sample(0:4, n, replace = TRUE, prob = c(0.3, 0.25, 0.2, 0.15, 0.1)), # KL scores with realistic distribution
    tka_status = sample(c(0, 1), n, replace = TRUE, prob = c(0.95, 0.05)), # Most haven't had TKA
    revision_status = sample(c(0, 1), n, replace = TRUE, prob = c(0.98, 0.02)), # Even fewer have had revision
    comorbidities = sample(c(0, 1, 2, 3), n, replace = TRUE, prob = c(0.4, 0.3, 0.2, 0.1)),
    qaly = runif(n, min = 0.6, max = 1.0),  # Quality adjusted life years
    cost = runif(n, min = 1000, max = 100000), # Annual costs
    stringsAsFactors = FALSE
  )
}

# Generate test configuration
generate_test_config <- function() {
  list(
    simulation = list(
      time_horizon = 20,
      start_year = 2025,
      population_size = 1000
    ),
    costs = list(
      tka_primary = list(
        hospital_stay = list(value = 15000, perspective = "healthcare_system"),
        patient_gap = list(value = 2000, perspective = "patient")
      ),
      tka_revision = list(
        hospital_stay = list(value = 20000, perspective = "healthcare_system"),
        patient_gap = list(value = 2500, perspective = "patient")
      )
    ),
    utilities = list(
      kl0 = 0.85,
      kl1 = 0.80,
      kl2 = 0.72,
      kl3 = 0.65,
      kl4 = 0.55,
      post_tka = 0.78
    ),
    risks = list(
      tka_annual = 0.02,  # 2% annual probability of TKA
      revision_annual = 0.03  # 3% annual risk of revision after TKA
    )
  )
}

# Generate test intervention parameters
generate_test_interventions <- function() {
  list(
    enabled = TRUE,
    interventions = list(
      bmi_reduction = list(
        type = "bmi_modification",
        start_year = 2025,
        end_year = 2030,
        target_population = list(min_age = 50, max_age = 80),
        parameters = list(
          uptake_rate = 0.6,
          bmi_change = -2.0
        )
      ),
      qaly_improvement = list(
        type = "qaly_and_cost_modification",
        start_year = 2026,
        end_year = 2032,
        target_population = list(min_age = 60),
        parameters = list(
          uptake_rate = 0.75,
          qaly_improvement = 0.05
        )
      ),
      tka_risk_reduction = list(
        type = "tka_risk_modification",
        start_year = 2027,
        end_year = 2035,
        target_population = list(min_age = 65),
        parameters = list(
          uptake_rate = 0.5,
          risk_reduction = 0.15
        )
      )
    )
  )
}

# Generate a minimal test dataset
generate_minimal_test_data <- function() {
  data.frame(
    id = 1:10,
    age = c(60, 65, 70, 75, 80, 62, 68, 72, 78, 82),
    sex = c(0, 1, 1, 0, 1, 0, 1, 0, 0, 1),
    bmi = c(25, 28, 30, 32, 35, 26, 29, 31, 33, 36),
    kl_score = c(1, 2, 2, 3, 3, 1, 2, 3, 3, 4),
    tka_status = c(0, 0, 1, 1, 0, 0, 1, 1, 1, 0),
    stringsAsFactors = FALSE
  )
}

# Test data with costs structure
generate_cost_test_data <- function() {
  data.frame(
    id = 1:20,
    age = rep(65:75, length.out = 20),
    sex = rep(c(0, 1), length.out = 20),
    tka = c(rep(0, 10), rep(1, 10)),
    revi = c(rep(0, 15), rep(1, 5)),
    oa = rep(1, 20),
    dead = c(rep(0, 18), rep(1, 2)),
    ir = c(rep(0, 5), rep(1, 5), rep(0, 5), rep(1, 5)),
    comp = c(rep(0, 16), rep(1, 4)),
    comorbidity_cost = runif(20, 0, 1000),
    intervention_cost = runif(20, 0, 500),
    stringsAsFactors = FALSE
  )
}

# Save test datasets to fixtures directory
save_test_fixtures <- function() {
  # Create test population
  test_pop <- generate_test_population(50)
  saveRDS(test_pop, file.path("tests/testthat/fixtures", "test_population.rds"))
  
  # Save minimal test data
  min_data <- generate_minimal_test_data()
  saveRDS(min_data, file.path("tests/testthat/fixtures", "minimal_test_data.rds"))
  
  # Save cost test data
  cost_data <- generate_cost_test_data()
  saveRDS(cost_data, file.path("tests/testthat/fixtures", "cost_test_data.rds"))
  
  # Save configuration
  config <- generate_test_config()
  saveRDS(config, file.path("tests/testthat/fixtures", "test_config.rds"))
  
  # Save intervention parameters
  interventions <- generate_test_interventions()
  saveRDS(interventions, file.path("tests/testthat/fixtures", "test_interventions.rds"))
  
  cat("Test fixtures saved to tests/testthat/fixtures/\n")
}

# Function to load test data
load_test_fixture <- function(fixture_name) {
  fixture_path <- file.path("tests/testthat/fixtures", paste0(fixture_name, ".rds"))
  if (file.exists(fixture_path)) {
    return(readRDS(fixture_path))
  } else {
    stop("Fixture ", fixture_name, " does not exist at ", fixture_path)
  }
}

# Run this once to create all fixtures
if (getRversion() >= "3.0.0") {
  # Only run if we're not in a check environment
  if (!nzchar(Sys.getenv("R_CHECKING", unset = ""))) {
    # Create all fixtures (uncomment if needed)
    # save_test_fixtures()
  }
}