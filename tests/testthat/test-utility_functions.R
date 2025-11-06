test_that("Utility functions exist", {
  # Test that various utility functions exist
  expect_true(exists("f_get_means_freq_sum"))
  expect_true(exists("f_get_percent_N_from_binary"))
  expect_true(exists("f_plot_distribution"))
  expect_true(exists("f_plot_trend_age_sex"))
  expect_true(exists("f_plot_trend_overall"))

  # Check they are functions
  expect_type(f_get_means_freq_sum, "closure")
  expect_type(f_get_percent_N_from_binary, "closure")
  expect_type(f_plot_distribution, "closure")
  expect_type(f_plot_trend_age_sex, "closure")
  expect_type(f_plot_trend_overall, "closure")

  # Verify they exist in namespace
  ausoa_ns <- ls(getNamespace("ausoa"))
  expect_true("f_get_means_freq_sum" %in% ausoa_ns)
  expect_true("f_get_percent_N_from_binary" %in% ausoa_ns)
  expect_true("f_plot_distribution" %in% ausoa_ns)
  expect_true("f_plot_trend_age_sex" %in% ausoa_ns)
  expect_true("f_plot_trend_overall" %in% ausoa_ns)

  expect_true(TRUE) # All functions exist
})

test_that("get_params and get_target_indices exist", {
  # Test these specific functions
  expect_true(exists("get_params"))
  expect_true(exists("get_target_indices"))

  expect_type(get_params, "closure")
  expect_type(get_target_indices, "closure")

  ausoa_ns <- ls(getNamespace("ausoa"))
  expect_true("get_params" %in% ausoa_ns)
  expect_true("get_target_indices" %in% ausoa_ns)
})
