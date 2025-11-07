# tests/testthat/test-Stats_temp_fcn.R
library(testthat)
library(ausoa)
library(dplyr)

# --- Test Setup ---
create_test_df <- function() {
  data.frame(
    group1 = c("A", "A", "B", "B"),
    group2 = c("X", "Y", "X", "Y"),
    binary1 = c(1, 0, 1, 1),
    binary2 = c(0, 0, 1, 0),
    numeric1 = c(10, 20, 30, 40),
    numeric2 = c(5, 15, 25, 35)
  )
}

create_am_all_test_data <- function() {
  data.frame(
    id = 1:10,
    dead = c(0, 0, 0, 0, 0, 0, 0, 0, 1, 0),
    age = c(40, 50, 60, 70, 80, 30, 45, 55, 65, 75),
    sex = c("[1] Male", "[2] Female", "[1] Male", "[2] Female", "[1] Male", "[2] Female", "[1] Male", "[2] Female", "[1] Male", "[2] Female"),
    year = rep(2020, 10),
    bmi = c(22, 26, 31, 28, 24, 29, 33, 21, 25, 27),
    oa = c(1, 1, 0, 0, 1, 0, 1, 0, 1, 0) # 5 with OA, but one is dead
  )
}

# --- Tests ---

test_that("f_get_percent_N_from_binary works correctly", {
  df <- create_test_df()
  result <- f_get_percent_N_from_binary(df, "group1")

  # Check for group A
  res_A <- result %>% filter(group1 == "A")
  expect_equal(res_A$binary1_percent, 50)
  expect_equal(res_A$binary1_frequency, 1)
  expect_equal(res_A$binary2_percent, 0)
  expect_equal(res_A$binary2_frequency, 0)

  # Check for group B
  res_B <- result %>% filter(group1 == "B")
  expect_equal(res_B$binary1_percent, 100)
  expect_equal(res_B$binary1_frequency, 2)
  expect_equal(res_B$binary2_percent, 50)
  expect_equal(res_B$binary2_frequency, 1)
})

test_that("f_get_means_freq_sum works correctly", {
  df <- create_test_df()
  result <- f_get_means_freq_sum(df, "group1")

  # Check for group A
  res_A <- result %>% filter(group1 == "A")
  expect_equal(res_A$numeric1_mean, 15)
  expect_equal(res_A$numeric1_sum, 30)
  expect_equal(res_A$binary1_frequency, 1) # Freq is sum of 1s

  # Check for group B
  res_B <- result %>% filter(group1 == "B")
  expect_equal(res_B$numeric2_mean, 30)
  expect_equal(res_B$numeric2_sum, 60)
  expect_equal(res_B$binary2_frequency, 1)
})

test_that("BMI_summary_data filters and calculates correctly", {
  am_all <- create_am_all_test_data()
  result <- BMI_summary_data(am_all)

  # Should filter out dead person and people under 35
  # Remaining n = 8
  expect_equal(nrow(result), 5)

  # Check a specific calculation
  # 45-54 age group, Female: age 50 (bmi 26), 55 (bmi 21) -> prop = 0.5
  res_45_54_F <- result %>% filter(age_cat == "45-54", sex == "Female")
  expect_equal(res_45_54_F$prop_overweight_obese, 0.5)

  # 35-44 age group, Male: age 40 (bmi 22), 45 (bmi 33) -> prop = 0.5
  res_35_44_M <- result %>% filter(age_cat == "35-44", sex == "Male")
  expect_equal(res_35_44_M$prop_overweight_obese, 0.5)
})

test_that("BMI_summary_RMSE calculates correctly", {
  sim_data <- data.frame(
    year = c(2018, 2018),
    age_cat = c("45-54", "55-64"),
    sex = c("Male", "Male"),
    prop_overweight_obese = c(0.6, 0.7),
    source = "Simulated"
  )

  obs_data <- data.frame(
    year = c(2018, 2018),
    prop_overweight_obese = c(65, 75), # Note: in percent
    age_cat = c("45-54", "55-64"),
    sex = c("Male", "Male"),
    lower_CI = c(60, 70),
    upper_CI = c(70, 80)
  )

  result <- BMI_summary_RMSE(obs_data, sim_data, "test")

  # Expected RMSE for 45-54: sqrt(((65 - 60)^2)) = 5
  # Expected RMSE for 55-64: sqrt(((75 - 70)^2)) = 5
  expect_equal(result$RMSE[1], 5)
  expect_equal(result$RMSE[2], 5)
})

test_that("OA_summary_fcn calculates correctly", {
  am_all <- create_am_all_test_data()
  result <- OA_summary_fcn(am_all)

  # 8 people alive and > 34. 4 have OA. Overall prevalence = 50%
  res_all <- result %>% filter(age_group == "All ages", sex == "All")
  expect_equal(res_all$percent, 50)

  # Males: 4 alive > 34. 3 have OA. Prevalence = 75%
  res_males <- result %>% filter(age_group == "All ages", sex == "Males")
  expect_equal(res_males$percent, 75)
})
