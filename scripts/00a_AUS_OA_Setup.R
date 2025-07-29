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

# Interactively select the scenario
# scenario_selection <- manage_scenarios_interactive()
# For non-interactive use, you can set the scenario directly:
scenario_selection <- get_scenario("public")


sim_setup <-
  scenario_selection %>%
  pivot_longer(cols = everything(), names_to = "param", values_to = "spec") %>%
  filter(!is.na(spec))


probabilistic <-
  sim_setup$spec[sim_setup$param == "Probabilistic"] %>% as.logical()
calibration_mode <-
  sim_setup$spec[sim_setup$param == "Calibration mode"] %>% as.logical()

parallel <-
  sim_setup$spec[sim_setup$param == "Parallelize"] %>% as.logical()

startyear <-
  sim_setup$spec[sim_setup$param == "Simulation start year"] %>% as.integer()
