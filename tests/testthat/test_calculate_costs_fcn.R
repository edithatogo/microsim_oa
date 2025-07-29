library(testthat)
library(data.table)

source(here::here("R", "calculate_costs_fcn.R"))

test_that("calculate_costs_fcn calculates costs correctly", {
  # 1. Mock data
  am_new <- data.table(
    tka = c(1, 0, 1, 0),
    revi = c(0, 0, 1, 0),
    oa = c(1, 1, 1, 0),
    dead = c(0, 0, 0, 0)
  )
  
  costs_config <- list(
    tka_primary = list(total = 20000, out_of_pocket = 2000),
    tka_revision = list(total = 30000, out_of_pocket = 3000),
    inpatient_rehab = list(total = 5000, out_of_pocket = 500),
    oa_annual_management = list(total = 1000, out_of_pocket = 200),
    productivity_loss = list(value = 2500),
    informal_care = list(value = 1800)
  )
  
  # 2. Call function
  result <- calculate_costs_fcn(am_new, costs_config)
  
  # 3. Assertions
  # Person 1: Primary TKA + Rehab + OA management
  expect_equal(result$cycle_cost_total[1], 20000 + 5000 + 1000)
  expect_equal(result$cycle_cost_oop[1], 2000 + 500 + 200)
  expect_equal(result$cycle_cost_prod[1], 2500)
  
  # Person 2: OA management only
  expect_equal(result$cycle_cost_total[2], 1000)
  
  # Person 3: Revision TKA + Rehab + OA management
  # Note: The function assumes a primary TKA event (`tka`=1) also happens with a revision, which might need review.
  # Based on current logic: Revision + Primary TKA + Rehab + OA Management
  expect_equal(result$cycle_cost_total[3], 30000 + 5000 + 1000)
  
  # Person 4: No OA, no events
  expect_equal(result$cycle_cost_total[4], 0)
})
