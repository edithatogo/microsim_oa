# install_dependencies.R
# This script installs all necessary R packages for the AUS-OA model.

options(repos = c(CRAN = "https://cloud.r-project.org"))

required_packages <- c("here", "readxl", "dplyr", "tibble", "arrow", "readr", "rmarkdown", "testthat", "pacman")

for (pkg in required_packages) {
  if (!require(pkg, character.only = TRUE)) {
    install.packages(pkg, dependencies = TRUE)
  }
}

# Load p_load from pacman
library(pacman)

# Ensure all required packages are loaded using p_load
p_load(here, readxl, dplyr, tibble, arrow, readr, rmarkdown, testthat)
