#!/usr/bin/env Rscript
#' Data Conversion Script for AUS-OA Model
#'
#' This script converts CSV and Excel files to Parquet format
#' for improved performance and data portability.

library(arrow)
library(readxl)
library(readr)
library(here)

# Set working directory
setwd(here())

#' Convert Excel file with multiple sheets to Parquet
convert_excel_sheets <- function(excel_file, output_dir = "input/scenarios") {
  sheets <- excel_sheets(excel_file)

  for (sheet in sheets) {
    data <- read_excel(excel_file, sheet = sheet)
    output_file <- file.path(output_dir, paste0(sheet, ".parquet"))
    write_parquet(data, output_file)
    message(sprintf("Converted sheet '%s' to %s", sheet, output_file))
  }
}

#' Convert CSV files to Parquet
convert_csv_files <- function(csv_files) {
  for (csv_file in csv_files) {
    data <- read_csv(csv_file, show_col_types = FALSE)
    parquet_file <- sub("\\.csv$", ".parquet", csv_file)
    write_parquet(data, parquet_file)
    message(sprintf("Converted %s to %s", csv_file, parquet_file))
  }
}

# Convert main input files
message("Converting main input files...")

# Convert Excel files in scenarios directory
excel_files <- list.files("input/scenarios", pattern = "\\.xlsx?$", full.names = TRUE)
for (excel_file in excel_files) {
  tryCatch({
    convert_excel_sheets(excel_file)
  }, error = function(e) {
    warning(sprintf("Failed to convert %s: %s", excel_file, e$message))
  })
}

# Convert CSV files in config directory
csv_files <- list.files("config", pattern = "\\.csv$", full.names = TRUE)
convert_csv_files(csv_files)

# Convert population CSV files
pop_csv_files <- list.files("input/population", pattern = "\\.csv$", full.names = TRUE)
convert_csv_files(pop_csv_files)

message("Data conversion completed!")</content>
<parameter name="filePath">\\wsl.localhost\Ubuntu\home\doughnut\github\aus_oa_public\scripts\convert_data_to_parquet.R
