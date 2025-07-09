# AUS-OA simulation in R
# candidate version 2 - written 28/02/2024
# original code written in MATLAB by: Chris Schilling, September 2023




# Set seed
set_seed <- sim_setup$spec[sim_setup$param == "Set seed"] %>% as.logical()
if (set_seed == TRUE) {
  seed_iter <- seed # maybe redundant but making sure the seed value is read in
  set.seed(seed_iter)
}

# load functions
source(here("scripts", "functions", "simulation_cycle_fcn.R"))
source(here("scripts", "functions", "BMI_mod_fcn.R"))
source(here("scripts", "functions", "OA_update_fcn.R"))
source(here("scripts", "functions", "TKA_update_fcn_v2.R"))
source(here("scripts", "functions", "revisions_fcn.R"))

startyear <-
  sim_setup$spec[sim_setup$param == "Simulation start year"] %>% as.integer()
numyears <-
  sim_setup$spec[sim_setup$param == "Simulation length (years)"] %>%
  as.integer()

# setup population
lt <- read_csv(here("config", "life_tables_2013.csv"), show_col_types = FALSE)

if (startyear == 2013) {
  am_file <- "am.parquet"
  am <-
    read_parquet(
      here("input", "population", am_file)
    )
} else {
  am_file <- str_glue("am_{startyear}.parquet")
  am <-
    read_parquet(
      here("input", "population", am_file)
    ) %>%
    # These variables are not in original am
    select(-kl0, -kl2, -kl3, -kl4, -kl_score)
}

bmi_edges <- c(0, 25, 30, 35, 40, 100)
age_edges <- c(min(am$age) - 1, 45, 55, 65, 75, 150)
# setup coefficents
# if probabilistic = TRUE the coefficents with distributions provide
# will be sampled per individual for the simulation run,
# if FALSE then the 'live' value from the supplied data will be used

probabilistic <-
  sim_setup$spec[sim_setup$param == "Probabilistic"] %>% as.logical()

# if calibration_mode = TRUE then the simulation will run with the supplied
calibration_mode <-
  sim_setup$spec[sim_setup$param == "Calibration mode"] %>% as.logical()

source(here("scripts", "setup_coefficents_v2.R"))

# load time trend data for use in the TKA update function
tka_time_trend <- read_excel(input_file,
  sheet = "TKA utilisation",
  range = "A53:I94", col_names = TRUE
)

# setup base OA and KL data
source(here("scripts", "setup_base_OA_KL_data_v2.R"))

# setup validation scripts and base data
# if calibration mode is FALSE then the simulation will run with the supplied
# variables via the "customise_coefficents.R" file
if (calibration_mode == TRUE) {
  print("Calibration mode is on, coefficients modifiers are being used.")
  print("The modifier values can be found in table 'customise_coefficents'")

  # get standard coefficients then modify within the loop,
  source(here("scripts", "customise_coefficents.R"))
} else {
  print("Calibration mode is off. Not using coefficients modifiers.")
  # note data loaded and set to 1 to keep code the same
  # but effectively turn off all calibration
  source(here("scripts", "customise_coefficents.R"))

  eq_cust[["BMI"]]$proportion_reduction <- 1
  eq_cust[["OA"]]$proportion_reduction <- 1
  eq_cust[["TKR"]]$proportion_reduction <- 1
}


am_all <- am
am_curr <- am
am_new <- am

# loop over years
# Note: the +1 is due to the fact that the original code is 1+indexed
for (i in 2:(numyears + 1)) {
  print(paste("Year:", i))

  am_curr$d_sf6d <- 0
  am_curr$d_bmi <- 0

  am_new$year <- am_curr$year + 1

  simulation_output_data <- simulation_cycle_fcn(
    am_curr, cycle.coefficents,
    am_new,
    age_edges, bmi_edges,
    am,
    mort_update_counter, lt,
    eq_cust,
    tka_time_trend
  ) # extract data.tables from output list

  am_curr <- simulation_output_data[["am_curr"]]
  am_new <- simulation_output_data[["am_new"]]
  if (probabilistic == FALSE) {
    write_parquet(
      am_new,
      here(
        "input",
        "population",
        str_glue("am_{am_new$year[1]}.parquet")
      )
    )
  }
  ############################## store cycle data and reset for next loop

  am_all <- rbind(am_all, am_new)


  am_curr <- am_new
}
# assign cost and QALYs

# Costs - not dependent on anything so just multiply at end
am_all$tkacost <- am_all$tka * cycle.coefficents$chs_tkacost_public *
  (1 - am_all$phi) + am_all$tka * cycle.coefficents$chs_tkacost_private *
    am_all$phi
am_all$revcost <- am_all$rev * cycle.coefficents$chs_revcost_public *
  (1 - am_all$phi) + am_all$rev * cycle.coefficents$chs_revcost_private *
    am_all$phi
am_all$rehabcost <- am_all$ir *
  cycle.coefficents$chs_inpatient_rehabcost_public *
  (1 - am_all$phi) + am_all$ir *
    cycle.coefficents$chs_inpatient_rehabcost_private * am_all$phi
am_all$oacost <- am_all$oa * cycle.coefficents$chs_oa_annualcost *
  (1 - am_all$tka1)

am_all$totalcost <- am_all$tkacost + am_all$revcost +
  am_all$rehabcost + am_all$oacost



if (set_seed == TRUE) {
  # Just to check what is the random number used in this simulation run
  am_all$seed <- seed_iter
}
