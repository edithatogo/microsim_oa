# tests/testthat/test-bmi_mod_fcn.R

library(testthat)

# Load all package functions
devtools::load_all()

test_that("BMI modification function calculates correctly", {

  # Create a sample data frame for a single individual
  am_curr <- data.frame(
    sex = "[1] Male",
    age = 40,
    year12 = 1,
    bmi = 28,
    d_bmi = 0
  )

  # Create sample cycle coefficients
  cycle.coefficents <- list(
    c1_cons = 0.1,
    c1_year12 = 0.05,
    c1_age = 0.01,
    c1_bmi = 0.02
  )
  
  # Create a dummy BMI_cust dataframe
  BMI_cust <- data.frame(
    covariate_set = "c1",
    proportion_reduction = 1
  )

  # Run the function
  result <- bmi_mod_fcn(am_curr, cycle.coefficents, BMI_cust)

  # Define the expected result
  expected_d_bmi <- 0.1 + (0.05 * 1) + (0.01 * 40) + (0.02 * 28)
  
  # Check that the result is as expected
  expect_equal(result$d_bmi, expected_d_bmi)
})
