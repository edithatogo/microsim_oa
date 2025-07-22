# Script to profile the AUS-OA simulation

# --- Setup ---
# Install the package in the current session to make functions available
devtools::install()
library(ausoa)
library(profvis)

# --- Profiling ---
# Use profvis to profile the execution of the new run script.
# We need to set a seed for reproducibility.
seed <- 123
profvis({
  source(here::here("scripts", "02_AUS_OA_Run_model_v2.R"))
})

# Note: The profvis() function in a non-interactive session will not
# open a browser. It will return a profvis object. To save the output,
# you would typically do:
# p <- profvis({...})
# htmlwidgets::saveWidget(p, "profile_report.html")
#
# For this environment, I will just run it and see the text output.
