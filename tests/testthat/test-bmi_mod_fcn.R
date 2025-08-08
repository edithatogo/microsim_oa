# tests/testthat/test-bmi_mod_fcn.R

library(testthat)



test_that("BMI modification function calculates correctly", {

  # Create a sample data frame for multiple individuals
  am_curr <- data.frame(
    sex = c("[1] Male", "[1] Male", "[2] Female", "[2] Female", "[2] Female"),
    age = c(40, 60, 40, 60, 60),
    year12 = c(1, 1, 1, 1, 0),
    bmi = c(28, 32, 28, 32, 32),
    d_bmi = c(0, 0, 0, 0, 0),
    bmi_under30 = c(28, 30, 28, 30, 30),
    bmi_over30 = c(0, 2, 0, 2, 2)
  )

  # Create sample cycle coefficients
  cycle.coefficents <- list(
    c1 = list(c1_cons = 0.1, c1_year12 = 0.05, c1_age = 0.01, c1_bmi = 0.02),
    c2 = list(c2_cons = 0.2, c2_year12 = 0.06, c2_age = 0.02, c2_bmi = 0.03),
    c3 = list(c3_cons = 0.15, c3_age = 0.015, c3_bmi_low = 0.025, c3_bmi_high = 0.035),
    c4 = list(c4_cons = 0.25, c4_age = 0.025, c4_bmi_low = 0.035, c4_bmi_high = 0.045),
    c5 = list(c5_cons = 0.3, c5_age = 0.03, c5_bmi_low = 0.04, c5_bmi_high = 0.05)
  )

  # Create a dummy BMI_cust dataframe
  BMI_cust <- data.frame(
    covariate_set = c("c1", "c2", "c3", "c4", "c5"),
    proportion_reduction = c(1, 1, 1, 1, 1)
  )

  # Run the function
  result <- bmi_mod_fcn(am_curr, cycle.coefficents, BMI_cust)

  # Define the expected result
  expected_d_bmi <- c(
    0.1 + (0.05 * 1) + (0.01 * 40) + (0.02 * 28),
    0.2 + (0.06 * 1) + (0.02 * 60) + (0.03 * 32),
    0.15 + (0.015 * 40) + (0.025 * 28) + (0.035 * 0),
    0.25 + (0.025 * 60) + (0.035 * 30) + (0.045 * 2),
    0.3 + (0.03 * 60) + (0.04 * 30) + (0.05 * 2)
  )

  # Check that the result is as expected
  expect_equal(result$d_bmi, expected_d_bmi)
})
