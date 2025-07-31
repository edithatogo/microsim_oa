# LIBRARIES
# Install pacman if it is not already installed
if (!require("pacman")) install.packages("pacman")
p_load(
  here, # for file paths
  rmarkdown, # for rendering rmarkdown
  quarto, # for rendering quarto
  readxl, # for reading in excel files
  tidyverse, # for data manipulation
  logr, # for logging
  kableExtra, # html tables
  arrow, # for parquet files (parquet takes less space than csv)
  reshape2, # converting data from wide to long
  gt, # for table development and display
  yaml # for reading yaml files
)
options(dplyr.summarise.inform = FALSE)

# SOURCE THE FUNCTIONS
source(here("R", "config_loader.R"))
source(here("R", "apply_policy_levers_fcn.R"))
source(here("R", "calculate_costs_fcn.R"))
source(here("R", "update_pros_fcn.R"))
source(here("R", "calculate_revision_risk_fcn.R"))


# Graph options
my_theme <-
  theme_bw(base_family = "serif") +
  theme(
    axis.title.x = element_text(margin = margin(t = 10), size = 14),
    axis.title.y = element_text(margin = margin(r = 10), size = 14),
    axis.text = element_text(size = 12),
    legend.background = element_blank(),
    legend.text = element_text(size = 14),
    legend.title = element_text(size = 16)
  )
theme_set(my_theme)
colors <- c(
  "#EE3377", "#0077BB", "#009988", "firebrick", "#33BBEE", "#CC3311",
  "darkmagenta", "black", "tan4"
)



# Load the config files
simulation_config <- load_config(here("config", "simulation.yaml"))
model_parameters <- load_config(here("config", "coefficients.yaml"))
comorbidity_parameters <- load_config(here("config", "comorbidities.yaml"))
intervention_parameters <- load_config(here("config", "interventions.yaml"))

# Apply policy levers to the parameters
model_parameters <- apply_policy_levers(model_parameters, simulation_config$policy_levers)


# Load the scenario management script
source(here("scripts", "manage_scenarios.R"))

# For non-interactive use, the script now reads all parameters directly
scenario_selection <- get_all_scenarios()


# Create a clean, reliable key-value data frame of parameters
params <- scenario_selection %>%
  rename(key = `Base population parameters`, value = `Value`) %>%
  select(key, value) %>%
  filter(!is.na(key)) %>%
  # Take the first value for each key to handle duplicates
  group_by(key) %>%
  summarise(value = first(value))

# A helper function to safely extract parameters from the new 'params' object
get_param_value <- function(param_name) {
  val <- params$value[params$key == param_name]
  if (length(val) == 0) return(NA)
  return(val)
}

probabilistic <- as.logical(get_param_value("Probabilistic"))
calibration_mode <- as.logical(get_param_value("Calibration mode"))
parallel <- as.logical(get_param_value("Parallelize"))
startyear <- as.integer(get_param_value("Simulation start year"))
