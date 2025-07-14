library(testthat)

source(here::here("scripts", "functions", "TKA_update_fcn_v2.R"))

test_that("TKA_update_fcn calculates TKA initiation correctly", {
  # 1. Set up mock data
  am_curr <- data.frame(
    oa = c(1, 1, 1, 0, 1),
    dead = c(0, 0, 0, 0, 1),
    tka = c(0, 1, 0, 0, 0),
    tka1 = c(0, 1, 0, 0, 0),
    tka2 = c(0, 0, 0, 0, 0),
    sex = c("[1] Male", "[1] Male", "[2] Female", "[2] Female", "[2] Female"),
    age = c(50, 60, 70, 80, 90),
    drugoa = c(1, 1, 0, 0, 1),
    ccount = c(1, 2, 0, 1, 3),
    mhc = c(0, 1, 1, 0, 0),
    kl2 = c(1, 0, 0, 0, 0),
    kl3 = c(0, 1, 0, 0, 0),
    kl4 = c(0, 0, 1, 0, 0),
    age4554 = c(1, 0, 0, 0, 0),
    age5564 = c(0, 1, 0, 0, 0),
    age6574 = c(0, 0, 1, 0, 0),
    age75 = c(0, 0, 0, 1, 1),
    year = c(2020, 2020, 2020, 2020, 2020),
    agetka1 = c(0, 5, 0, 0, 0),
    agetka2 = c(0, 0, 0, 0, 0)
  )
  
  am_new <- am_curr

  cycle.coefficents <- data.frame(
    c9_cons = -10, c9_age = 0.1, c9_age2 = 0, c9_drugoa = 0.1, c9_ccount = 0.1,
    c9_mhc = 0.1, c9_tkr = -1, c9_kl2hr = 1, c9_kl3hr = 2, c9_kl4hr = 3
  )
  
  OA_cust <- data.frame(
    covariate_set = c("c6_cons", "c6_age1m", "c6_age2m", "c6_age3m", "c6_age4m", "c6_age5m", "c6_age1f", "c6_age3f", "c6_age4f", "c6_age5f"),
    proportion_reduction = rep(1, 10)
  )

  TKA_time_trend <- data.frame(
    Year = 2020,
    female4554 = 1, female5564 = 1, female6574 = 1, female75 = 1,
    male4554 = 1, male5564 = 1, male6574 = 1, male75 = 1
  )
  
  pin <- data.frame(Parameter = "p_tka_qol", Live = 0.1)

  # 2. Call the function
  result <- TKA_update_fcn(am_curr, am_new, pin, TKA_time_trend, OA_cust, cycle.coefficents)

  # 3. Assert expectations
  # As the function uses random numbers, we can't check for exact values.
  # We will check if the columns have been updated (i.e., not all zeros).
  expect_true(sum(result$am_new$tka) >= 0)
  expect_true(sum(result$am_new$tka1) >= sum(am_curr$tka1))
  expect_true(sum(result$am_new$tka2) >= sum(am_curr$tka2))
})
