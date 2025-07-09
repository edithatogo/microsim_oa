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
  gt # for table development and display
)
options(dplyr.summarise.inform = FALSE)


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



# Load the input file
sim_setup <- yaml::read_yaml(here("config", "simulation_setup.yml"))

probabilistic <- sim_setup$probabilistic
calibration_mode <- sim_setup$calibration_mode
parallel <- sim_setup$parallelize
startyear <- sim_setup$simulation_start_year
