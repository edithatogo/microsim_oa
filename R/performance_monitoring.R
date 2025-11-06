#' Performance Monitoring for AUS-OA Package
#'
#' Benchmark key functions for performance and memory usage
#' @name performance_monitoring
#' @importFrom bench mark press system_time
#' @importFrom profmem profmem
NULL

# Load performance benchmarking functions
library(bench)
library(profmem)

#' Benchmark core functions of the AUS-OA package
#'
#' @param iterations Number of benchmarking iterations to run
#' @return Benchmark results for all tested functions
benchmark_core_functions <- function(iterations = 5) {
  # Create test data for benchmarking
  test_data <- data.frame(
    id = 1:1000,
    age = sample(40:85, 1000, replace = TRUE),
    sex = sample(c(0, 1), 1000, replace = TRUE),
    bmi = rnorm(1000, mean = 28, sd = 5),
    kl_score = sample(0:4, 1000, replace = TRUE, prob = c(0.3, 0.25, 0.2, 0.15, 0.1)),
    tka_status = sample(c(0, 1), 1000, replace = TRUE, prob = c(0.95, 0.05)),
    revision_status = sample(c(0, 1), 1000, replace = TRUE, prob = c(0.98, 0.02)),
    comorbidities = sample(c(0, 1, 2, 3), 1000, replace = TRUE, prob = c(0.4, 0.3, 0.2, 0.1)),
    qaly = runif(1000, min = 0.6, max = 1.0),
    stringsAsFactors = FALSE
  )
  
  # Create test cost data
  cost_test_data <- data.frame(
    tka = c(rep(0, 500), rep(1, 500)),
    revi = c(rep(0, 800), rep(1, 200)),
    oa = rep(1, 1000),
    dead = c(rep(0, 950), rep(1, 50)),
    ir = sample(c(0, 1), 1000, replace = TRUE),
    comp = sample(c(0, 1), 1000, replace = TRUE, prob = c(0.8, 0.2)),
    comorbidity_cost = runif(1000, 0, 10000),
    intervention_cost = runif(1000, 0, 2000),
    stringsAsFactors = FALSE
  )
  
  # Create test configuration
  test_config <- list(
    costs = list(
      tka_primary = list(
        hospital_stay = list(value = 15000, perspective = "healthcare_system"),
        patient_gap = list(value = 2000, perspective = "patient")
      ),
      tka_revision = list(
        hospital_stay = list(value = 20000, perspective = "healthcare_system"),
        patient_gap = list(value = 2500, perspective = "patient")
      )
    )
  )
  
  # Create test interventions
  test_interventions <- list(
    enabled = TRUE,
    interventions = list(
      bmi_intervention = list(
        type = "bmi_modification",
        start_year = 2025,
        end_year = 2030,
        parameters = list(uptake_rate = 0.6, bmi_change = -1.5)
      )
    )
  )
  
  cat("Benchmarking core functions with", nrow(test_data), "rows...\n")
  
  # Benchmark apply_interventions
  cat("Benchmarking apply_interventions...\n")
  bench_interventions <- bench::mark(
    apply_interventions(test_data, test_interventions, 2025),
    iterations = iterations,
    check = FALSE
  )
  
  # Benchmark calculate_costs_fcn
  cat("Benchmarking calculate_costs_fcn...\n")
  bench_costs <- bench::mark(
    calculate_costs_fcn(cost_test_data, test_config),
    iterations = iterations,
    check = FALSE
  )
  
  # Benchmark calculate_qaly
  cat("Benchmarking calculate_qaly...\n")
  bench_qaly <- bench::mark(
    calculate_qaly(test_data),
    iterations = iterations,
    check = FALSE
  )
  
  # Benchmark load_config
  cat("Benchmarking load_config...\n")
  temp_config <- tempfile(fileext = ".yaml")
  yaml::write_yaml(test_config, temp_config)
  bench_config <- bench::mark(
    load_config(temp_config),
    iterations = iterations,
    check = FALSE
  )
  unlink(temp_config)
  
  # Combine results
  results <- list(
    apply_interventions = bench_interventions,
    calculate_costs = bench_costs,
    calculate_qaly = bench_qaly,
    load_config = bench_config
  )
  
  return(results)
}

#' Benchmark function with memory profiling
#'
#' @param func The function to benchmark
#' @param ... Arguments to pass to the function
#' @return Profiled memory usage
profile_memory <- function(func, ...) {
  # Memory profiling
  prof_result <- profmem({
    func(...)
  }, threshold = 1024^2)  # Only show allocations > 1MB
  
  return(prof_result)
}

#' Run comprehensive performance benchmark
#'
#' Executes performance tests on all main functions
#' @param iterations Number of iterations for each test
#' @return List of all benchmark results
run_performance_benchmarks <- function(iterations = 3) {
  cat("Running comprehensive performance benchmarks...\n")
  
  # Run the benchmark
  results <- benchmark_core_functions(iterations)
  
  # Print summary
  cat("\n=== PERFORMANCE BENCHMARK SUMMARY ===\n")
  for (func_name in names(results)) {
    if (nrow(results[[func_name]]) > 0) {
      median_time <- median(results[[func_name]]$time)
      median_time_ms <- median_time / 1e6  # Convert to milliseconds
      
      cat(sprintf("%s: Median time = %.2f ms\n", func_name, median_time_ms))
    }
  }
  
  # Save results
  timestamp <- format(Sys.time(), "%Y%m%d_%H%M%S")
  filename <- paste0("performance_benchmarks_", timestamp, ".rds")
  saveRDS(results, file.path("tests/testthat", filename))
  
  cat(sprintf("\nBenchmark results saved to: %s\n", filename))
  
  return(results)
}

#' Compare performance between function versions
#'
#' @param func1 First function to compare
#' @param func2 Second function to compare
#' @param data Input data for both functions
#' @param iterations Number of iterations to run
#' @return Comparison results
compare_function_performance <- function(func1, func2, data, iterations = 5) {
  # Benchmark both functions
  # Use bench::press with a different name to avoid conflict with reserved word
  fun_list <- list(func1 = func1, func2 = func2)
  
  result_list <- list()
  for (i in seq_along(fun_list)) {
    func_name <- names(fun_list)[i]
    func <- fun_list[[i]]
    
    result_list[[func_name]] <- bench::mark(
      func(data),
      iterations = iterations,
      check = FALSE
    )
  }
  
  return(result_list)
}

#' Generate performance report
#'
#' Creates a performance report showing benchmark results
#' @param results Benchmarked results
#' @return Performance report as text
#' @export
generate_performance_report <- function(results) {
  report <- c("AUS-OA Package Performance Report", 
              replicate(50, "=", simplify = TRUE),
              "",
              "Function Performance Benchmarks:")
  
  for (func_name in names(results)) {
    if (nrow(results[[func_name]]) > 0) {
      median_time <- median(results[[func_name]]$time)
      median_time_ms <- median_time / 1e6  # Convert to milliseconds
      mem_alloc <- median(results[[func_name]]$mem_alloc)
      
      report <- c(report, 
                  sprintf("  %s:", func_name),
                  sprintf("    Median execution time: %.2f ms", median_time_ms),
                  sprintf("    Median memory allocation: %.2f MB", mem_alloc / 1024^2),
                  "")
    }
  }
  
  report <- c(report, 
              "Recommendations:",
              "  - Functions should execute in under 1000ms for reasonable dataset sizes",
              "  - Memory usage should be proportional to data size",
              "  - Consider optimizations if performance degrades significantly")
  
  return(paste(report, collapse = "\n"))
}

# Export functions
#' @export
bench_core_functions <- benchmark_core_functions

#' @export
prof_memory <- profile_memory

#' @export
run_perf_benchmarks <- run_performance_benchmarks

#' @export
compare_perf <- compare_function_performance

#' @export
gen_perf_report <- generate_performance_report