# scripts/generate_report.R

library(here)
library(tidyverse)
library(knitr)
library(rmarkdown)
library(ggplot2)
library(arrow)

# --- Plotting Functions (copied and adapted from 05_AUS_OA_Results.Rmd) ---

# Function to plot simulated time series with confidence intervals
plot_mean_CI <-
  function(data, y_axis_title, mean_col, lower_CI_col, upper_CI_col,
           probabilistic = FALSE, colors = c("#EE3377", "#0077BB")) {

    mean_col_enq <- enquo(mean_col)
    lower_CI_col_enq <- enquo(lower_CI_col)
    upper_CI_col_enq <- enquo(upper_CI_col)

    fig <-
      ggplot(data, aes(x = year)) +
      geom_line(
        aes(y = !!mean_col_enq, color = sex)
      ) +
      facet_grid(sex ~ age_group, scales = "free_y") +
      theme_bw(base_family = "serif") +
      theme(legend.position = "none", axis.text.x = element_text(angle = 45, hjust = 1)) +
      scale_x_continuous(breaks = scales::pretty_breaks()) +
      scale_color_manual(values = colors) +
      labs(
        title = y_axis_title,
        x = "Year",
        y = y_axis_title
      )

    if (probabilistic) {
      fig <-
        fig +
        geom_ribbon(
          aes(ymin = !!lower_CI_col_enq, ymax = !!upper_CI_col_enq, group = sex),
          fill = "blue", alpha = 0.25
        )
    }
    fig
  }


# --- Report Generation Functions ---

#' Generate a report for specified variables
#'
#' @param model_stats The data frame containing the model statistics.
#' @param selected_variables A character vector of variable names to include.
#' @param output_format The desired output format ("html", "pdf", "plots_only", "csv", "parquet").
#' @param output_dir The directory to save the report and/or plots.
#' @param probabilistic A logical indicating if the simulation was probabilistic.
#'
generate_report <- function(model_stats,
                            selected_variables,
                            output_format = "html",
                            output_dir = here("output", "custom_reports"),
                            probabilistic = FALSE) {

  if (!dir.exists(output_dir)) {
    dir.create(output_dir, recursive = TRUE)
  }

  # --- Filter Data ---

  filtered_data <- model_stats %>% filter(variable %in% selected_variables)

  # --- Save Data if requested ---

  if (output_format == "csv") {
    write_csv(filtered_data, file.path(output_dir, "custom_report_data.csv"))
    print(paste("Data saved to", file.path(output_dir, "custom_report_data.csv")))
    return()
  } else if (output_format == "parquet") {
    write_parquet(filtered_data, file.path(output_dir, "custom_report_data.parquet"))
    print(paste("Data saved to", file.path(output_dir, "custom_report_data.parquet")))
    return()
  }

  # --- Generate and Save Plots ---

  plot_list <- list()
  for (var in selected_variables) {

    plot_data <- filtered_data %>% filter(variable == var)

    if (nrow(plot_data) > 0) {

      title <- unique(plot_data$description)

      # Generate the plot
      p <- plot_mean_CI(
        data = plot_data,
        y_axis_title = title,
        mean_col = Mean_mean,
        lower_CI_col = Mean_lower_CI,
        upper_CI_col = Mean_upper_CI,
        probabilistic = probabilistic
      )

      plot_list[[var]] <- p

      if (output_format == "plots_only") {
        ggsave(
          filename = file.path(output_dir, paste0(var, "_timeseries.png")),
          plot = p,
          device = ragg::agg_png,
          width = 10,
          height = 6,
          dpi = 300
        )
      }
    }
  }

  if (output_format == "plots_only") {
    print(paste("Plots saved in", output_dir))
    return()
  }

  # --- Generate R Markdown Report ---

  template_path <- here("templates", "custom_report_template.Rmd")

  # Render the Rmd file
  render(
    template_path,
    output_format = paste0(output_format, "_document"),
    output_dir = output_dir,
    output_file = "custom_report",
    params = list(
      plot_list = plot_list,
      selected_variables = selected_variables
    ),
    envir = new.env(parent = globalenv()) # Pass plot_list to the rendering environment
  )

  print(paste("Report generated in", output_dir))
}


# --- Example Usage ---

run_custom_report_example <- function() {

  # Create a dummy Model_stats dataframe
  Model_stats <- expand.grid(
    variable = c("bmi_overweight_or_obese", "oa", "tka"),
    year = 2020:2029,
    sex = c("Male", "Female"),
    age_group = c("45-54", "55-64")
  ) %>%
  as_tibble() %>%
  mutate(
    description = case_when(
      variable == "bmi_overweight_or_obese" ~ "BMI Overweight or Obese",
      variable == "oa" ~ "Osteoarthritis",
      variable == "tka" ~ "Total Knee Arthroplasty"
    ),
    Mean_mean = runif(n(), 5, 20),
    Mean_lower_CI = Mean_mean - runif(n(), 1, 2),
    Mean_upper_CI = Mean_mean + runif(n(), 1, 2)
  )

  # --- User Selections ---
  vars_to_plot <- c("bmi_overweight_or_obese", "tka")
  report_format <- "csv" # or "pdf", "plots_only", "html", "parquet"

  generate_report(
    model_stats = Model_stats,
    selected_variables = vars_to_plot,
    output_format = report_format,
    probabilistic = TRUE
  )
}

# To run the example, uncomment the following line:
# run_custom_report_example()
