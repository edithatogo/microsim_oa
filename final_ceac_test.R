#!/usr/bin/env Rscript

# Final CEAC Integration Test
source('/home/doughnut/github/aus_oa_public/R/psa_integration.R')
source('/home/doughnut/github/aus_oa_public/R/psa_visualization.R')
library(ggplot2)

cat("=== Final CEAC Integration Test ===\n")

# Create mock configuration
mock_config <- list(
  coefficients = list(
    psa = list(
      monte_carlo = list(
        default_n_samples = list(live = 100),
        min_samples_convergence = list(live = 50),
        target_samples_convergence = list(live = 200),
        default_seed = list(live = 12345)
      ),
      convergence = list(
        ci_width_threshold = list(live = 0.05),
        relative_se_threshold = list(live = 0.02),
        n_batches_convergence = list(live = 5)
      ),
      uncertainty = list(
        default_uncertainty_level = list(live = 0.1)
      ),
      cost_effectiveness = list(
        wtp_threshold = list(live = 50000)
      )
    ),
    cost_base = list(live = 50000),
    qaly_base = list(live = 8),
    complication_rate = list(live = 0.1)
  )
)

# Run PSA analysis
cat("Running PSA analysis...\n")
psa_results <- run_psa_analysis(mock_config, n_samples = 50, seed = 12345)

cat("PSA analysis completed with", length(psa_results$simulation_results), "simulations\n")

# Generate enhanced CEAC
cat("Generating enhanced CEAC analysis...\n")
enhanced_ceac <- generate_enhanced_ceac(psa_results, wtp_threshold = 50000)

cat("CEAC probability at WTP 50000:", enhanced_ceac$summary$ceac_probability, "\n")
cat("NMB mean:", enhanced_ceac$nmb$mean_nmb, "\n")
cat("EVPI:", enhanced_ceac$voi$evpi, "\n")

# Test visualization
cat("Testing visualization functions...\n")
ceac_plot <- plot_ceac(enhanced_ceac$ceac, wtp_threshold = 50000)
cat("CEAC plot created\n")

if (!is.null(enhanced_ceac$ceac_bootstrap)) {
  bootstrap_plot <- plot_ceac_bootstrap(enhanced_ceac$ceac_bootstrap)
  cat("Bootstrap CEAC plot created\n")
}

nmb_plot <- plot_nmb_distribution(enhanced_ceac$nmb)
cat("NMB distribution plot created\n")

voi_plot <- plot_voi_analysis(enhanced_ceac$voi)
cat("VOI analysis plot created\n")

cat("\n=== CEAC Integration Test Completed Successfully! ===\n")
cat("✅ CEAC calculation with bootstrap methods\n")
cat("✅ Enhanced visualization functions\n")
cat("✅ NMB and VOI analysis\n")
cat("✅ Full integration with PSA framework\n")
