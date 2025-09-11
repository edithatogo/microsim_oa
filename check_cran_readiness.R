# CRAN Readiness Validation Script
# Run this to check if your package is ready for CRAN submission

cat("🔍 CRAN Readiness Check for ausoa v2.2.0\n")
cat("=========================================\n\n")

# Check 1: Required files exist
cat("📁 Step 1: Checking required files...\n")
required_files <- c(
  "DESCRIPTION",
  "NAMESPACE",
  "NEWS.md",
  "cran-comments.md"
)

for (file in required_files) {
  if (file.exists(file)) {
    cat("✅", file, "exists\n")
  } else {
    cat("❌", file, "missing\n")
  }
}

# Check directories
required_dirs <- c("R", "man", "tests")
for (dir in required_dirs) {
  if (dir.exists(dir)) {
    cat("✅", dir, "directory exists\n")
  } else {
    cat("❌", dir, "directory missing\n")
  }
}

cat("\n📋 Step 2: Package information...\n")
# Read DESCRIPTION
if (file.exists("DESCRIPTION")) {
  desc_lines <- readLines("DESCRIPTION")
  for (line in desc_lines) {
    if (grepl("^(Package|Version|Title|Maintainer|License):", line)) {
      cat("  ", line, "\n")
    }
  }
}

cat("\n🧪 Step 3: Test status...\n")
# Check test directory
if (dir.exists("tests")) {
  test_files <- list.files("tests", pattern = "\\.R$", full.names = TRUE)
  cat("  Found", length(test_files), "test files\n")
  if (length(test_files) > 0) {
    cat("  Test files:\n")
    for (file in test_files) {
      cat("    -", basename(file), "\n")
    }
  }
}

cat("\n📚 Step 4: Documentation status...\n")
# Check man directory
if (dir.exists("man")) {
  man_files <- list.files("man", pattern = "\\.Rd$", full.names = TRUE)
  cat("  Found", length(man_files), "documentation files\n")
}

cat("\n🔗 Step 5: Checking for broken links in DESCRIPTION...\n")
# Check for bare URLs in DESCRIPTION (CRAN doesn't like these)
if (file.exists("DESCRIPTION")) {
  desc_content <- paste(readLines("DESCRIPTION"), collapse = "\n")
  url_pattern <- "https?://[^\\s)]+"
  urls <- regmatches(desc_content, gregexpr(url_pattern, desc_content))[[1]]

  if (length(urls) > 0) {
    cat("⚠️  Found URLs in DESCRIPTION (should be in angle brackets):\n")
    for (url in urls) {
      cat("  -", url, "\n")
    }
  } else {
    cat("✅ No bare URLs found in DESCRIPTION\n")
  }
}

cat("\n📦 Step 6: Checking package size...\n")
# Check for large files that might be issues
all_files <- list.files(".", recursive = TRUE, full.names = TRUE)
large_files <- file.info(all_files)$size > 5 * 1024 * 1024  # 5MB
large_files <- all_files[large_files & !is.na(large_files)]

if (length(large_files) > 0) {
  cat("⚠️  Large files found (>5MB):\n")
  for (file in large_files) {
    size_mb <- round(file.info(file)$size / (1024 * 1024), 1)
    cat("  -", file, "(", size_mb, "MB)\n")
  }
} else {
  cat("✅ No large files found\n")
}

cat("\n🎯 Step 7: CRAN submission readiness...\n")
cat("Ready for CRAN submission checklist:\n")
cat("□ Package builds without errors\n")
cat("□ R CMD check passes (no errors, review warnings/notes)\n")
cat("□ cran-comments.md updated for this version\n")
cat("□ All required files present\n")
cat("□ No bare URLs in DESCRIPTION\n")
cat("□ Package size reasonable\n")
cat("□ Tests pass\n")
cat("□ Documentation complete\n\n")

cat("✨ Validation complete! Review items above before submitting to CRAN.\n")
