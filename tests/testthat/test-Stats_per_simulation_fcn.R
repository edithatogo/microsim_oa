# tests/testthat/test-Stats_per_simulation_fcn.R
library(ausoa)
library(dplyr)

# --- Test Setup ---
create_test_sim_storage <- function(n = 100) {
  list(
    data.frame(
      year = rep(2020:2024, each = n / 5),
      age = sample(40:80, n, replace = TRUE),
      sex = sample(c("male", "female"), n, replace = TRUE),
      dead = sample(c(0, 1), n, replace = TRUE, prob = c(0.9, 0.1)),
      bmi = runif(n, 20, 40),
      some_binary_var = sample(c(0, 1), n, replace = TRUE),
      some_numeric_var = runif(n, 10, 20)
    )
  )
}

# --- Tests for stats_per_simulation ---

test_that("stats_per_simulation returns a data.frame with the correct columns", {
  sim_storage <- create_test_sim_storage()
  stats <- stats_per_simulation(sim_storage, 1, c("year", "sex"))
  
  expect_true(is.data.frame(stats))
  expect_true(all(c("year", "sex", "variable", "N", "Mean", "Sum", "sim_number") %in% names(stats)))
})

test_that("stats_per_simulation correctly filters by age and dead status", {
  sim_storage <- list(
    data.frame(
      age = c(40, 50, 60, 70),
      dead = c(0, 0, 1, 0),
      bmi = c(20, 25, 30, 35),
      some_numeric_var = c(10, 20, 30, 40)
    )
  )
  
  # Expecting only the person aged 50 and 70 to be included
  stats <- stats_per_simulation(sim_storage, 1, "age")
  
  # The age column in the output refers to the grouping, not the original age
  # so we need to check the calculated stats
  # Mean of some_numeric_var should be (20+40)/2 = 30
  mean_val <- stats %>%
    filter(variable == "some_numeric_var") %>%
    pull(Mean)
    
  # There are two age groups, so we can't directly check the mean
  # Instead, let's check the sum
  sum_val <- stats %>%
    filter(variable == "some_numeric_var") %>%
    pull(Sum)
    
  expect_equal(sum(sum_val), 60)
})

test_that("stats_per_simulation correctly calculates N, Mean, and Sum", {
  sim_storage <- list(
    data.frame(
      year = 2020,
      age = 50,
      sex = "male",
      dead = 0,
      bmi = c(20, 25, 30, 35),
      some_binary_var = c(1, 1, 0, 0),
      some_numeric_var = c(10, 20, 30, 40)
    )
  )
  
  stats <- stats_per_simulation(sim_storage, 1, c("year", "sex"))
  
  binary_stats <- stats %>% filter(variable == "some_binary_var")
  numeric_stats <- stats %>% filter(variable == "some_numeric_var")
  
  expect_equal(binary_stats$N, 2)
  expect_equal(binary_stats$Mean, 0.5)
  expect_equal(binary_stats$Sum, 2)
  
  expect_equal(numeric_stats$N, 4) 
  expect_equal(numeric_stats$Mean, 25)
  expect_equal(numeric_stats$Sum, 100)
})

test_that("stats_per_simulation correctly creates derived variables", {
  sim_storage <- list(
    data.frame(
      age = c(50, 60, 70, 80),
      dead = 0,
      bmi = c(24, 26, 31, 28)
    )
  )
  
  stats <- stats_per_simulation(sim_storage, 1, "age_group")
  
  expect_true("age_group" %in% names(stats))
  expect_true("bmi_overweight_or_obese" %in% stats$variable)
  expect_true("bmi_obese" %in% stats$variable)
  
  bmi_obese_stats <- stats %>% filter(variable == "bmi_obese")
  expect_equal(sum(bmi_obese_stats$N), 1)
})
