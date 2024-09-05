# GRAPH FUNCTIONS
# This file contains functions to create graphs from the model output

# Function to generate a time series plot for overall population
f_plot_trend_overall <- function(data, x_var, y_var, shape_var, color_var, colors, x_label, y_label) {
  ggplot(data, aes_string(x = x_var, y = y_var, shape = shape_var, color = color_var)) +
    geom_point(size = 3) +
    geom_line(linewidth = 1) +
    theme(legend.position = 'top') +
    scale_color_manual(values = colors) +
    scale_x_continuous(breaks = scales::pretty_breaks()) +
    scale_y_continuous(labels = scales::comma,breaks = scales::pretty_breaks()) +
    labs(
      x = x_label,
      y = y_label,
      color = ' ',
      shape = ' '
    )
}


# Function to plot time series by age group and sex
f_plot_trend_age_sex <- 
  function(data, x_var, y_var, color_var, age_group_var, colors, x_label, y_label) {
    ggplot(data, aes_string(x = x_var, y = y_var, color = color_var)) +
      geom_point(size = 2) +
      geom_line(linewidth = 0.8) +
      facet_wrap(as.formula(paste("~", age_group_var)), scale = 'free_y') +
      theme(legend.position = 'top') +
      scale_x_continuous(breaks = scales::pretty_breaks()) +
      scale_y_continuous(labels = scales::comma,
                         breaks = scales::pretty_breaks()) +
      labs(
        x = x_label,
        y = y_label,
        color = "",
        shape = ""
      ) +
      geom_point() +
      scale_color_manual(values = colors)
  }


# Function to plot the distribution by age and sex
f_plot_distribution <- function(data, variable, yearv) {
  # Filter data for the selected year
  filtered_data <- data %>%
    filter(year %in% c(yearv) & dead == 0) %>%
    select(year, {{variable}}, age_group, sex) %>%
    group_by(year, sex, age_group) %>%
    summarise(mean_value = mean(!!sym(variable)) * 100, .groups = "drop")
  
  # Plot the distribution
  ggplot(filtered_data, aes(x = age_group, y = mean_value, fill = sex)) +
    geom_bar(stat = "identity", position = "dodge", width = 0.5) +
    scale_fill_manual(values = colors) +
    labs(x = "Age group", y = paste0(variable, " (%)"), fill = "") +
    scale_y_continuous(limits = c(0, max(filtered_data$mean_value))) +
    facet_wrap(~ year, ncol = 2) +
    theme(legend.position = "top")
}