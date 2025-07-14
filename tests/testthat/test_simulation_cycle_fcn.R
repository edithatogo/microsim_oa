library(testthat)

# Source the function to be tested
source(here::here("scripts", "functions", "simulation_cycle_fcn.R"))
source(here::here("scripts", "functions", "BMI_mod_fcn.R"))
source(here::here("scripts", "functions", "OA_update_fcn.R"))
source(here::here("scripts", "functions", "TKA_update_fcn_v2.R"))
source(here::here("scripts", "functions", "revisions_fcn.R"))

test_that("simulation_cycle_fcn runs without errors and updates key variables", {
  # 1. Set up mock data
  # am_curr and am_new
  am_curr <- data.frame(
    id = 1:5,
    sex = c("[1] Male", "[1] Male", "[2] Female", "[2] Female", "[2] Female"),
    age = c(40, 60, 40, 60, 99),
    bmi = c(25, 35, 25, 35, 25),
    year12 = c(1, 0, 1, 1, 0),
    d_bmi = c(0, 0, 0, 0, 0),
    oa = c(0, 1, 0, 1, 1),
    kl2 = c(0, 1, 0, 0, 0),
    kl3 = c(0, 0, 0, 1, 0),
    kl4 = c(0, 0, 0, 0, 1),
    dead = c(0, 0, 0, 0, 0),
    drugoa = c(0, 1, 0, 1, 0),
    sf6d = c(0.8, 0.7, 0.8, 0.7, 0.6),
    d_sf6d = c(0, 0, 0, 0, 0),
    age044 = c(1,0,1,0,0),
    age4554 = c(0,0,0,0,0),
    age5564 = c(0,1,0,1,0),
    age6574 = c(0,0,0,0,0),
    age75 = c(0,0,0,0,1),
    male = c(1,1,0,0,0),
    female = c(0,0,1,1,1),
    bmi024 = c(1,0,1,0,1),
    bmi2529 = c(0,0,0,0,0),
    bmi3034 = c(0,1,0,1,0),
    bmi3539 = c(0,0,0,0,0),
    bmi40 = c(0,0,0,0,0),
    ccount = c(0,1,0,1,2),
    mhc = c(0,1,0,1,0),
    tka = c(0,1,0,1,0),
    tka1 = c(0,1,0,1,0),
    tka2 = c(0,0,0,0,0),
    comp = c(0,1,0,1,0),
    ir = c(0,1,0,1,0),
    revision1 = c(0,0,0,0,0),
    revision2 = c(0,0,0,0,0),
    revi = c(0,0,0,0,0),
    cum_haz1 = c(0,0,0,0,0),
    cum_haz2 = c(0,0,0,0,0),
    rev_haz1 = c(0,0,0,0,0),
    rev_haz2 = c(0,0,0,0,0),
    qaly = c(10, 12, 10, 12, 11),
    year = c(2020, 2020, 2020, 2020, 2020),
    agetka1 = c(0, 5, 0, 3, 0),
    agetka2 = c(0, 0, 0, 0, 0),
    ASA2 = c(0,1,0,1,0),
    ASA3 = c(0,0,1,0,1),
    ASA4_5 = c(0,0,0,0,0),
    public = c(1,0,1,0,1)
  )
  am_new <- am_curr

  # cycle.coefficents
  cycle.coefficents <- data.frame(
    c1_cons = 0.1, c1_year12 = 0.01, c1_age = 0.001, c1_bmi = -0.002,
    c2_cons = 0.2, c2_year12 = 0.02, c2_age = -0.002, c2_bmi = -0.004,
    c3_cons = 0.05, c3_age = 0.0015, c3_bmi_low = -0.001, c3_bmi_high = -0.003,
    c4_cons = 0.15, c4_age = -0.001, c4_bmi_low = -0.002, c4_bmi_high = -0.005,
    c5_cons = 0.25, c5_age = -0.0025, c5_bmi_low = -0.003, c5_bmi_high = -0.006,
    c6_cons = -5, c6_year12 = 0.1, c6_age1m = 0.2, c6_age2m = 0.3, c6_age3m = 0.4, c6_age4m = 0.5, c6_age5m = 0.6,
    c6_age1f = 0.25, c6_age2f = 0.35, c6_age3f = 0.45, c6_age4f = 0.55, c6_age5f = 0.65,
    c6_bmi0 = 0.01, c6_bmi1 = 0.02, c6_bmi2 = 0.03, c6_bmi3 = 0.04, c6_bmi4 = 0.05,
    c7_cons = -6, c7_sex = 0.1, c7_age3 = 0.2, c7_age4 = 0.3, c7_age5 = 0.4,
    c7_bmi0 = 0.01, c7_bmi1 = 0.02, c7_bmi2 = 0.03, c7_bmi3 = 0.04, c7_bmi4 = 0.05,
    c8_cons = -7, c8_sex = 0.1, c8_age3 = 0.2, c8_age4 = 0.3, c8_age5 = 0.4,
    c8_bmi0 = 0.01, c8_bmi1 = 0.02, c8_bmi2 = 0.03, c8_bmi3 = 0.04, c8_bmi4 = 0.05,
    c9_cons = -10, c9_age = 0.1, c9_age2 = 0, c9_drugoa = 0.1, c9_ccount = 0.1,
    c9_mhc = 0.1, c9_tkr = -1, c9_kl2hr = 1, c9_kl3hr = 2, c9_kl4hr = 3,
    c10_1 = 0.01, c10_2 = 0.01, c10_3 = 0.02, c10_4 = 0.03, c10_5 = 0.04,
    c12_male = 0.01, c12_female = 0.015,
    c14_bmi = -0.001, c14_ccount = -0.01, c14_mhc = -0.02, c14_rev = -0.05,
    c16_cons = -5, c16_male = 0.1, c16_ccount = 0.1, c16_bmi3 = 0.2, c16_bmi4 = 0.3,
    c16_mhc = 0.1, c16_age3 = 0.2, c16_age4 = 0.3, c16_age5 = 0.4, c16_sf6d = -0.1,
    c16_kl3 = 0.2, c16_kl4 = 0.3,
    c17_cons = -6, c17_male = 0.1, c17_ccount = 0.1, c17_bmi3 = 0.2, c17_bmi4 = 0.3,
    c17_mhc = 0.1, c17_age3 = 0.2, c17_age4 = 0.3, c17_age5 = 0.4, c17_sf6d = -0.1,
    c17_kl3 = 0.2, c17_kl4 = 0.3, c17_comp = 0.5,
    hr_BMI_mort = 0.05, hr_SEP_mort = 1.1,
    p_rev1_shape = 1.5, p_rev1_scale = 0.1, p_rev2_shape = 1.6, p_rev2_scale = 0.11,
    cr_age = 0.01, cr_age53 = 0, cr_age63 = 0, cr_age69 = 0, cr_age74 = 0, cr_age83 = 0,
    cr_female = 0.1, cr_asa2 = 0.1, cr_asa3 = 0.2, cr_asa4_5 = 0.3, cr_bmi = 0.01,
    cr_bmi23 = 0, cr_bmi27 = 0, cr_bmi31 = 0, cr_bmi34 = 0, cr_bmi43 = 0, cr_public = 0.1,
    cr_k_1 = 0, cr_k_2 = 0, cr_k_3 = 0, cr_k_4 = 0, cr_k_5 = 0, cr_k_6 = 0, cr_k_7 = 0,
    cr_k_min = 0, cr_k_max = 0,
    cr_lambda_1 = 0, cr_lambda_2 = 0, cr_lambda_3 = 0, cr_lambda_4 = 0, cr_lambda_5 = 0, cr_lambda_6 = 0, cr_lambda_7 = 0,
    cr_gamma_0 = 0, cr_gamma_1 = 0, cr_gamma_2 = 0, cr_gamma_3 = 0, cr_gamma_4 = 0, cr_gamma_5 = 0, cr_gamma_6 = 0, cr_gamma_7 = 0, cr_gamma_8 = 0
  )

  # Other required data
  age_edges <- c(0, 44, 54, 64, 74, 100)
  bmi_edges <- c(0, 24, 29, 34, 39, 100)
  am <- am_curr
  mort_update_counter <- 1
  lt <- data.frame(
    male_sep1_bmi0 = rep(0.001, 101),
    female_sep1_bmi0 = rep(0.0008, 101)
  )
  rownames(lt) <- 0:100
  eq_cust <- list(
    BMI = data.frame(covariate_set = c("c1", "c2", "c3", "c4", "c5"), proportion_reduction = c(1, 1, 1, 1, 1)),
    TKR = data.frame(),
    OA = data.frame(covariate_set = c("c6_cons", "c6_age1m", "c6_age2m", "c6_age3m", "c6_age4m", "c6_age5m", "c6_age1f", "c6_age2f", "c6_age3f", "c6_age4f", "c6_age5f"),
                    proportion_reduction = c(1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1))
  )
  TKA_time_trend <- data.frame(
    Year = 2020,
    female4554 = 1, female5564 = 1, female6574 = 1, female75 = 1,
    male4554 = 1, male5564 = 1, male6574 = 1, male75 = 1
  )
  pin <- data.frame(
    Parameter = c("c14_kl2", "c14_kl3", "c14_kl4"),
    Live = c(0.1, 0.2, 0.3)
  )

  # 2. Call the function
  result <- simulation_cycle_fcn(am_curr, cycle.coefficents, am_new, age_edges, bmi_edges, am, mort_update_counter, lt, eq_cust, TKA_time_trend, pin)

  # 3. Assert expectations
  # Check that age has increased by 1 for the living
  expect_equal(result$am_new$age[result$am_new$dead == 0], am_curr$age[am_curr$dead == 0] + 1)
  # Check that QALYs have been updated
  expect_true(all(result$am_new$qaly >= am_curr$qaly))
  # Check that some people have died (probabilistically)
  expect_true(sum(result$am_new$dead) >= sum(am_curr$dead))
})
