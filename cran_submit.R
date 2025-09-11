#!/usr/bin/env Rscript
# CRAN Submission Automation Script for ausoa v2.2.0
# This script automates the CRAN submission preparation process

cat("🚀 Starting CRAN Submission Preparation for ausoa v2.2.0\n")
cat("========================================================\n\n")

# Set working directory to package root
setwd(".")

# Load required packages
if (!require("devtools")) {
  install.packages("devtools")
  library(devtools)
}

if (!require("rcmdcheck")) {
  install.packages("rcmdcheck")
  library(rcmdcheck)
}

cat("📦 Step 1: Building package...\n")
# Build the package
build_result <- devtools::build()
cat("✅ Package built successfully:", build_result, "\n\n")

cat("🔍 Step 2: Running R CMD check...\n")
# Run comprehensive R CMD check
check_result <- rcmdcheck::rcmdcheck(
  path = ".",
  args = c("--as-cran", "--no-manual", "--no-vignettes"),
  check_dir = "cran_check_results"
)

cat("📊 R CMD Check Results:\n")
print(check_result)

# Check for errors, warnings, notes
if (length(check_result$errors) > 0) {
  cat("❌ ERRORS found:\n")
  print(check_result$errors)
  stop("Package has errors - cannot proceed with CRAN submission")
}

if (length(check_result$warnings) > 0) {
  cat("⚠️  WARNINGS found:\n")
  print(check_result$warnings)
  cat("⚠️  Please review warnings before submitting to CRAN\n")
}

if (length(check_result$notes) > 0) {
  cat("📝 NOTES found:\n")
  print(check_result$notes)
  cat("📝 Please review notes - some may need to be addressed for CRAN\n")
}

if (length(check_result$errors) == 0) {
  cat("✅ No errors found - package is ready for CRAN submission!\n\n")
}

cat("📋 Step 3: Package Information\n")
# Get package info
pkg_info <- devtools::build_readme()
cat("Package:", pkg_info$Package, "\n")
cat("Version:", pkg_info$Version, "\n")
cat("Title:", pkg_info$Title, "\n")
cat("Maintainer:", pkg_info$Maintainer, "\n\n")

cat("🎯 Step 4: CRAN Submission Instructions\n")
cat("=====================================\n")
cat("1. Go to: https://cran.r-project.org/submit.html\n")
cat("2. Fill out the submission form with:\n")
cat("   - Package source: Select the built .tar.gz file\n")
cat("   - Email: dylan.mordaunt@vuw.ac.nz\n")
cat("   - Upload cran-comments.md as comments\n")
cat("3. Submit and wait for CRAN response\n\n")

cat("📁 Files ready for submission:\n")
cat("- Package file:", build_result, "\n")
cat("- Comments file: cran-comments.md\n\n")

cat("✨ CRAN submission preparation complete!\n")
cat("📧 Check your email for CRAN confirmation and any follow-up requests.\n")
