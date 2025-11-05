#!/usr/bin/env Rscript

# Test enhanced CEAC functionality
source('/home/doughnut/github/aus_oa_public/R/psa_integration.R')
source('/home/doughnut/github/aus_oa_public/R/psa_framework.R')

cat("=== Testing Enhanced CEAC Functionality ===\n")

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

# Test enhanced CEAC
enhanced_ceac <- generate_enhanced_ceac(psa_results, wtp_threshold = 50000)

cat("Enhanced CEAC analysis completed\n")
cat("CEAC probability at WTP 50000:", enhanced_ceac$summary$ceac_probability, "\n")
cat("NMB mean:", enhanced_ceac$nmb$mean_nmb, "\n")
cat("EVPI:", enhanced_ceac$voi$evpi, "\n")
cat("Probability positive NMB:", enhanced_ceac$nmb$prob_positive_nmb, "\n")

# Test bootstrap CEAC
cat("\n=== Testing Bootstrap CEAC ===\n")
bootstrap_ceac <- generate_ceac_bootstrap(psa_results, wtp_threshold = 50000, n_bootstrap = 100)
cat("Bootstrap CEAC completed\n")
cat("Bootstrap sample size:", bootstrap_ceac$n_bootstrap, "\n")
cat("Confidence level:", bootstrap_ceac$conf_level, "\n")

cat("\n=== Test Completed Successfully ===\n")
