test_that("apply_coefficient_customisations_fcn works correctly", {
  # Mock data for testing
  customisations <- data.frame(
    parameter = c("age_effect", "sex_effect"),
    multiplier = c(1.05, 0.95),
    stringsAsFactors = FALSE
  )

  coefficients <- list(
    age_effect = 0.02,
    sex_effect = 0.01
  )

  # Apply customisations
  result <- apply_coefficient_customisations_fcn(customisations, coefficients)

  # Check that the function returns expected structure
  expect_type(result, "list")
  expect_named(result, c("age_effect", "sex_effect"))
})
