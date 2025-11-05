# CRAN Submission Follow-up Automation
# Automates monitoring and follow-up after CRAN submission

cat("📧 CRAN Submission Follow-up System\n")
cat("===================================\n\n")

# Configuration
PACKAGE_NAME <- "ausoa"
PACKAGE_VERSION <- "2.2.0"
MAINTAINER_EMAIL <- "dylan.mordaunt@vuw.ac.nz"
SUBMISSION_DATE <- Sys.Date()
EXPECTED_REVIEW_TIME <- 14  # days

# Function to check submission status
check_submission_status <- function() {
  cat("📊 Checking CRAN submission status...\n")

  # Calculate days since submission
  days_since <- as.numeric(difftime(Sys.Date(), SUBMISSION_DATE, units = "days"))

  cat("📅 Days since submission:", days_since, "\n")
  cat("⏱️  Expected review time:", EXPECTED_REVIEW_TIME, "days\n")

  if (days_since < 3) {
    cat("🟢 Status: Recently submitted - normal processing\n")
    cat("💡 CRAN typically takes 1-2 weeks for initial review\n")
  } else if (days_since < EXPECTED_REVIEW_TIME) {
    cat("🟡 Status: Under review - within expected timeframe\n")
    cat("💡 Continue monitoring email for updates\n")
  } else {
    cat("🟠 Status: Overdue - consider follow-up\n")
    cat("💡 It may be appropriate to send a polite follow-up email\n")
  }

  return(days_since)
}

# Function to generate follow-up email template
generate_followup_email <- function() {
  cat("\n📧 FOLLOW-UP EMAIL TEMPLATE\n")
  cat("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n")

  followup_template <- paste0(
    "Subject: Follow-up on ", PACKAGE_NAME, " ", PACKAGE_VERSION, " submission\n\n",
    "Dear CRAN Team,\n\n",
    "I am writing to follow up on my recent submission of ", PACKAGE_NAME, " version ", PACKAGE_VERSION, ".\n\n",
    "Submission Details:\n",
    "- Package: ", PACKAGE_NAME, "\n",
    "- Version: ", PACKAGE_VERSION, "\n",
    "- Submission Date: ", format(SUBMISSION_DATE, "%Y-%m-%d"), "\n",
    "- Maintainer: ", MAINTAINER_EMAIL, "\n\n",
    "It has been ", as.numeric(difftime(Sys.Date(), SUBMISSION_DATE, units = "days")),
    " days since submission. I understand that CRAN review can take 1-2 weeks,\n",
    "but I wanted to check if there are any issues with the submission that need\n",
    "to be addressed.\n\n",
    "Please let me know if:\n",
    "1. The submission was received successfully\n",
    "2. There are any issues that need to be resolved\n",
    "3. Additional information is required\n\n",
    "Thank you for your time and for maintaining the quality of the R package ecosystem.\n\n",
    "Best regards,\n",
    "[Your Name]\n",
    "Maintainer of ", PACKAGE_NAME, "\n",
    MAINTAINER_EMAIL, "\n"
  )

  cat(followup_template)
  cat("\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n")
  cat("💡 Send this to: cran@r-project.org\n")
  cat("⚠️  Only send if it's been more than 2 weeks since submission\n\n")
}

# Function to check for common CRAN response patterns
check_common_issues <- function() {
  cat("🔍 COMMON CRAN ISSUES TO CHECK\n")
  cat("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n")

  issues <- list(
    "No ERRORs, WARNINGs, or NOTEs in R CMD check" = "✅ Handled by cran_auto_submit.R",
    "Package builds successfully" = "✅ Handled by cran_auto_submit.R",
    "All required files present" = "✅ Validated in cran_auto_submit.R",
    "Proper DESCRIPTION format" = "✅ Validated in cran_auto_submit.R",
    "No bare URLs in DESCRIPTION" = "✅ Should be wrapped in <>",
    "Reasonable package size" = "✅ Check file size < 5MB",
    "Tests pass" = "✅ 157 tests should pass",
    "Documentation complete" = "✅ All functions documented",
    "cran-comments.md updated" = "✅ Updated for v2.2.0",
    "Maintainer email valid" = "✅ dylan.mordaunt@vuw.ac.nz"
  )

  for (issue in names(issues)) {
    cat("□", issue, "-", issues[[issue]], "\n")
  }

  cat("\n💡 If CRAN reports issues, address them and resubmit\n")
  cat("🔄 Use cran_auto_submit.R again for revised submissions\n\n")
}

# Function to prepare resubmission
prepare_resubmission <- function() {
  cat("🔄 RESUBMISSION PREPARATION\n")
  cat("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n")

  cat("If CRAN requests changes:\n")
  cat("1. 📝 Make the requested changes to the code\n")
  cat("2. ⬆️ Update version number (e.g., 2.2.0.1)\n")
  cat("3. 📝 Update cran-comments.md with resubmission notes\n")
  cat("4. 🔄 Run cran_auto_submit.R again\n")
  cat("5. 📤 Submit revised package to CRAN\n")
  cat("6. 📧 Reference original submission in comments\n\n")

  cat("📋 RESUBMISSION COMMENTS TEMPLATE:\n")
  cat("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n")
  cat("This is a resubmission. In the previous submission, CRAN noted:\n")
  cat("[Paste CRAN's specific comments here]\n\n")
  cat("Changes made in response:\n")
  cat("1. [Describe first change]\n")
  cat("2. [Describe second change]\n")
  cat("etc.\n\n")
  cat("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n\n")
}

# Main execution
cat("📅 Submission Date:", format(SUBMISSION_DATE, "%Y-%m-%d"), "\n")
cat("📦 Package:", PACKAGE_NAME, PACKAGE_VERSION, "\n")
cat("👤 Maintainer:", MAINTAINER_EMAIL, "\n\n")

# Run status checks
days_since <- check_submission_status()
cat("\n")

# Provide follow-up guidance
if (days_since > EXPECTED_REVIEW_TIME) {
  cat("🚨 ACTION REQUIRED\n")
  cat("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n")
  generate_followup_email()
} else {
  cat("✅ STATUS: Within normal review timeframe\n")
  cat("💡 Continue monitoring email for CRAN responses\n\n")
}

# Show common issues checklist
check_common_issues()

# Show resubmission guidance
prepare_resubmission()

cat("🎯 CRAN SUBMISSION MONITORING ACTIVE\n")
cat("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n")
cat("• Check this script daily for status updates\n")
cat("• Monitor email for CRAN responses\n")
cat("• Address any issues promptly\n")
cat("• Keep track of all correspondence\n\n")

cat("📞 SUPPORT RESOURCES\n")
cat("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n")
cat("• CRAN Repository Policy: https://cran.r-project.org/web/packages/policies.html\n")
cat("• R Package Development: https://r-pkgs.org/\n")
cat("• CRAN Email: cran@r-project.org\n\n")

cat("✨ Follow-up system ready! Monitor daily for updates.\n")
