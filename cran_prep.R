# CRAN Submission Preparation for ausoa v2.2.0
cat("🚀 Starting CRAN Submission Preparation for ausoa v2.2.0\n")
cat("========================================================\n\n")

# Load required packages
if (!require("devtools")) {
  install.packages("devtools", quiet = TRUE)
  library(devtools)
}

if (!require("rcmdcheck")) {
  install.packages("rcmdcheck", quiet = TRUE)
  library(rcmdcheck)
}

cat("📦 Step 1: Building package...\n")
# Build the package
tryCatch({
  build_result <- devtools::build(quiet = TRUE)
  cat("✅ Package built successfully:", build_result, "\n\n")
}, error = function(e) {
  cat("❌ Error building package:", e$message, "\n")
  stop("Package build failed")
})

cat("🔍 Step 2: Running R CMD check...\n")
# Run comprehensive R CMD check
tryCatch({
  check_result <- rcmdcheck::rcmdcheck(
    path = ".",
    args = c("--as-cran", "--no-manual", "--no-vignettes"),
    check_dir = "cran_check_results",
    quiet = TRUE
  )

  cat("📊 R CMD Check Results:\n")
  if (length(check_result$errors) > 0) {
    cat("❌ ERRORS found:\n")
    for (error in check_result$errors) {
      cat("  -", error, "\n")
    }
    cat("\n❌ Package has errors - cannot proceed with CRAN submission\n")
  } else {
    cat("✅ No errors found\n")
  }

  if (length(check_result$warnings) > 0) {
    cat("⚠️  WARNINGS found:\n")
    for (warning in check_result$warnings) {
      cat("  -", warning, "\n")
    }
  } else {
    cat("✅ No warnings found\n")
  }

  if (length(check_result$notes) > 0) {
    cat("📝 NOTES found:\n")
    for (note in check_result$notes) {
      cat("  -", note, "\n")
    }
  } else {
    cat("✅ No notes found\n")
  }

}, error = function(e) {
  cat("❌ Error during R CMD check:", e$message, "\n")
})

cat("\n📋 Step 3: Package Information\n")
# Get package info
tryCatch({
  desc <- desc::desc()
  cat("Package:", desc$get("Package"), "\n")
  cat("Version:", desc$get("Version"), "\n")
  cat("Title:", desc$get("Title"), "\n")
  cat("Maintainer:", desc$get("Maintainer"), "\n\n")
}, error = function(e) {
  cat("Could not read DESCRIPTION file:", e$message, "\n")
})

cat("🎯 Step 4: CRAN Submission Instructions\n")
cat("=====================================\n")
cat("1. Go to: https://cran.r-project.org/submit.html\n")
cat("2. Fill out the submission form with:\n")
cat("   - Package source: Select the built .tar.gz file\n")
cat("   - Email: dylan.mordaunt@vuw.ac.nz\n")
cat("   - Upload cran-comments.md as comments\n")
cat("3. Submit and wait for CRAN response\n\n")

cat("📁 Files ready for submission:\n")
cat("- Comments file: cran-comments.md\n")

# List built packages
pkg_files <- list.files(pattern = "\\.tar\\.gz$", full.names = TRUE)
if (length(pkg_files) > 0) {
  cat("- Package files found:\n")
  for (file in pkg_files) {
    cat("  -", file, "\n")
  }
} else {
  cat("- No .tar.gz files found (build may have failed)\n")
}

cat("\n✨ CRAN submission preparation complete!\n")
cat("📧 Check your email for CRAN confirmation and any follow-up requests.\n")
