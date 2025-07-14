library(testthat)

source(here::here("scripts", "functions", "BMI_mod_fcn.R"))

test_that("BMI_mod_fcn calculates d_bmi correctly", {
  # 1. Set up mock data
  am_curr <- data.frame(
    sex = c("[1] Male", "[1] Male", "[2] Female", "[2] Female", "[2] Female"),
    age = c(40, 60, 40, 60, 60),
    bmi = c(25, 35, 25, 35, 25),
    year12 = c(1, 0, 1, 1, 0),
    d_bmi = c(0, 0, 0, 0, 0)
  )

  cycle.coefficents <- data.frame(
    c1_cons = 0.1, c1_year12 = 0.01, c1_age = 0.001, c1_bmi = -0.002,
    c2_cons = 0.2, c2_year12 = 0.02, c2_age = -0.002, c2_bmi = -0.004,
    c3_cons = 0.05, c3_age = 0.0015, c3_bmi_low = -0.001, c3_bmi_high = -0.003,
    c4_cons = 0.15, c4_age = -0.001, c4_bmi_low = -0.002, c4_bmi_high = -0.005,
    c5_cons = 0.25, c5_age = -0.0025, c5_bmi_low = -0.003, c5_bmi_high = -0.006
  )

  BMI_cust <- data.frame(
    covariate_set = c("c1", "c2", "c3", "c4", "c5"),
    proportion_reduction = c(1, 1, 1, 1, 1)
  )

  # 2. Call the function
  result <- BMI_mod_fcn(am_curr, cycle.coefficents, BMI_cust)

  # 3. Define expected output
  expected_d_bmi <- c(
    # Male, 40, bmi 25, year12 1
    0.1 + 0.01 * 1 + 0.001 * 40 + (-0.002) * 25,
    # Male, 60, bmi 35, year12 0
    0.2 + 0.02 * 0 + (-0.002) * 60 + (-0.004) * 35,
    # Female, 40, bmi 25, year12 1
    0.05 + 0.0015 * 40 + (-0.001) * 25 + (-0.003) * 0,
    # Female, 60, bmi 35, year12 1
    0.15 + (-0.001) * 60 + (-0.002) * 30 + (-0.005) * 5,
    # Female, 60, bmi 25, year12 0
    0.25 + (-0.0025) * 60 + (-0.003) * 25 + (-0.006) * 0
  )

  # 4. Assert expectations
  expect_equal(result$d_bmi, expected_d_bmi)
})
