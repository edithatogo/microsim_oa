# scripts/manage_scenarios.R

library(readxl)
library(writexl)
library(here)

# Define the path to the scenario file
scenario_file_path <- here("input", "scenarios", "ausoa_input_public.xlsx")

# Function to validate a scenario's parameters
validate_scenario <- function(scenario) {
  errors <- c()
  
  # Check for required columns (using the names from the wide format)
  required_cols <- c("scenario_name", "Probabilistic", "Calibration mode", "Parallelize", "Simulation start year")
  missing_cols <- setdiff(required_cols, names(scenario))
  if (length(missing_cols) > 0) {
    errors <- c(errors, paste("Missing required columns:", paste(missing_cols, collapse = ", ")))
  }
  
  # Check for NA or empty values in critical fields
  for (col in required_cols) {
    if (any(is.na(scenario[[col]])) || any(scenario[[col]] == "")) {
      errors <- c(errors, paste("Column '", col, "' contains missing or empty values."))
    }
  }
  
  # Check data types
  if (!is.logical(scenario$`Probabilistic`)) {
    errors <- c(errors, "'Probabilistic' must be a logical value (TRUE/FALSE).")
  }
  if (!is.logical(scenario$`Calibration mode`)) {
    errors <- c(errors, "'Calibration mode' must be a logical value (TRUE/FALSE).")
  }
  if (!is.logical(scenario$`Parallelize`)) {
    errors <- c(errors, "'Parallelize' must be a logical value (TRUE/FALSE).")
  }
  if (!is.numeric(scenario$`Simulation start year`)) {
    errors <- c(errors, "'Simulation start year' must be a numeric value.")
  }
  
  if (length(errors) > 0) {
    stop(paste("Scenario validation failed:\n-", paste(errors, collapse = "\n- ")))
  }
  
  return(TRUE)
}


# Function to read all scenarios from the Excel file
get_all_scenarios <- function() {
  read_excel(scenario_file_path, sheet = "Simulation inputs")
}

# Function to get a specific scenario by name
get_scenario <- function(scenario_name) {
  scenarios <- get_all_scenarios()
  scenario <- scenarios[scenarios$scenario_name == scenario_name, ]
  if (nrow(scenario) == 0) {
    stop(paste("Scenario '", scenario_name, "' not found."))
  }
  
  # Validate the selected scenario
  validate_scenario(scenario)
  
  return(scenario)
}

# Function to create a new scenario
create_scenario <- function(new_scenario_data) {
  # Validate the new scenario data
  validate_scenario(new_scenario_data)
  
  scenarios <- get_all_scenarios()
  
  if (new_scenario_data$scenario_name %in% scenarios$scenario_name) {
    stop(paste("Scenario '", new_scenario_data$scenario_name, "' already exists."))
  }
  
  updated_scenarios <- rbind(scenarios, new_scenario_data)
  write_xlsx(updated_scenarios, scenario_file_path)
  print(paste("Scenario '", new_scenario_data$scenario_name, "' created successfully."))
}

# Function to update an existing scenario
update_scenario <- function(scenario_name, updated_data) {
  # Validate the updated data
  validate_scenario(updated_data)
  
  scenarios <- get_all_scenarios()
  
  if (!scenario_name %in% scenarios$scenario_name) {
    stop(paste("Scenario '", scenario_name, "' not found."))
  }
  
  scenario_index <- which(scenarios$scenario_name == scenario_name)
  scenarios[scenario_index, ] <- updated_data
  
  write_xlsx(scenarios, scenario_file_path)
  print(paste("Scenario '", scenario_name, "' updated successfully."))
}

# --- Interactive Scenario Management ---

# The following code provides a simple command-line interface for managing scenarios.
# This can be run interactively in an R session.

manage_scenarios_interactive <- function() {
  cat("Welcome to the AUS-OA Scenario Manager!\n")
  
  while (TRUE) {
    cat("\nAvailable commands: [s]elect, [c]reate, [u]pdate, [l]ist, [q]uit\n")
    command <- readline("Enter command: ")
    
    if (command == "l") {
      cat("\nAvailable scenarios:\n")
      scenarios <- get_all_scenarios()
      print(scenarios$scenario_name)
      
    } else if (command == "s") {
      scenario_name <- readline("Enter the name of the scenario to select: ")
      selected_scenario <- try(get_scenario(scenario_name), silent = TRUE)
      if (inherits(selected_scenario, "try-error")) {
        cat("Error:", as.character(selected_scenario), "\n")
      } else {
        cat("\nSelected scenario:\n")
        print(selected_scenario)
        return(selected_scenario)
      }
      
    } else if (command == "c") {
      cat("\nEnter details for the new scenario:\n")
      new_name <- readline("Scenario Name: ")
      
      # For simplicity, we'll just create a copy of the 'public' scenario
      # In a real app, you would prompt for all fields.
      scenarios <- get_all_scenarios()
      new_scenario <- scenarios[scenarios$scenario_name == "public",]
      new_scenario$scenario_name <- new_name
      
      # Prompt for other key values
      new_scenario$`Probabilistic` <- as.logical(readline("Probabilistic (TRUE/FALSE): "))
      new_scenario$`Calibration mode` <- as.logical(readline("Calibration mode (TRUE/FALSE): "))
      new_scenario$`Parallelize` <- as.logical(readline("Parallelize (TRUE/FALSE): "))
      new_scenario$`Simulation start year` <- as.integer(readline("Simulation start year: "))
      
      
      result <- try(create_scenario(new_scenario), silent = TRUE)
      if (inherits(result, "try-error")) {
        cat("Error:", as.character(result), "\n")
      }
      
    } else if (command == "u") {
      scenario_name <- readline("Enter the name of the scenario to update: ")
      # In a real application, you would prompt for which fields to update.
      cat("This is a placeholder for the update functionality.\n")
      
    } else if (command == "q") {
      cat("Exiting Scenario Manager.\n")
      break
    } else {
      cat("Invalid command.\n")
    }
  }
}

# To run the interactive manager, uncomment the following line:
# manage_scenarios_interactive()