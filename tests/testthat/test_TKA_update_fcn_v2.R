library(testthat)

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
    agetka2 = c(0, 0, 0, 0, 0),
    pain = c(60, 80, 90, 20, 70),
    function_score = c(50, 70, 80, 10, 60),
    bmi3539 = c(0, 0, 0, 0, 0),
    bmi40 = c(0, 0, 0, 0, 0),
    sf6d = c(0.7, 0.65, 0.6, 0.8, 0.5),
    comp = c(0, 0, 0, 0, 0),
    male = c(1, 1, 0, 0, 0),
    d_sf6d = c(0, 0, 0, 0, 0),
    kl_score = c(2, 3, 4, 0, 0)
  )
  am_new <- am_curr

  # Add age_cat to the mock data
  age_edges <- c(0, 44, 54, 64, 74, 1000)
  am_curr$age_cat <- cut(am_curr$age, breaks = age_edges, include.lowest = TRUE)

  # Mock coefficients
  cycle.coefficents <- list(
    c9_cons = -10, c9_age = 0.1, c9_age2 = 0, c9_drugoa = 0.1, c9_ccount = 0.1,
    c9_mhc = 0.1, c9_tkr = -1, c9_kl2hr = 1, c9_kl3hr = 2, c9_kl4hr = 3,
    c9_pain = 0.02, c9_function = 0.01,
    c15_cons = 0.1, c15_male = 0.01, c15_ccount = 0.02, c15_bmi3 = 0.03,
    c15_bmi4 = 0.04, c15_mhc = 0.05, c15_age3 = 0.06, c15_age4 = 0.07,
    c15_age5 = 0.08, c15_sf6d = -0.1, c15_kl3 = 0.1, c15_kl4 = 0.1, c15_comp = 0.2
  )

  TKR_cust <- data.frame()

  # 2. Call the function
  result <- TKA_update_fcn(
    am_curr = am_curr,
    am_new = am_new,
    cycle.coefficents = cycle.coefficents,
    TKR_cust = TKR_cust,
    summary_TKR_observed_diff = NULL
  )

  # 3. Assert expectations
  expect_true(is.data.frame(result$am_curr))
  expect_true(is.data.frame(result$am_new))
  expect_true(is.numeric(result$am_curr$tkai))
  expect_false(any(is.na(result$am_curr$tkai)))

  # Person 4 has no OA, so should have 0 probability
  expect_equal(result$am_curr$tkai[4], 0)

  # Person 5 is dead, so should have 0 probability
  expect_equal(result$am_curr$tkai[5], 0)

  # Check that tkai is numeric
  expect_true(is.numeric(result$am_curr$tkai))
})


test_that("TKA_update_fcn handles empty input", {
  # 1. Set up empty mock data
  am_curr <- data.frame()
  am_new <- data.frame()
  cycle.coefficents <- list()
  TKR_cust <- data.frame()

  # 2. Call the function
  result <- TKA_update_fcn(
    am_curr = am_curr,
    am_new = am_new,
    cycle.coefficents = cycle.coefficents,
    TKR_cust = TKR_cust,
    summary_TKR_observed_diff = NULL
  )

  # 3. Assert expectations
  expect_true(is.data.frame(result$am_curr))
  expect_true(is.data.frame(result$am_new))
  expect_true(nrow(result$am_curr) == 0)
  expect_true(nrow(result$am_new) == 0)
})

test_that("TKA_update_fcn handles missing coefficients", {
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
    agetka2 = c(0, 0, 0, 0, 0),
    pain = c(60, 80, 90, 20, 70),
    function_score = c(50, 70, 80, 10, 60),
    bmi3539 = c(0, 0, 0, 0, 0),
    bmi40 = c(0, 0, 0, 0, 0),
    sf6d = c(0.7, 0.65, 0.6, 0.8, 0.5),
    comp = c(0, 0, 0, 0, 0),
    male = c(1, 1, 0, 0, 0),
    d_sf6d = c(0, 0, 0, 0, 0),
    kl_score = c(2, 3, 4, 0, 0)
  )
  am_new <- am_curr

  # Add age_cat to the mock data
  age_edges <- c(0, 44, 54, 64, 74, 1000)
  am_curr$age_cat <- cut(am_curr$age, breaks = age_edges, include.lowest = TRUE)

  # Mock coefficients with some missing
  cycle.coefficents <- list(
    c9_cons = -10, c9_age = 0.1, c9_age2 = 0, c9_drugoa = 0.1, c9_ccount = 0.1,
    c9_mhc = 0.1, c9_tkr = -1, c9_kl2hr = 1, c9_kl3hr = 2, c9_kl4hr = 3,
    c9_pain = 0.02, c9_function = 0.01
  )

  TKR_cust <- data.frame()

  # 2. Call the function
  result <- TKA_update_fcn(
    am_curr = am_curr,
    am_new = am_new,
    cycle.coefficents = cycle.coefficents,
    TKR_cust = TKR_cust,
    summary_TKR_observed_diff = NULL
  )

  # 3. Assert expectations
  expect_true(is.data.frame(result$am_curr))
  expect_true(is.data.frame(result$am_new))
  expect_true(is.numeric(result$am_curr$tkai))
  expect_false(any(is.na(result$am_curr$tkai)))
})
