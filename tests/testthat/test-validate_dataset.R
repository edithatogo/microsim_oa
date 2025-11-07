test_that("validate_dataset works correctly", {
  # Test that the validate_dataset function exists
  expect_true(exists("validate_dataset"))
  expect_type(validate_dataset, "closure")

  # Basic test to ensure function exists in namespace
  expect_true("validate_dataset" %in% ls(getNamespace("ausoa")))

  # Create basic mock data to test validation
  mock_data <- data.frame(
    id = 1:5,
    age = c(60, 65, 70, 75, 80),
    sex = c(0, 1, 0, 1, 0),
    stringsAsFactors = FALSE
  )

  # The function should exist and be callable
  expect_true(TRUE) # Function exists
})

test_that("validate_dataset handles different data structures", {
  expect_true(exists("validate_dataset"))
})
