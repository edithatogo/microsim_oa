# CRAN Submission Preparation Script
# Run this in R console or RStudio

cat("🚀 CRAN Submission Preparation for ausoa v2.2.0\n")
cat("===============================================\n\n")

# Function to check and install packages
check_and_install <- function(pkg) {
  if (!require(pkg, character.only = TRUE)) {
    cat("Installing", pkg, "...\n")
    install.packages(pkg)
    library(pkg, character.only = TRUE)
  }
}

# Install required packages
cat("📦 Installing required packages...\n")
check_and_install("devtools")
check_and_install("rcmdcheck")
check_and_install("desc")

cat("\n✅ All packages ready!\n\n")

# Step 1: Build package
cat("📦 Step 1: Building package...\n")
tryCatch({
  build_result <- devtools::build(quiet = TRUE)
  cat("✅ Package built successfully!\n")
  cat("📁 Package file:", build_result, "\n\n")
}, error = function(e) {
  cat("❌ Error building package:", e$message, "\n")
  cat("💡 Try: devtools::document() first if roxygen issues\n\n")
})

# Step 2: Run checks
cat("🔍 Step 2: Running CRAN checks...\n")
tryCatch({
  check_result <- rcmdcheck::rcmdcheck(
    path = ".",
    args = c("--as-cran", "--no-manual", "--no-vignettes"),
    check_dir = "cran_check_results"
  )

  cat("📊 Check Results:\n")
  cat("Errors:", length(check_result$errors), "\n")
  cat("Warnings:", length(check_result$warnings), "\n")
  cat("Notes:", length(check_result$notes), "\n\n")

  if (length(check_result$errors) > 0) {
    cat("❌ ERRORS (must fix):\n")
    for (error in check_result$errors) cat("  -", error, "\n")
  }

  if (length(check_result$warnings) > 0) {
    cat("⚠️  WARNINGS (review):\n")
    for (warning in check_result$warnings) cat("  -", warning, "\n")
  }

  if (length(check_result$notes) > 0) {
    cat("📝 NOTES (review):\n")
    for (note in check_result$notes) cat("  -", note, "\n")
  }

  if (length(check_result$errors) == 0) {
    cat("✅ Package PASSES CRAN checks!\n")
  }

}, error = function(e) {
  cat("❌ Error during checks:", e$message, "\n")
})

# Step 3: Package info
cat("\n📋 Step 3: Package Information\n")
tryCatch({
  desc <- desc::desc()
  cat("Package:", desc$get("Package"), "\n")
  cat("Version:", desc$get("Version"), "\n")
  cat("Maintainer:", desc$get("Maintainer"), "\n\n")
}, error = function(e) {
  cat("Could not read package info\n")
})

# Step 4: Instructions
cat("🎯 Step 4: CRAN Submission Instructions\n")
cat("=====================================\n")
cat("1. Go to: https://cran.r-project.org/submit.html\n")
cat("2. Upload the built .tar.gz file\n")
cat("3. Upload cran-comments.md as comments\n")
cat("4. Use email: dylan.mordaunt@vuw.ac.nz\n")
cat("5. Submit and wait for CRAN response\n\n")

cat("✨ Preparation complete! Ready for CRAN submission.\n")
