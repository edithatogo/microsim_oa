# tests/testthat/test-apply_interventions_fcn.R
library(ausoa)
library(covr)

# --- Test Setup ---
create_test_attribute_matrix <- function(n = 10) {
  data.frame(
    age = sample(30:80, n, replace = TRUE),
    sex = sample(c("male", "female"), n, replace = TRUE),
    year12 = sample(c(0, 1), n, replace = TRUE),
    oa_state = sample(0:4, n, replace = TRUE),
    bmi = runif(n, 20, 40),
    d_sf6d = runif(n, 0.5, 0.9),
    tkai = runif(n, 0.01, 0.1),
    intervention_cost = 0
  )
}


# --- Tests for get_target_indices ---

test_that("get_target_indices correctly filters by age", {
  am <- create_test_attribute_matrix(5)
  am$age <- c(25, 35, 45, 55, 65)

  target_def <- list(min_age = 30, max_age = 60)
  indices <- get_target_indices(am, target_def)
  expect_equal(indices, c(FALSE, TRUE, TRUE, TRUE, FALSE))
})

test_that("get_target_indices correctly filters by sex", {
  am <- create_test_attribute_matrix(4)
  am$sex <- c("male", "female", "male", "female")

  target_def <- list(sex = "male")
  indices <- get_target_indices(am, target_def)
  expect_equal(indices, c(TRUE, FALSE, TRUE, FALSE))
})

test_that("get_target_indices correctly filters by multiple criteria", {
  am <- create_test_attribute_matrix(6)
  am$age <- c(40, 40, 60, 60, 70, 70)
  am$sex <- c("male", "female", "male", "female", "male", "female")

  target_def <- list(min_age = 50, sex = "female")
  indices <- get_target_indices(am, target_def)
  expect_equal(indices, c(FALSE, FALSE, FALSE, TRUE, FALSE, TRUE))
})

test_that("get_target_indices returns all TRUE when no criteria are given", {
  am <- create_test_attribute_matrix(5)
  target_def <- list()
  indices <- get_target_indices(am, target_def)
  expect_equal(indices, rep(TRUE, 5))
})


# --- Tests for apply_interventions ---

test_that("apply_interventions applies a bmi_modification intervention", {
  am <- create_test_attribute_matrix(1)
  am$bmi <- 30

  intervention_params <- list(
    enabled = TRUE,
    interventions = list(
      bmi_reduction = list(
        type = "bmi_modification",
        start_year = 2020,
        end_year = 2030,
        target_population = list(),
        parameters = list(uptake_rate = 1, bmi_change = -2)
      )
    )
  )

  am_new <- apply_interventions(am, intervention_params, year = 2025)
  expect_equal(am_new$bmi, 28)
})

test_that("apply_interventions applies a qaly_and_cost_modification intervention", {
  am <- create_test_attribute_matrix(1)
  am$d_sf6d <- 0.7
  am$intervention_cost <- 0

  intervention_params <- list(
    enabled = TRUE,
    interventions = list(
      qaly_increase = list(
        type = "qaly_and_cost_modification",
        start_year = 2020,
        end_year = 2030,
        target_population = list(),
        parameters = list(uptake_rate = 1, qaly_gain = 0.1, annual_cost = 100)
      )
    )
  )

  am_new <- apply_interventions(am, intervention_params, year = 2025)
  expect_equal(am_new$d_sf6d, 0.8)
  expect_equal(am_new$intervention_cost, 100)
})

test_that("apply_interventions applies a tka_risk_modification intervention", {
  am <- create_test_attribute_matrix(1)
  am$tkai <- 0.1

  intervention_params <- list(
    enabled = TRUE,
    interventions = list(
      tka_risk_reduction = list(
        type = "tka_risk_modification",
        start_year = 2020,
        end_year = 2030,
        target_population = list(),
        parameters = list(uptake_rate = 1, tka_risk_multiplier = 0.5)
      )
    )
  )

  am_new <- apply_interventions(am, intervention_params, year = 2025)
  expect_equal(am_new$tkai, 0.05)
})

test_that("apply_interventions does not apply an inactive intervention", {
  am <- create_test_attribute_matrix(1)
  am$bmi <- 30

  intervention_params <- list(
    enabled = TRUE,
    interventions = list(
      bmi_reduction = list(
        type = "bmi_modification",
        start_year = 2020,
        end_year = 2024,
        target_population = list(),
        parameters = list(uptake_rate = 1, bmi_change = -2)
      )
    )
  )

  am_new <- apply_interventions(am, intervention_params, year = 2025)
  expect_equal(am_new$bmi, 30)
})

test_that("apply_interventions handles multiple interventions", {
  am <- create_test_attribute_matrix(1)
  am$bmi <- 30
  am$d_sf6d <- 0.7
  am$intervention_cost <- 0

  intervention_params <- list(
    enabled = TRUE,
    interventions = list(
      bmi_reduction = list(
        type = "bmi_modification",
        start_year = 2020,
        end_year = 2030,
        target_population = list(),
        parameters = list(uptake_rate = 1, bmi_change = -2)
      ),
      qaly_increase = list(
        type = "qaly_and_cost_modification",
        start_year = 2020,
        end_year = 2030,
        target_population = list(),
        parameters = list(uptake_rate = 1, qaly_gain = 0.1, annual_cost = 100)
      )
    )
  )

  am_new <- apply_interventions(am, intervention_params, year = 2025)
  expect_equal(am_new$bmi, 28)
  expect_equal(am_new$d_sf6d, 0.8)
  expect_equal(am_new$intervention_cost, 100)
})

test_that("apply_interventions returns original matrix if disabled", {
  am <- create_test_attribute_matrix(1)
  am_orig <- am

  intervention_params <- list(enabled = FALSE)

  am_new <- apply_interventions(am, intervention_params, year = 2025)
  expect_equal(am_new, am_orig)
})

test_that("apply_interventions returns original matrix if no interventions are defined", {
  am <- create_test_attribute_matrix(1)
  am_orig <- am

  intervention_params <- list(enabled = TRUE, interventions = list())

  am_new <- apply_interventions(am, intervention_params, year = 2025)
  expect_equal(am_new, am_orig)
})
