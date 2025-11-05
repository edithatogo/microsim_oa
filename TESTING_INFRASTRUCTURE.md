# Enhanced Testing Infrastructure for AUS-OA

This document describes the comprehensive testing infrastructure implemented for the AUS-OA microsimulation library.

## Test Categories

The testing infrastructure is organized into several categories:

### 1. Unit Tests
- Located in `tests/testthat/`
- Test individual functions in isolation
- Fast execution, run on every commit

### 2. Property-Based Tests
- Located in `test-property-based.R`
- Use the `hedgehog` library for generative testing
- Test invariants and properties of the system

### 3. Mutation Tests  
- Located in `test-mutation.R`
- Test the robustness of the test suite by introducing artificial mutations
- Verify that tests can detect incorrect behavior

### 4. Performance Tests
- Located in `test-performance.R`
- Benchmark execution time and memory usage
- Test scalability and efficiency

### 5. Load and Stress Tests
- Located in `test-load-stress.R`
- Test the system under high load conditions
- Verify resource management and error handling

### 6. Recovery Tests
- Located in `test-recovery.R` (new)
- Test error handling and graceful degradation
- Verify system resilience to failures

### 7. Endurance Tests
- Located in `test-endurance.R` (new)
- Test long-running simulations and memory stability
- Verify system reliability over extended periods

### 8. API Contract Tests
- Located in `test-api-contracts.R`
- Verify interface compatibility between modules
- Test integration points and data flow

### 9. Regression Tests
- Located in `test-regression.R` (new)
- Ensure previously working functionality remains intact
- Prevent breaking changes

## Test Configuration

The testing infrastructure is configured using:

- `tests/testthat/_test_config.R`: Defines test categories, timeouts, and execution parameters
- `tests/testthat/helper-test-utils.R`: Provides utility functions for testing

## Running Tests

### All Tests
```bash
Rscript run_tests.R all
```

### Specific Test Category
```bash
Rscript run_tests.R unit          # Unit tests only
Rscript run_tests.R performance   # Performance tests
Rscript run_tests.R stress        # Stress tests (requires RUN_STRESS_TESTS=true)
Rscript run_tests.R mutation      # Mutation tests (requires RUN_MUTATION_TESTS=true)
```

### Environment Variables

- `RUN_PERFORMANCE_TESTS=true`: Enable performance tests
- `RUN_STRESS_TESTS=true`: Enable stress/load tests  
- `RUN_MUTATION_TESTS=true`: Enable mutation tests

## Test Utilities

The `helper-test-utils.R` file provides:

- `generate_test_population()`: Create synthetic population data
- `verify_simulation_result()`: Validate result structure
- `benchmark_function()`: Measure execution performance
- `check_memory_usage()`: Monitor memory consumption
- `generate_test_scenarios()`: Create standard test scenarios
- `compare_simulation_results()`: Compare simulation outputs

## Error Handling and Recovery

The recovery tests specifically verify:

- Graceful handling of invalid inputs
- Proper error messages
- Resource cleanup
- Memory management
- System stability under adverse conditions

## Continuous Integration

The enhanced testing infrastructure supports:

- Fast unit tests for every commit
- Performance and stress tests for PRs and releases
- Environment-specific test execution
- Configurable test timeouts

## Quality Metrics

The testing infrastructure helps ensure:

- **Reliability**: Through comprehensive error handling and recovery tests
- **Performance**: Through benchmarking and scalability tests
- **Maintainability**: Through API contract and regression tests
- **Robustness**: Through mutation and property-based tests