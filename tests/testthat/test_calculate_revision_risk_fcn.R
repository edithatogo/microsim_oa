library(testthat)
library(data.table)

source(here::here("R", "calculate_revision_risk_fcn.R"))

test_that("calculate_revision_risk_fcn works correctly", {
  # 1. Mock data
  am_curr <- data.table(
    age = c(60, 65, 70, 75),
    female = c(1, 0, 1, 0),
    bmi = c(25, 30, 35, 40),
    public = c(1, 0, 1, 0),
    tka1 = c(1, 1, 1, 1),
    agetka1 = c(1, 5, 1, 10),
    dead = c(0, 0, 0, 1),
    rev1 = c(0, 0, 1, 0)
  )
  
  rev_coeffs <- list(
    linear_predictor = list(age = 0.01, female = -0.1, bmi = 0.02, public = 0.1),
    early_hazard = list(intercept = -7),
    late_hazard = list(intercept = -9, log_time = 1.2)
  )
  
  # 2. Call function
  # Set seed for reproducible random numbers
  set.seed(123)
  result <- calculate_revision_risk_fcn(am_curr, rev_coeffs)
  
  # 3. Assertions
  # Person 1: Early revision (agetka1 = 1)
  expect_true(result$revi[1] == 0) # Based on seed
  
  # Person 2: Late revision (agetka1 = 5)
  expect_true(result$revi[2] == 0) # Based on seed
  
  # Person 3: Already had a revision (rev1 = 1) -> should not have another
  expect_equal(result$revi[3], 0)
  
  # Person 4: Is dead -> should not have a revision
  expect_equal(result$revi[4], 0)
})
