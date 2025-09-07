# Simple data conversion script
library(readxl)
library(arrow)

# Convert main Excel file sheets to Parquet
excel_file <- "input/scenarios/ausoa_input_public.xlsx"

# Get sheet names
sheets <- excel_sheets(excel_file)

for (sheet in sheets) {
  data <- read_excel(excel_file, sheet = sheet)
  output_file <- paste0("input/scenarios/", sheet, ".parquet")
  write_parquet(data, output_file)
  message(paste("Converted", sheet, "to", output_file))
}

# Convert CSV files
csv_files <- c("config/coefficients.csv", "config/life_tables_2013.csv", "config/tka_utilisation.csv")

for (csv_file in csv_files) {
  if (file.exists(csv_file)) {
    data <- read.csv(csv_file)
    parquet_file <- sub("\\.csv$", ".parquet", csv_file)
    write_parquet(data, parquet_file)
    message(paste("Converted", csv_file, "to", parquet_file))
  }
}</content>
<parameter name="filePath">\\wsl.localhost\Ubuntu\home\doughnut\github\aus_oa_public\convert_files.R
