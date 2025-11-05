#!/usr/bin/env Rscript

# Simple test runner to bypass renv issues
cat("Starting ML framework test...\n")

# Set working directory
setwd("/home/doughnut/github/aus_oa_public")

# Load required packages
library(data.table)
library(dplyr)
library(caret)
library(ggplot2)

# Suppress warnings
options(warn = -1)

# Source the ML modules
source("R/ml_framework.R")
source("R/predictive_modeling.R")

# Source the test file
source("tests/test_ml_framework.R")

# Run the test suite
run_ml_test_suite()
