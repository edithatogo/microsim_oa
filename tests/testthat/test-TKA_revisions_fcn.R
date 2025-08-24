# tests/testthat/test-TKA_revisions_fcn.R
library(ausoa)
library(dplyr)

# --- Test Setup ---
create_test_am_for_tka <- function(n = 10) {
  data.frame(
    id = 1:n,
    year = rep(2020, n),
    age = sample(50:80, n, replace = TRUE),
    female = sample(c(0, 1), n, replace = TRUE),
    bmi = runif(n, 20, 40),
    phi = sample(c(0, 1), n, replace = TRUE),
    agetka1 = runif(n, 1, 10),
    agetka2 = runif(n, 1, 10)
  )
}

create_test_cycle_coefficients_for_tka <- function() {
  data.frame(
    cr_age = 0.01, cr_age53 = 0, cr_age63 = 0, cr_age69 = 0, cr_age74 = 0, cr_age83 = 0,
    cr_female = 0.1, cr_asa2 = 0.2, cr_asa3 = 0.3, cr_asa4_5 = 0.4,
    cr_bmi = 0.05, cr_bmi23 = 0, cr_bmi27 = 0, cr_bmi31 = 0, cr_bmi34 = 0, cr_bmi43 = 0,
    cr_public = 0.15,
    cr_k_1 = 1, cr_lambda_1 = 0.5, cr_k_min = 0, cr_k_max = 10,
    cr_k_2 = 2, cr_lambda_2 = 0.5, cr_k_3 = 3, cr_lambda_3 = 0.5,
    cr_k_4 = 4, cr_lambda_4 = 0.5, cr_k_5 = 5, cr_lambda_5 = 0.5,
    cr_k_6 = 6, cr_lambda_6 = 0.5, cr_k_7 = 7, cr_lambda_7 = 0.5,
    cr_gamma_0 = -5, cr_gamma_1 = 1, cr_gamma_2 = 0, cr_gamma_3 = 0,
    cr_gamma_4 = 0, cr_gamma_5 = 0, cr_gamma_6 = 0, cr_gamma_7 = 0, cr_gamma_8 = 0
  )
}

# --- Tests for TKA_revisions ---

test_that("TKA_revisions returns a data.frame with the correct columns", {
  am_all <- create_test_am_for_tka()
  cycle_coeffs <- create_test_cycle_coefficients_for_tka()
  
  result <- TKA_revisions(am_all, cycle_coeffs)
  
  expect_true(is.data.frame(result))
  expect_true(all(c("revision_haz_1", "revision_haz_2", "revision_1", "revision_2") %in% names(result)))
})

test_that("TKA_revisions calculates revision hazards", {
  am_all <- create_test_am_for_tka(1)
  cycle_coeffs <- create_test_cycle_coefficients_for_tka()
  
  result <- TKA_revisions(am_all, cycle_coeffs)
  
  expect_true(is.numeric(result$revision_haz_1))
  expect_true(is.numeric(result$revision_haz_2))
  expect_gte(result$revision_haz_1, 0)
  expect_gte(result$revision_haz_2, 0)
})

test_that("TKA_revisions generates binary revision indicators", {
  am_all <- create_test_am_for_tka(100)
  cycle_coeffs <- create_test_cycle_coefficients_for_tka()
  
  result <- TKA_revisions(am_all, cycle_coeffs)
  
  expect_true(all(result$revision_1 %in% c(0, 1)))
  expect_true(all(result$revision_2 %in% c(0, 1)))
})

test_that("TKA_revisions handles multiple years correctly", {
  am_all <- rbind(
    create_test_am_for_tka(10) %>% mutate(year = 2020),
    create_test_am_for_tka(10) %>% mutate(year = 2021)
  )
  cycle_coeffs <- create_test_cycle_coefficients_for_tka()
  
  result <- TKA_revisions(am_all, cycle_coeffs)
  
  # Check that the hazard is calculated per year and is not negative
  # (due to the lag calculation)
  expect_true(all(result$revision_haz_1 >= 0))
  expect_true(all(result$revision_haz_2 >= 0))
})
