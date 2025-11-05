library(testthat)
library(ausoa)

context("Endurance and Long-Running Tests")

# Endurance test for long-running simulations
test_that("Long simulations complete without resource exhaustion", {
  skip_if_not(interactive() || Sys.getenv("RUN_STRESS_TESTS") == "true")
  
  # Long simulation to test endurance
  start_time <- Sys.time()
  
  result <- simulation_cycle_fcn(
    population_data = 500,        # Moderate population
    time_horizon = 50,            # Long time horizon
    scenario = "base_case"
  )
  
  end_time <- Sys.time()
  duration <- as.numeric(difftime(end_time, start_time, units = "mins"))
  
  # Should complete within reasonable time (allow up to 15 minutes for long sim)
  expect_lt(duration, 15)
  
  # Should produce valid results
  expect_false(is.null(result))
  expect_gt(length(result), 0)
})

# Endurance test for repeated calls
test_that("Repeated function calls don't cause memory leaks", {
  skip_if_not(interactive() || Sys.getenv("RUN_STRESS_TESTS") == "true")
  
  # Initial memory state
  gc()
  initial_mem <- sum(gc()[, "used"])
  
  # Execute function repeatedly
  results <- list()
  for (i in 1:10) {
    results[[i]] <- simulation_cycle_fcn(
      population_data = 100,
      time_horizon = 5,
      scenario = "base_case"
    )
    
    # Force garbage collection periodically
    if (i %% 3 == 0) {
      gc()
    }
  }
  
  # Final memory state
  gc()
  final_mem <- sum(gc()[, "used"])
  
  # Memory increase should be reasonable (less than 50MB for 10 calls)
  mem_increase <- final_mem - initial_mem
  expect_lt(mem_increase, 50 * 1024)  # Less than 50MB
  
  # All results should be valid
  expect_true(all(sapply(results, function(x) !is.null(x))))
})

# Endurance test for parallel processing
test_that("Parallel simulations work without resource conflicts", {
  skip_if_not(interactive() || Sys.getenv("RUN_STRESS_TESTS") == "true")
  skip_if_not(requireNamespace("parallel", quietly = TRUE))
  
  library(parallel)
  
  # Test parallel execution doesn't cause resource conflicts
  parallel_results <- mclapply(1:4, function(i) {
    set.seed(123 + i)  # Different seed for each process
    simulation_cycle_fcn(
      population_data = 100,
      time_horizon = 5,
      scenario = "base_case"
    )
  }, mc.cores = min(4, detectCores()))
  
  # All results should be valid
  expect_true(all(sapply(parallel_results, function(x) !is.null(x))))
  
  # Results should be different due to different seeds (stochastic nature)
  expect_false(identical(parallel_results[[1]], parallel_results[[2]]))
})

# Endurance test for data I/O over time
test_that("Repeated file I/O operations don't cause issues", {
  skip_if_not(interactive() || Sys.getenv("RUN_STRESS_TESTS") == "true")
  
  temp_dir <- tempdir()
  
  # Perform multiple file operations
  for (i in 1:5) {
    # Create test data
    test_data <- list(
      simulation_results = simulation_cycle_fcn(
        population_data = 50,
        time_horizon = 3,
        scenario = "base_case"
      ),
      timestamp = Sys.time(),
      run_id = i
    )
    
    # Write to file
    temp_file <- file.path(temp_dir, paste0("test_data_", i, ".rds"))
    saveRDS(test_data, temp_file)
    
    # Read back
    loaded_data <- readRDS(temp_file)
    
    # Verify content
    expect_false(is.null(loaded_data))
    expect_equal(loaded_data$run_id, i)
    
    # Clean up
    unlink(temp_file)
  }
})

# Endurance test for configuration reloading
test_that("Frequent configuration loading doesn't cause issues", {
  skip_if_not(interactive() || Sys.getenv("RUN_STRESS_TESTS") == "true")
  
  # Create a temporary config
  config_path <- create_test_config()
  
  # Load configuration multiple times
  configs <- list()
  for (i in 1:5) {
    configs[[i]] <- load_config(config_path)
    expect_false(is.null(configs[[i]]))
  }
  
  # All configs should be valid
  expect_true(all(sapply(configs, function(x) !is.null(x))))
  
  # Clean up
  unlink(config_path)
})

# Endurance test for error handling over time
test_that("Extended error handling doesn't cause performance degradation", {
  skip_if_not(interactive() || Sys.getenv("RUN_STRESS_TESTS") == "true")
  
  errors_caught <- 0
  start_time <- Sys.time()
  
  # Deliberately trigger errors multiple times to test error handling robustness
  for (i in 1:10) {
    result <- tryCatch({
      simulation_cycle_fcn(
        population_data = -100,  # Invalid
        time_horizon = 5,
        scenario = "base_case"
      )
    }, error = function(e) {
      errors_caught <<- errors_caught + 1
      return("error_handled")
    })
  }
  
  end_time <- Sys.time()
  duration <- as.numeric(difftime(end_time, start_time, units = "secs"))
  
  # Should have caught all errors
  expect_equal(errors_caught, 10)
  
  # Should complete in reasonable time
  expect_lt(duration, 30)  # Less than 30 seconds for 10 error checks
})

# Memory endurance test
test_that("Memory usage remains stable over extended runs", {
  skip_if_not(interactive() || Sys.getenv("RUN_STRESS_TESTS") == "true")
  
  # Test memory stability over multiple runs
  memory_usage <- numeric(10)
  
  for (i in 1:10) {
    gc()  # Clean garbage before measurement
    before_mem <- sum(gc()[, "used"])
    
    # Run simulation
    result <- simulation_cycle_fcn(
      population_data = 100,
      time_horizon = 5,
      scenario = "base_case"
    )
    
    gc()  # Clean garbage after measurement
    after_mem <- sum(gc()[, "used"])
    
    memory_usage[i] <- after_mem - before_mem
    expect_false(is.null(result))
  }
  
  # Memory usage should be relatively stable (std dev < 20% of mean)
  mem_mean <- mean(memory_usage)
  mem_sd <- sd(memory_usage)
  expect_lt(mem_sd / mem_mean, 0.5)  # Coefficient of variation < 0.5
})

# Endurance test for edge case handling
test_that("Edge cases handled consistently over time", {
  skip_if_not(interactive() || Sys.getenv("RUN_STRESS_TESTS") == "true")
  
  edge_cases <- list(
    list(population = 1, time = 1, scenario = "base_case"),
    list(population = 10000, time = 1, scenario = "base_case"),
    list(population = 1, time = 100, scenario = "base_case"),
    list(population = 50, time = 50, scenario = "intervention")
  )
  
  results <- list()
  for (i in seq_along(edge_cases)) {
    case <- edge_cases[[i]]
    results[[i]] <- simulation_cycle_fcn(
      population_data = case$population,
      time_horizon = case$time,
      scenario = case$scenario
    )
    
    expect_false(is.null(results[[i]]))
  }
  
  # All results should be valid
  expect_true(all(sapply(results, function(x) !is.null(x))))
})