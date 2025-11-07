#' PSA Visualization Module
#'
#' This module provides comprehensive visualization functions for Probabilistic
#' Sensitivity Analysis (PSA) results in the AUS-OA simulation model.
#'
#' Key Functions:
#' - plot_ceac(): Cost-Effectiveness Acceptability Curves
#' - plot_psa_scatter(): PSA scatter plots
#' - plot_tornado_diagram(): Tornado diagrams for parameter influence
#' - plot_convergence_diagnostics(): Convergence assessment plots
#' - create_psa_visualization_report(): Generate complete visualization report

#' Plot Cost-Effectiveness Acceptability Curve (CEAC)
#'
#' @param ceac_data CEAC data from generate_ceac()
#' @param wtp_threshold Willingness-to-pay threshold (optional)
#' @param title Plot title
#' @param subtitle Plot subtitle
#' @return ggplot object
plot_ceac <- function(ceac_data, wtp_threshold = NULL, title = "Cost-Effectiveness Acceptability Curve",
                      subtitle = "Probability of Cost-Effectiveness vs Willingness-to-Pay") {
  if (is.null(ceac_data) || nrow(ceac_data) == 0) {
    warning("No CEAC data available for plotting")
    return(NULL)
  }

  # Create base plot
  p <- ggplot2::ggplot(ceac_data, ggplot2::aes(x = wtp, y = probability_ce)) +
    ggplot2::geom_line(color = "#2E86AB", linewidth = 1.2) +
    ggplot2::geom_point(color = "#2E86AB", size = 2) +
    ggplot2::labs(
      title = title,
      subtitle = subtitle,
      x = "Willingness-to-Pay Threshold (AUD per QALY)",
      y = "Probability Cost-Effective"
    ) +
    ggplot2::theme_minimal() +
    ggplot2::theme(
      plot.title = ggplot2::element_text(size = 14, face = "bold"),
      plot.subtitle = ggplot2::element_text(size = 10, color = "gray50"),
      axis.title = ggplot2::element_text(size = 12),
      axis.text = ggplot2::element_text(size = 10)
    ) +
    ggplot2::scale_y_continuous(labels = scales::percent_format()) +
    ggplot2::scale_x_continuous(labels = scales::comma_format())

  # Add WTP threshold line if provided
  if (!is.null(wtp_threshold)) {
    threshold_data <- ceac_data[which.min(abs(ceac_data$wtp - wtp_threshold)), ]

    p <- p +
      ggplot2::geom_vline(
        xintercept = wtp_threshold, linetype = "dashed",
        color = "#A23B72", linewidth = 1
      ) +
      ggplot2::geom_hline(
        yintercept = threshold_data$probability_ce,
        linetype = "dashed", color = "#A23B72", linewidth = 1
      ) +
      ggplot2::annotate("text",
        x = wtp_threshold + max(ceac_data$wtp) * 0.05,
        y = threshold_data$probability_ce + 0.05,
        label = sprintf(
          "WTP: $%s\nProb: %.1f%%",
          format(wtp_threshold, big.mark = ","),
          threshold_data$probability_ce * 100
        ),
        hjust = 0, vjust = 0, size = 3, color = "#A23B72"
      )
  }

  # Add expected ICER reference line
  if ("expected_icer" %in% names(ceac_data)) {
    expected_icer <- unique(ceac_data$expected_icer)
    if (!is.na(expected_icer) && expected_icer > 0) {
      p <- p +
        ggplot2::geom_vline(
          xintercept = expected_icer, linetype = "dotted",
          color = "#F18F01", linewidth = 1
        ) +
        ggplot2::annotate("text",
          x = expected_icer + max(ceac_data$wtp) * 0.02,
          y = 0.9,
          label = sprintf(
            "Expected ICER:\n$%s",
            format(expected_icer, big.mark = ",")
          ),
          hjust = 0, vjust = 1, size = 3, color = "#F18F01"
        )
    }
  }

  return(p)
}

#' Plot PSA Scatter Plot
#'
#' @param psa_results PSA results
#' @param wtp_threshold Willingness-to-pay threshold for ICER reference
#' @param title Plot title
#' @return ggplot object
plot_psa_scatter <- function(psa_results, wtp_threshold = 50000,
                             title = "PSA Scatter Plot: Incremental Costs vs QALYs") {
  # Extract successful results
  successful_results <- Filter(
    function(x) is.list(x) && !("error" %in% names(x)),
    psa_results$simulation_results
  )

  if (length(successful_results) == 0) {
    warning("No successful simulations for scatter plot")
    return(NULL)
  }

  # Extract data
  scatter_data <- data.frame(
    incremental_cost = sapply(successful_results, function(x) x$total_cost),
    incremental_qaly = sapply(successful_results, function(x) x$total_qaly)
  )

  # Calculate ICER for each point
  scatter_data$icer <- scatter_data$incremental_cost / scatter_data$incremental_qaly

  # Determine cost-effectiveness
  scatter_data$cost_effective <- scatter_data$icer <= wtp_threshold

  # Create plot
  p <- ggplot2::ggplot(scatter_data, ggplot2::aes(
    x = incremental_qaly, y = incremental_cost,
    color = cost_effective
  )) +
    ggplot2::geom_point(alpha = 0.6, size = 2) +
    ggplot2::geom_hline(yintercept = 0, linetype = "dashed", color = "gray50") +
    ggplot2::geom_vline(xintercept = 0, linetype = "dashed", color = "gray50") +
    ggplot2::labs(
      title = title,
      x = "Incremental QALYs",
      y = "Incremental Cost (AUD)",
      color = sprintf("Cost-Effective\n(WTP = $%s/QALY)", format(wtp_threshold, big.mark = ","))
    ) +
    ggplot2::theme_minimal() +
    ggplot2::theme(
      plot.title = ggplot2::element_text(size = 14, face = "bold"),
      axis.title = ggplot2::element_text(size = 12),
      axis.text = ggplot2::element_text(size = 10),
      legend.position = "bottom"
    ) +
    ggplot2::scale_y_continuous(labels = scales::comma_format()) +
    ggplot2::scale_color_manual(values = c("#A23B72", "#2E86AB"))

  # Add WTP threshold line
  if (wtp_threshold > 0) {
    max_qaly <- max(scatter_data$incremental_qaly, na.rm = TRUE)
    wtp_line <- data.frame(
      qaly = c(0, max_qaly),
      cost = c(0, wtp_threshold * max_qaly)
    )

    p <- p +
      ggplot2::geom_line(
        data = wtp_line, ggplot2::aes(x = qaly, y = cost),
        linetype = "dashed", color = "#F18F01", linewidth = 1
      ) +
      ggplot2::annotate("text",
        x = max_qaly * 0.7,
        y = wtp_threshold * max_qaly * 0.8,
        label = sprintf("WTP = $%s/QALY", format(wtp_threshold, big.mark = ",")),
        angle = 45, size = 3, color = "#F18F01"
      )
  }

  return(p)
}

#' Plot Convergence Diagnostics
#'
#' @param psa_results PSA results with convergence assessment
#' @param title Plot title
#' @return ggplot object or list of plots
plot_convergence_diagnostics <- function(psa_results, title = "PSA Convergence Diagnostics") {
  if (!"convergence_assessment" %in% names(psa_results)) {
    warning("No convergence assessment available")
    return(NULL)
  }

  conv <- psa_results$convergence_assessment

  if (!"cost_convergence" %in% names(conv) || !"qaly_convergence" %in% names(conv)) {
    warning("Incomplete convergence data")
    return(NULL)
  }

  # Create convergence metrics data
  metrics_data <- data.frame(
    outcome = c("Cost", "QALY"),
    ci_width = c(conv$cost_convergence$ci_width, conv$qaly_convergence$ci_width),
    relative_se = c(conv$cost_convergence$relative_se, conv$qaly_convergence$relative_se),
    ci_converged = c(conv$cost_convergence$ci_width_converged, conv$qaly_convergence$ci_width_converged),
    rse_converged = c(conv$cost_convergence$rse_converged, conv$qaly_convergence$rse_converged)
  )

  # CI Width plot
  p1 <- ggplot2::ggplot(metrics_data, ggplot2::aes(x = outcome, y = ci_width, fill = ci_converged)) +
    ggplot2::geom_bar(stat = "identity", alpha = 0.7) +
    ggplot2::geom_hline(yintercept = 0.05, linetype = "dashed", color = "red") +
    ggplot2::labs(
      title = "Confidence Interval Width",
      subtitle = "Target: <=5% of mean",
      x = "Outcome",
      y = "CI Width (% of mean)"
    ) +
    ggplot2::theme_minimal() +
    ggplot2::scale_fill_manual(values = c("#A23B72", "#2E86AB")) +
    ggplot2::scale_y_continuous(labels = scales::percent_format())

  # Relative SE plot
  p2 <- ggplot2::ggplot(metrics_data, ggplot2::aes(x = outcome, y = relative_se, fill = rse_converged)) +
    ggplot2::geom_bar(stat = "identity", alpha = 0.7) +
    ggplot2::geom_hline(yintercept = 0.02, linetype = "dashed", color = "red") +
    ggplot2::labs(
      title = "Relative Standard Error",
      subtitle = "Target: <=2% of mean",
      x = "Outcome",
      y = "Relative SE (% of mean)"
    ) +
    ggplot2::theme_minimal() +
    ggplot2::scale_fill_manual(values = c("#A23B72", "#2E86AB")) +
    ggplot2::scale_y_continuous(labels = scales::percent_format())

  return(list(ci_width_plot = p1, relative_se_plot = p2))
}

#' Plot Tornado Diagram for Parameter Influence
#'
#' @param influence_data Parameter influence data from analyze_parameter_influence()
#' @param top_n Number of top parameters to display
#' @param title Plot title
#' @param subtitle Plot subtitle
#' @return ggplot object
plot_tornado_diagram <- function(influence_data, top_n = 10,
                                 title = "Parameter Influence (Tornado Diagram)",
                                 subtitle = "Impact of Parameter Uncertainty on ICER") {
  if (is.null(influence_data) || length(influence_data) == 0) {
    warning("No parameter influence data available for tornado diagram")
    return(NULL)
  }

  # Convert to data frame
  tornado_data <- data.frame()
  for (param_name in names(influence_data)) {
    param_data <- influence_data[[param_name]]
    tornado_data <- rbind(tornado_data, data.frame(
      parameter = param_name,
      influence = param_data$influence,
      min_outcome = param_data$min_outcome,
      max_outcome = param_data$max_outcome
    ))
  }

  # Sort by influence and take top N
  tornado_data <- tornado_data[order(tornado_data$influence, decreasing = TRUE), ]
  if (nrow(tornado_data) > top_n) {
    tornado_data <- tornado_data[1:top_n, ]
  }

  # Create tornado plot data
  plot_data <- data.frame()
  for (i in 1:nrow(tornado_data)) {
    param <- tornado_data$parameter[i]
    min_val <- tornado_data$min_outcome[i]
    max_val <- tornado_data$max_outcome[i]
    base_val <- (min_val + max_val) / 2

    plot_data <- rbind(plot_data, data.frame(
      parameter = param,
      value = min_val,
      type = "min",
      base = base_val
    ))
    plot_data <- rbind(plot_data, data.frame(
      parameter = param,
      value = max_val,
      type = "max",
      base = base_val
    ))
  }

  # Create tornado diagram
  p <- ggplot2::ggplot(plot_data) +
    ggplot2::geom_segment(
      ggplot2::aes(
        x = base, xend = value, y = reorder(parameter, influence),
        yend = reorder(parameter, influence)
      ),
      color = "gray70", linewidth = 1
    ) +
    ggplot2::geom_point(
      ggplot2::aes(
        x = value, y = reorder(parameter, influence),
        color = type, shape = type
      ),
      size = 3
    ) +
    ggplot2::geom_vline(xintercept = 0, linetype = "dashed", color = "red", alpha = 0.7) +
    ggplot2::labs(
      title = title,
      subtitle = subtitle,
      x = "ICER (AUD per QALY)",
      y = "Parameter"
    ) +
    ggplot2::scale_color_manual(
      values = c("min" = "#E74C3C", "max" = "#27AE60"),
      labels = c("min" = "Minimum", "max" = "Maximum")
    ) +
    ggplot2::scale_shape_manual(
      values = c("min" = 16, "max" = 17),
      labels = c("min" = "Minimum", "max" = "Maximum")
    ) +
    ggplot2::theme_minimal() +
    ggplot2::theme(
      plot.title = ggplot2::element_text(size = 14, face = "bold"),
      plot.subtitle = ggplot2::element_text(size = 10, color = "gray50"),
      axis.title = ggplot2::element_text(size = 12),
      axis.text = ggplot2::element_text(size = 10),
      legend.title = ggplot2::element_blank(),
      legend.position = "top"
    ) +
    ggplot2::scale_x_continuous(labels = scales::comma_format())

  return(p)
}

#' Plot Parameter Correlation Matrix
#'
#' @param correlation_data Correlation data from analyze_parameter_correlations()
#' @param title Plot title
#' @param subtitle Plot subtitle
#' @return ggplot object
plot_parameter_correlations <- function(correlation_data,
                                        title = "Parameter Correlation Matrix",
                                        subtitle = "Pearson Correlations with ICER") {
  if (is.null(correlation_data) || is.null(correlation_data$correlation_data)) {
    warning("No correlation data available for plotting")
    return(NULL)
  }

  corr_df <- correlation_data$correlation_data

  # Create correlation plot
  p <- ggplot2::ggplot(corr_df, ggplot2::aes(
    x = reorder(parameter, abs_correlation),
    y = pearson_correlation
  )) +
    ggplot2::geom_bar(stat = "identity", fill = "#3498DB", alpha = 0.7) +
    ggplot2::geom_hline(yintercept = 0, linetype = "dashed", color = "gray50") +
    ggplot2::geom_hline(
      yintercept = c(-0.3, 0.3), linetype = "dotted",
      color = "orange", alpha = 0.7
    ) +
    ggplot2::labs(
      title = title,
      subtitle = subtitle,
      x = "Parameter",
      y = "Pearson Correlation"
    ) +
    ggplot2::theme_minimal() +
    ggplot2::theme(
      plot.title = ggplot2::element_text(size = 14, face = "bold"),
      plot.subtitle = ggplot2::element_text(size = 10, color = "gray50"),
      axis.title = ggplot2::element_text(size = 12),
      axis.text = ggplot2::element_text(size = 10),
      axis.text.x = ggplot2::element_text(angle = 45, hjust = 1)
    ) +
    ggplot2::scale_y_continuous(limits = c(-1, 1)) +
    ggplot2::geom_text(
      ggplot2::aes(label = sprintf("%.2f", pearson_correlation)),
      vjust = ifelse(corr_df$pearson_correlation >= 0, -0.5, 1.5),
      size = 3
    )

  return(p)
}

#' Plot Sensitivity Analysis Results
#'
#' @param sensitivity_results Sensitivity analysis results
#' @param title Plot title
#' @param subtitle Plot subtitle
#' @return ggplot object
plot_sensitivity_analysis <- function(sensitivity_results,
                                      title = "Sensitivity Analysis",
                                      subtitle = "Parameter Impact on ICER") {
  if (is.null(sensitivity_results) || length(sensitivity_results) == 0) {
    warning("No sensitivity analysis data available for plotting")
    return(NULL)
  }

  # Convert to data frame
  sens_data <- data.frame()
  for (param_name in names(sensitivity_results)) {
    param_data <- sensitivity_results[[param_name]]
    sens_data <- rbind(sens_data, data.frame(
      parameter = param_name,
      elasticity = param_data$elasticity,
      outcome_change = param_data$outcome_change,
      sensitivity_ratio = param_data$sensitivity_ratio
    ))
  }

  # Remove NA values
  sens_data <- sens_data[complete.cases(sens_data), ]

  if (nrow(sens_data) == 0) {
    warning("No valid sensitivity data available for plotting")
    return(NULL)
  }

  # Sort by absolute elasticity
  sens_data <- sens_data[order(abs(sens_data$elasticity), decreasing = TRUE), ]

  # Create sensitivity plot
  p <- ggplot2::ggplot(sens_data, ggplot2::aes(
    x = reorder(parameter, abs(elasticity)),
    y = elasticity
  )) +
    ggplot2::geom_bar(
      stat = "identity",
      fill = ifelse(sens_data$elasticity >= 0, "#27AE60", "#E74C3C"),
      alpha = 0.7
    ) +
    ggplot2::geom_hline(yintercept = 0, linetype = "dashed", color = "gray50") +
    ggplot2::labs(
      title = title,
      subtitle = subtitle,
      x = "Parameter",
      y = "Elasticity"
    ) +
    ggplot2::theme_minimal() +
    ggplot2::theme(
      plot.title = ggplot2::element_text(size = 14, face = "bold"),
      plot.subtitle = ggplot2::element_text(size = 10, color = "gray50"),
      axis.title = ggplot2::element_text(size = 12),
      axis.text = ggplot2::element_text(size = 10),
      axis.text.x = ggplot2::element_text(angle = 45, hjust = 1)
    ) +
    ggplot2::geom_text(
      ggplot2::aes(label = sprintf("%.2f", elasticity)),
      vjust = ifelse(sens_data$elasticity >= 0, -0.5, 1.5),
      size = 3
    )

  return(p)
}

#' Create Comprehensive PSA Visualization Report
#'
#' @param psa_results Complete PSA results
#' @param output_dir Directory to save plots
#' @param wtp_threshold Willingness-to-pay threshold
#' @return List of generated plots and files
create_psa_visualization_report <- function(psa_results, output_dir = "output/plots",
                                            wtp_threshold = 50000) {
  # Create output directory
  if (!dir.exists(output_dir)) {
    dir.create(output_dir, recursive = TRUE)
  }

  report <- list()
  timestamp <- format(Sys.time(), "%Y%m%d_%H%M%S")

  # 1. CEAC Plot
  if ("ceac" %in% names(psa_results) && !is.null(psa_results$ceac)) {
    ceac_plot <- plot_ceac(psa_results$ceac, wtp_threshold)
    if (!is.null(ceac_plot)) {
      ceac_file <- file.path(output_dir, paste0("ceac_", timestamp, ".png"))
      ggplot2::ggsave(ceac_file, ceac_plot, width = 8, height = 6, dpi = 300)
      report$ceac <- list(plot = ceac_plot, file = ceac_file)
    }
  }

  # 2. PSA Scatter Plot
  scatter_plot <- plot_psa_scatter(psa_results, wtp_threshold)
  if (!is.null(scatter_plot)) {
    scatter_file <- file.path(output_dir, paste0("psa_scatter_", timestamp, ".png"))
    ggplot2::ggsave(scatter_file, scatter_plot, width = 8, height = 6, dpi = 300)
    report$scatter <- list(plot = scatter_plot, file = scatter_file)
  }

  # 3. Convergence Diagnostics
  conv_plots <- plot_convergence_diagnostics(psa_results)
  if (!is.null(conv_plots)) {
    conv_file1 <- file.path(output_dir, paste0("convergence_ci_", timestamp, ".png"))
    conv_file2 <- file.path(output_dir, paste0("convergence_rse_", timestamp, ".png"))

    ggplot2::ggsave(conv_file1, conv_plots$ci_width_plot, width = 6, height = 4, dpi = 300)
    ggplot2::ggsave(conv_file2, conv_plots$relative_se_plot, width = 6, height = 4, dpi = 300)

    report$convergence <- list(
      plots = conv_plots,
      files = list(ci_width = conv_file1, relative_se = conv_file2)
    )
  }

  # 4. Tornado Diagram
  tornado_plot <- plot_tornado_diagram(psa_results)
  if (!is.null(tornado_plot)) {
    tornado_file <- file.path(output_dir, paste0("tornado_", timestamp, ".png"))
    ggplot2::ggsave(tornado_file, tornado_plot, width = 8, height = 6, dpi = 300)
    report$tornado <- list(plot = tornado_plot, file = tornado_file)
  }

  # 5. Parameter Distributions
  param_plots <- plot_parameter_distributions(psa_results)
  if (!is.null(param_plots)) {
    if (is.list(param_plots) && !inherits(param_plots, "ggplot")) {
      # Multiple plots
      param_files <- list()
      for (i in seq_along(param_plots)) {
        param_name <- names(param_plots)[i]
        param_file <- file.path(output_dir, paste0("param_dist_", param_name, "_", timestamp, ".png"))
        ggplot2::ggsave(param_file, param_plots[[i]], width = 6, height = 4, dpi = 300)
        param_files[[param_name]] <- param_file
      }
      report$parameter_distributions <- list(plots = param_plots, files = param_files)
    } else {
      # Single plot
      param_file <- file.path(output_dir, paste0("param_distributions_", timestamp, ".png"))
      ggplot2::ggsave(param_file, param_plots, width = 8, height = 6, dpi = 300)
      report$parameter_distributions <- list(plot = param_plots, file = param_file)
    }
  }

  # Save report metadata
  report_file <- file.path(output_dir, paste0("visualization_report_", timestamp, ".rds"))
  saveRDS(report, file = report_file)
  report$metadata <- list(
    timestamp = Sys.time(),
    output_dir = output_dir,
    wtp_threshold = wtp_threshold,
    report_file = report_file
  )

  return(report)
}

#' Plot CEAC with Bootstrap Confidence Intervals
#'
#' @param ceac_bootstrap CEAC data with bootstrap confidence intervals
#' @param wtp_threshold Willingness-to-pay threshold (optional)
#' @param title Plot title
#' @param subtitle Plot subtitle
#' @return ggplot object
plot_ceac_bootstrap <- function(ceac_bootstrap, wtp_threshold = NULL,
                                title = "CEAC with Bootstrap Confidence Intervals",
                                subtitle = "Probability Cost-Effective vs Willingness-to-Pay") {
  if (is.null(ceac_bootstrap) || nrow(ceac_bootstrap) == 0) {
    warning("No CEAC bootstrap data available for plotting")
    return(NULL)
  }

  # Create base plot
  p <- ggplot2::ggplot(ceac_bootstrap, ggplot2::aes(x = wtp, y = probability_ce)) +
    ggplot2::geom_line(color = "#2E86AB", linewidth = 1.2) +
    ggplot2::geom_point(color = "#2E86AB", size = 2) +
    ggplot2::geom_ribbon(ggplot2::aes(ymin = ci_lower, ymax = ci_upper),
      fill = "#2E86AB", alpha = 0.2
    ) +
    ggplot2::labs(
      title = title,
      subtitle = subtitle,
      x = "Willingness-to-Pay Threshold (AUD per QALY)",
      y = "Probability Cost-Effective"
    ) +
    ggplot2::theme_minimal() +
    ggplot2::theme(
      plot.title = ggplot2::element_text(size = 14, face = "bold"),
      plot.subtitle = ggplot2::element_text(size = 10, color = "gray50"),
      axis.title = ggplot2::element_text(size = 12),
      axis.text = ggplot2::element_text(size = 10)
    ) +
    ggplot2::scale_y_continuous(labels = scales::percent_format()) +
    ggplot2::scale_x_continuous(labels = scales::comma_format())

  # Add WTP threshold line if provided
  if (!is.null(wtp_threshold)) {
    threshold_data <- ceac_bootstrap[which.min(abs(ceac_bootstrap$wtp - wtp_threshold)), ]

    p <- p +
      ggplot2::geom_vline(
        xintercept = wtp_threshold, linetype = "dashed",
        color = "#A23B72", linewidth = 1
      ) +
      ggplot2::geom_hline(
        yintercept = threshold_data$probability_ce,
        linetype = "dashed", color = "#A23B72", linewidth = 1
      ) +
      ggplot2::annotate("text",
        x = wtp_threshold + max(ceac_bootstrap$wtp) * 0.05,
        y = threshold_data$probability_ce + 0.05,
        label = sprintf(
          "WTP: $%s\nProb: %.1f%%\n(95%% CI: %.1f%% - %.1f%%)",
          format(wtp_threshold, big.mark = ","),
          threshold_data$probability_ce * 100,
          threshold_data$ci_lower * 100,
          threshold_data$ci_upper * 100
        ),
        hjust = 0, vjust = 0, size = 3, color = "#A23B72"
      )
  }

  # Add expected ICER reference line
  if ("expected_icer" %in% names(ceac_bootstrap)) {
    expected_icer <- unique(ceac_bootstrap$expected_icer)
    if (!is.na(expected_icer) && expected_icer > 0) {
      p <- p +
        ggplot2::geom_vline(
          xintercept = expected_icer, linetype = "dotted",
          color = "#F18F01", linewidth = 1
        ) +
        ggplot2::annotate("text",
          x = expected_icer + max(ceac_bootstrap$wtp) * 0.02,
          y = 0.9,
          label = sprintf(
            "Expected ICER:\n$%s",
            format(expected_icer, big.mark = ",")
          ),
          hjust = 0, vjust = 1, size = 3, color = "#F18F01"
        )
    }
  }

  return(p)
}

#' Plot Net Monetary Benefit (NMB) Distribution
#'
#' @param nmb_stats NMB statistics from calculate_nmb()
#' @param title Plot title
#' @return ggplot object
plot_nmb_distribution <- function(nmb_stats, title = "Net Monetary Benefit Distribution") {
  if (is.null(nmb_stats)) {
    warning("No NMB statistics available for plotting")
    return(NULL)
  }

  # Create data for plotting (simplified - would need actual NMB values for full histogram)
  # For now, create a summary plot
  nmb_data <- data.frame(
    metric = c("Mean NMB", "Median NMB", "95% CI Lower", "95% CI Upper"),
    value = c(
      nmb_stats$mean_nmb, nmb_stats$median_nmb,
      nmb_stats$ci_nmb[1], nmb_stats$ci_nmb[2]
    ),
    type = c("point", "point", "interval", "interval")
  )

  p <- ggplot2::ggplot(nmb_data, ggplot2::aes(x = metric, y = value, color = type)) +
    ggplot2::geom_point(size = 3) +
    ggplot2::geom_line(ggplot2::aes(group = 1),
      data = nmb_data[nmb_data$type == "interval", ],
      color = "#A23B72", linewidth = 1
    ) +
    ggplot2::labs(
      title = title,
      subtitle = sprintf("WTP Threshold: $%s per QALY", format(nmb_stats$wtp_threshold, big.mark = ",")),
      x = "Statistic",
      y = "Net Monetary Benefit (AUD)"
    ) +
    ggplot2::theme_minimal() +
    ggplot2::theme(
      plot.title = ggplot2::element_text(size = 14, face = "bold"),
      plot.subtitle = ggplot2::element_text(size = 10, color = "gray50"),
      axis.title = ggplot2::element_text(size = 12),
      axis.text = ggplot2::element_text(size = 10),
      legend.position = "none"
    ) +
    ggplot2::scale_y_continuous(labels = scales::comma_format()) +
    ggplot2::scale_color_manual(values = c("point" = "#2E86AB", "interval" = "#A23B72"))

  # Add probability positive NMB annotation
  p <- p +
    ggplot2::annotate("text",
      x = 2, y = max(nmb_data$value) * 0.9,
      label = sprintf(
        "P(NMB > 0): %.1f%%",
        nmb_stats$prob_positive_nmb * 100
      ),
      hjust = 0.5, vjust = 1, size = 4, color = "#2E86AB"
    )

  return(p)
}

#' Plot Value of Information (VOI) Analysis
#'
#' @param voi_stats VOI statistics from calculate_voi()
#' @param title Plot title
#' @return ggplot object
plot_voi_analysis <- function(voi_stats, title = "Value of Information Analysis") {
  if (is.null(voi_stats)) {
    warning("No VOI statistics available for plotting")
    return(NULL)
  }

  # Create data for plotting
  voi_data <- data.frame(
    measure = c("EVPI per Person", "Expected NMB"),
    value = c(voi_stats$evpi_per_person, voi_stats$nmb_stats$mean_nmb),
    type = c("voi", "nmb")
  )

  p <- ggplot2::ggplot(voi_data, ggplot2::aes(x = measure, y = value, fill = type)) +
    ggplot2::geom_bar(stat = "identity", width = 0.6) +
    ggplot2::labs(
      title = title,
      subtitle = sprintf("WTP Threshold: $%s per QALY", format(voi_stats$wtp_threshold, big.mark = ",")),
      x = "",
      y = "Value (AUD)"
    ) +
    ggplot2::theme_minimal() +
    ggplot2::theme(
      plot.title = ggplot2::element_text(size = 14, face = "bold"),
      plot.subtitle = ggplot2::element_text(size = 10, color = "gray50"),
      axis.title = ggplot2::element_text(size = 12),
      axis.text = ggplot2::element_text(size = 10),
      legend.position = "none"
    ) +
    ggplot2::scale_y_continuous(labels = scales::comma_format()) +
    ggplot2::scale_fill_manual(values = c("voi" = "#F18F01", "nmb" = "#2E86AB"))

  # Add value labels on bars
  p <- p +
    ggplot2::geom_text(ggplot2::aes(label = sprintf("$%s", format(value, big.mark = ","))),
      vjust = -0.5, size = 4
    )

  return(p)
}

#' Create Enhanced CEAC Visualization Report
#'
#' @param enhanced_ceac Enhanced CEAC analysis from generate_enhanced_ceac()
#' @param output_dir Directory to save plots
#' @param timestamp Timestamp for file naming
#' @return Visualization report
create_enhanced_ceac_report <- function(enhanced_ceac, output_dir = "output",
                                        timestamp = format(Sys.time(), "%Y%m%d_%H%M%S")) {
  # Create output directory if it doesn't exist
  if (!dir.exists(output_dir)) {
    dir.create(output_dir, recursive = TRUE)
  }

  report <- list()

  # 1. CEAC Plot
  if (!is.null(enhanced_ceac$ceac)) {
    ceac_plot <- plot_ceac(enhanced_ceac$ceac, wtp_threshold = enhanced_ceac$summary$wtp_threshold)
    if (!is.null(ceac_plot)) {
      ceac_file <- file.path(output_dir, paste0("ceac_", timestamp, ".png"))
      ggplot2::ggsave(ceac_file, ceac_plot, width = 8, height = 6, dpi = 300)
      report$ceac <- list(plot = ceac_plot, file = ceac_file)
    }
  }

  # 2. Bootstrap CEAC Plot
  if (!is.null(enhanced_ceac$ceac_bootstrap)) {
    bootstrap_plot <- plot_ceac_bootstrap(enhanced_ceac$ceac_bootstrap,
      wtp_threshold = enhanced_ceac$summary$wtp_threshold
    )
    if (!is.null(bootstrap_plot)) {
      bootstrap_file <- file.path(output_dir, paste0("ceac_bootstrap_", timestamp, ".png"))
      ggplot2::ggsave(bootstrap_file, bootstrap_plot, width = 8, height = 6, dpi = 300)
      report$ceac_bootstrap <- list(plot = bootstrap_plot, file = bootstrap_file)
    }
  }

  # 3. NMB Distribution Plot
  if (!is.null(enhanced_ceac$nmb)) {
    nmb_plot <- plot_nmb_distribution(enhanced_ceac$nmb)
    if (!is.null(nmb_plot)) {
      nmb_file <- file.path(output_dir, paste0("nmb_distribution_", timestamp, ".png"))
      ggplot2::ggsave(nmb_file, nmb_plot, width = 8, height = 6, dpi = 300)
      report$nmb <- list(plot = nmb_plot, file = nmb_file)
    }
  }

  # 4. VOI Analysis Plot
  if (!is.null(enhanced_ceac$voi)) {
    voi_plot <- plot_voi_analysis(enhanced_ceac$voi)
    if (!is.null(voi_plot)) {
      voi_file <- file.path(output_dir, paste0("voi_analysis_", timestamp, ".png"))
      ggplot2::ggsave(voi_file, voi_plot, width = 8, height = 6, dpi = 300)
      report$voi <- list(plot = voi_plot, file = voi_file)
    }
  }

  # Save report metadata
  report_file <- file.path(output_dir, paste0("enhanced_ceac_report_", timestamp, ".rds"))
  saveRDS(report, file = report_file)
  report$metadata <- list(
    timestamp = Sys.time(),
    output_dir = output_dir,
    wtp_threshold = enhanced_ceac$summary$wtp_threshold,
    report_file = report_file,
    analysis_summary = enhanced_ceac$summary
  )

  return(report)
}

#' Create Comprehensive Uncertainty Analysis Report
#'
#' @param uncertainty_analysis Uncertainty analysis results
#' @param output_dir Output directory for plots
#' @param timestamp Timestamp for file naming
#' @return List containing plots and file paths
create_uncertainty_analysis_report <- function(uncertainty_analysis, output_dir = "output",
                                               timestamp = format(Sys.time(), "%Y%m%d_%H%M%S")) {
  if (is.null(uncertainty_analysis)) {
    warning("No uncertainty analysis data available for report generation")
    return(NULL)
  }

  # Create output directory if it doesn't exist
  if (!dir.exists(output_dir)) {
    dir.create(output_dir, recursive = TRUE)
  }

  report <- list()

  # 1. Tornado Diagram
  if (!is.null(uncertainty_analysis$parameter_influence)) {
    tornado_plot <- plot_tornado_diagram(uncertainty_analysis$parameter_influence)
    if (!is.null(tornado_plot)) {
      tornado_file <- file.path(output_dir, paste0("tornado_diagram_", timestamp, ".png"))
      ggplot2::ggsave(tornado_file, tornado_plot, width = 10, height = 8, dpi = 300)
      report$tornado <- list(plot = tornado_plot, file = tornado_file)
    }
  }

  # 2. Parameter Correlations
  if (!is.null(uncertainty_analysis$parameter_correlations)) {
    corr_plot <- plot_parameter_correlations(uncertainty_analysis$parameter_correlations)
    if (!is.null(corr_plot)) {
      corr_file <- file.path(output_dir, paste0("parameter_correlations_", timestamp, ".png"))
      ggplot2::ggsave(corr_file, corr_plot, width = 10, height = 6, dpi = 300)
      report$correlations <- list(plot = corr_plot, file = corr_file)
    }
  }

  # 3. Sensitivity Analysis
  if (!is.null(uncertainty_analysis$sensitivity_analysis)) {
    sens_plot <- plot_sensitivity_analysis(uncertainty_analysis$sensitivity_analysis)
    if (!is.null(sens_plot)) {
      sens_file <- file.path(output_dir, paste0("sensitivity_analysis_", timestamp, ".png"))
      ggplot2::ggsave(sens_file, sens_plot, width = 10, height = 6, dpi = 300)
      report$sensitivity <- list(plot = sens_plot, file = sens_file)
    }
  }

  # Save report metadata
  report_file <- file.path(output_dir, paste0("uncertainty_analysis_report_", timestamp, ".rds"))
  saveRDS(report, file = report_file)
  report$metadata <- list(
    timestamp = Sys.time(),
    output_dir = output_dir,
    analysis_summary = uncertainty_analysis$uncertainty_summary,
    report_file = report_file,
    insights = uncertainty_analysis$insights
  )

  return(report)
}
