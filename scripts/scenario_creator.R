library(readxl)
library(writexl)
library(here)

#' Create a new scenario file.
#'
#' @param scenario_name The name of the scenario.
#' @param base_scenario_sheet The sheet name of the base scenario in the input file.
#' @param modifications A named list of modifications to apply to the base scenario.
#' @param input_file The path to the input Excel file.
#' @param output_dir The directory to save the new scenario file.
#' @return The path to the new scenario file.
create_scenario <- function(scenario_name,
                            base_scenario_sheet = "Simulation inputs",
                            modifications = list(),
                            input_file = here("input", "scenarios", "ausoa_input_public.xlsx"),
                            output_dir = here("input", "scenarios")) {

  # 1. Read the base scenario from the Excel file.
  base_scenario_data <- read_excel(input_file, sheet = base_scenario_sheet)

  # 2. Apply modifications to the scenario data.
  modified_scenario_data <- base_scenario_data
  for (param in names(modifications)) {
    if (param %in% modified_scenario_data$`Base population parameters`) {
      modified_scenario_data$Value[modified_scenario_data$`Base population parameters` == param] <-
        modifications[[param]]
    } else {
      warning(paste("Parameter", param, "not found in the base scenario."))
    }
  }

  # 3. Write the new scenario to a new Excel file.
  output_filename <- paste0(scenario_name, ".xlsx")
  output_path <- file.path(output_dir, output_filename)

  write_xlsx(list(Simulation_inputs = modified_scenario_data), path = output_path)

  print(paste("Scenario", scenario_name, "created at:", output_path))

  return(output_path)
}
