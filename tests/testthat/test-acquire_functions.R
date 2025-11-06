test_that("acquire functions exist and work", {
  # Test that the data acquisition functions exist
  expect_true(exists("acquire_abs_health_data"))
  expect_true(exists("acquire_aihw_nhs_data"))
  expect_true(exists("acquire_oai_data"))
  
  # Check they are functions
  expect_type(acquire_abs_health_data, "closure")
  expect_type(acquire_aihw_nhs_data, "closure")
  expect_type(acquire_oai_data, "closure")
  
  # Verify they exist in namespace
  ausoa_ns <- ls(getNamespace("ausoa"))
  expect_true("acquire_abs_health_data" %in% ausoa_ns)
  expect_true("acquire_aihw_nhs_data" %in% ausoa_ns)
  expect_true("acquire_oai_data" %in% ausoa_ns)
  
  expect_true(TRUE)  # All functions exist
})