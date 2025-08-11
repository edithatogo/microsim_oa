# Get a parameter value from the simulation setup
# It can access nested parameters using a dot-separated string.
get_param_value <- function(param_name, config_path = here::here("config", "simulation_setup.yml")) {
  sim_setup <- yaml::read_yaml(config_path)
  # Use stringsplit to handle nested parameter names
  param_path <- unlist(strsplit(param_name, "\\."))
  # Traverse the list to get the final value
  value <- purrr::reduce(param_path, function(config, name) {
    if (is.list(config) && name %in% names(config)) {
      config[[name]]
    } else {
      # Return a special value (e.g., NULL) if the path is invalid
      NULL
    }
  }, .init = sim_setup)
  if (is.null(value)) {
    warning(paste("Parameter not found:", param_name))
  }
  return(value)
}
# Update BMI for one cycle (Optimized with data.table)
#
# This function updates the Body Mass Index (BMI) for each individual in the
# attribute matrix for a single simulation cycle. This version is optimized
# for performance using the data.table package.
#
# @param am_curr A data.table representing the attribute matrix for the current
#   cycle.
# @param cycle_coefficients A list containing the regression coefficients.
# @param bmi_customisations A data.frame containing calibration factors.
#
# @return The updated attribute matrix (a copy) with a new 'd_bmi' column.
# @importFrom data.table := .SD .N .I as.data.table
# @export
bmi_mod_fcn <- function(am_curr, cycle_coefficients, bmi_customisations) {
  # Ensure am_curr is a data.table and create a copy to avoid side effects
  dt <- data.table::copy(as.data.table(am_curr))
  # --- Pre-calculate BMI components ---
  dt[, bmi_under30 := ifelse(dt$bmi <= 30, dt$bmi, 30)]
  dt[, bmi_over30 := ifelse(dt$bmi > 30, dt$bmi - 30, 0)]
  # --- Vectorized BMI Progression Calculation ---
  # Get calibration factors once, ensuring they are numeric and default to 1
  calib_c1 <- 
    as.numeric(bmi_customisations$proportion_reduction[bmi_customisations$covariate_set == "c1"])
  if (length(calib_c1) == 0) {
    calib_c1 <- 1.0
  }
  calib_c2 <- 
    as.numeric(bmi_customisations$proportion_reduction[bmi_customisations$covariate_set == "c2"])
  if (length(calib_c2) == 0) {
    calib_c2 <- 1.0
  }
  calib_c3 <- 
    as.numeric(bmi_customisations$proportion_reduction[bmi_customisations$covariate_set == "c3"])
  if (length(calib_c3) == 0) {
    calib_c3 <- 1.0
  }
  calib_c4 <- 
    as.numeric(bmi_customisations$proportion_reduction[bmi_customisations$covariate_set == "c4"])
  if (length(calib_c4) == 0) {
    calib_c4 <- 1.0
  }
  calib_c5 <- 
    as.numeric(bmi_customisations$proportion_reduction[bmi_customisations$covariate_set == "c5"])
  if (length(calib_c5) == 0) {
    calib_c5 <- 1.0
  }
  # Initialize d_bmi column
  dt[, d_bmi := 0.0]
  # Apply calculations to each segment using data.table's syntax
  # Apply calculations to each segment using data.table's syntax
  if (nrow(dt[dt$sex == "[1] Male" & dt$age < 50]) > 0) {
    dt[dt$sex == "[1] Male" & dt$age < 50, d_bmi := (
      cycle_coefficients$c1$c1_cons +
      cycle_coefficients$c1$c1_year12 * dt[dt$sex == "[1] Male" & dt$age < 50]$year12 +
      cycle_coefficients$c1$c1_age * dt[dt$sex == "[1] Male" & dt$age < 50]$age +
      cycle_coefficients$c1$c1_bmi * dt[dt$sex == "[1] Male" & dt$age < 50]$bmi
    ) * calib_c1]
  }
  if (nrow(dt[dt$sex == "[1] Male" & dt$age >= 50]) > 0) {
    dt[dt$sex == "[1] Male" & dt$age >= 50, d_bmi := (
      cycle_coefficients$c2$c2_cons +
      cycle_coefficients$c2$c2_year12 * dt[dt$sex == "[1] Male" & dt$age >= 50]$year12 +
      cycle_coefficients$c2$c2_age * dt[dt$sex == "[1] Male" & dt$age >= 50]$age +
      cycle_coefficients$c2$c2_bmi * dt[dt$sex == "[1] Male" & dt$age >= 50]$bmi
    ) * calib_c2]
  }
  if (nrow(dt[dt$sex == "[2] Female" & dt$age < 50]) > 0) {
    dt[dt$sex == "[2] Female" & dt$age < 50, d_bmi := (
      cycle_coefficients$c3$c3_cons +
      cycle_coefficients$c3$c3_age * dt[dt$sex == "[2] Female" & dt$age < 50]$age +
      cycle_coefficients$c3$c3_bmi_low * dt[dt$sex == "[2] Female" & dt$age < 50]$bmi_under30 +
      cycle_coefficients$c3$c3_bmi_high * dt[dt$sex == "[2] Female" & dt$age < 50]$bmi_over30
    ) * calib_c3]
  }
  if (nrow(dt[dt$sex == "[2] Female" & dt$age >= 50 & dt$year12 == 1]) > 0) {
    dt[dt$sex == "[2] Female" & dt$age >= 50 & dt$year12 == 1, d_bmi := (
      cycle_coefficients$c4$c4_cons +
      cycle_coefficients$c4$c4_age * dt[dt$sex == "[2] Female" & dt$age >= 50 & dt$year12 == 1]$age +
      cycle_coefficients$c4$c4_bmi_low * dt[dt$sex == "[2] Female" & dt$age >= 50 & dt$year12 == 1]$bmi_under30 +
      cycle_coefficients$c4$c4_bmi_high * dt[dt$sex == "[2] Female" & dt$age >= 50 & dt$year12 == 1]$bmi_over30
    ) * calib_c4]
  }
  if (nrow(dt[dt$sex == "[2] Female" & dt$age >= 50 & dt$year12 == 0]) > 0) {
    dt[dt$sex == "[2] Female" & dt$age >= 50 & dt$year12 == 0, d_bmi := (
      cycle_coefficients$c5$c5_cons +
      cycle_coefficients$c5$c5_age * dt[dt$sex == "[2] Female" & dt$age >= 50 & dt$year12 == 0]$age +
      cycle_coefficients$c5$c5_bmi_low * dt[dt$sex == "[2] Female" & dt$age >= 50 & dt$year12 == 0]$bmi_under30 +
      cycle_coefficients$c5$c5_bmi_high * dt[dt$sex == "[2] Female" & dt$age >= 50 & dt$year12 == 0]$bmi_over30
    ) * calib_c5]
  }
  # --- Clean up temporary columns ---
  dt[, `:=`(bmi_under30 = NULL, bmi_over30 = NULL)]
  dt
}