library(testthat)

source(here::here("R", "apply_policy_levers_fcn.R"))

test_that("apply_policy_levers works correctly with 2 levels of nesting", {
  # 1. Mock data
  params <- list(
    costs = list(
      tka_primary = list(total = 20000),
      oa_annual_management = list(total = 1000)
    ),
    c1 = list(
      c1_cons = 0.1
    )
  )

  policy_levers <- list(
    list(
      name = "Weight Loss Program",
      enabled = TRUE,
      effects = list(
        list(target = "c1.c1_cons", operation = "add", value = -0.05),
        list(target = "costs.oa_annual_management.total", operation = "multiply", value = 0.9)
      )
    )
  )

  # 2. Call function
  modified_params <- apply_policy_levers(params, policy_levers)

  # 3. Assertions
  expect_equal(modified_params$c1$c1_cons, 0.05)
  expect_equal(modified_params$costs$oa_annual_management$total, 900)
  expect_equal(modified_params$costs$tka_primary$total, 20000) # Unchanged
})

test_that("apply_policy_levers works correctly with 3 levels of nesting", {
  # 1. Mock data
  params <- list(
    costs = list(
      tka = list(
        primary = 20000
      )
    )
  )

  policy_levers <- list(
    list(
      name = "Cost increase",
      enabled = TRUE,
      effects = list(
        list(target = "costs.tka.primary", operation = "multiply", value = 1.1)
      )
    )
  )

  # 2. Call function
  modified_params <- apply_policy_levers(params, policy_levers)

  # 3. Assertions
  expect_equal(modified_params$costs$tka$primary, 22000)
})

test_that("apply_policy_levers handles 'No Intervention' correctly", {
  params <- list(costs = list(tka_primary = list(total = 20000)))
  policy_levers <- list(list(name = "No Intervention", enabled = TRUE, effects = list()))

  modified_params <- apply_policy_levers(params, policy_levers)

  expect_equal(modified_params, params)
})

test_that("apply_policy_levers handles new parameter creation", {
  params <- list(costs = list())
  policy_levers <- list(
    list(
      name = "New Drug",
      enabled = TRUE,
      effects = list(
        list(target = "costs.new_drug_cost", operation = "replace", value = 150)
      )
    )
  )

  modified_params <- apply_policy_levers(params, policy_levers)

  expect_equal(modified_params$costs$new_drug_cost, 150)
})
