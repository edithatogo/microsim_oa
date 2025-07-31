# install_dependencies.R

# This script installs all the necessary packages for the AUS-OA model.

# It uses the pacman package to manage packages. If pacman is not installed,
# it will be installed first.

if (!require("pacman")) install.packages("pacman")

pacman::p_load(
  here,
  rmarkdown,
  quarto,
  readxl,
  tidyverse,
  logr,
  kableExtra,
  arrow,
  reshape2,
  gt,
  testthat, # for testing
  yaml, # for reading yaml files
  readr # for reading csv files
)