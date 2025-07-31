library(testthat)
library(dplyr)
library(data.table)

# Source the functions to be tested
source(here::here("R", "simulation_cycle_fcn.R"))
source(here::here("R", "bmi_mod_fcn.R"))
source(here::here("R", "OA_update_fcn.R"))
source(here::here("R", "TKA_update_fcn_v2.R"))
source(here::here("R", "calculate_revision_risk_fcn.R"))
source(here::here("R", "apply_coefficient_customisations_fcn.R"))
source(here::here("R", "calculate_costs_fcn.R"))
source(here::here("R", "update_pros_fcn.R"))


test_that("simulation_cycle_fcn runs and updates key variables", {
  # 1. Set up mock data
  am_curr <- data.table(
    id = 1:2,
    sex = c("[1] Male", "[2] Female"),
    age = c(60, 65),
    bmi = c(32, 28),
    oa = c(1, 1),
    kl2 = c(0, 0),
    kl3 = c(1, 0),
    kl4 = c(0, 1),
    dead = c(0, 0),
    sf6d = c(0.7, 0.65),
    d_sf6d = c(0, 0),
    tka = c(1, 1),
    tka1 = c(1, 0),
    tka2 = c(0, 0),
    agetka1 = c(5, 0),
    agetka2 = c(0, 0),
    rev1 = c(0, 0),
    revi = c(0, 0),
    pain = c(70, 80),
    function_score = c(60, 70),
    qaly = c(12, 11),
    year = c(2020, 2020),
    year12 = c(0, 1),
    d_bmi = c(0, 0),
    drugoa = c(1, 1),
    age044 = c(0,0), age4554 = c(0,0), age5564 = c(1,0), age6574 = c(0,1), age75 = c(0,0),
    male = c(1,0), female = c(0,1),
    bmi024 = c(0,0), bmi2529 = c(0,1), bmi3034 = c(1,0), bmi3539 = c(0,0), bmi40 = c(0,0),
    ccount = c(1, 2),
    mhc = c(1, 0),
    comp = c(0, 0),
    ir = c(1, 1),
    public = c(1, 0)
  )
  am_new <- am_curr

  # Mock coefficients (simplified)
  model_parameters <- list(
    c1 = list(c1_cons = 0.1, c1_year12 = 0.01, c1_age = 0.001, c1_bmi = -0.002),
    c2 = list(c2_cons = 0.2, c2_year12 = 0.02, c2_age = 0.002, c2_bmi = -0.003),
    c3 = list(c3_cons = 0.15, c3_age = 0.0015, c3_bmi_low = -0.0025, c3_bmi_high = -0.0035),
    c4 = list(c4_cons = 0.18, c4_age = 0.0018, c4_bmi_low = -0.0028, c4_bmi_high = -0.0038),
    c5 = list(c5_cons = 0.22, c5_age = 0.0022, c5_bmi_low = -0.0032, c5_bmi_high = -0.0042),
    c6 = list(c6_cons = -5, c6_kl2 = 1, c6_kl3 = 1.5, c6_kl4 = 2),
    c9 = list(c9_cons = -10, c9_age = 0.1, c9_age2 = 0, c9_drugoa = 0.1, c9_ccount = 0.1,
              c9_mhc = 0.1, c9_tkr = -1, c9_kl2hr = 1, c9_kl3hr = 2, c9_kl4hr = 3,
              c9_pain = 0.02, c9_function = 0.01),
    c10 = list(c10_1 = 0.01, c10_2 = 0.01, c10_3 = 0.02, c10_4 = 0.03, c10_5 = 0.04),
    c12 = list(c12_male = 0.01, c12_female = 0.015),
    c14 = list(c14_bmi = -0.001, c14_ccount = -0.01, c14_mhc = -0.02),
    c16 = list(c16_cons = -5, c16_male = 0.1, c16_ccount = 0.1, c16_bmi3 = 0.2, c16_bmi4 = 0.3,
               c16_mhc = 0.1, c16_age3 = 0.2, c16_age4 = 0.3, c16_age5 = 0.4, c16_sf6d = -0.1,
               c16_kl3 = 0.2, c16_kl4 = 0.3),
    c17 = list(c17_cons = -6, c17_male = 0.1, c17_ccount = 0.1, c17_bmi3 = 0.2, c17_bmi4 = 0.3,
               c17_mhc = 0.1, c17_age3 = 0.2, c17_age4 = 0.3, c17_age5 = 0.4, c17_sf6d = -0.1,
               c17_kl3 = 0.2, c17_kl4 = 0.3, c17_comp = 0.5),
    costs = list(
      tka_primary = list(
        total = list(perspective = "healthcare_system", value = 20000),
        out_of_pocket = list(perspective = "patient", value = 2000)
      ),
      tka_revision = list(
        total = list(perspective = "healthcare_system", value = 30000),
        out_of_pocket = list(perspective = "patient", value = 3000)
      ),
      inpatient_rehab = list(
        total = list(perspective = "healthcare_system", value = 5000),
        out_of_pocket = list(perspective = "patient", value = 500)
      ),
      oa_annual_management = list(
        total = list(perspective = "healthcare_system", value = 1000),
        out_of_pocket = list(perspective = "patient", value = 200)
      ),
      productivity_loss = list(
        value = list(perspective = "societal", value = 2500)
      ),
      informal_care = list(
        value = list(perspective = "societal", value = 1800)
      )
    ),
    revision_model = list(
      linear_predictor = list(age = 0.01, female = -0.1, bmi = 0.02, public = 0.1),
      early_hazard = list(intercept = -7),
      late_hazard = list(intercept = -9, log_time = 1.2)
    ),
    utilities = list(c14_rev = -0.2, c14 = list(c14_bmi = -0.001), kl_grades = list(kl2 = 0.1, kl3 = 0.2, kl4 = 0.3)),
    hr = list(hr_BMI_mort = 1.1, hr_SEP_mort = 1.2)
  )

  # Other required data
  age_edges <- c(0, 44, 54, 64, 74, 100)
  bmi_edges <- c(0, 24, 29, 34, 39, 100)
  lt <- data.frame(male_sep1_bmi0 = rep(0.001, 101), female_sep1_bmi0 = rep(0.0008, 101))
  rownames(lt) <- 0:100
  eq_cust <- list(
    BMI = data.frame(
      covariate_set = c("c1", "c2", "c3", "c4", "c5"),
      proportion_reduction = c(1.0, 1.0, 1.0, 1.0, 1.0)
    ),
    TKR = data.frame(),
    OA = data.frame()
  )
  TKA_time_trend <- data.frame(
    Year = 2020,
    female4554 = 1, female5564 = 1, female6574 = 1, female75 = 1,
    male4554 = 1, male5564 = 1, male6574 = 1, male75 = 1
  )

  # 2. Call the function
  set.seed(123)
  result <- simulation_cycle_fcn(am_curr, model_parameters, am_new, age_edges, bmi_edges, am_curr, 1, lt, eq_cust, TKA_time_trend)

  # 3. Assert expectations
  expect_true(is.list(result))
  expect_true("am_new" %in% names(result))
  
  res_new <- result$am_new
  
  # Age should increase by 1 for the living
  expect_equal(res_new$age[res_new$dead == 0], am_curr$age[am_curr$dead == 0] + 1)
  
  # QALYs should be updated
  expect_true(all(res_new$qaly > am_curr$qaly))
  
  # Costs should be calculated
  expect_true("cycle_cost_total" %in% names(res_new))
  expect_true(all(res_new$cycle_cost_total > 0))
  
  # PROs should be updated
  expect_true(is.numeric(res_new$pain))
  expect_true(is.numeric(res_new$function_score))
  
  # Revisions should be updated
  expect_true(is.numeric(res_new$revi))
})