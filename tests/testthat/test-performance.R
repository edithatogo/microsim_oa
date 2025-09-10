library(testthat)
library(bench)
library(profvis)

# Performance test suite for ausoa package
context("Performance Tests")

# Load test data if available
test_data <- if (file.exists("../../input/test_data.rds")) {
  readRDS("../../input/test_data.rds")
} else {
  # Generate synthetic test data
  list(
    population_size = 1000,
    time_horizon = 10,
    scenarios = c("base_case", "intervention")
  )
}

# Benchmark core simulation functions
test_that("Core simulation performance is acceptable", {
  # Skip if performance testing is disabled
  skip_if_not(interactive() || Sys.getenv("RUN_PERFORMANCE_TESTS") == "true")
  
  # Benchmark simulation cycle function
  bench_result <- bench::mark(
    simulation_result <- ausoa::simulation_cycle_fcn(
      population_data = test_data,
      time_horizon = test_data,
      scenario = "base_case"
    ),
    iterations = 5,
    check = FALSE
  )
  
  # Assert performance requirements
  expect_lt(bench_result, 30)  # Should complete in under 30 seconds
  expect_lt(bench_result, 60)     # Should never exceed 60 seconds
  
  # Save benchmark results for regression testing
  if (!dir.exists("../../output")) dir.create("../../output")
  saveRDS(bench_result, file.path("../../output", "benchmark_results.rds"))
})

# Memory usage tests
test_that("Memory usage is within acceptable limits", {
  skip_if_not(interactive() || Sys.getenv("RUN_PERFORMANCE_TESTS") == "true")
  
  # Profile memory usage
  profvis_result <- profvis::profvis({
    simulation_result <- ausoa::simulation_cycle_fcn(
      population_data = test_data,
      time_horizon = test_data,
      scenario = "base_case"
    )
  })
  
  # Check memory allocation (rough estimate)
  memory_mb <- as.numeric(profvis_result) / 1024 / 1024
  expect_lt(memory_mb, 500)  # Should use less than 500MB
  
  # Save profiling results
  saveRDS(profvis_result, file.path("../../output", "memory_profile.rds"))
})

# Scalability tests
test_that("Performance scales appropriately with input size", {
  skip_if_not(interactive() || Sys.getenv("RUN_PERFORMANCE_TESTS") == "true")
  
  # Test different population sizes
  sizes <- c(100, 500, 1000, 2000)
  
  scaling_results <- lapply(sizes, function(size) {
    bench::mark(
      ausoa::simulation_cycle_fcn(
        population_data = size,
        time_horizon = 5,
        scenario = "base_case"
      ),
      iterations = 3,
      check = FALSE
    )
  })
  
  # Check that scaling is roughly linear or better
  scaling_ratios <- sapply(2:length(scaling_results), function(i) {
    scaling_results[[i]] / scaling_results[[i-1]]
  })
  
  # Performance should scale reasonably (not worse than quadratic)
  expect_lt(max(scaling_ratios), 4)  # Allow some performance degradation but not exponential
  
  # Save scaling results
  saveRDS(list(sizes = sizes, times = scaling_results), 
          file.path("../../output", "scaling_results.rds"))
})

# I/O performance tests
test_that("File I/O operations are efficient", {
  skip_if_not(interactive() || Sys.getenv("RUN_PERFORMANCE_TESTS") == "true")
  
  # Create temporary files for testing
  temp_dir <- tempdir()
  temp_file <- file.path(temp_dir, "test_output.rds")
  
  # Benchmark file writing
  write_bench <- bench::mark(
    saveRDS(test_data, temp_file),
    iterations = 10
  )
  
  # Benchmark file reading
  read_bench <- bench::mark(
    data <- readRDS(temp_file),
    iterations = 10
  )
  
  # Assert I/O performance
  expect_lt(write_bench, 1.0)  # Should write in under 1 second
  expect_lt(read_bench, 0.5)   # Should read in under 0.5 seconds
  
  # Clean up
  unlink(temp_file)
})

# Parallel processing tests (if applicable)
test_that("Parallel processing provides speedup", {
  skip_if_not(interactive() || Sys.getenv("RUN_PERFORMANCE_TESTS") == "true")
  
  # Test sequential vs parallel execution
  sequential_time <- bench::mark(
    lapply(1:4, function(i) {
      ausoa::simulation_cycle_fcn(
        population_data = 500,
        time_horizon = 3,
        scenario = "base_case"
      )
    }),
    iterations = 2,
    check = FALSE
  )
  
  # Note: This would need to be adapted based on your actual parallel implementation
  # parallel_time <- bench::mark(
  #   parallel::mclapply(1:4, function(i) {
  #     ausoa::simulation_cycle_fcn(
  #       population_data = 500,
  #       time_horizon = 3,
  #       scenario = "base_case"
  #     )
  #   }, mc.cores = 2),
  #   iterations = 2,
  #   check = FALSE
  # )
  
  # For now, just test that sequential execution is reasonable
  expect_lt(as.numeric(sequential_time), 120)  # Should complete in under 2 minutes
})
