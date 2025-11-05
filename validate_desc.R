#!/usr/bin/env Rscript

# Check DESCRIPTION validation
cat("Checking DESCRIPTION file validation...\n")

tryCatch({
  result <- tools::checkDescription("DESCRIPTION")
  print(result)
  if (length(result) == 0) {
    cat("✅ DESCRIPTION validation passed\n")
  } else {
    cat("⚠️  DESCRIPTION validation warnings:\n")
    print(result)
  }
}, error = function(e) {
  cat("❌ DESCRIPTION validation failed:", e$message, "\n")
})

# Also try to read the package name
cat("\nChecking package name...\n")
desc <- read.dcf("DESCRIPTION")
package_name <- desc[1, "Package"]
cat("Package name:", package_name, "\n")

# Check if package name is valid
if (grepl("^[a-zA-Z][a-zA-Z0-9.]*$", package_name)) {
  cat("✅ Package name format is valid\n")
} else {
  cat("❌ Package name format is invalid\n")
}
