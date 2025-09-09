#!/usr/bin/env Rscript

# Test enhanced CEAC visualization functions
source('/home/doughnut/github/aus_oa_public/R/psa_integration.R')
source('/home/doughnut/github/aus_oa_public/R/psa_visualization.R')
library(ggplot2)

cat("=== Testing Enhanced CEAC Visualization ===\n")

# Create test PSA results
n_simulations <- 100
test_results <- lapply(1:n_simulations, function(i) {
  list(
    total_cost = rnorm(1, 50000, 10000),
    total_qaly = rnorm(1, 8, 1),
    successful = TRUE
  )
})

psa_results <- list(simulation_results = test_results)

# Generate enhanced CEAC
enhanced_ceac <- generate_enhanced_ceac(psa_results, wtp_threshold = 50000)

cat("Testing enhanced CEAC visualization functions...\n")

# Test bootstrap CEAC plot
if (!is.null(enhanced_ceac$ceac_bootstrap)) {
  bootstrap_plot <- plot_ceac_bootstrap(enhanced_ceac$ceac_bootstrap)
  cat("Bootstrap CEAC plot created successfully\n")
  cat("Plot class:", class(bootstrap_plot), "\n")
} else {
  cat("Bootstrap CEAC data not available\n")
}

# Test NMB distribution plot
if (!is.null(enhanced_ceac$nmb)) {
  nmb_plot <- plot_nmb_distribution(enhanced_ceac$nmb)
  cat("NMB distribution plot created successfully\n")
  cat("Plot class:", class(nmb_plot), "\n")
} else {
  cat("NMB data not available\n")
}

# Test VOI analysis plot
if (!is.null(enhanced_ceac$voi)) {
  voi_plot <- plot_voi_analysis(enhanced_ceac$voi)
  cat("VOI analysis plot created successfully\n")
  cat("Plot class:", class(voi_plot), "\n")
} else {
  cat("VOI data not available\n")
}

# Test enhanced CEAC report generation
report <- create_enhanced_ceac_report(enhanced_ceac, output_dir = "output/test_enhanced")
cat("Enhanced CEAC report created\n")
cat("Report components:", paste(names(report), collapse = ", "), "\n")

cat("\n=== Enhanced CEAC Visualization Test Completed ===\n")
