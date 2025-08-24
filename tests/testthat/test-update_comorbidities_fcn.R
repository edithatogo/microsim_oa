# tests/testthat/test-update_comorbidities_fcn.R
library(testthat)
library(ausoa)

# --- Test Setup ---
create_test_am <- function(n = 100) {
  data.frame(
    id = 1:n,
    alive = 1,
    d_sf6d = 1.0,
    comorbidity_cost = 0
  )
}

create_test_comorbidity_params <- function() {
  list(
    enabled = TRUE,
    conditions = list(
      diabetes = list(
        annual_incidence_rate = 0.1,
        annual_cost = 500,
        qaly_decrement = 0.05
      ),
      asthma = list(
        annual_incidence_rate = 0.05,
        annual_cost = 200,
        qaly_decrement = 0.02
      )
    )
  )
}

# --- Tests for update_comorbidities ---

test_that("update_comorbidities returns matrix unchanged if disabled", {
  am <- create_test_am()
  params <- list(enabled = FALSE)
  
  result <- update_comorbidities(am, params)
  
  expect_equal(result, am)
})

test_that("update_comorbidities handles no defined conditions", {
  am <- create_test_am()
  params <- list(enabled = TRUE, conditions = list())
  
  expect_warning(
    result <- update_comorbidities(am, params),
    "Comorbidity modeling is enabled, but no conditions are defined in the config."
  )
  expect_equal(result, am)
})

test_that("update_comorbidities correctly initializes new comorbidity columns", {
  am <- create_test_am(5)
  params <- create_test_comorbidity_params()
  
  result <- update_comorbidities(am, params)
  
  expect_true("has_diabetes" %in% names(result))
  expect_true("has_asthma" %in% names(result))
  expect_true(all(result$has_diabetes %in% c(0, 1)))
})

test_that("update_comorbidities applies incidence rate correctly using mocking", {
  am <- create_test_am(100)
  params <- create_test_comorbidity_params()

  # We will mock runif to return predictable values.
  # For diabetes (rate 0.1), we want the first 10 people to get it.
  # For asthma (rate 0.05), we want the next 5 people to get it.
  
  # The first call to runif is for diabetes (100 people at risk)
  # The second call is for asthma (100 people at risk)
  # We need to provide enough values for both calls.
  mock_runif_values <- c(rep(0.05, 10), rep(0.5, 90),  # First 10 get diabetes
                         rep(0.02, 5), rep(0.5, 95))   # Next 5 get asthma
  
  # A function to dispense the mock values one by one
  i <- 0
  mock_runif <- function(n) {
    start <- i + 1
    end <- i + n
    i <<- end
    mock_runif_values[start:end]
  }

  # Run the function with runif mocked
  result <- testthat::with_mocked_bindings(
    update_comorbidities(am, params),
    runif = mock_runif
  )

  # Check the results
  expect_equal(sum(result$has_diabetes), 10)
  expect_equal(sum(result$has_asthma), 5)
})

test_that("update_comorbidities applies costs and QALY decrements correctly", {
  am <- create_test_am(10)
  # Manually assign a comorbidity to test the impact calculation
  am$has_diabetes <- c(1, 1, 0, 0, 0, 0, 0, 0, 0, 0)
  am$has_asthma <- c(0, 1, 1, 0, 0, 0, 0, 0, 0, 0)
  
  params <- create_test_comorbidity_params()
  # Set incidence to 0 to isolate the impact calculation
  params$conditions$diabetes$annual_incidence_rate <- 0
  params$conditions$asthma$annual_incidence_rate <- 0
  
  result <- update_comorbidities(am, params)
  
  # Check costs
  # 2 people with diabetes (500 each), 2 with asthma (200 each), 1 with both
  # Person 1: diabetes only -> cost = 500
  # Person 2: diabetes and asthma -> cost = 500 + 200 = 700
  # Person 3: asthma only -> cost = 200
  expect_equal(result$comorbidity_cost[1], 500)
  expect_equal(result$comorbidity_cost[2], 700)
  expect_equal(result$comorbidity_cost[3], 200)
  expect_equal(sum(result$comorbidity_cost), 1400)
  
  # Check QALY decrements
  # Person 1: diabetes only -> d_sf6d = 1.0 - 0.05 = 0.95
  # Person 2: diabetes and asthma -> d_sf6d = 1.0 - 0.05 - 0.02 = 0.93
  # Person 3: asthma only -> d_sf6d = 1.0 - 0.02 = 0.98
  expect_equal(result$d_sf6d[1], 0.95)
  expect_equal(result$d_sf6d[2], 0.93)
  expect_equal(result$d_sf6d[3], 0.98)
})

test_that("update_comorbidities handles no one at risk", {
  am <- create_test_am(10)
  am$has_diabetes <- 1 # Everyone already has it
  
  params <- create_test_comorbidity_params()
  
  # No error should occur
  result <- update_comorbidities(am, params)
  
  # No new cases should be added beyond the initial 10
  expect_equal(sum(result$has_diabetes), 10)
})
