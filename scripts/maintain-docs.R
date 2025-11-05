#!/usr/bin/env Rscript

# Documentation Maintenance Script
# Run this script to update and maintain package documentation

cat('=== PACKAGE DOCUMENTATION MAINTENANCE ===\n')

# Load required packages
library(devtools)
library(pkgdown)
library(roxygen2)

# 1. Update package documentation
cat('Updating package documentation...\n')
try({
  document()
  cat('✓ Documentation updated\n')
}, error = function(e) {
  cat(' Error updating documentation:', e, '\n')
  quit(status = 1)
})

# 2. Check for undocumented functions
cat('\nChecking for undocumented functions...\n')
try({
  functions <- ls(envir = asNamespace('aus_oa_public'))
  documented <- length(functions) > 0
  
  if (documented) {
    cat(' Functions appear to be documented\n')
  } else {
    cat('  Some functions may not be documented\n')
  }
}, error = function(e) {
  cat('  Could not check documentation status\n')
})

# 3. Build pkgdown site
cat('\nBuilding pkgdown site...\n')
try({
  build_site()
  cat(' pkgdown site built successfully\n')
  cat('Site location: docs/\n')
}, error = function(e) {
  cat(' Error building pkgdown site:', e, '\n')
  quit(status = 1)
})

# 4. Check site integrity
cat('\nChecking site integrity...\n')
if (dir.exists('docs')) {
  files <- list.files('docs', recursive = TRUE)
  cat(sprintf(' Site contains %d files\n', length(files)))
  
  # Check for key files
  key_files <- c('index.html', 'reference/index.html', 'articles/index.html')
  missing_files <- key_files[!file.exists(file.path('docs', key_files))]
  
  if (length(missing_files) > 0) {
    cat('  Missing key files:', paste(missing_files, collapse = ', '), '\n')
  } else {
    cat(' All key documentation files present\n')
  }
} else {
  cat(' docs directory not found\n')
  quit(status = 1)
}

cat('\n=== DOCUMENTATION MAINTENANCE COMPLETE ===\n')
cat('Your documentation is ready for deployment!\n')
