# scripts/inspect_debug_file.R
coeffs_debug <- readRDS("debug_coeffs.rds")

print("--- Structure of the coefficients object ---")
str(coeffs_debug, max.level = 4, list.len = 200)
