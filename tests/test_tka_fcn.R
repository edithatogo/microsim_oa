# test_tka_fcn.R (simplified)

library(here)
library(arrow)
library(yaml)

# --- 1. Load Data ---
am_curr <- as.data.frame(arrow::read_parquet(here("input", "population", "am_2013.parquet")))
am_curr$pain <- 0
am_curr$function_score <- 0

# --- 2. Load Coefficients ---
model_coefficients <- yaml::read_yaml(here("config", "coefficients.yaml"))
extract_live_values <- function(x) {
  if (is.list(x)) {
    if ("live" %in% names(x)) return(x$live)
    else if ("value" %in% names(x)) return(x$value)
    else return(lapply(x, extract_live_values))
  } else {
    return(x)
  }
}
cycle.coefficents <- extract_live_values(model_coefficients$coefficients)

# --- 3. Print names ---
print("am_curr columns:")
print(names(am_curr))

print("c9 coefficients:")
print(names(cycle.coefficents$c9))

# --- 4. Check for missing columns ---
required_cols <- c("age", "drugoa", "ccount", "mhc", "tka1", "kl2", "kl3", "kl4", "pain", "function_score")
missing_cols <- setdiff(required_cols, names(am_curr))
if (length(missing_cols) > 0) {
  print("Missing columns in am_curr:")
  print(missing_cols)
} else {
  print("All required columns are present in am_curr.")
}

# --- 5. Check for missing coefficients ---
required_coeffs <- c("c9_cons", "c9_age", "c9_age2", "c9_drugoa", "c9_ccount",
                     "c9_mhc", "c9_tkr", "c9_kl2hr", "c9_kl3hr", "c9_kl4hr",
                     "c9_pain", "c9_function")
missing_coeffs <- setdiff(required_coeffs, names(cycle.coefficents$c9))
if (length(missing_coeffs) > 0) {
    print("Missing coefficients in c9:")
    print(missing_coeffs)
} else {
    print("All required coefficients are present in c9.")
}
