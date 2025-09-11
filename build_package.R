#!/usr/bin/env Rscript

# Build package for CRAN submission
# Usage: Rscript build_package.R

# Set working directory to package root
setwd(".")

# Load required packages
if (!require("devtools")) {
  install.packages("devtools")
  library(devtools)
}

# Clean previous builds
cat("Cleaning previous builds...\n")
if (file.exists("ausoa_2.0.1.tar.gz")) {
  file.remove("ausoa_2.0.1.tar.gz")
}

# Run document to ensure man files are up to date
cat("Updating documentation...\n")
devtools::document()

# Build package
cat("Building package...\n")
devtools::build()

# Run checks
cat("Running R CMD check...\n")
check_results <- devtools::check()

# Print results
if (length(check_results$errors) == 0 && length(check_results$warnings) == 0) {
  cat("\n✅ Package built successfully!\n")
  cat("📦 Package file: ausoa_2.0.1.tar.gz\n")
  cat("📋 Ready for CRAN submission\n")
} else {
  cat("\n❌ Issues found during check:\n")
  if (length(check_results$errors) > 0) {
    cat("Errors:\n")
    print(check_results$errors)
  }
  if (length(check_results$warnings) > 0) {
    cat("Warnings:\n")
    print(check_results$warnings)
  }
}

cat("\n📝 Next steps for CRAN submission:\n")
cat("1. Test package installation: R CMD INSTALL ausoa_2.0.1.tar.gz\n")
cat("2. Submit to CRAN: https://cran.r-project.org/submit.html\n")
cat("3. Upload ausoa_2.0.1.tar.gz and cran-comments.md\n")
