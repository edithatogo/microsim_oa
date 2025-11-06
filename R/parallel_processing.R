# Parallel processing capabilities for AUS-OA package

# Load required parallel libraries
library(parallel)
library(foreach)
library(doParallel)
library(data.table)

#' Parallel Simulation Execution
#'
#' Runs multiple simulation scenarios in parallel to speed up analysis.
#'
#' @param scenarios List of scenario configurations to run in parallel
#' @param n_cores Number of CPU cores to use
#' @param export_vars Additional variables to export to parallel workers
#' @return List of simulation results for each scenario
#' @export
run_parallel_simulations <- function(scenarios, n_cores = NULL, export_vars = NULL) {
  # Determine number of cores to use
  if (is.null(n_cores)) {
    n_cores <- min(length(scenarios), parallel::detectCores() - 1)  # Leave one core free
  }
  
  # Set up parallel backend
  cl <- parallel::makeCluster(n_cores)
  
  # Export necessary functions and data to workers
  parallel::clusterExport(cl, 
                         varlist = c("simulation_cycle_fcn", "calculate_costs_fcn", 
                                   "calculate_qaly", "apply_interventions", "load_config"),
                         envir = environment())
  
  # Export additional variables if specified
  if (!is.null(export_vars)) {
    parallel::clusterExport(cl, varlist = export_vars, envir = environment())
  }
  
  # Register the cluster with foreach
  doParallel::registerDoParallel(cl)
  
  # Run simulations in parallel
  results <- foreach::foreach(
    i = seq_along(scenarios),
    .packages = c("data.table", "ausoa"),
    .export = c("simulation_cycle_fcn", "calculate_costs_fcn", "calculate_qaly", "apply_interventions")
  ) %dopar% {
    scenario <- scenarios[[i]]
    
    # Load configuration for this scenario
    scenario_config <- if (is.character(scenario$config_path)) {
      load_config(scenario$config_path)
    } else {
      scenario$config
    }
    
    # Create population for this scenario (simplified)
    pop_data <- scenario$population
    if (is.null(pop_data)) {
      pop_data <- generate_efficient_population(scenario$n_pop %||% 1000)
    }
    
    # Run simulation cycles
    result <- run_single_simulation(pop_data, scenario$years %||% 10, scenario_config)
    
    # Return results with scenario ID
    list(
      scenario_id = scenario$id %||% i,
      config = scenario_config,
      results = result,
      completed = TRUE,
      error = NULL
    )
  }
  
  # Stop the cluster
  parallel::stopCluster(cl)
  
  return(results)
}

#' Run Single Simulation Helper Function
#'
#' Helper function called by parallel execution to run a single scenario.
#'
#' @param pop_data Population data for the simulation
#' @param n_years Number of years to simulate
#' @param config Configuration for the simulation
#' @return Simulation results
run_single_simulation <- function(pop_data, n_years, config) {
  # Create a copy of the population data to work with
  current_pop <- copy(pop_data)
  
  # Initialize results tracking
  all_cycle_results <- list()
  
  # Run simulation cycles
  for (year in 1:n_years) {
    # Apply simulation cycle function
    current_pop <- simulation_cycle_fcn(current_pop, config$coefficients, current_pop,
                                      age_edges = c(50, 60, 70, 80),
                                      bmi_edges = c(25, 30, 35),
                                      am = current_pop,
                                      mort_update_counter = 0,
                                      lt = list(),
                                      eq_cust = NULL,
                                      tka_time_trend = 0)
    
    # Collect results for this cycle
    cycle_summary <- list(
      year = year,
      population_size = nrow(current_pop),
      mean_age = mean(current_pop$age, na.rm = TRUE),
      tka_rate = mean(current_pop$tka_status %in% c("Primary", "Revision"), na.rm = TRUE),
      mean_cost = mean(current_pop$total_cost, na.rm = TRUE),
      mean_qaly = mean(current_pop$qaly, na.rm = TRUE)
    )
    
    all_cycle_results[[year]] <- cycle_summary
  }
  
  return(list(
    cycle_results = all_cycle_results,
    final_population = current_pop,
    summary_stats = do.call(rbind, all_cycle_results)
  ))
}

#' Parallel Cost Calculation
#'
#' Calculates costs in parallel to speed up processing for large populations.
#'
#' @param population_data Large population dataset
#' @param cost_configs List of cost configurations to apply
#' @param n_cores Number of cores to use
#' @return Combined cost calculation results
#' @export
parallel_cost_calculation <- function(population_data, cost_configs, n_cores = NULL) {
  if (is.null(n_cores)) {
    n_cores <- min(8, parallel::detectCores() - 1)  # Use up to 8 cores
  }
  
  # Split data into chunks for parallel processing
  n_chunks <- n_cores * 2  # Create more chunks than cores for better load balancing
  chunk_size <- ceiling(nrow(population_data) / n_chunks)
  
  # Create data chunks
  data_chunks <- list()
  for (i in 1:n_chunks) {
    start_row <- (i - 1) * chunk_size + 1
    end_row <- min(i * chunk_size, nrow(population_data))
    data_chunks[[i]] <- population_data[start_row:end_row, ]
  }
  
  # Set up parallel processing
  cl <- parallel::makeCluster(n_cores)
  doParallel::registerDoParallel(cl)
  
  # Export necessary functions
  parallel::clusterExport(cl, 
                         varlist = c("calculate_costs_fcn", "cost_configs"),
                         envir = environment())
  
  # Process chunks in parallel
  chunk_results <- foreach::foreach(
    chunk = data_chunks,
    .packages = c("data.table", "ausoa")
  ) %dopar% {
    # Calculate costs for this chunk
    tryCatch({
      calc_result <- calculate_costs_fcn(chunk, cost_configs)
      return(calc_result)
    }, error = function(e) {
      warning("Error in cost calculation for chunk: ", e$message)
      return(chunk)  # Return original chunk with no cost columns if error
    })
  }
  
  # Stop cluster
  parallel::stopCluster(cl)
  
  # Combine results
  combined_result <- data.table::rbindlist(chunk_results)
  
  return(combined_result)
}

#' Parallel Bootstrap for Uncertainty Analysis
#'
#' Performs bootstrap resampling in parallel for uncertainty analysis.
#'
#' @param data Original dataset to bootstrap
#' @param n_boot Number of bootstrap samples
#' @param statistic Function to compute on each bootstrap sample
#' @param n_cores Number of CPU cores to use
#' @param ... Additional arguments to pass to the statistic function
#' @return List of bootstrap results
#' @export
parallel_bootstrap <- function(data, n_boot = 1000, statistic, n_cores = NULL, ...) {
  if (is.null(n_cores)) {
    n_cores <- min(12, parallel::detectCores() - 1)  # Use up to 12 cores, leaving 1 free
  }
  
  # Calculate boots per core to distribute work evenly
  boots_per_core <- ceiling(n_boot / n_cores)
  
  # Set up cluster
  cl <- parallel::makeCluster(n_cores)
  
  # Export necessary variables
  parallel::clusterExport(cl, 
                         varlist = c("statistic", "data"),
                         envir = environment())
  
  doParallel::registerDoParallel(cl)
  
  # Create bootstrap indices for each core
  bootstrap_indices <- list()
  for (i in 1:n_cores) {
    start_idx <- (i - 1) * boots_per_core + 1
    end_idx <- min(i * boots_per_core, n_boot)
    
    core_indices <- list()
    for (j in start_idx:end_idx) {
      core_indices[[j - start_idx + 1]] <- sample(nrow(data), replace = TRUE)
    }
    bootstrap_indices[[i]] <- core_indices
  }
  
  # Run bootstrapping in parallel
  results <- foreach::foreach(
    i = seq_along(bootstrap_indices),
    .packages = c("data.table", "ausoa"),
    .combine = 'c'
  ) %dopar% {
    core_results <- list()
    
    for (j in seq_along(bootstrap_indices[[i]])) {
      boot_idx <- bootstrap_indices[[i]][[j]]
      boot_data <- data[boot_idx, ]
      
      tryCatch({
        stat_result <- statistic(boot_data, ...)
        core_results[[j]] <- stat_result
      }, error = function(e) {
        core_results[[j]] <- NA
      })
    }
    
    core_results
  }
  
  # Cleanup
  parallel::stopCluster(cl)
  
  # Remove any NA results
  results <- results[!is.na(results)]
  
  return(results)
}

#' Parallel PSA (Probabilistic Sensitivity Analysis)
#'
#' Runs probabilistic sensitivity analysis in parallel across parameter sets.
#'
#' @param param_samples Matrix/data frame of parameter samples from distributions
#' @param base_config Base configuration to modify for each sample
#' @param n_cores Number of cores to use
#' @param run_function Function to run for each parameter set
#' @return Results for each parameter combination
#' @export
parallel_psa <- function(param_samples, base_config, n_cores = NULL, run_function = NULL) {
  if (is.null(n_cores)) {
    n_cores <- min(16, parallel::detectCores() - 1)
  }
  
  if (is.null(run_function)) {
    run_function <- function(population, config) {
      # Default simulation run
      result <- run_single_simulation(population, config$n_years %||% 10, config)
      # Extract key outcomes
      final_stats <- result$summary_stats[nrow(result$summary_stats), ]  # Last row
      return(final_stats)
    }
  }
  
  # Set up cluster
  cl <- parallel::makeCluster(n_cores)
  doParallel::registerDoParallel(cl)
  
  # Export necessary variables
  parallel::clusterExport(cl,
                         varlist = c("run_function", "base_config", "run_single_simulation"),
                         envir = environment())
  
  # Run PSA in parallel
  results <- foreach::foreach(
    i = 1:nrow(param_samples),
    .packages = c("data.table", "ausoa"),
    .export = c("run_function", "base_config", "run_single_simulation")
  ) %dopar% {
    # Create configuration for this parameter set
    param_set <- param_samples[i, ]
    config_for_run <- modify_config_with_params(base_config, param_set)
    
    # Create test population with fixed characteristics but varying parameters
    test_pop <- generate_efficient_population(config_for_run$simulation$population_size %||% 1000)
    
    # Run simulation with these parameters
    outcome <- tryCatch({
      run_function(test_pop, config_for_run)
    }, error = function(e) {
      list(
        error = e$message,
        params = param_set,
        outcome = NA
      )
    })
    
    list(params = param_set, outcome = outcome)
  }
  
  # Clean up
  parallel::stopCluster(cl)
  
  return(results)
}

# Helper function to modify config with sampled parameters
modify_config_with_params <- function(base_config, param_set) {
  # This function would modify the base configuration using the parameter set
  # Implementation depends on the specific parameters being varied
  modified_config <- base_config
  
  # Example modifications (this would be customized based on actual parameters)
  if (!is.null(param_set$tka_cost_multiplier)) {
    if (!is.null(modified_config$costs$tka_primary$hospital_stay$value)) {
      modified_config$costs$tka_primary$hospital_stay$value <- 
        modified_config$costs$tka_primary$hospital_stay$value * param_set$tka_cost_multiplier
    }
  }
  
  if (!is.null(param_set$utility_kl2)) {
    if (!is.null(modified_config$utilities$kl2)) {
      modified_config$utilities$kl2 <- param_set$utility_kl2
    }
  }
  
  return(modified_config)
}


#' Parallel Cohort Analysis
#'
#' Analyzes multiple population cohorts in parallel.
#'
#' @param cohort_definitions List of cohort definitions (filters and parameters)
#' @param base_data Base population data to filter
#' @param analysis_function Function to run on each cohort
#' @param n_cores Number of cores to use
#' @return Results for each cohort
#' @export
parallel_cohort_analysis <- function(cohort_definitions, base_data, analysis_function, n_cores = NULL) {
  if (is.null(n_cores)) {
    n_cores <- min(parallel::detectCores() - 1, length(cohort_definitions))
  }
  
  # Set up parallel backend
  cl <- parallel::makeCluster(n_cores)
  doParallel::registerDoParallel(cl)
  
  # Export necessary variables
  parallel::clusterExport(cl,
                         varlist = c("analysis_function", "base_data", "cohort_definitions"),
                         envir = environment())
  
  # Process cohorts in parallel
  results <- foreach::foreach(
    i = seq_along(cohort_definitions),
    .packages = c("data.table", "ausoa"),
    .export = c("analysis_function")
  ) %dopar% {
    cohort_def <- cohort_definitions[[i]]
    
    # Filter data for this cohort
    cohort_data <- tryCatch({
      if (is.function(cohort_def$filter)) {
        filtered_data <- cohort_def$filter(base_data)
      } else {
        # Assume it's a logical expression to evaluate
        filtered_data <- base_data[eval(parse(text = cohort_def$filter)), ]
      }
      
      # Run analysis on cohort
      cohort_result <- analysis_function(filtered_data, cohort_def$params)
      return(list(
        cohort_id = cohort_def$id %||% i,
        size = nrow(filtered_data),
        result = cohort_result,
        success = TRUE
      ))
    }, error = function(e) {
      return(list(
        cohort_id = cohort_def$id %||% i,
        size = 0,
        result = NULL,
        success = FALSE,
        error = e$message
      ))
    })
  }
  
  # Clean up
  parallel::stopCluster(cl)
  
  return(results)
}

#' Get Recommended Number of Cores
#'
#' Returns a recommended number of cores based on system resources and task type.
#'
#' @param task_type Type of task ("cpu_intensive", "io_intensive", "memory_limited")
#' @param max_cores Maximum cores to recommend (NULL for automatic)
#' @return Recommended number of cores to use
#' @export
get_optimal_cores <- function(task_type = "cpu_intensive", max_cores = NULL) {
  total_cores <- parallel::detectCores()
  
  if (is.null(max_cores)) {
    max_cores <- total_cores
  }
  
  # Adjust based on task type
  cores <- switch(task_type,
                 "cpu_intensive" = min(max_cores, total_cores - 1),  # Leave 1 free
                 "io_intensive" = min(max_cores, ceiling(total_cores * 0.75)),  # IO bound tasks
                 "memory_limited" = min(max_cores, ceiling(total_cores * 0.5)),  # Conserve memory
                 min(max_cores, total_cores - 1))  # Default to CPU intensive
  
  # Ensure we're not using more cores than available
  cores <- min(cores, total_cores)
  
  # At least use 1 core
  cores <- max(1, cores)
  
  return(cores)
}

#' Parallel Processing Wrapper for Internal Functions
#'
#' Provides parallel versions of internally-used functions where appropriate.
#'
#' @param fun_name Name of the function to run in parallel
#' @param data_list List of data to process in parallel
#' @param n_cores Number of cores to use
#' @param ... Additional args to pass to the function
#' @return Results from parallel processing
#' @export
parallel_internal_function <- function(fun_name, data_list, n_cores = NULL, ...) {
  if (is.null(n_cores)) {
    n_cores <- get_optimal_cores("cpu_intensive")
  }
  
  # Set up parallel processing
  cl <- parallel::makeCluster(n_cores)
  doParallel::registerDoParallel(cl)
  
  # Get the function by name
  func <- get(fun_name)
  
  # Process in parallel
  results <- foreach::foreach(
    data_item = data_list,
    .packages = c("data.table", "ausoa")
  ) %dopar% {
    do.call(func, args = list(data_item, ...))
  }
  
  # Clean up
  parallel::stopCluster(cl)
  
  return(results)
}

# Export functions
parallel_simulations <- run_parallel_simulations
run_parallel_psa_analysis <- parallel_psa
parallel_cost_analysis <- parallel_cost_calculation
parallel_bootstrap_analysis <- parallel_bootstrap
parallel_cohort_eval <- parallel_cohort_analysis
get_recommended_cores <- get_optimal_cores
parallel_internal_execute <- parallel_internal_function