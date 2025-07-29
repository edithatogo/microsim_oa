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

# Apply policy levers to the parameters
model_parameters <- apply_policy_levers(model_parameters, simulation_config$policy_levers)


# Load the input file
if (exists("scenario")) {
  input_file <-
    here("input", "scenarios", paste0("ausoa_input_", scenario, ".xlsx"))
} else {
  input_file <- here("input", "scenarios", "choose file.txt")
  print("PLEASE CHOOSE THE INPUT FILE FROM THE MENU...")
  input_file <- choose.files(input_file)
  scenario <- gsub(".xlsx$", "", basename(input_file))
  scenario <- gsub("ausoa_input_", "", scenario)
}

sim_setup <-
  read_excel(input_file, sheet = "Simulation inputs") %>%
  rename(
    param = `Base population parameters`,
    spec  = `Value`
  ) %>%
  filter(!is.na(spec))


probabilistic <-
  sim_setup$spec[sim_setup$param == "Probabilistic"] %>% as.logical()
calibration_mode <-
  sim_setup$spec[sim_setup$param == "Calibration mode"] %>% as.logical()

parallel <-
  sim_setup$spec[sim_setup$param == "Parallelize"] %>% as.logical()

startyear <-
  sim_setup$spec[sim_setup$param == "Simulation start year"] %>% as.integer()
