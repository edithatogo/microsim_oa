#' Data I/O Utilities for AUS-OA Model
#'
#' This module provides utilities for efficient data I/O operations
#' using the Arrow/Parquet format for improved performance.
#'
#' @import arrow
#' @import readxl
#' @import readr
#' @import here
#' @export

#' Convert CSV/Excel files to Parquet format
#'
#' @param input_path Path to the input CSV or Excel file
#' @param output_path Path to the output Parquet file (optional)
#' @param sheet Excel sheet name (if applicable)
#' @return Path to the created Parquet file
#' @export
convert_to_parquet <- function(input_path, output_path = NULL, sheet = NULL) {
  # Determine output path if not provided
  if (is.null(output_path)) {
    output_path <- sub("\\.(csv|xlsx?|xls)$", ".parquet", input_path)
  }

  # Read data based on file extension
  if (grepl("\\.csv$", input_path)) {
    data <- readr::read_csv(input_path, show_col_types = FALSE)
  } else if (grepl("\\.(xlsx?|xls)$", input_path)) {
    if (is.null(sheet)) {
      data <- readxl::read_excel(input_path)
    } else {
      data <- readxl::read_excel(input_path, sheet = sheet)
    }
  } else {
    stop("Unsupported file format. Only CSV and Excel files are supported.")
  }

  # Write to Parquet
  arrow::write_parquet(data, output_path)

  message(sprintf("Converted %s to %s", input_path, output_path))
  return(output_path)
}

#' Read data from Parquet file with fallback to CSV/Excel
#'
#' @param file_path Path to the data file (Parquet, CSV, or Excel)
#' @param sheet Excel sheet name (if applicable)
#' @return Data frame containing the loaded data
#' @export
read_data <- function(file_path, sheet = NULL) {
  # Try Parquet first
  parquet_path <- sub("\\.(csv|xlsx?|xls)$", ".parquet", file_path)

  if (file.exists(parquet_path)) {
    return(arrow::read_parquet(parquet_path))
  }

  # Fallback to original format
  if (grepl("\\.csv$", file_path)) {
    return(readr::read_csv(file_path, show_col_types = FALSE))
  } else if (grepl("\\.(xlsx?|xls)$", file_path)) {
    if (is.null(sheet)) {
      return(readxl::read_excel(file_path))
    } else {
      return(readxl::read_excel(file_path, sheet = sheet))
    }
  } else {
    stop("Unsupported file format")
  }
}

#' Batch convert directory of CSV/Excel files to Parquet
#'
#' @param input_dir Directory containing CSV/Excel files
#' @param output_dir Directory to save Parquet files (optional)
#' @param recursive Whether to search subdirectories
#' @return Vector of paths to created Parquet files
#' @export
convert_directory_to_parquet <- function(input_dir, output_dir = NULL, recursive = TRUE) {
  if (is.null(output_dir)) {
    output_dir <- input_dir
  }

  # Find all CSV and Excel files
  csv_files <- list.files(input_dir, pattern = "\\.csv$", full.names = TRUE, recursive = recursive)
  excel_files <- list.files(input_dir, pattern = "\\.(xlsx?|xls)$", full.names = TRUE, recursive = recursive)

  all_files <- c(csv_files, excel_files)
  converted_files <- character()

  for (file_path in all_files) {
    tryCatch({
      converted_path <- convert_to_parquet(file_path)
      converted_files <- c(converted_files, converted_path)
    }, error = function(e) {
      warning(sprintf("Failed to convert %s: %s", file_path, e$message))
    })
  }

  return(converted_files)
}
