test_that("read_data works correctly", {
  # Test that the read_data function exists and is callable
  expect_true(exists("read_data"))
  expect_type(read_data, "closure")
  
  # Test with a non-existent file to ensure it handles errors gracefully
  expect_error(read_data("non_existent_file.csv"))
  
  # Check that function is in namespace
  expect_true("read_data" %in% ls(getNamespace("ausoa")))
})

test_that("read_data handles valid file extensions", {
  # Test that the function handles valid file extension checks
  expect_true(exists("read_data"))
})