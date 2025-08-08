# GRAPH FUNCTIONS
# This file contains functions to create graphs from the model output

#' @import ggplot2
#' @importFrom dplyr filter select group_by summarise sym
#' @importFrom scales pretty_breaks comma
#' @importFrom stats as.formula
NULL

#' Plot Overall Time Series Trend
#'
#' Generates a time series plot for a given variable, showing the overall
#' trend for the entire population.
#'
#' @param data A data.frame containing the data to plot.
#' @param x_var A character string naming the x-axis variable (e.g., "year").
#' @param y_var A character string naming the y-axis variable.
#' @param shape_var A character string naming the variable for point shape.
#' @param color_var A character string naming the variable for point/line color.
#' @param colors A vector of color values to use for the plot.
#' @param x_label A character string for the x-axis label.
#' @param y_label A character string for the y-axis label.
#' @return A ggplot object.
#' @export
f_plot_trend_overall <- function(data,
                                 x_var,
                                 y_var,
                                 shape_var,
                                 color_var,
                                 colors,
                                 x_label,
                                 y_label) {
  ggplot(
    data,
    aes_string(
      x = x_var,
      y = y_var,
      shape = shape_var,
      color = color_var
    )
  ) +
    geom_point(size = 3) +
    geom_line(linewidth = 1) +
    theme(legend.position = "top") +
    scale_color_manual(values = colors) +
    scale_x_continuous(breaks = scales::pretty_breaks()) +
    scale_y_continuous(labels = scales::comma, breaks = scales::pretty_breaks()) +
    labs(
      x = x_label,
      y = y_label,
      color = " ",
      shape = " "
    )
}


#' Plot Time Series Trend by Age and Sex
#'
#' Generates a time series plot for a given variable, faceted by age group
#' and colored by sex.
#'
#' @param data A data.frame containing the data to plot.
#' @param x_var A character string naming the x-axis variable (e.g., "year").
#' @param y_var A character string naming the y-axis variable.
#' @param color_var A character string naming the variable for color
#'   (e.g., "sex").
#' @param age_group_var A character string naming the faceting variable
#'   (e.g., "age_group").
#' @param colors A vector of color values to use for the plot.
#' @param x_label A character string for the x-axis label.
#' @param y_label A character string for the y-axis label.
#' @return A ggplot object.
#' @export
f_plot_trend_age_sex <-
  function(data,
           x_var,
           y_var,
           color_var,
           age_group_var,
           colors,
           x_label,
           y_label) {
    ggplot(data, aes_string(x = x_var, y = y_var, color = color_var)) +
      geom_point(size = 2) +
      geom_line(linewidth = 0.8) +
      facet_wrap(as.formula(paste("~", age_group_var)), scales = "free_y") +
      theme(legend.position = "top") +
      scale_x_continuous(breaks = scales::pretty_breaks()) +
      scale_y_continuous(
        labels = scales::comma,
        breaks = scales::pretty_breaks()
      ) +
      labs(
        x = x_label,
        y = y_label,
        color = "",
        shape = ""
      ) +
      geom_point() +
      scale_color_manual(values = colors)
  }


#' Plot Distribution by Age and Sex for a Given Year
#'
#' Generates a bar chart showing the distribution of a variable across age
#' groups and by sex for a specific year.
#'
#' @param data A data.frame containing the data to plot.
#' @param variable The variable (unquoted) to be plotted on the y-axis.
#' @param yearv The specific year to filter the data by.
#' @return A ggplot object.
#' @export
f_plot_distribution <- function(data, variable, yearv) {
  # Filter data for the selected year
  filtered_data <- data %>%
    filter(.data$year %in% c(yearv) & .data$dead == 0) %>%
    select(.data$year, {{ variable }}, .data$age_group, .data$sex) %>%
    group_by(.data$year, .data$sex, .data$age_group) %>%
    summarise(mean_value = mean(!!sym(variable)) * 100, .groups = "drop")

  # Plot the distribution
  ggplot(
    filtered_data,
    aes(x = .data$age_group, y = .data$mean_value, fill = .data$sex)
  ) +
    geom_bar(stat = "identity", position = "dodge", width = 0.5) +
    scale_fill_manual(values = .data$colors) +
    labs(x = "Age group", y = paste0(variable, " (%)"), fill = "") +
    scale_y_continuous(limits = c(0, max(filtered_data$mean_value))) +
    facet_wrap(~ .data$year, ncol = 2) +
    theme(legend.position = "top")
}
