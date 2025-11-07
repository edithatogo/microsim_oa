test_that("Modification functions exist", {
  # Test that the modification functions exist
  expect_true(exists("apply_bmi_modification"))
  expect_true(exists("apply_qaly_cost_modification"))
  expect_true(exists("apply_tka_risk_modification"))
  expect_true(exists("update_comorbidities"))
  expect_true(exists("update_pros_fcn"))

  # Check they are functions
  expect_type(apply_bmi_modification, "closure")
  expect_type(apply_qaly_cost_modification, "closure")
  expect_type(apply_tka_risk_modification, "closure")
  expect_type(update_comorbidities, "closure")
  expect_type(update_pros_fcn, "closure")

  # Verify they exist in namespace
  ausoa_ns <- ls(getNamespace("ausoa"))
  expect_true("apply_bmi_modification" %in% ausoa_ns)
  expect_true("apply_qaly_cost_modification" %in% ausoa_ns)
  expect_true("apply_tka_risk_modification" %in% ausoa_ns)
  expect_true("update_comorbidities" %in% ausoa_ns)
  expect_true("update_pros_fcn" %in% ausoa_ns)

  expect_true(TRUE) # All functions exist
})

test_that("Initialization functions exist", {
  # Test initialize_kl_grades
  expect_true(exists("initialize_kl_grades"))
  expect_type(initialize_kl_grades, "closure")

  ausoa_ns <- ls(getNamespace("ausoa"))
  expect_true("initialize_kl_grades" %in% ausoa_ns)
})
