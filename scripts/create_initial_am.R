# Temporary script to create the initial attribute matrix in Parquet format

# Load required packages
library(tidyverse)
library(arrow)

# Define file paths
simpop_file <- "input/population/mysim_public.csv"
output_file <- "input/population/am_2013.parquet"

# Load synthetic dataset
am <- read_csv(simpop_file, show_col_types = FALSE)

# Add year column
am$year <- 2013

# Write to Parquet
write_parquet(am, output_file)

cat("Successfully created", output_file, "\n")
