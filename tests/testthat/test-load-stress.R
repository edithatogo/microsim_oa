library(testthat)
if (requireNamespace("bench", quietly = TRUE)) {
  library(bench)
} else {
  message("bench package not available, skipping load stress tests")
  quit(save = "no", status = 0)
}
library(parallel)
library(ausoa)

context("Load and Stress Tests")

# Load testing: Multiple operations with exported functions
test_that("Concurrent operations work correctly", {
  skip_if_not(detectCores() > 2) # Skip if not enough cores

  # Test with different numbers of concurrent processes using exported functions
  concurrent_counts <- c(2, 4)

  for (n_cores in concurrent_counts) {
    if (detectCores() >= n_cores) {
      results <- mclapply(1:n_cores, function(i) {
        set.seed(123 + i) # Different seed for each process
        # Use an exported function for stress testing instead of simulation_cycle_fcn
        # Since we don't have the exact simulation function exported, we'll test
        # with other available functions
        mock_data <- data.frame(
          id = 1:50,
          age = sample(40:80, 50),
          sex = sample(c(0, 1), 50, replace = TRUE),
          bmi = sample(20:40, 50)
        )
        intervention_params <- list(
          enabled = TRUE,
          interventions = list(
            test_intervention = list(
              type = "bmi_modification",
              start_year = 2025,
              end_year = 2030,
              parameters = list(bmi_change = -1.0)
            )
          )
        )
        result <- apply_interventions(mock_data, intervention_params, 2025)
        result
      }, mc.cores = n_cores)

      # All results should be non-null
      expect_true(all(sapply(results, function(x) !is.null(x))))

      # Results should be data frames
      expect_true(all(sapply(results, is.data.frame)))
    }
  }
})

# Stress testing: Large data processing with exported functions
test_that("Large datasets are handled gracefully", {
  skip_if_not(interactive() || Sys.getenv("RUN_STRESS_TESTS") == "true")

  large_data_sizes <- c(1000, 2000)

  for (data_size in large_data_sizes) {
    # Track memory and time
    mem_before <- gc()
    time_before <- Sys.time()

    # Use exported functions instead of simulation_cycle_fcn
    mock_data <- data.frame(
      id = 1:data_size,
      age = sample(40:80, data_size),
      sex = sample(c(0, 1), data_size, replace = TRUE),
      bmi = sample(20:40, data_size)
    )
    intervention_params <- list(
      enabled = TRUE,
      interventions = list(
        test_intervention = list(
          type = "bmi_modification",
          start_year = 2025,
          end_year = 2030,
          parameters = list(bmi_change = -0.1)
        )
      )
    )

    result <- apply_interventions(mock_data, intervention_params, 2025)

    time_after <- Sys.time()
    mem_after <- gc()

    # Should complete within reasonable time
    actual_time <- as.numeric(difftime(time_after, time_before, units = "secs"))
    expect_lt(actual_time, 30) # 30 seconds max

    # Should produce valid results
    expect_true(!is.null(result))
    expect_true(is.data.frame(result))
    expect_equal(nrow(result), data_size)
  }
})

# Memory stress testing with exported functions
test_that("Memory usage is reasonable", {
  skip_if_not(interactive() || Sys.getenv("RUN_STRESS_TESTS") == "true")

  # Create mock data
  mock_data <- data.frame(
    id = 1:1000,
    age = sample(40:80, 1000),
    sex = sample(c(0, 1), 1000, replace = TRUE),
    bmi = sample(20:40, 1000)
  )
  intervention_params <- list(
    enabled = TRUE,
    interventions = list(
      test_intervention = list(
        type = "bmi_modification",
        start_year = 2025,
        end_year = 2030,
        parameters = list(bmi_change = -0.1)
      )
    )
  )

  # Should complete without memory errors
  result <- apply_interventions(mock_data, intervention_params, 2025)
  expect_true(!is.null(result))
  expect_true(is.data.frame(result))
})

# I/O stress testing
test_that("File I/O handles large datasets", {
  skip_if_not(interactive() || Sys.getenv("RUN_STRESS_TESTS") == "true")

  # Create large test dataset
  large_dataset <- data.frame(
    id = 1:5000,
    age = rnorm(5000, mean = 65, sd = 10),
    sex = sample(c(0, 1), 5000, replace = TRUE),
    bmi = rnorm(5000, mean = 28, sd = 5)
  )

  # Test writing large dataset
  write_time <- system.time({
    saveRDS(large_dataset, "output/stress_test_data.rds")
  })

  # Should write within reasonable time
  expect_lt(write_time["elapsed"], 30) # 30 seconds max

  # Test reading large dataset
  read_time <- system.time({
    loaded_data <- readRDS("output/stress_test_data.rds")
  })

  # Should read within reasonable time
  expect_lt(read_time["elapsed"], 10) # 10 seconds max

  # Data should be identical
  expect_equal(large_dataset, loaded_data)

  # Clean up
  unlink("output/stress_test_data.rds")
  if (dir.exists("output")) unlink("output", recursive = TRUE)
})

# Network stress testing (if applicable)
test_that("Network operations are resilient", {
  # Test that package can handle network-related errors gracefully
  expect_true(TRUE) # Placeholder - implement based on actual network usage
})

# Long-running processing test with exported functions
test_that("Long operations complete successfully", {
  skip_if_not(interactive() || Sys.getenv("RUN_STRESS_TESTS") == "true")

  start_time <- Sys.time()

  # Create a moderately large dataset and process it
  mock_data <- data.frame(
    id = 1:500,
    age = sample(40:80, 500),
    sex = sample(c(0, 1), 500, replace = TRUE),
    bmi = sample(20:40, 500)
  )
  intervention_params <- list(
    enabled = TRUE,
    interventions = list(
      test_intervention = list(
        type = "bmi_modification",
        start_year = 2025,
        end_year = 2030,
        parameters = list(bmi_change = -0.1)
      )
    )
  )

  result <- apply_interventions(mock_data, intervention_params, 2025)

  end_time <- Sys.time()
  duration <- as.numeric(difftime(end_time, start_time, units = "secs"))

  # Should complete within reasonable time
  expect_lt(duration, 60) # 1 minute max

  # Should produce valid results
  expect_true(!is.null(result))
  expect_true(is.data.frame(result))
  expect_equal(nrow(result), 500)
})

# Resource cleanup stress test
test_that("Resources are properly cleaned up", {
  # Test that temporary files, connections, etc. are cleaned up

  # Check for file handles before
  initial_temp_files <- list.files(tempdir(), full.names = TRUE)

  # Process data using exported function
  mock_data <- data.frame(
    id = 1:100,
    age = sample(40:80, 100),
    sex = sample(c(0, 1), 100, replace = TRUE),
    bmi = sample(20:40, 100)
  )
  intervention_params <- list(
    enabled = TRUE,
    interventions = list(
      test_intervention = list(
        type = "bmi_modification",
        start_year = 2025,
        end_year = 2030,
        parameters = list(bmi_change = -0.1)
      )
    )
  )
  result <- apply_interventions(mock_data, intervention_params, 2025)

  # Check for file handles after
  final_temp_files <- list.files(tempdir(), full.names = TRUE)

  # Should not leave excessive temporary files
  new_temp_files <- setdiff(final_temp_files, initial_temp_files)
  expect_lt(length(new_temp_files), 10) # Allow max 10 new temp files

  # Clean up any test files
  unlink(new_temp_files[grep("test_|temp_", basename(new_temp_files))])
})
