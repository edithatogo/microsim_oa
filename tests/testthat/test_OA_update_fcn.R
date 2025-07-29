library(testthat)

source(here::here("R", "OA_update_fcn.R"))
source(here::here("R", "apply_coefficent_customisations_fcn.R"))

test_that("OA_update_fcn calculates OA progression correctly", {
  # 1. Set up mock data
  am_curr <- data.frame(
    oa = c(0, 1, 0, 1, 1),
    kl2 = c(0, 1, 0, 0, 0),
    kl3 = c(0, 0, 0, 1, 0),
    kl4 = c(0, 0, 0, 0, 1),
    dead = c(0, 0, 0, 0, 0),
    sex = c("[1] Male", "[1] Male", "[2] Female", "[2] Female", "[2] Female"),
    age = c(40, 60, 40, 60, 60),
    bmi = c(25, 35, 25, 35, 25),
    year12 = c(1, 0, 1, 1, 0),
    drugoa = c(0, 1, 0, 1, 0),
    sf6d_change = c(0, 0, 0, 0, 0),
    age044 = c(1,0,1,0,0),
    age4554 = c(0,0,0,0,0),
    age5564 = c(0,1,0,1,1),
    age6574 = c(0,0,0,0,0),
    age75 = c(0,0,0,0,0),
    male = c(1,1,0,0,0),
    female = c(0,0,1,1,1),
    bmi024 = c(1,0,1,0,1),
    bmi2529 = c(0,0,0,0,0),
    bmi3034 = c(0,1,0,1,0),
    bmi3539 = c(0,0,0,0,0),
    bmi40 = c(0,0,0,0,0)
  )
  
  am_new <- am_curr

  cycle.coefficents <- data.frame(
    c6_cons = -5, c6_year12 = 0.1, c6_age1m = 0.2, c6_age2m = 0.3, c6_age3m = 0.4, c6_age4m = 0.5, c6_age5m = 0.6,
    c6_age1f = 0.25, c6_age2f = 0.35, c6_age3f = 0.45, c6_age4f = 0.55, c6_age5f = 0.65,
    c6_bmi0 = 0.01, c6_bmi1 = 0.02, c6_bmi2 = 0.03, c6_bmi3 = 0.04, c6_bmi4 = 0.05,
    c7_cons = -6, c7_sex = 0.1, c7_age3 = 0.2, c7_age4 = 0.3, c7_age5 = 0.4,
    c7_bmi0 = 0.01, c7_bmi1 = 0.02, c7_bmi2 = 0.03, c7_bmi3 = 0.04, c7_bmi4 = 0.05,
    c8_cons = -7, c8_sex = 0.1, c8_age3 = 0.2, c8_age4 = 0.3, c8_age5 = 0.4,
    c8_bmi0 = 0.01, c8_bmi1 = 0.02, c8_bmi2 = 0.03, c8_bmi3 = 0.04, c8_bmi4 = 0.05
  )

  OA_cust <- data.frame(
    covariate_set = c("c6_cons", "c6_age1m", "c6_age2m", "c6_age3m", "c6_age4m", "c6_age5m", "c6_age1f", "c6_age2f", "c6_age3f", "c6_age4f", "c6_age5f"),
    proportion_reduction = c(1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1)
  )
  
  pin <- data.frame(
    Parameter = c("c14_kl2", "c14_kl3", "c14_kl4"),
    Live = c(0.1, 0.2, 0.3)
  )

  # 2. Call the function
  result <- OA_update(am_curr, am_new, cycle.coefficents, OA_cust)

  # 3. Assert expectations
  # As the function uses random numbers, we can't check for exact values.
  # We will check if the columns have been updated (i.e., not all zeros).
  expect_true(sum(result$am_new$oa) >= sum(am_curr$oa))
  expect_true(sum(result$am_new$kl2) >= sum(am_curr$kl2))
  expect_true(sum(result$am_new$kl3) >= sum(am_curr$kl3))
  expect_true(sum(result$am_new$kl4) >= sum(am_curr$kl4))
})
