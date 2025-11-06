#' Validate Input Data Structure
#'
#' Validates the structure, types, and completeness of input data for simulation functions.
#' Checks for required columns, data types, and data quality issues.
#'
#' @param data The input data to be validated (typically a data.frame)
#' @param required_columns Character vector of column names that must be present
#' @param data_type Expected data type (currently supports "data.frame")
#' @return Vector of error messages, empty if no errors found
#' @export
validate_input_data <- function(data, required_columns = NULL, data_type = "data.frame") {
  errors <- c()
  
  # Check if data exists
  if (is.null(data)) {
    errors <- c(errors, "Input data is NULL")
  } else {
    # Check data type
    if (data_type == "data.frame" && !is.data.frame(data)) {
      errors <- c(errors, paste("Expected data.frame, got", class(data)[1]))
    }
    if (data_type == "data.table" && !inherits(data, "data.table")) {
      errors <- c(errors, paste("Expected data.table, got", class(data)[1]))
    }
    
    # Check for required columns
    if (!is.null(required_columns) && is.data.frame(data)) {
      missing_cols <- setdiff(required_columns, names(data))
      if (length(missing_cols) > 0) {
        errors <- c(errors, paste("Missing required columns:", paste(missing_cols, collapse = ", ")))
      }
    }
    
    # Check for empty data
    if (is.data.frame(data) && nrow(data) == 0) {
      errors <- c(errors, "Input data has 0 rows")
    }
    
    # Check for all-NAs in critical columns
    if (is.data.frame(data) && ncol(data) > 0) {
      critical_cols <- intersect(c("id", "age", "sex"), names(data))
      for (col in critical_cols) {
        if (all(is.na(data[[col]]))) {
          errors <- c(errors, paste("Column", col, "contains only NA values"))
        }
      }
    }
  }
  
  return(errors)
}

#' Validate Configuration Parameters
#'
#' Validates the structure and content of configuration objects used throughout the model.
#' Checks for required sections and parameter validity.
#'
#' @param config The configuration object to validate
#' @return Vector of error messages, empty if no errors found
#' @export
validate_config <- function(config) {
  errors <- c()
  
  if (is.null(config)) {
    errors <- c(errors, "Configuration is NULL")
    return(errors)
  }
  
  # Check for required sections
  required_sections <- c("simulation", "costs", "utilities")
  missing_sections <- setdiff(required_sections, names(config))
  if (length(missing_sections) > 0) {
    errors <- c(errors, paste("Missing configuration sections:", paste(missing_sections, collapse = ", ")))
  }
  
  # Validate simulation section if present
  if ("simulation" %in% names(config)) {
    sim_config <- config$simulation
    if (!is.null(sim_config$time_horizon) && (!is.numeric(sim_config$time_horizon) || sim_config$time_horizon <= 0)) {
      errors <- c(errors, "simulation$time_horizon must be a positive number")
    }
    
    if (!is.null(sim_config$population_size) && (!is.numeric(sim_config$population_size) || sim_config$population_size <= 0)) {
      errors <- c(errors, "simulation$population_size must be a positive number")
    }
  }
  
  # Validate costs section if present
  if ("costs" %in% names(config)) {
    costs_config <- config$costs
    if (is.list(costs_config$tka_primary)) {
      if (is.list(costs_config$tka_primary$hospital_stay)) {
        if (!is.null(costs_config$tka_primary$hospital_stay$value) &&
            (!is.numeric(costs_config$tka_primary$hospital_stay$value) || 
             costs_config$tka_primary$hospital_stay$value < 0)) {
          errors <- c(errors, "Cost values must be non-negative")
        }
      }
    }
  }
  
  return(errors)
}

#' Validate Intervention Parameters
#'
#' Validates the structure and content of intervention parameters.
#' Ensures required fields are present and values are within valid ranges.
#'
#' @param intervention_params The intervention parameters to validate
#' @return Vector of error messages, empty if no errors found
#' @export
validate_intervention_params <- function(intervention_params) {
  errors <- c()
  
  if (is.null(intervention_params)) {
    errors <- c(errors, "Intervention parameters are NULL")
    return(errors)
  }
  
  # Check enabled flag
  if (!isTRUE(intervention_params$enabled %in% c(TRUE, FALSE, T, F, 0, 1))) {
    errors <- c(errors, "intervention_params$enabled must be TRUE/FALSE")
  } else {
    # If not enabled, return early
    if (!isTRUE(intervention_params$enabled)) {
      return(errors)
    }
  }
  
  # Check interventions list
  if (is.null(intervention_params$interventions)) {
    errors <- c(errors, "intervention_params$interventions is NULL")
  } else if (!is.list(intervention_params$interventions)) {
    errors <- c(errors, "intervention_params$interventions must be a list")
  } else {
    # Validate each intervention
    for (int_name in names(intervention_params$interventions)) {
      intervention <- intervention_params$interventions[[int_name]]
      
      if (!is.list(intervention)) {
        errors <- c(errors, paste("Intervention", int_name, "must be a list"))
        next
      }
      
      # Check required fields
      required_fields <- c("type", "start_year", "end_year", "parameters")
      missing_fields <- setdiff(required_fields, names(intervention))
      if (length(missing_fields) > 0) {
        errors <- c(errors, paste("Intervention", int_name, "missing fields:", paste(missing_fields, collapse = ", ")))
      }
      
      # Validate year ranges
      if (!is.null(intervention$start_year) && !is.numeric(intervention$start_year)) {
        errors <- c(errors, paste("Intervention", int_name, "start_year must be numeric"))
      }
      if (!is.null(intervention$end_year) && !is.numeric(intervention$end_year)) {
        errors <- c(errors, paste("Intervention", int_name, "end_year must be numeric"))
      }
      if (!is.null(intervention$start_year) && !is.null(intervention$end_year) &&
          intervention$start_year > intervention$end_year) {
        errors <- c(errors, paste("Intervention", int_name, "start_year must be before end_year"))
      }
      
      # Validate parameters
      if (!is.null(intervention$parameters) && !is.list(intervention$parameters)) {
        errors <- c(errors, paste("Intervention", int_name, "parameters must be a list"))
      }
    }
  }
  
  return(errors)
}

#' Safely Apply Interventions with Validation
#'
#' A wrapper function for apply_interventions that includes comprehensive validation
#' of inputs before applying interventions to the population.
#'
#' @param attribute_matrix The main data frame of the simulation population
#' @param intervention_params A list of parameters for the interventions
#' @param year The current simulation year
#' @return The updated attribute_matrix after applying the interventions
#' @export
safe_apply_interventions <- function(attribute_matrix, intervention_params, year) {
  # Validate inputs
  data_errors <- validate_input_data(attribute_matrix, required_columns = c("id", "age", "sex"))
  param_errors <- validate_intervention_params(intervention_params)
  
  all_errors <- c(data_errors, param_errors)
  
  if (length(all_errors) > 0) {
    stop("Validation errors in safe_apply_interventions:\n", 
         paste("-", all_errors, collapse = "\n"))
  }
  
  # Check year validity
  if (!is.numeric(year) || year < 1900 || year > 2100) {
    stop("Invalid year provided: must be between 1900 and 2100")
  }
  
  # Call the original function
  result <- apply_interventions(attribute_matrix, intervention_params, year)
  
  # Post-processing validation
  if (nrow(result) != nrow(attribute_matrix)) {
    warning("Row count changed unexpectedly after applying interventions")
  }
  
  return(result)
}

#' Safely Calculate Costs with Validation
#'
#' A wrapper function for calculate_costs_fcn that includes comprehensive validation
#' of inputs before calculating costs.
#'
#' @param am_new A data.table representing the attribute matrix with the latest events
#' @param costs_config A list containing the detailed cost parameters
#' @return The attribute matrix with new cost columns added
#' @export
safe_calculate_costs_fcn <- function(am_new, costs_config) {
  # Validate inputs
  data_errors <- validate_input_data(am_new, required_columns = c("tka", "revi", "oa", "dead"))
  config_errors <- validate_config(list(costs = costs_config))
  
  all_errors <- c(data_errors, config_errors)
  
  if (length(all_errors) > 0) {
    stop("Validation errors in safe_calculate_costs_fcn:\n", 
         paste("-", all_errors, collapse = "\n"))
  }
  
  # Call the original function
  result <- calculate_costs_fcn(am_new, costs_config)
  
  # Post-validation
  if (is.data.frame(result)) {
    # Check for negative costs if columns exist
    cost_cols <- grep("_cost_", names(result), value = TRUE)
    for (col in cost_cols) {
      neg_costs <- sum(result[[col]] < 0, na.rm = TRUE)
      if (neg_costs > 0) {
        warning(paste("Found", neg_costs, "negative values in cost column", col))
      }
    }
  }
  
  return(result)
}

#' Safely Load Configuration with Validation
#'
#' A wrapper function for load_config that includes validation of the file existence
#' and content structure before loading.
#'
#' @param config_path The path to the configuration file
#' @return The loaded configuration list
#' @export
safe_load_config <- function(config_path) {
  if (!file.exists(config_path)) {
    stop("Configuration file does not exist: ", config_path)
  }
  
  # Check file extension
  if (!grepl("\\.(ya?ml|json|rds)$", tolower(config_path))) {
    warning("Config file may not be in expected format: ", config_path)
  }
  
  # Attempt to load
  result <- tryCatch({
    load_config(config_path)
  }, error = function(e) {
    stop("Failed to load config from ", config_path, ": ", e$message)
  })
  
  # Validate loaded config
  config_errors <- validate_config(result)
  if (length(config_errors) > 0) {
    warning("Potential issues with loaded config:\n", 
            paste("-", config_errors, collapse = "\n"))
  }
  
  return(result)
}

#' Safely Run Simulation with Parameter Validation
#'
#' A wrapper for simulation runs that performs comprehensive validation of all parameters
#' before executing the simulation.
#'
#' @param population_data The initial population data for the simulation
#' @param time_horizon The number of years to run the simulation
#' @param scenario The scenario to run (default is "base_case")
#' @param config_path Optional path to additional configuration file
#' @return TRUE if validation passes (ready to run simulation)
#' @export
run_simulation_safe <- function(population_data, time_horizon, scenario = "base_case", config_path = NULL) {
  errors <- c()
  
  # Validate parameters
  if (is.null(population_data)) {
    errors <- c(errors, "population_data is NULL")
  }
  
  if (is.null(time_horizon) || !is.numeric(time_horizon) || time_horizon <= 0) {
    errors <- c(errors, "time_horizon must be a positive number")
  }
  
  if (is.null(scenario) || !is.character(scenario)) {
    errors <- c(errors, "scenario must be a character string")
  }
  
  if (length(errors) > 0) {
    stop("Simulation parameter validation failed:\n", 
         paste("-", errors, collapse = "\n"))
  }
  
  # Validate population data structure
  required_cols <- c("id", "age", "sex", "bmi")
  data_errors <- validate_input_data(population_data, required_columns = required_cols)
  if (length(data_errors) > 0) {
    stop("Population data validation failed:\n", 
         paste("-", data_errors, collapse = "\n"))
  }
  
  # Additional checks for age range
  if ("age" %in% names(population_data)) {
    invalid_ages <- population_data$age[!is.na(population_data$age) & population_data$age < 0]
    if (length(invalid_ages) > 0) {
      stop("Found invalid ages (negative): ", paste(head(invalid_ages), collapse = ", "))
    }
  }
  
  # Attempt the simulation (this would call the actual simulation function)
  # Since we don't have the internal simulation function, we return basic validation
  message("All validations passed. Ready to run simulation.")
  
  return(TRUE)
}

#' Check Data Completeness
#'
#' Calculates the completeness ratio of a dataset by determining the proportion of non-missing values.
#'
#' @param df A data frame to check for completeness
#' @return A numeric value representing the completeness ratio (0-1)
#' @export
check_data_completeness <- function(df) {
  if (!is.data.frame(df)) return(NA)
  
  total_values <- length(df)
  missing_values <- sum(sapply(df, function(col) sum(is.na(col))))
  completeness_ratio <- 1 - (missing_values / total_values)
  
  return(completeness_ratio)
}

#' Check Data Consistency
#'
#' Validates the consistency of certain variables in a dataset (e.g., age ranges, sex codes).
#'
#' @param df A data frame to check for consistency issues
#' @return Vector of consistency issues found, empty if none found
#' @export
check_data_consistency <- function(df) {
  issues <- c()
  
  if (is.data.frame(df)) {
    # Check age consistency (if age column exists)
    if ("age" %in% names(df)) {
      invalid_ages <- df[df$age < 0 | df$age > 150, "age", drop = TRUE]
      if (length(invalid_ages) > 0) {
        issues <- c(issues, paste("Found", length(invalid_ages), "invalid age values"))
      }
    }
    
    # Check sex consistency (if sex column exists)
    if ("sex" %in% names(df)) {
      invalid_sex <- df[!df$sex %in% c(0, 1, NA), "sex", drop = TRUE]
      if (length(invalid_sex) > 0) {
        issues <- c(issues, paste("Found", length(invalid_sex), "invalid sex values (not 0/1/NA)"))
      }
    }
  }
  
  return(issues)
}