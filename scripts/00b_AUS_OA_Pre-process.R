# PRE-PROCESSING
source(here::here("scripts", "00a_AUS_OA_Setup.R"))

## Synthetic dataset
simpop_file <- get_param_value("Synthetic population if not generating a new one")
simpop_file <- here("input", "population", simpop_file)

run_sim_pop <- as.logical(get_param_value("Generate new base population?"))

if (startyear == 2013 && (run_sim_pop == TRUE || !file.exists(simpop_file))) {
  pop_weight <- as.numeric(get_param_value("Population scale"))
  scale_hilda <- as.numeric(get_param_value("Population adjuster"))
  input_data <- get_param_value("Input data for base population")

  input_data <-
    here("input", "population", input_data)

  source(here("scripts", "00_PREP_Synthetic_population.R"))
}

## Prepare am matrix

## Get the attribute matrix for base population
## This is a check to see if the base population dimensions and
## the attribute matrix for start year are consistent
if (startyear == 2013) {
  source(here("scripts", "01_AUS_OA_Setup_attribute_matrix.R"))
}


am_file <- here("input", "population", str_glue("am_{startyear}.parquet"))
if (!file.exists(am_file) && startyear != 2013) {
  stop("Attribute matrix for specified start year does not exist.
       Run the simulation from 2013 to specified start year
       in deterministic mode to save the attribute matrix. Then re-run
       from new start year")
}

## Compile data to validate the model
## Only run this step if data does not exist
file_paths <-
  c(
    here("supporting_data", "Cleaned_validation_data_BMI.csv"),
    here("supporting_data", "Cleaned_validation_data_OA.csv"),
    here("supporting_data", "Cleaned_validation_data_TKR.csv")
  )

if (any(!file.exists(file_paths))) {
  # Run the script if any of the files does not exist
  cat("One or more files do not exist. Running script...\n")

  # Run pre-processing script
  source(here("scripts", "00_PREP_Validation_data.R"))
} else {
  cat("All validation files exist. No action needed.\n")
}