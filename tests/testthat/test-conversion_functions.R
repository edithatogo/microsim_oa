test_that("Conversion functions exist", {
  # Test that the conversion functions exist
  expect_true(exists("convert_to_parquet"))
  expect_true(exists("convert_directory_to_parquet"))

  # Check they are functions
  expect_type(convert_to_parquet, "closure")
  expect_type(convert_directory_to_parquet, "closure")

  # Verify they exist in namespace
  ausoa_ns <- ls(getNamespace("ausoa"))
  expect_true("convert_to_parquet" %in% ausoa_ns)
  expect_true("convert_directory_to_parquet" %in% ausoa_ns)

  expect_true(TRUE) # All functions exist
})
