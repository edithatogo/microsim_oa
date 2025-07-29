library(testthat)
library(dplyr)
library(forcats)
library(stringr)

source(here::here("R", "Stats_temp_fcn.R"))

test_that("f_get_percent_N_from_binary calculates percentages and frequencies correctly", {
  # 1. Set up mock data
  df <- data.frame(
    group1 = c("A", "A", "B", "B"),
    group2 = c("X", "X", "Y", "Y"),
    binary1 = c(1, 0, 1, 1),
    binary2 = c(0, 0, 1, 0),
    non_binary = c(1, 2, 3, 4)
  )

  # 2. Call the function
  result <- f_get_percent_N_from_binary(df, c("group1", "group2"))

  # 3. Assert expectations
  expect_equal(nrow(result), 2)
  expect_equal(ncol(result), 6) # group1, group2, binary1_percent, binary1_frequency, binary2_percent, binary2_frequency
  expect_equal(result$binary1_percent[result$group1 == "A"], 50)
  expect_equal(result$binary1_frequency[result$group1 == "A"], 1)
  expect_equal(result$binary1_percent[result$group1 == "B"], 100)
  expect_equal(result$binary1_frequency[result$group1 == "B"], 2)
})

test_that("f_get_means_freq_sum calculates means, frequencies, and sums correctly", {
  # 1. Set up mock data
  df <- data.frame(
    group1 = c("A", "A", "B", "B"),
    numeric1 = c(1, 2, 3, 4),
    numeric2 = c(1, 1, 0, 1)
  )

  # 2. Call the function
  result <- f_get_means_freq_sum(df, "group1")

  # 3. Assert expectations
  expect_equal(nrow(result), 2)
  expect_equal(result$numeric1_mean[result$group1 == "A"], 1.5)
  expect_equal(result$numeric2_sum[result$group1 == "A"], 2)
  expect_equal(result$numeric2_frequency[result$group1 == "A"], 2)
})

test_that("BMI_summary_data creates BMI summary correctly", {
  # 1. Set up mock data
  am_all <- data.frame(
    dead = c(0, 0, 1, 0),
    age = c(40, 50, 60, 70),
    sex = c("[1] Male", "[2] Female", "[1] Male", "[2] Female"),
    year = c(2020, 2020, 2020, 2020),
    bmi = c(26, 24, 30, 31)
  )

  # 2. Call the function
  result <- BMI_summary_data(am_all)

  # 3. Assert expectations
  expect_equal(nrow(result), 3)
  expect_true("prop_overweight_obese" %in% names(result))
  expect_equal(result$prop_overweight_obese[result$age_cat == "35–44" & result$sex == "Male"], 1)
})

test_that("OA_summary_fcn creates OA summary correctly", {
  # 1. Set up mock data
  am_all <- data.frame(
    dead = c(0, 0, 1, 0),
    age = c(40, 50, 60, 70),
    sex = c("[1] Male", "[2] Female", "[1] Male", "[2] Female"),
    year = c(2020, 2020, 2020, 2020),
    oa = c(1, 0, 1, 1)
  )

  # 2. Call the function
  result <- OA_summary_fcn(am_all)

  # 3. Assert expectations
  expect_true("percent" %in% names(result))
  expect_equal(result$percent[result$age_group == "35-44" & result$sex == "Males"], 100)
})
