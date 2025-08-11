library(testthat)
library(data.table)

test_that("update_pros_fcn updates PROs correctly", {
  # 1. Mock data
  am_new <- data.table(
    oa = c(1, 1, 0, 1, 1),
    dead = c(0, 0, 0, 0, 0),
    tka = c(0, 1, 0, 0, 1),
    pain = c(60, 70, 10, 99, 5),
    function_score = c(50, 80, 5, 98, 2)
  )

  # 2. Call function
  result <- update_pros_fcn(am_new, list()) # No coefficients needed for this version

  # 3. Assertions
  # Person 1: OA, no TKA -> pain/function should worsen
  expect_equal(result$pain[1], 61)
  expect_equal(result$function_score[1], 50.5)

  # Person 2: OA, with TKA -> pain/function should improve after worsening
  expect_equal(result$pain[2], (70 + 1) * 0.4)
  expect_equal(result$function_score[2], (80 + 0.5) * 0.5)

  # Person 3: No OA -> no change
  expect_equal(result$pain[3], 10)
  expect_equal(result$function_score[3], 5)

  # Person 4: Test clamping at 100
  expect_equal(result$pain[4], 100)
  expect_equal(result$function_score[4], 98.5)

  # Person 5: Test clamping at 0
  expect_equal(result$pain[5], (5 + 1) * 0.4)
  expect_equal(result$function_score[5], (2 + 0.5) * 0.5)
})
