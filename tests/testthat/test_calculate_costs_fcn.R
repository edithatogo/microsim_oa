library(testthat)
library(data.table)



test_that("calculate_costs_fcn calculates costs correctly", {
  # 1. Mock data
  am_new <- data.table(
    tka = c(1, 0, 1, 0, 1),
    revi = c(0, 0, 1, 0, 0),
    oa = c(1, 1, 1, 0, 1),
    dead = c(0, 0, 0, 0, 0),
    ir = c(1, 0, 1, 0, 0),
    comp = c(0, 0, 0, 0, 1) # Added 'comp' column
  )

  costs_config <- list(
    tka_primary = list(
      hospital_stay = list(value = 18000, perspective = "healthcare_system"),
      patient_gap = list(value = 2000, perspective = "patient")
    ),
    tka_revision = list(
      hospital_stay = list(value = 27000, perspective = "healthcare_system"),
      patient_gap = list(value = 3000, perspective = "patient")
    ),
    inpatient_rehab = list(
      rehab_facility = list(value = 4500, perspective = "healthcare_system"),
      patient_gap = list(value = 500, perspective = "patient")
    ),
    oa_annual_management = list(
      gp_visits = list(value = 800, perspective = "healthcare_system"),
      patient_oop = list(value = 200, perspective = "patient")
    ),
    productivity_loss = list(
      loss = list(value = 2500, perspective = "societal")
    ),
    informal_care = list(
      care = list(value = 1800, perspective = "societal")
    ),
    tka_complication = list( # Added for the 'comp' case
      treatment = list(value = 5000, perspective = "healthcare_system"),
      patient_oop = list(value = 500, perspective = "patient")
    )
  )

  # 2. Call function
  result <- calculate_costs_fcn(am_new, costs_config)

  # 3. Assertions
  # Person 1: Primary TKA + Rehab + OA management
  expect_equal(result$cycle_cost_healthcare[1], 18000 + 4500 + 800)
  expect_equal(result$cycle_cost_patient[1], 2000 + 500 + 200)
  expect_equal(result$cycle_cost_societal[1], 2500 + 1800)
  expect_equal(result$cycle_cost_total[1], 23300 + 2700 + 4300)

  # Person 2: OA management only
  expect_equal(result$cycle_cost_healthcare[2], 800)
  expect_equal(result$cycle_cost_patient[2], 200)
  expect_equal(result$cycle_cost_societal[2], 2500 + 1800)
  expect_equal(result$cycle_cost_total[2], 800 + 200 + 4300)

  # Person 3: Revision TKA + Rehab + OA management
  expect_equal(result$cycle_cost_healthcare[3], 27000 + 4500 + 800)
  expect_equal(result$cycle_cost_patient[3], 3000 + 500 + 200)
  expect_equal(result$cycle_cost_societal[3], 2500 + 1800)
  expect_equal(result$cycle_cost_total[3], 32300 + 3700 + 4300)

  # Person 4: No OA, no events
  expect_equal(result$cycle_cost_total[4], 0)
  expect_equal(result$cycle_cost_healthcare[4], 0)
  expect_equal(result$cycle_cost_patient[4], 0)
  expect_equal(result$cycle_cost_societal[4], 0)

  # Person 5: Primary TKA + Complication + OA management
  expect_equal(result$cycle_cost_healthcare[5], 18000 + 800 + 5000)
  expect_equal(result$cycle_cost_patient[5], 2000 + 200 + 500)
  expect_equal(result$cycle_cost_societal[5], 2500 + 1800)
  expect_equal(result$cycle_cost_total[5], 23800 + 2700 + 4300)
})
