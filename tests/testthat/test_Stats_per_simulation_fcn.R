library(testthat)
library(dplyr)
library(tidyr)

test_that("stats_per_simulation calculates statistics correctly", {
  # 1. Set up mock data
  sim_storage <- list(
    data.frame(
      dead = c(0, 0, 0, 1, 0),
      age = c(50, 60, 50, 70, 80),
      bmi = c(24, 28, 32, 26, 35),
      oa = c(1, 0, 1, 0, 1),
      tka = c(0, 0, 1, 0, 0),
      sex = c("Male", "Female", "Male", "Female", "Male")
    )
  )

  # 2. Call the function
  # Test with one grouping variable
  result1 <- stats_per_simulation(sim_storage, 1, "sex")

  # Test with two grouping variables
  result2 <- stats_per_simulation(sim_storage, 1, c("sex", "age_group"))

  print(result1)
  print(result2)

  # 3. Assert expectations
  numeric_cols <- sum(sapply(sim_storage[[1]], is.numeric))

  # Test 1
  expect_equal(nrow(result1), 2 * (numeric_cols + 2))
  expect_true(all(c("sex", "variable", "N", "Mean", "Sum", "sim_number") %in% names(result1)))

  # Test 2
  expect_equal(nrow(result2), 3 * (numeric_cols + 2))
  expect_true(all(c("sex", "age_group", "variable", "N", "Mean", "Sum", "sim_number") %in% names(result2)))

  # Check a specific value
  male_oa_n <- result1$N[result1$sex == "Male" & result1$variable == "oa"]
  expect_equal(male_oa_n, 3)
})
