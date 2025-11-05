# CRAN Submission Dashboard - Complete Automation Suite
# This is the master script for the entire CRAN submission process

cat("🎯 CRAN SUBMISSION DASHBOARD - ausoa v2.2.0\n")
cat("===============================================\n\n")

# Configuration
DASHBOARD_VERSION <- "1.0"
PACKAGE_NAME <- "ausoa"
PACKAGE_VERSION <- "2.2.0"
MAINTAINER_EMAIL <- "dylan.mordaunt@vuw.ac.nz"

# Display header
cat("📊 DASHBOARD INFO\n")
cat("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n")
cat("Dashboard Version:", DASHBOARD_VERSION, "\n")
cat("Package:", PACKAGE_NAME, "\n")
cat("Version:", PACKAGE_VERSION, "\n")
cat("Maintainer:", MAINTAINER_EMAIL, "\n")
cat("Date:", format(Sys.Date(), "%Y-%m-%d"), "\n\n")

# Menu system
show_menu <- function() {
  cat("🚀 AVAILABLE AUTOMATION SCRIPTS\n")
  cat("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n")
  cat("1. 🔄 cran_auto_submit.R      - Complete submission preparation\n")
  cat("2. 🔍 cran_advanced_submit.R  - Advanced automation check\n")
  cat("3. 📧 cran_followup.R         - Post-submission monitoring\n")
  cat("4. 📋 prepare_cran_submission.R - Basic preparation\n")
  cat("5. ✅ check_cran_readiness.R  - Validation checklist\n")
  cat("6. 📖 CRAN_SUBMISSION_GUIDE.md - Manual guide\n")
  cat("7. 📊 cran_workflow.R         - Workflow overview\n")
  cat("8. ❌ Exit\n\n")
}

# Function to run selected script
run_script <- function(choice) {
  scripts <- c(
    "cran_auto_submit.R",
    "cran_advanced_submit.R",
    "cran_followup.R",
    "prepare_cran_submission.R",
    "check_cran_readiness.R",
    NA,  # CRAN_SUBMISSION_GUIDE.md is not an R script
    "cran_workflow.R"
  )

  if (choice >= 1 && choice <= 7 && !is.na(scripts[choice])) {
    script <- scripts[choice]
    if (file.exists(script)) {
      cat("🔄 Running", script, "...\n\n")
      source(script)
    } else {
      cat("❌ Script", script, "not found\n")
    }
  } else if (choice == 6) {
    cat("📖 Opening CRAN_SUBMISSION_GUIDE.md...\n")
    if (file.exists("CRAN_SUBMISSION_GUIDE.md")) {
      cat("Guide contents:\n")
      cat("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n")
      guide_content <- readLines("CRAN_SUBMISSION_GUIDE.md")
      cat(head(guide_content, 50), sep = "\n")
      cat("\n... (truncated - see full file)\n")
    } else {
      cat("❌ Guide file not found\n")
    }
  } else if (choice == 8) {
    cat("👋 Goodbye! Happy CRAN submitting!\n")
    return(FALSE)
  } else {
    cat("❌ Invalid choice\n")
  }
  return(TRUE)
}

# Function to show current status
show_status <- function() {
  cat("\n📊 CURRENT SUBMISSION STATUS\n")
  cat("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n")

  # Check if package is built
  pkg_files <- list.files(pattern = "\\.tar\\.gz$", full.names = TRUE)
  if (length(pkg_files) > 0) {
    cat("✅ Package built:", basename(pkg_files[length(pkg_files)]), "\n")
  } else {
    cat("❌ No package file found - run preparation script\n")
  }

  # Check cran-comments.md
  if (file.exists("cran-comments.md")) {
    cat("✅ cran-comments.md exists\n")
  } else {
    cat("❌ cran-comments.md missing\n")
  }

  # Check submission directory
  if (dir.exists("cran_submission_package")) {
    cat("✅ Submission package directory exists\n")
    submission_files <- list.files("cran_submission_package")
    cat("📁 Files ready:", paste(submission_files, collapse = ", "), "\n")
  } else {
    cat("❌ Submission package not created\n")
  }

  cat("\n")
}

# Function to show next steps
show_next_steps <- function() {
  cat("🎯 NEXT STEPS FOR CRAN SUBMISSION\n")
  cat("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n")

  steps <- c(
    "1. Run cran_auto_submit.R for complete preparation",
    "2. Review CRAN check results for errors/warnings",
    "3. Fix any issues found",
    "4. Go to https://cran.r-project.org/submit.html",
    "5. Upload package file and cran-comments.md",
    "6. Submit form and wait for confirmation",
    "7. Use cran_followup.R to monitor progress",
    "8. Address any CRAN feedback promptly"
  )

  for (step in steps) {
    cat("□", step, "\n")
  }

  cat("\n💡 Pro tip: Run option 1 first for complete automation\n\n")
}

# Function to show help
show_help <- function() {
  cat("❓ CRAN SUBMISSION HELP\n")
  cat("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n")
  cat("• This dashboard automates everything except the web form\n")
  cat("• CRAN requires manual submission for security reasons\n")
  cat("• All scripts validate your package before submission\n")
  cat("• Use cran_followup.R to track submission progress\n")
  cat("• Address CRAN feedback within 2 weeks\n")
  cat("• Expect 1-4 weeks total for publication\n\n")

  cat("🔗 USEFUL LINKS\n")
  cat("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n")
  cat("• CRAN Submit: https://cran.r-project.org/submit.html\n")
  cat("• CRAN Policies: https://cran.r-project.org/web/packages/policies.html\n")
  cat("• R Packages Book: https://r-pkgs.org/\n\n")
}

# Main dashboard loop
continue <- TRUE
while (continue) {
  show_status()
  show_menu()

  cat("Enter your choice (1-8): ")
  choice <- as.integer(readline())

  if (!is.na(choice)) {
    continue <- run_script(choice)
  } else {
    cat("❌ Please enter a valid number\n\n")
  }

  if (continue) {
    cat("\n" , rep("=", 50), "\n\n", sep = "")
  }
}

# Final message
cat("\n🎉 Thank you for using the CRAN Submission Dashboard!\n")
cat("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n")
cat("Your ausoa v2.2.0 package is ready for CRAN submission.\n")
cat("Remember: Only the web form submission requires manual action.\n")
cat("Everything else is fully automated! 🚀\n\n")
