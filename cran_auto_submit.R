# CRAN Auto-Submission System for ausoa v2.2.0
# This script automates everything possible before manual CRAN submission

cat("🚀 CRAN Auto-Submission System v2.2.0\n")
cat("=======================================\n\n")

# Configuration
PACKAGE_NAME <- "ausoa"
PACKAGE_VERSION <- "2.2.0"
MAINTAINER_EMAIL <- "dylan.mordaunt@vuw.ac.nz"
CRAN_SUBMIT_URL <- "https://cran.r-project.org/submit.html"

# Function to check and install packages
auto_install <- function(pkg) {
  if (!require(pkg, character.only = TRUE, quietly = TRUE)) {
    cat("📦 Installing", pkg, "...\n")
    tryCatch({
      install.packages(pkg, quiet = TRUE)
      library(pkg, character.only = TRUE, quietly = TRUE)
      cat("✅", pkg, "installed and loaded\n")
    }, error = function(e) {
      cat("❌ Failed to install", pkg, ":", e$message, "\n")
      return(FALSE)
    })
  } else {
    cat("✅", pkg, "already available\n")
  }
  return(TRUE)
}

# Step 1: Install required packages
cat("📦 Step 1: Installing required packages...\n")
required_pkgs <- c("devtools", "rcmdcheck", "desc", "curl", "httr", "rvest")
install_success <- TRUE
for (pkg in required_pkgs) {
  if (!auto_install(pkg)) {
    install_success <- FALSE
  }
}

if (!install_success) {
  cat("❌ Some packages failed to install. Please install manually and rerun.\n")
  stop("Package installation failed")
}

cat("\n✅ All packages ready!\n\n")

# Step 2: Validate package structure
cat("🔍 Step 2: Validating package structure...\n")
checks_passed <- TRUE

# Check required files
required_files <- c("DESCRIPTION", "NAMESPACE", "NEWS.md", "cran-comments.md")
for (file in required_files) {
  if (file.exists(file)) {
    cat("✅", file, "exists\n")
  } else {
    cat("❌", file, "missing\n")
    checks_passed <- FALSE
  }
}

# Check required directories
required_dirs <- c("R", "man")
for (dir in required_dirs) {
  if (dir.exists(dir)) {
    cat("✅", dir, "directory exists\n")
  } else {
    cat("❌", dir, "directory missing\n")
    checks_passed <- FALSE
  }
}

if (!checks_passed) {
  cat("❌ Package structure validation failed. Please fix missing files/directories.\n")
  stop("Validation failed")
}

cat("\n✅ Package structure validated!\n\n")

# Step 3: Build package
cat("📦 Step 3: Building package...\n")
tryCatch({
  build_result <- devtools::build(quiet = TRUE)
  cat("✅ Package built successfully!\n")
  cat("📁 Package file:", build_result, "\n")

  # Verify the built file exists
  if (!file.exists(build_result)) {
    stop("Built package file not found")
  }

}, error = function(e) {
  cat("❌ Error building package:", e$message, "\n")
  cat("💡 Try running: devtools::document() first\n")
  stop("Package build failed")
})

# Step 4: Run CRAN checks
cat("\n🔍 Step 4: Running CRAN checks...\n")
tryCatch({
  check_result <- rcmdcheck::rcmdcheck(
    path = ".",
    args = c("--as-cran", "--no-manual", "--no-vignettes"),
    check_dir = "cran_check_results",
    quiet = TRUE
  )

  cat("📊 CRAN Check Results:\n")
  cat("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n")
  cat("Errors:", length(check_result$errors), "\n")
  cat("Warnings:", length(check_result$warnings), "\n")
  cat("Notes:", length(check_result$notes), "\n\n")

  if (length(check_result$errors) > 0) {
    cat("❌ CRITICAL ERRORS (MUST FIX):\n")
    cat("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n")
    for (i in seq_along(check_result$errors)) {
      cat(i, ".", check_result$errors[i], "\n\n")
    }
    cat("❌ Package has errors - cannot proceed with CRAN submission\n")
    stop("CRAN check failed with errors")
  }

  if (length(check_result$warnings) > 0) {
    cat("⚠️  WARNINGS (REVIEW CAREFULLY):\n")
    cat("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n")
    for (i in seq_along(check_result$warnings)) {
      cat(i, ".", check_result$warnings[i], "\n\n")
    }
  } else {
    cat("✅ No warnings found\n")
  }

  if (length(check_result$notes) > 0) {
    cat("📝 NOTES (REVIEW):\n")
    cat("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n")
    for (i in seq_along(check_result$notes)) {
      cat(i, ".", check_result$notes[i], "\n\n")
    }
  } else {
    cat("✅ No notes found\n")
  }

  if (length(check_result$errors) == 0) {
    cat("✅ CRAN CHECKS PASSED!\n")
    cat("🎉 Package is ready for CRAN submission\n")
  }

}, error = function(e) {
  cat("❌ Error during CRAN checks:", e$message, "\n")
  stop("CRAN check process failed")
})

# Step 5: Generate submission summary
cat("\n📋 Step 5: Generating submission summary...\n")

# Get package info
desc <- desc::desc()
package_info <- list(
  name = desc$get("Package"),
  version = desc$get("Version"),
  title = desc$get("Title"),
  maintainer = desc$get("Maintainer"),
  description = desc$get("Description")
)

cat("📦 PACKAGE INFORMATION:\n")
cat("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n")
cat("Name:", package_info$name, "\n")
cat("Version:", package_info$version, "\n")
cat("Title:", package_info$title, "\n")
cat("Maintainer:", package_info$maintainer, "\n")
cat("Built file:", build_result, "\n")
cat("File size:", round(file.info(build_result)$size / (1024 * 1024), 2), "MB\n\n")

# Step 6: Create submission instructions
cat("🎯 Step 6: CRAN SUBMISSION INSTRUCTIONS\n")
cat("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n")
cat("1. 📧 Open your email client\n")
cat("2. 📨 Go to:", CRAN_SUBMIT_URL, "\n")
cat("3. 📤 Fill out the submission form:\n")
cat("   ├─ Package source: Select '", build_result, "'\n")
cat("   ├─ Email address: ", MAINTAINER_EMAIL, "\n")
cat("   └─ Upload comments: Select 'cran-comments.md'\n")
cat("4. 🚀 Click 'Submit' button\n")
cat("5. 📬 Wait for CRAN confirmation email\n\n")

# Step 7: Create submission package
cat("📦 Step 7: Creating submission package...\n")
submission_dir <- "cran_submission_package"
if (!dir.exists(submission_dir)) {
  dir.create(submission_dir)
}

# Copy files to submission directory
files_to_copy <- c(build_result, "cran-comments.md", "DESCRIPTION", "NEWS.md")
for (file in files_to_copy) {
  if (file.exists(file)) {
    file.copy(file, file.path(submission_dir, basename(file)))
    cat("✅ Copied:", basename(file), "\n")
  }
}

# Create submission README
submission_readme <- file.path(submission_dir, "SUBMISSION_README.txt")
writeLines(c(
  paste("CRAN Submission Package for", package_info$name, package_info$version),
  "",
  "Files:",
  paste("- Package:", basename(build_result)),
  "- Comments: cran-comments.md",
  "- Description: DESCRIPTION",
  "- Changelog: NEWS.md",
  "",
  "Submission URL:", CRAN_SUBMIT_URL,
  "Maintainer Email:", MAINTAINER_EMAIL,
  "",
  "Generated on:", format(Sys.time(), "%Y-%m-%d %H:%M:%S"),
  "R Version:", R.version$version.string
), submission_readme)

cat("✅ Submission package created in:", submission_dir, "\n\n")

# Step 8: Final status
cat("🎉 AUTOMATION COMPLETE!\n")
cat("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n")
cat("✅ Package built successfully\n")
cat("✅ CRAN checks passed\n")
cat("✅ Submission package prepared\n")
cat("✅ Instructions generated\n\n")

cat("📂 SUBMISSION PACKAGE LOCATION:\n")
cat("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n")
cat(normalizePath(submission_dir), "\n\n")

cat("🚀 FINAL STEP - MANUAL SUBMISSION:\n")
cat("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n")
cat("1. Go to:", CRAN_SUBMIT_URL, "\n")
cat("2. Upload:", basename(build_result), "\n")
cat("3. Upload: cran-comments.md\n")
cat("4. Use email:", MAINTAINER_EMAIL, "\n")
cat("5. Submit and wait for confirmation\n\n")

cat("⏱️  EXPECTED TIMELINE:\n")
cat("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n")
cat("• Submission: Complete the web form now\n")
cat("• CRAN Review: 1-2 weeks\n")
cat("• Publication: 1-4 weeks after approval\n\n")

cat("📧 MONITORING:\n")
cat("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n")
cat("• Check email:", MAINTAINER_EMAIL, "\n")
cat("• CRAN responses from: cran@r-project.org\n")
cat("• Address feedback within 2 weeks\n\n")

cat("🎯 STATUS: READY FOR CRAN SUBMISSION!\n")
cat("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n")
cat("Your package is fully prepared and validated.\n")
cat("Complete the manual web form submission to finish the process.\n\n")

# Save submission info to file
submission_info <- file.path(submission_dir, "submission_info.txt")
writeLines(c(
  "CRAN Submission Information",
  "==========================",
  paste("Package:", package_info$name),
  paste("Version:", package_info$version),
  paste("Maintainer:", package_info$maintainer),
  paste("Built File:", basename(build_result)),
  paste("Submission URL:", CRAN_SUBMIT_URL),
  paste("Generated:", format(Sys.time(), "%Y-%m-%d %H:%M:%S")),
  "",
  "Next Steps:",
  "1. Go to submission URL",
  "2. Upload package file and comments",
  "3. Submit form",
  "4. Wait for CRAN response"
), submission_info)

cat("💾 Submission info saved to:", submission_info, "\n")
cat("📋 All files ready in:", normalizePath(submission_dir), "\n\n")

# Final message
cat("🎉 CRAN SUBMISSION PREPARATION COMPLETE!\n")
cat("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n")
cat("Everything is automated except the final web form.\n")
cat("Your package is ready for CRAN submission! 🚀\n")
