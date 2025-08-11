library(testthat)
library(data.table)

test_that("TKA_update_fcn runs with test data and adds expected columns", {
  # --- 1. Load Data ---
  am_curr <- data.table(
    id = 1:10,
    age = 50:59,
    drugoa = rep(0, 10),
    ccount = rep(0, 10),
    mhc = rep(0, 10),
    tka1 = rep(0, 10),
    kl2 = rep(0, 10),
    kl3 = rep(1, 10),
    kl4 = rep(0, 10),
    pain = rep(5, 10),
    function_score = rep(60, 10),
    dead = rep(0, 10),
    sex = rep("[1] Male", 10),
    bmi = rep(28, 10),
    public = rep(1, 10),
    age_cat = rep("55-64", 10),
    oa = rep(1, 10),
    revi = rep(0, 10),
    tka2 = rep(0, 10),
    agetka1 = rep(0, 10),
    agetka2 = rep(0, 10),
    male = rep(1, 10),
    bmi3539 = rep(0, 10),
    bmi40 = rep(0, 10),
    age5564 = rep(1, 10),
    age6574 = rep(0, 10),
    age75 = rep(0, 10),
    sf6d = rep(0.7, 10),
    comp = rep(0, 10),
    d_sf6d = rep(0, 10),
    kl_score = rep(3, 10),
    year = rep(2023, 10)
  )
  am_new <- copy(am_curr)

  # --- 2. Load Coefficients ---
  cycle.coefficents <- list(
    c9_cons = -6.0, c9_age = 0.05, c9_age2 = 0, c9_drugoa = 0.5,
    c9_ccount = 0.1, c9_mhc = 0.2, c9_tkr = 1.0, c9_kl2hr = 0,
    c9_kl3hr = 0.8, c9_kl4hr = 1.5, c9_pain = 0.1, c9_function = -0.05,
    c15_cons = 0.1, c15_male = 0.01, c15_ccount = 0.02, c15_bmi3 = 0.03,
    c15_bmi4 = 0.04, c15_mhc = 0.05, c15_age3 = 0.06, c15_age4 = 0.07,
    c15_age5 = 0.08, c15_sf6d = -0.1, c15_kl3 = 0.1, c15_kl4 = 0.1, c15_comp = 0.2
  )

  # --- 4. Run TKA_update_fcn ---
  result <- TKA_update_fcn(
    am_curr,
    am_new = am_new,
    cycle.coefficents = cycle.coefficents,
    TKR_cust = data.frame(),
    summary_TKR_observed_diff = NULL
  )

  # --- 5. Check Output ---
  expect_true(is.list(result))
  expect_true("am_new" %in% names(result))
  expect_true(is.data.table(result$am_new))
  expect_equal(nrow(result$am_new), nrow(am_curr))

  # Check that the key output column 'tka' has been added
  expect_true("tka" %in% names(result$am_new))
})
