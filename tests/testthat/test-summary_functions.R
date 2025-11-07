test_that("Summary functions exist", {
  # Test that the summary functions exist
  expect_true(exists("BMI_summary_data"))
  expect_true(exists("BMI_summary_plot"))
  expect_true(exists("BMI_summary_RMSE"))
  expect_true(exists("OA_summary_fcn"))

  # Check they are functions
  expect_type(BMI_summary_data, "closure")
  expect_type(BMI_summary_plot, "closure")
  expect_type(BMI_summary_RMSE, "closure")
  expect_type(OA_summary_fcn, "closure")

  # Verify they exist in namespace
  ausoa_ns <- ls(getNamespace("ausoa"))
  expect_true("BMI_summary_data" %in% ausoa_ns)
  expect_true("BMI_summary_plot" %in% ausoa_ns)
  expect_true("BMI_summary_RMSE" %in% ausoa_ns)
  expect_true("OA_summary_fcn" %in% ausoa_ns)

  expect_true(TRUE) # All functions exist
})
