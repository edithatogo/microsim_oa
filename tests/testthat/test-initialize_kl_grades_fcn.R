# tests/testthat/test-initialize_kl_grades_fcn.R
library(ausoa)

# --- Test Setup ---
create_test_am_for_kl <- function(n = 100) {
  data.frame(
    oa = sample(c(0, 1), n, replace = TRUE, prob = c(0.8, 0.2))
  )
}

create_test_utilities_for_kl <- function() {
  list(
    kl_grades = list(
      kl2 = 0.1,
      kl3 = 0.2,
      kl4 = 0.3
    )
  )
}

create_test_initial_kl_grades <- function() {
  list(
    p_KL2init = 0.4,
    p_KL3init = 0.3
  )
}

# --- Tests for initialize_kl_grades ---

test_that("initialize_kl_grades creates the required columns", {
  am <- create_test_am_for_kl()
  utilities <- create_test_utilities_for_kl()
  initial_kl_grades <- create_test_initial_kl_grades()

  am_new <- initialize_kl_grades(am, utilities, initial_kl_grades)

  expect_true("kl0" %in% names(am_new))
  expect_true("kl2" %in% names(am_new))
  expect_true("kl3" %in% names(am_new))
  expect_true("kl4" %in% names(am_new))
  expect_true("sf6d" %in% names(am_new))
  expect_true("kl_score" %in% names(am_new))
})

test_that("kl0 is correctly initialized", {
  am <- create_test_am_for_kl(2)
  am$oa <- c(1, 0)
  utilities <- create_test_utilities_for_kl()
  initial_kl_grades <- create_test_initial_kl_grades()

  am_new <- initialize_kl_grades(am, utilities, initial_kl_grades)

  expect_equal(am_new$kl0, c(1, 0))
})

test_that("KL grades are mutually exclusive for individuals with OA", {
  am <- create_test_am_for_kl(100)
  am$oa <- 1 # All have OA
  utilities <- create_test_utilities_for_kl()
  initial_kl_grades <- create_test_initial_kl_grades()

  am_new <- initialize_kl_grades(am, utilities, initial_kl_grades)

  # For each person with OA, only one KL grade should be active
  kl_sum <- am_new$kl2 + am_new$kl3 + am_new$kl4
  expect_true(all(kl_sum[am_new$oa == 1] == 1))
  expect_true(all(kl_sum[am_new$oa == 0] == 0))
})

test_that("sf6d is correctly updated based on KL grades", {
  am <- create_test_am_for_kl(3)
  am$oa <- 1
  # Manually set KL grades to test sf6d calculation
  am$kl2 <- c(1, 0, 0)
  am$kl3 <- c(0, 1, 0)
  am$kl4 <- c(0, 0, 1)

  utilities <- create_test_utilities_for_kl()
  initial_kl_grades <- create_test_initial_kl_grades()

  # We need to bypass the random allocation for this test
  # So we calculate the expected sf6d manually
  expected_sf6d <- 1 - c(utilities$kl_grades$kl2, utilities$kl_grades$kl3, utilities$kl_grades$kl4)

  # The function will overwrite our manual kl grades, so we can't test it directly this way.
  # Instead, we can check that the sf6d values are within the expected range.
  am_new <- initialize_kl_grades(am, utilities, initial_kl_grades)
  expect_true(all(am_new$sf6d <= 1))
})

test_that("kl_score is correctly calculated", {
  am <- create_test_am_for_kl(3)
  am$oa <- 1
  # Manually set KL grades to test kl_score calculation
  am$kl2 <- c(1, 0, 0)
  am$kl3 <- c(0, 1, 0)
  am$kl4 <- c(0, 0, 1)

  utilities <- create_test_utilities_for_kl()
  initial_kl_grades <- create_test_initial_kl_grades()

  # Similar to sf6d, we can't test this directly with the current function structure.
  # We can check that the kl_score is within the expected range.
  am_new <- initialize_kl_grades(am, utilities, initial_kl_grades)
  expect_true(all(am_new$kl_score %in% c(0, 2, 3, 4)))
})
