library(testthat)


# --- Test Data Setup ---
create_test_params <- function() {
  list(
    costs = list(
      tka = 10000,
      revision = 20000
    ),
    coefficients = list(
      intercept = 0.5,
      age = 0.01
    )
  )
}

# --- Tests for apply_policy_levers() ---

test_that("apply_policy_levers returns params unchanged if no levers are enabled", {
  params <- create_test_params()
  policy_levers <- list(
    list(name = "lever1", enabled = FALSE)
  )
  result <- apply_policy_levers(params, policy_levers)
  expect_identical(result, params)
})

test_that("apply_policy_levers returns params unchanged for 'No Intervention'", {
  params <- create_test_params()
  policy_levers <- list(
    list(name = "No Intervention", enabled = TRUE)
  )
  result <- apply_policy_levers(params, policy_levers)
  expect_identical(result, params)
})

test_that("apply_policy_levers correctly applies a 'multiply' operation", {
  params <- create_test_params()
  policy_levers <- list(
    list(
      name = "test_lever",
      enabled = TRUE,
      effects = list(
        list(target = "costs.tka", operation = "multiply", value = 1.2)
      )
    )
  )
  result <- apply_policy_levers(params, policy_levers)
  expect_equal(result$costs$tka, 12000)
})

test_that("apply_policy_levers correctly applies an 'add' operation", {
  params <- create_test_params()
  policy_levers <- list(
    list(
      name = "test_lever",
      enabled = TRUE,
      effects = list(
        list(target = "coefficients.age", operation = "add", value = 0.005)
      )
    )
  )
  result <- apply_policy_levers(params, policy_levers)
  expect_equal(result$coefficients$age, 0.015)
})

test_that("apply_policy_levers correctly applies a 'replace' operation", {
  params <- create_test_params()
  policy_levers <- list(
    list(
      name = "test_lever",
      enabled = TRUE,
      effects = list(
        list(target = "costs.revision", operation = "replace", value = 25000)
      )
    )
  )
  result <- apply_policy_levers(params, policy_levers)
  expect_equal(result$costs$revision, 25000)
})

test_that("apply_policy_levers handles multiple effects", {
  params <- create_test_params()
  policy_levers <- list(
    list(
      name = "test_lever",
      enabled = TRUE,
      effects = list(
        list(target = "costs.tka", operation = "multiply", value = 1.1),
        list(target = "coefficients.intercept", operation = "replace", value = 0.6)
      )
    )
  )
  result <- apply_policy_levers(params, policy_levers)
  expect_equal(result$costs$tka, 11000)
  expect_equal(result$coefficients$intercept, 0.6)
})

test_that("apply_policy_levers handles unknown operations gracefully", {
  params <- create_test_params()
  policy_levers <- list(
    list(
      name = "test_lever",
      enabled = TRUE,
      effects = list(
        list(target = "costs.tka", operation = "unknown", value = 1.2)
      )
    )
  )
  expect_warning(result <- apply_policy_levers(params, policy_levers))
  expect_identical(result, params)
})

test_that("apply_policy_levers handles non-existent targets gracefully", {
  params <- create_test_params()
  policy_levers <- list(
    list(
      name = "test_lever",
      enabled = TRUE,
      effects = list(
        list(target = "costs.non_existent", operation = "multiply", value = 1.2)
      )
    )
  )
  expect_warning(result <- apply_policy_levers(params, policy_levers))
  expect_identical(result, params)
})
