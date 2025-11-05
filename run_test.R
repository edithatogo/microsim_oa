library(data.table)
source("R/calculate_costs_fcn.R")
source("R/get_cost_sum.R")

# Mock data
am_new <- data.table(
  tka = c(1, 0, 1, 0, 1),
  revi = c(0, 0, 1, 0, 0),
  oa = c(1, 1, 1, 0, 1),
  dead = c(0, 0, 0, 0, 0),
  ir = c(1, 0, 1, 0, 0),
  comp = c(0, 0, 0, 0, 1),
  comorbidity_cost = c(10, 20, 30, 40, 50),
  intervention_cost = c(0, 0, 0, 0, 0)
)

costs_config <- list(
  costs = list(
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
    tka_complication = list(
      treatment = list(value = 5000, perspective = "healthcare_system"),
      patient_oop = list(value = 500, perspective = "patient")
    )
  )
)

# Call function
result <- calculate_costs_fcn(am_new, costs_config)

# Check results
print("Results for person 4:")
print(paste("cycle_cost_healthcare[4]:", result$cycle_cost_healthcare[4]))
print(paste("cycle_cost_patient[4]:", result$cycle_cost_patient[4]))
print(paste("cycle_cost_societal[4]:", result$cycle_cost_societal[4]))
print(paste("cycle_cost_total[4]:", result$cycle_cost_total[4]))

# Expected values
expected_healthcare <- 40
expected_patient <- 0
expected_societal <- 0
expected_total <- 40

print("\nExpected values:")
print(paste("Expected healthcare:", expected_healthcare))
print(paste("Expected patient:", expected_patient))
print(paste("Expected societal:", expected_societal))
print(paste("Expected total:", expected_total))

# Check if they match
if (result$cycle_cost_healthcare[4] == expected_healthcare &&
    result$cycle_cost_patient[4] == expected_patient &&
    result$cycle_cost_societal[4] == expected_societal &&
    result$cycle_cost_total[4] == expected_total) {
  print("\n✅ Person 4 test PASSED!")
} else {
  print("\n❌ Person 4 test FAILED!")
}
