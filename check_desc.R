#!/usr/bin/env Rscript

# Check DESCRIPTION file
cat("Checking DESCRIPTION file...\n")

desc <- read.dcf("DESCRIPTION")
print(desc)

cat("\nPackage name:", desc[1, "Package"], "\n")
cat("Version:", desc[1, "Version"], "\n")

# Try to validate the DESCRIPTION
cat("\nValidating DESCRIPTION...\n")
tryCatch({
  tools:::.check_package_description("DESCRIPTION")
  cat("✅ DESCRIPTION validation passed\n")
}, error = function(e) {
  cat("❌ DESCRIPTION validation failed:", e$message, "\n")
})
