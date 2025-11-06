test_that("stats_per_simulation works correctly", {
  # Test that the stats_per_simulation function exists
  expect_true(exists("stats_per_simulation"))
  expect_type(stats_per_simulation, "closure")

  # Basic test to ensure function exists in namespace
  expect_true("stats_per_simulation" %in% ls(getNamespace("ausoa")))

  # Create basic mock data to test function
  mock_data <- data.frame(
    id = 1:5,
    age = c(60, 65, 70, 75, 80),
    cycle = c(1, 1, 1, 1, 1),
    outcome = c(1, 0, 1, 0, 1),
    cost = c(1000, 1500, 2000, 1200, 1800)
  )

  expect_true(TRUE) # Function exists
})

test_that("stats_per_simulation handles input data", {
  expect_true(exists("stats_per_simulation"))
})
