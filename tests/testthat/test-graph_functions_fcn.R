# tests/testthat/test-graph_functions_fcn.R
library(ausoa)
library(ggplot2)

# --- Test Setup ---
create_test_graph_data <- function(n = 20) {
  data.frame(
    year = rep(2020:2024, each = n / 5),
    age = sample(30:80, n, replace = TRUE),
    sex = sample(c("male", "female"), n, replace = TRUE),
    age_group = sample(c("30-39", "40-49", "50-59", "60-69", "70-79"), n, replace = TRUE),
    some_value = runif(n, 100, 200),
    some_other_value = runif(n, 0, 1),
    type = sample(c("A", "B"), n, replace = TRUE),
    dead = 0
  )
}

# --- Tests for f_plot_trend_overall ---

test_that("f_plot_trend_overall returns a ggplot object", {
  test_data <- create_test_graph_data()
  p <- f_plot_trend_overall(
    data = test_data,
    x_var = "year",
    y_var = "some_value",
    shape_var = "type",
    color_var = "type",
    colors = c("A" = "blue", "B" = "red"),
    x_label = "Year",
    y_label = "Some Value"
  )
  expect_true(is.ggplot(p))
})

# --- Tests for f_plot_trend_age_sex ---

test_that("f_plot_trend_age_sex returns a ggplot object", {
  test_data <- create_test_graph_data()
  p <- f_plot_trend_age_sex(
    data = test_data,
    x_var = "year",
    y_var = "some_value",
    color_var = "sex",
    age_group_var = "age_group",
    colors = c("male" = "blue", "female" = "red"),
    x_label = "Year",
    y_label = "Some Value"
  )
  expect_true(is.ggplot(p))
})

# --- Tests for f_plot_distribution ---

test_that("f_plot_distribution returns a ggplot object", {
  test_data <- create_test_graph_data()
  p <- f_plot_distribution(
    data = test_data,
    variable = "some_other_value",
    yearv = 2022,
    colors = c("male" = "blue", "female" = "red")
  )
  expect_true(is.ggplot(p))
})
