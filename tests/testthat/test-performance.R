# Performance benchmarking tests for ausoa package

library(testthat)
library(bench)
library(ausoa)

test_that("Core functions meet performance requirements", {
  # Create smaller test data for CI/CD
  test_data <- data.frame(
    id = 1:100,
    age = sample(40:80, 100, replace = TRUE),
    sex = sample(c(0, 1), 100, replace = TRUE),
    bmi = rnorm(100, mean = 28, sd = 5),
    kl_score = sample(0:4, 100, replace = TRUE, prob = c(0.3, 0.25, 0.2, 0.15, 0.1)),
    stringsAsFactors = FALSE
  )

  # Test calculate_qaly performance
  bench_result <- bench::mark(
    result <- calculate_qaly(test_data),
    iterations = 3,
    check = FALSE
  )

  # Should execute quickly (median time < 200ms for 100 records)
  median_time <- median(bench_result$time)
  median_time_ms <- median_time / 1e6 # Convert nanoseconds to milliseconds
  expect_lt(median_time_ms, 200) # Less than 200ms

  # Test apply_interventions performance
  interventions <- list(
    enabled = TRUE,
    interventions = list(
      test_intervention = list(
        type = "bmi_modification",
        start_year = 2025,
        end_year = 2030,
        parameters = list(uptake_rate = 0.5, bmi_change = -1.0)
      )
    )
  )

  bench_result2 <- bench::mark(
    result <- apply_interventions(test_data, interventions, 2025),
    iterations = 3,
    check = FALSE
  )

  median_time2 <- median(bench_result2$time)
  median_time2_ms <- median_time2 / 1e6
  expect_lt(median_time2_ms, 200) # Less than 200ms
})

test_that("Memory usage is reasonable", {
  # Create test data of increasing sizes to check scalability
  sizes <- c(50, 100, 200)

  for (size in sizes) {
    test_data <- data.frame(
      id = 1:size,
      age = sample(40:80, size, replace = TRUE),
      sex = sample(c(0, 1), size, replace = TRUE),
      bmi = rnorm(size, mean = 28, sd = 5),
      stringsAsFactors = FALSE
    )

    # Benchmark memory usage
    bench_result <- bench::mark(
      result <- calculate_qaly(test_data),
      iterations = 2,
      filter_gc = FALSE, # Keep GC info for memory measurement
      check = FALSE
    )

    # Memory should scale reasonably (less than quadratic growth expected)
    # Just make sure no excessive memory allocation occurs
    max_memory <- max(bench_result$mem_alloc)
    expect_lt(max_memory, 100 * 1024^2) # Less than 100MB
  }
})

test_that("Cost calculation scales appropriately", {
  # Create test cost data
  cost_data <- data.frame(
    tka = rep(c(0, 1), 50),
    revi = rep(c(0, 1), each = 50),
    oa = rep(1, 100),
    dead = rep(0, 100),
    ir = rep(c(0, 1), 50),
    comp = rep(c(0, 1), each = 50),
    comorbidity_cost = runif(100, 0, 5000),
    intervention_cost = runif(100, 0, 1000),
    stringsAsFactors = FALSE
  )

  config <- list(
    costs = list(
      tka_primary = list(
        hospital_stay = list(value = 15000, perspective = "healthcare_system")
      )
    )
  )

  bench_result <- bench::mark(
    result <- calculate_costs_fcn(cost_data, config),
    iterations = 3,
    check = FALSE
  )

  median_time <- median(bench_result$time) / 1e6 # Convert to ms
  expect_lt(median_time, 100) # Less than 100ms for cost calculations
})
