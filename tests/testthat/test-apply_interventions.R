# tests/testthat/test-apply_interventions.R

library(testthat)

# Source the function to be tested
# Note: In a real package, this would be handled by devtools::load_all()
source("../../R/apply_interventions_fcn.R")

# --- Test Data Setup ---
create_test_am <- function(n = 10) {
  data.frame(
    id = 1:n,
    age = sample(45:80, n, replace = TRUE),
    sex = sample(c("[1] Male", "[2] Female"), n, replace = TRUE),
    year12 = sample(0:1, n, replace = TRUE),
    bmi = rnorm(n, 28, 4),
    d_sf6d = rnorm(n, -0.01, 0.005),
    tkai = runif(n, 0, 0.1),
    oa_state = sample(0:4, n, replace = TRUE), # Current KL grade
    kl0 = rep(0, n),
    kl1 = rep(0, n),
    kl2 = rep(0, n),
    kl3 = rep(0, n),
    kl4 = rep(0, n)
  )
}

# --- Tests for apply_interventions() ---

test_that("apply_interventions returns matrix unchanged if interventions are disabled", {
  am <- create_test_am()
  params <- list(enabled = FALSE)
  result <- apply_interventions(am, params, 2025)
  expect_identical(result, am)
})

test_that("apply_interventions returns matrix unchanged if no interventions are defined", {
  am <- create_test_am()
  params <- list(enabled = TRUE, interventions = list())
  result <- apply_interventions(am, params, 2025)
  expect_identical(result, am)
})

test_that("apply_interventions correctly applies a BMI modification", {
  set.seed(123)
  am <- create_test_am()
  am_original <- am
  params <- list(
    enabled = TRUE,
    interventions = list(
      weight_loss = list(
        type = "bmi_modification",
        start_year = 2025,
        end_year = 2030,
        target_population = list(min_age = 50),
        parameters = list(uptake_rate = 1.0, bmi_change = -2.0)
      )
    )
  )

  result <- apply_interventions(am, params, 2025)
  target_indices <- am_original$age >= 50
  expect_equal(result$bmi[target_indices], am_original$bmi[target_indices] - 2.0)
  expect_equal(result$bmi[!target_indices], am_original$bmi[!target_indices])
})

test_that("apply_interventions correctly applies a QALY/cost modification", {
  set.seed(123)
  am <- create_test_am()
  am_original <- am
  params <- list(
    enabled = TRUE,
    interventions = list(
      pain_clinic = list(
        type = "qaly_and_cost_modification",
        start_year = 2025,
        end_year = 2030,
        target_population = list(sex = "[2] Female"),
        parameters = list(uptake_rate = 1.0, qaly_gain = 0.05, annual_cost = 500)
      )
    )
  )

  result <- apply_interventions(am, params, 2026)
  target_indices <- am_original$sex == "[2] Female"
  expect_equal(result$d_sf6d[target_indices], am_original$d_sf6d[target_indices] + 0.05)
  expect_equal(result$intervention_cost[target_indices], rep(500, sum(target_indices)))
  expect_true(all(result$intervention_cost[!target_indices] == 0))
})

test_that("apply_interventions correctly applies a TKA risk modification", {
  set.seed(123)
  am <- create_test_am()
  am_original <- am
  params <- list(
    enabled = TRUE,
    interventions = list(
      exercise_program = list(
        type = "tka_risk_modification",
        start_year = 2025,
        end_year = 2030,
        target_population = list(), # All individuals
        parameters = list(uptake_rate = 1.0, tka_risk_multiplier = 0.8)
      )
    )
  )

  result <- apply_interventions(am, params, 2028)
  expect_equal(result$tkai, am_original$tkai * 0.8)
})

test_that("Intervention is not applied outside its active years", {
  set.seed(123)
  am <- create_test_am()
  params <- list(
    enabled = TRUE,
    interventions = list(
      weight_loss = list(
        type = "bmi_modification",
        start_year = 2025,
        end_year = 2030,
        target_population = list(min_age = 50),
        parameters = list(uptake_rate = 1.0, bmi_change = -2.0)
      )
    )
  )

  result_before <- apply_interventions(am, params, 2024)
  result_after <- apply_interventions(am, params, 2031)
  expect_identical(result_before, am)
  expect_identical(result_after, am)
})

test_that("apply_interventions respects the uptake rate", {
  set.seed(123)
  # Create a larger sample to get a more reliable proportion
  am <- create_test_am(1000)
  am_original <- am
  params <- list(
    enabled = TRUE,
    interventions = list(
      weight_loss = list(
        type = "bmi_modification",
        start_year = 2025,
        end_year = 2030,
        target_population = list(), # Target everyone
        parameters = list(uptake_rate = 0.5, bmi_change = -2.0)
      )
    )
  )

  result <- apply_interventions(am, params, 2025)
  
  # Check that approximately 50% of the population has been modified
  modified_count <- sum(result$bmi != am_original$bmi)
  expected_count <- 1000 * 0.5
  # Allow for some stochastic variation
  expect_lt(abs(modified_count - expected_count), 100) 
  
  # Check that the modification was applied correctly to those who were changed
  modified_indices <- result$bmi != am_original$bmi
  expected_bmi <- pmax(15, am_original$bmi[modified_indices] - 2.0)
  expect_equal(result$bmi[modified_indices], expected_bmi, tolerance = 1e-6)
  
  # Check that the non-modified population remains unchanged
  unmodified_indices <- result$bmi == am_original$bmi
  expect_equal(result$bmi[unmodified_indices], am_original$bmi[unmodified_indices])
})



# --- Tests for get_target_indices() ---

test_that("get_target_indices correctly targets by age", {
  am <- create_test_am(100)
  target <- list(min_age = 50, max_age = 70)
  indices <- get_target_indices(am, target)
  result_am <- am[indices, ]
  expect_true(all(result_am$age >= 50 & result_am$age <= 70))
})

test_that("get_target_indices correctly targets by sex", {
  am <- create_test_am(100)
  target <- list(sex = "[1] Male")
  indices <- get_target_indices(am, target)
  result_am <- am[indices, ]
  expect_true(all(result_am$sex == "[1] Male"))
})

test_that("get_target_indices correctly targets by multiple criteria", {
  am <- create_test_am(100)
  target <- list(min_age = 60, sex = "[2] Female")
  indices <- get_target_indices(am, target)
  result_am <- am[indices, ]
  expect_true(all(result_am$age >= 60 & result_am$sex == "[2] Female"))
})

test_that("get_target_indices correctly targets by KL grade", {
  am <- create_test_am(100)
  target <- list(min_kl = 2, max_kl = 3)
  indices <- get_target_indices(am, target)
  result_am <- am[indices, ]
  expect_true(all(result_am$oa_state >= 2 & result_am$oa_state <= 3))
})

test_that("apply_interventions correctly handles multiple interventions", {
  set.seed(123)
  am <- create_test_am()
  am_original <- am
  params <- list(
    enabled = TRUE,
    interventions = list(
      weight_loss = list(
        type = "bmi_modification",
        start_year = 2025,
        end_year = 2030,
        target_population = list(min_age = 50),
        parameters = list(uptake_rate = 1.0, bmi_change = -2.0)
      ),
      exercise_program = list(
        type = "tka_risk_modification",
        start_year = 2025,
        end_year = 2030,
        target_population = list(sex = "[1] Male"),
        parameters = list(uptake_rate = 1.0, tka_risk_multiplier = 0.5)
      )
    )
  )

  result <- apply_interventions(am, params, 2025)

  # Check BMI modification
  bmi_target_indices <- am_original$age >= 50
  expect_equal(result$bmi[bmi_target_indices], am_original$bmi[bmi_target_indices] - 2.0)
  expect_equal(result$bmi[!bmi_target_indices], am_original$bmi[!bmi_target_indices])

  # Check TKA risk modification
  tka_target_indices <- am_original$sex == "[1] Male"
  expect_equal(result$tkai[tka_target_indices], am_original$tkai[tka_target_indices] * 0.5)
  expect_equal(result$tkai[!tka_target_indices], am_original$tkai[!tka_target_indices])
})

test_that("apply_interventions throws an error for invalid intervention definition", {
  am <- create_test_am()
  params <- list(
    enabled = TRUE,
    interventions = list(
      bad_intervention = list(
        # Missing 'type'
        start_year = 2025,
        end_year = 2030,
        target_population = list(),
        parameters = list(uptake_rate = 1.0)
      )
    )
  )
  expect_error(apply_interventions(am, params, 2025))
})
