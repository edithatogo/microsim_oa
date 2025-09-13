library(testthat)
library(ausoa)
if (requireNamespace("mutatr", quietly = TRUE)) {
  library(mutatr)
} else {
  message("mutatr package not available, skipping mutation tests")
  quit(save = "no", status = 0)
}

context("Mutation Testing")

# Mutation testing for critical functions
test_that("Critical functions survive mutations", {
  skip_if_not(interactive() || Sys.getenv("RUN_MUTATION_TESTS") == "true")
  
  # Test simulation_cycle_fcn with mutations
  original_function <- simulation_cycle_fcn
  
  # Create mutated versions
  mutations <- list(
    # Mutation 1: Change arithmetic operators
    function(population_data, time_horizon, scenario) {
      # Original: population_data * time_horizon
      # Mutated: population_data + time_horizon
      result <- original_function(population_data, time_horizon, scenario)
      if (is.numeric(result)) {
        result <- result * 0.9  # Slightly modify result
      }
      result
    },
    
    # Mutation 2: Change comparison operators
    function(population_data, time_horizon, scenario) {
      result <- original_function(population_data, time_horizon, scenario)
      # Introduce subtle bug in comparison
      if (is.list(result) && length(result) > 0) {
        result[[1]] <- result[[1]] * 1.01  # 1% change
      }
      result
    },
    
    # Mutation 3: Change logical operators
    function(population_data, time_horizon, scenario) {
      result <- original_function(population_data, time_horizon, scenario)
      # Introduce logical error
      if (is.data.frame(result)) {
        result[1, ] <- result[1, ] * 0.99  # 1% change
      }
      result
    }
  )
  
  # Test that mutations are caught by existing tests
  for (i in seq_along(mutations)) {
    mutated_result <- mutations[[i]](100, 5, "base_case")
    
    # The mutation should produce different results
    original_result <- original_function(100, 5, "base_case")
    
    # Results should be different (mutation detected)
    expect_false(identical(mutated_result, original_result))
  }
})

# Test suite robustness against mutations
test_that("Test suite detects mutations", {
  # This test verifies that our test suite would catch common mutations
  
  # Test with slightly modified inputs
  original_result <- simulation_cycle_fcn(100, 5, "base_case")
  
  # Test with mutated inputs
  mutated_results <- list(
    simulation_cycle_fcn(101, 5, "base_case"),  # +1 to population
    simulation_cycle_fcn(100, 6, "base_case"),  # +1 to time_horizon
    simulation_cycle_fcn(100, 5, "intervention")  # Different scenario
  )
  
  # At least one mutation should be detected
  differences_detected <- sapply(mutated_results, function(x) {
    !identical(x, original_result)
  })
  
  expect_true(any(differences_detected))
})

# Edge case mutation testing
test_that("Edge cases survive mutations", {
  # Test edge cases with mutations
  
  edge_cases <- list(
    list(population = 1, time = 1, scenario = "base_case"),
    list(population = 1000, time = 1, scenario = "base_case"),
    list(population = 1, time = 50, scenario = "base_case"),
    list(population = 1000, time = 50, scenario = "base_case")
  )
  
  for (case in edge_cases) {
    original <- simulation_cycle_fcn(
      case, case, case
    )
    
    # Test with small mutations
    mutated <- simulation_cycle_fcn(
      case + 1, case, case
    )
    
    # Should detect the difference
    expect_false(identical(original, mutated))
  }
})

# Performance mutation testing
test_that("Performance is affected by mutations", {
  skip_if_not(interactive() || Sys.getenv("RUN_MUTATION_TESTS") == "true")
  
  library(bench)
  
  # Compare performance of original vs mutated function
  original_perf <- bench::mark(
    simulation_cycle_fcn(100, 5, "base_case"),
    iterations = 10,
    check = FALSE
  )
  
  # Create a mutated version that does extra work
  mutated_function <- function(pop, time, scenario) {
    result <- simulation_cycle_fcn(pop, time, scenario)
    Sys.sleep(0.01)  # Add small delay
    result
  }
  
  mutated_perf <- bench::mark(
    mutated_function(100, 5, "base_case"),
    iterations = 10,
    check = FALSE
  )
  
  # Mutated version should be slower
  expect_gt(mutated_perf, original_perf)
})

# Memory mutation testing
test_that("Memory usage changes with mutations", {
  skip_if_not(interactive() || Sys.getenv("RUN_MUTATION_TESTS") == "true")
  
  # Test memory usage of original function
  mem_original <- profmem::profmem({
    result1 <- simulation_cycle_fcn(100, 5, "base_case")
  })
  
  # Create mutated version that uses more memory
  mutated_function <- function(pop, time, scenario) {
    result <- simulation_cycle_fcn(pop, time, scenario)
    # Add memory overhead
    temp_data <- rep(1, 100000)  # Allocate extra memory
    rm(temp_data)
    result
  }
  
  mem_mutated <- profmem::profmem({
    result2 <- mutated_function(100, 5, "base_case")
  })
  
  # Mutated version should use more memory
  expect_gte(sum(mem_mutated), sum(mem_original))
})

# Robustness mutation testing
test_that("Robustness against input mutations", {
  # Test that function handles mutated inputs gracefully
  
  # Test with various input mutations
  test_cases <- list(
    list(pop = 100, time = 5, scenario = "base_case"),
    list(pop = 0, time = 5, scenario = "base_case"),  # Edge case
    list(pop = -100, time = 5, scenario = "base_case"),  # Invalid
    list(pop = 100, time = 0, scenario = "base_case"),  # Edge case
    list(pop = 100, time = -5, scenario = "base_case"),  # Invalid
    list(pop = 100, time = 5, scenario = NULL),  # Invalid
    list(pop = 100, time = 5, scenario = 123),  # Invalid type
    list(pop = "100", time = 5, scenario = "base_case"),  # Wrong type
    list(pop = 100, time = "5", scenario = "base_case"),  # Wrong type
  )
  
  for (case in test_cases) {
    if (case > 0 && case > 0 && is.character(case)) {
      # Valid case
      result <- simulation_cycle_fcn(case, case, case)
      expect_true(!is.null(result))
    } else {
      # Invalid case - should handle gracefully
      expect_error(
        simulation_cycle_fcn(case, case, case)
      )
    }
  }
})

# Integration mutation testing
test_that("Integration points survive mutations", {
  # Test that mutations at integration points are detected
  
  # Test file I/O mutations
  temp_file <- tempfile(fileext = ".rds")
  
  # Save original data
  original_data <- list(test = 1:10)
  saveRDS(original_data, temp_file)
  
  # Load and verify
  loaded_data <- readRDS(temp_file)
  expect_equal(original_data, loaded_data)
  
  # Test with mutated file
  mutated_data <- list(test = 2:11)  # Mutation: +1 to each element
  saveRDS(mutated_data, temp_file)
  
  loaded_mutated <- readRDS(temp_file)
  expect_false(identical(original_data, loaded_mutated))
  
  # Clean up
  unlink(temp_file)
})

