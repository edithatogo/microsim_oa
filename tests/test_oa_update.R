library(data.table)

# Create dummy data
am_curr <- data.table(
  oa = rep(0, 10),
  dead = rep(0, 10),
  year12 = rep(0, 10),
  age044 = rep(1, 10),
  age4554 = rep(0, 10),
  age5564 = rep(0, 10),
  age6574 = rep(0, 10),
  age75 = rep(0, 10),
  male = rep(1, 10),
  female = rep(0, 10),
  bmi024 = rep(1, 10),
  bmi2529 = rep(0, 10),
  bmi3034 = rep(0, 10),
  bmi3539 = rep(0, 10),
  bmi40 = rep(0, 10),
  kl2 = rep(0, 10),
  kl3 = rep(0, 10),
  kl4 = rep(0, 10),
  sf6d_change = rep(0, 10)
)

am_new <- copy(am_curr)

cycle.coefficents <- list(
  c6_cons = -4,
  c6_year12 = 0,
  c6_age1m = 0,
  c6_age2m = 0,
  c6_age3m = 0,
  c6_age4m = 0,
  c6_age5m = 0,
  c6_age1f = 0,
  c6_age2f = 0,
  c6_age3f = 0,
  c6_age4f = 0,
  c6_age5f = 0,
  c6_bmi0 = 0,
  c6_bmi1 = 0,
  c6_bmi2 = 0,
  c6_bmi3 = 0,
  c6_bmi4 = 0,
  c7_cons = -4,
  c7_sex = 0,
  c7_age3 = 0,
  c7_age4 = 0,
  c7_age5 = 0,
  c7_bmi0 = 0,
  c7_bmi1 = 0,
  c7_bmi2 = 0,
  c7_bmi3 = 0,
  c7_bmi4 = 0,
  c8_cons = -4,
  c8_sex = 0,
  c8_age3 = 0,
  c8_age4 = 0,
  c8_age5 = 0,
  c8_bmi0 = 0,
  c8_bmi1 = 0,
  c8_bmi2 = 0,
  c8_bmi3 = 0,
  c8_bmi4 = 0,
  utilities = list(
    kl_grades = list(
      kl2 = -0.1,
      kl3 = -0.2,
      kl4 = -0.3
    )
  )
)

OA_cust <- data.frame(covariate_set = "cons", proportion_reduction = 1)

# Run the function
output <- OA_update(am_curr, am_new, cycle.coefficents, OA_cust)

# Print the output
print(output)
