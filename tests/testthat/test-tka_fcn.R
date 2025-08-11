test_that("TKA_update_fcn runs with test data and adds expected columns", {
  
  # --- 1. Load Data ---
  # Using a small, controlled data.table instead of a large parquet file
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
    sex = rep(1, 10),
    bmi = rep(28, 10),
    public = rep(1, 10),
    age_cat = rep(2, 10),
    oa = rep(1, 10),
    revi = rep(0, 10)
  )

  # --- 2. Load Coefficients ---
  # Using a simplified mock object for coefficients
  cycle.coefficents <- list(
    c9 = list(
      c9_cons = -6.0, c9_age = 0.05, c9_age2 = 0, c9_drugoa = 0.5,
      c9_ccount = 0.1, c9_mhc = 0.2, c9_tkr = 1.0, c9_kl2hr = 0,
      c9_kl3hr = 0.8, c9_kl4hr = 1.5, c9_pain = 0.1, c9_function = -0.05
    ),
    revision_risk = list(
        cons = -5,
        age = 0.03,
        female = 0.2,
        bmi = 0.01,
        public = 0.1,
        shape = 1.5,
        scale_early = 0.5,
        scale_late = 0.8
    )
  )

  # --- 3. Check for required columns ---
  required_cols <- c("age", "drugoa", "ccount", "mhc", "tka1", "kl2", "kl3", "kl4", "pain", "function_score")
  expect_true(all(required_cols %in% names(am_curr)), "All required columns should be in am_curr")

  # --- 4. Run TKA_update_fcn ---
  am_new <- TKA_update_fcn(
    am_curr, 
    am_new = copy(am_curr), 
    cycle.coefficents, 
    TKR_cust = data.frame()
  )

  # --- 5. Check Output ---
  expect_true(is.list(am_new))
  expect_true("am_new" %in% names(am_new))
  expect_true(is.data.table(am_new$am_new))
  expect_equal(nrow(am_new$am_new), nrow(am_curr))
  
  # Check that the key output column 'tka' has been added
  expect_true("tka" %in% names(am_new$am_new), "Column 'tka' should be added")
})
