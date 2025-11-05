# CRAN Submission Guide for ausoa v2.2.0

## 🚀 Automated CRAN Submission Process

This guide provides step-by-step instructions for submitting ausoa v2.2.0 to CRAN.

### Prerequisites
- R installed with devtools and rcmdcheck packages
- Package repository cloned and up to date
- Version 2.2.0 committed and tagged

### Step 1: Build the Package
Run in R console:
```r
# Install required packages if needed
install.packages(c("devtools", "rcmdcheck", "desc"))

# Load packages
library(devtools)
library(rcmdcheck)

# Build the package
build_result <- devtools::build()
cat("Package built:", build_result)
```

### Step 2: Run CRAN Checks
Run in R console:
```r
# Run comprehensive R CMD check
check_result <- rcmdcheck::rcmdcheck(
  path = ".",
  args = c("--as-cran", "--no-manual", "--no-vignettes"),
  check_dir = "cran_check_results"
)

# Check results
if (length(check_result$errors) > 0) {
  cat("❌ ERRORS found - fix before submission:\n")
  print(check_result$errors)
} else {
  cat("✅ No errors - ready for CRAN!\n")
}

if (length(check_result$warnings) > 0) {
  cat("⚠️  WARNINGS found - review before submission:\n")
  print(check_result$warnings)
}

if (length(check_result$notes) > 0) {
  cat("📝 NOTES found - review before submission:\n")
  print(check_result$notes)
}
```

### Step 3: Manual CRAN Submission
1. **Go to CRAN submission page**: https://cran.r-project.org/submit.html
2. **Fill out the form**:
   - **Package source**: Select the built `.tar.gz` file (should be named `ausoa_2.2.0.tar.gz`)
   - **Email address**: dylan.mordaunt@vuw.ac.nz
   - **Upload comments**: Select `cran-comments.md`
3. **Submit the form**
4. **Wait for email confirmation** from CRAN

### Step 4: Post-Submission
- **Monitor email** for CRAN responses
- **Address any issues** if CRAN requests changes
- **Resubmit** if needed following CRAN feedback

### Files Required for Submission
- `ausoa_2.2.0.tar.gz` (built package)
- `cran-comments.md` (submission comments)

### Expected Timeline
- **Initial review**: 1-2 weeks
- **Follow-up reviews**: 1-2 weeks each
- **Publication**: 1-4 weeks after approval

### Troubleshooting
- **Build errors**: Check DESCRIPTION file and dependencies
- **Check failures**: Review error messages and fix issues
- **CRAN feedback**: Address all requested changes promptly

---
**Package Information:**
- Name: ausoa
- Version: 2.2.0
- Title: A Microsimulation Model of Osteoarthritis in Australia
- Maintainer: Dylan Mordaunt <dylan.mordaunt@vuw.ac.nz>
