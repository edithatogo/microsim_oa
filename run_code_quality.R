#!/usr/bin/env Rscript
# Code quality check and improvement script for AUS-OA package

# Install required packages if not already available
if (!require("lintr", quietly = TRUE)) {
  install.packages("lintr", repos = "https://cran.r-project.org/")
}

if (!require("styler", quietly = TRUE)) {
  install.packages("styler", repos = "https://cran.r-project.org/")
}

library(lintr)
library(styler)

# Define the directories and files to check
r_source_dirs <- c("R/", "tests/testthat/")
r_files <- list.files(path = r_source_dirs, pattern = "\\.[Rr]$", full.names = TRUE, recursive = TRUE)

cat("Found", length(r_files), "R files to check\n")

# Check for lint errors
cat("\nChecking for lint errors...\n")
errors <- list()
for (file in r_files) {
  file_errors <- lint(file)
  if (length(file_errors) > 0) {
    errors[[file]] <- file_errors
    cat("Found", length(file_errors), "errors in", file, "\n")
  }
}

if (length(errors) > 0) {
  total_errors <- sum(sapply(errors, length))
  cat("\nTotal lint errors found:", total_errors, "\n")
  
  # Print some of the errors
  cat("Sample of errors:\n")
  count <- 0
  for (file in names(errors)) {
    for (error in errors[[file]]) {
      if (count < 10) {  # Only show first 10 errors
        cat("  ", as.character(error), "\n")
        count <- count + 1
      } else {
        break
      }
    }
    if (count >= 10) break
  }
} else {
  cat("No lint errors found!\n")
}

# Run styler to fix common formatting issues
cat("\nFormatting R files with styler...\n")
style_pkg()

cat("Code styling completed.\n")

# Run goodpractice checks if available
if (require("goodpractice", quietly = TRUE)) {
  cat("\nRunning goodpractice checks...\n")
  gp_result <- tryCatch({
    goodpractice::gp(path = ".", checks = goodpractice::all_checks())
  }, error = function(e) {
    cat("Goodpractice check failed:", e$message, "\n")
    NULL
  })
  
  if (!is.null(gp_result)) {
    if (!gp_result$passed) {
      cat("Goodpractice checks found issues:\n")
      issues <- gp_result$comments
      for (issue in issues) {
        cat("  -", issue$text, "\n")
      }
    } else {
      cat("All goodpractice checks passed!\n")
    }
  }
} else {
  cat("Goodpractice package not available, skipping checks\n")
  cat("To install: install.packages('goodpractice')\n")
}

# Check documentation
cat("\nChecking documentation with R CMD check...\n")
check_result <- tryCatch({
  devtools::check(cran = FALSE)
}, error = function(e) {
  cat("R CMD check produced errors/warnings:\n", e$message, "\n")
  NULL
})

if (is.null(check_result)) {
  cat("Check completed with issues noted above.\n")
} else {
  cat("R CMD check completed successfully.\n")
}

cat("\nCode quality checks completed!\n")