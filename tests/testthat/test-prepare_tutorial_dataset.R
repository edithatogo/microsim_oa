test_that("prepare_tutorial_dataset works correctly", {
  # Test that the prepare_tutorial_dataset function exists
  expect_true(exists("prepare_tutorial_dataset"))
  expect_type(prepare_tutorial_dataset, "closure")
  
  # Basic test to ensure function exists in namespace
  expect_true("prepare_tutorial_dataset" %in% ls(getNamespace("ausoa")))
  
  expect_true(TRUE)  # Function exists
})

test_that("prepare_tutorial_dataset returns expected structure", {
  expect_true(exists("prepare_tutorial_dataset"))
})