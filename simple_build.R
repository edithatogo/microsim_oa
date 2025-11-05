#!/usr/bin/env Rscript

# Simple build script for ausoa 2.2.0
cat("Building ausoa package version 2.2.0...\n")

# Load devtools
library(devtools)

# Update documentation
cat("Updating documentation...\n")
tryCatch({
  document()
  cat("✅ Documentation updated successfully\n")
}, error = function(e) {
  cat("⚠️  Documentation update failed:", e$message, "\n")
  cat("Continuing with build...\n")
})

# Build package
cat("Building package...\n")
build_result <- build()
cat("✅ Package built successfully:", build_result, "\n")

# Check package
cat("Running package checks...\n")
check_result <- check()
if (check_result$errors > 0) {
  cat("❌ Package has", check_result$errors, "errors\n")
} else if (check_result$warnings > 0) {
  cat("⚠️  Package has", check_result$warnings, "warnings\n")
} else {
  cat("✅ Package passed all checks\n")
}

cat("Build process completed!\n")
