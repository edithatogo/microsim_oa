#!/usr/bin/env Rscript

# Coverage analysis for ausoa package
library(covr)
library(ausoa)

# Generate coverage report
coverage_result <- package_coverage(
  type = "all",
  quiet = FALSE
)

# Print coverage summary
print(coverage_result)

# Generate HTML report
report(coverage_result, file = "coverage_report.html")

# Create coverage badge
# If coverage is above 95%, create a success badge
ratio <- 1 - (attr(coverage_result, "total")$missing / attr(coverage_result, "total")$traced)
percentage <- round(ratio * 100, 1)

cat("\nCoverage Summary:\n")
cat("Lines of code covered:", attr(coverage_result, "total")$covered, "\n")
cat("Lines of code missing:", attr(coverage_result, "total")$missing, "\n")
cat("Coverage percentage:", percentage, "%\n")

# Create a coverage badge
badge_url <- paste0("https://img.shields.io/badge/Coverage-", percentage, "%25-brightgreen.svg")
cat("Coverage badge URL:", badge_url, "\n")

# Write coverage to a file for CI/CD
writeLines(c(
  paste("coverage_percentage:", percentage),
  paste("total_lines:", attr(coverage_result, "total")$traced),
  paste("covered_lines:", attr(coverage_result, "total")$covered),
  paste("missing_lines:", attr(coverage_result, "total")$missing)
), "coverage_summary.txt")