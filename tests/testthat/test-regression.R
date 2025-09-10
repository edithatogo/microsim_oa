library(testthat)
library(data.table)
library(ausoa)

test_that("Simulation produces consistent outputs", {
  # This test runs a short, deterministic simulation and compares its output
  # to a "golden" snapshot. This prevents unintended changes to model results.



  # Set a seed for reproducibility of stochastic processes
  set.seed(123)

  # --- 1. SETUP ---
  # Use test_path to construct a path relative to the tests/testthat directory.
  # This makes the test robust to changes in the working directory.
  initial_am_path <- test_path("am_curr_before_oa.rds")
  config_path <- system.file("config", package = "ausoa", mustWork = TRUE)

  # Check that the required files exist before running the test
  if (!dir.exists(config_path)) {
    stop("Configuration directory not found at: ", config_path)
  }
  if (!file.exists(initial_am_path)) {
    stop("Initial attribute matrix file not found at: ", initial_am_path)
  }

  # Load model parameters from the config directory
  params <- load_config(config_path)
  params$coefficients <- list(
    revision_model = list(
      age = list(live = 0.1),
      female = list(live = 0.1),
      bmi = list(live = 0.1),
      public = list(live = 0.1),
      early_intercept = list(live = 0.1),
      late_intercept = list(live = 0.1),
      log_time = list(live = 0.1)
    ),
    waiting_list = list(
      prioritization_scheme = list(live = "clinical"),
      capacity = list(
        total_capacity = list(live = 1000),
        public_proportion = list(live = 0.7)
      ),
      wait_time_impacts = list(
        qaly_loss_per_month = list(live = 0.01),
        additional_cost_per_month = list(live = 100),
        oa_progression_prob_per_month = list(live = 0.05)
      ),
      pathways = list(
        private_base_prob = list(live = 0.3),
        socioeconomic_weight = list(live = 0.4),
        urgency_weight = list(live = 0.3),
        private_cost_multiplier = list(live = 2.0)
      )
    )
  )

  # Load the initial attribute matrix (the population state at the start)
  am_initial <- readRDS(initial_am_path)

  # For a fast test, we use a small population subset and few cycles.
  n_test_pop <- 50
  n_test_cycles <- 2
  am_test_input <- am_initial[1:n_test_pop, ]
  setDT(am_test_input)
  am_test_input[, public := 0]

  # Robustly ensure all columns that should be numeric are converted.
  # This prevents "non-numeric argument" errors in downstream functions.
  cols_to_convert <- c(
    "age", "bmi", "oa", "kl2", "kl3", "kl4", "dead", "tka", "tka1", "tka2",
    "agetka1", "agetka2", "rev1", "revi", "pain", "function_score", "qaly",
    "year", "d_bmi", "drugoa", "age044", "age4554", "age5564", "age6574",
    "age75", "male", "female", "bmi024", "bmi2529", "bmi3034", "bmi3539",
    "bmi40", "ccount", "mhc", "comp", "ir", "public", "sf6d", "d_sf6d", "year12"
  )

  for (col in cols_to_convert) {
    if (col %in% names(am_test_input)) {
      # Handle potential factors by converting to character first
      am_test_input[[col]] <- as.numeric(as.character(am_test_input[[col]]))
    }
  }

  # Override simulation parameters for the test run
  params$simulation_setup$n_total_cycles <- n_test_cycles

  # --- 2. EXECUTION ---
  # The simulation_cycle_fcn requires several specific inputs.
  # We create mock versions of these based on the loaded params.
  am_new <- am_test_input
  age_edges <- params$simulation_setup$age_edges
  bmi_edges <- params$simulation_setup$bmi_edges

  # Create a dummy life table for the test
  lt <- data.frame(
    male_sep1_bmi0 = rep(0.001, 101),
    female_sep1_bmi0 = rep(0.0008, 101)
  )
  rownames(lt) <- 0:100

  # Create dummy customisation tables
  eq_cust <- list(
    BMI = data.frame(covariate_set = "c1", proportion_reduction = 1),
    TKR = data.frame(covariate_set = "c9_cons", proportion_reduction = 1),
    OA = data.frame(covariate_set = "c6_cons", proportion_reduction = 1)
  )

  # Create a dummy TKA time trend table
  tka_time_trend <- data.frame(Year = 2023, female4554 = 1, male4554 = 1)


  # Run the simulation loop
  am_final_state <- am_test_input

  # Get the live parameters
  live_coeffs <- get_params(params$coefficients)

  for (i in 1:n_test_cycles) {
    am_new <- data.table::copy(am_final_state)
    # The function returns a list; we need the 'am_new' element
    results_list <- simulation_cycle_fcn(
      am_curr = am_final_state,
      cycle.coefficents = live_coeffs,
      am_new = am_new,
      age_edges = age_edges,
      bmi_edges = bmi_edges,
      am = am_final_state, # Mocking 'am' with the current state
      mort_update_counter = 1, # Dummy counter
      lt = lt,
      eq_cust = eq_cust,
      tka_time_trend = tka_time_trend
    )
    am_final_state <- results_list$am_new
  }

  # --- 3. VERIFICATION ---
  # Calculate summary statistics from the final state of the population
  summary_stats <- OA_summary_fcn(am_final_state)

  # The path for the temporary output file that we will snapshot.
  # This file is created during the test run and then compared to the snapshot.
  output_file_for_snapshot <- tempfile(fileext = ".rds")
  saveRDS(summary_stats, output_file_for_snapshot)

  # Compare the output with the stored "golden" snapshot.
  # The first time this test is run, it will create the snapshot file.
  # Subsequent runs will compare against this file.
  # If the output changes, the test will fail. To update the snapshot,
  # run testthat::snapshot_review() or delete the snapshot file and re-run.
  expect_snapshot_file(output_file_for_snapshot, name = "regression-summary.rds")

  # The tempfile will be cleaned up automatically, but good practice to be explicit
  unlink(output_file_for_snapshot, force = TRUE)
})
