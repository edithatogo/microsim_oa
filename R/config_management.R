# Configuration management improvements for AUS-OA package

# Load required libraries
library(yaml)
library(data.table)

#' Enhanced Configuration Loader
#'
#' Loads and validates configuration with enhanced error handling and defaults
#'
#' @param config_path Path to configuration file
#' @param validate Logical indicating whether to validate config
#' @return List containing validated configuration
#' @export
enhanced_load_config <- function(config_path, validate = TRUE) {
  # Check if file exists
  if (!file.exists(config_path)) {
    stop("Configuration file does not exist: ", config_path)
  }

  # Check file extension
  if (!grepl("\\.(ya?ml)$", tolower(config_path))) {
    warning("Expected YAML configuration file, got: ", config_path)
  }

  # Attempt to load configuration
  config <- tryCatch({
    config <- yaml::read_yaml(config_path)
    
    # Apply default values if not specified
    config <- fill_missing_defaults(config)
    
    # Validate if requested
    if (validate) {
      validation_result <- validate_config_comprehensive(config)
      if (!validation_result$valid) {
        stop("Configuration validation failed:\n",
             paste(validation_result$errors, collapse = "\n"))
      }
    }
    
    return(config)
  }, error = function(e) {
    stop("Failed to load configuration from ", config_path, ": ", e$message)
  })
  
  return(config)
}

#' Fill Missing Configuration Defaults
#'
#' Adds default values to configuration for missing parameters
#'
#' @param config Configuration list to process
#' @return Configuration list with defaults filled in
fill_missing_defaults <- function(config) {
  # Define default values
  defaults <- list(
    simulation = list(
      time_horizon = 20,
      start_year = 2025,
      population_size = 1000,
      seed = 12345,
      verbose = TRUE
    ),
    costs = list(
      tka_primary = list(
        hospital_stay = list(value = 15000, perspective = "healthcare_system"),
        patient_gap = list(value = 2000, perspective = "patient"),
        annual_review = list(value = 200, perspective = "healthcare_system")
      ),
      tka_revision = list(
        hospital_stay = list(value = 20000, perspective = "healthcare_system"),
        patient_gap = list(value = 2500, perspective = "patient")
      ),
      dvt_complication = list(
        hospital_stay = list(value = 3000, perspective = "healthcare_system"),
        anticoagulant = list(value = 500, perspective = "healthcare_system")
      ),
      pji_complication = list(
        hospital_stay = list(value = 8000, perspective = "healthcare_system"),
        antibiotics = list(value = 1500, perspective = "healthcare_system")
      )
    ),
    utilities = list(
      kl0 = 0.85,
      kl1 = 0.80,
      kl2 = 0.72,
      kl3 = 0.65,
      kl4 = 0.55,
      post_tka = 0.78,
      dead = 0.0
    ),
    risks = list(
      tka_annual = 0.02,  # Annual probability of primary TKA
      revision_annual = 0.03,  # Annual probability of revision after TKA
      dvt_prob = 0.05,  # Probability of DVT after TKA
      pji_prob = 0.01   # Probability of PJI after TKA
    )
  )
  
  # Fill in missing elements recursively
  for (section_name in names(defaults)) {
    if (is.null(config[[section_name]])) {
      config[[section_name]] <- list()
    }
    
    if (is.list(defaults[[section_name]]) && is.list(config[[section_name]])) {
      for (param_name in names(defaults[[section_name]])) {
        if (is.null(config[[section_name]][[param_name]])) {
          config[[section_name]][[param_name]] <- defaults[[section_name]][[param_name]]
        } else if (is.list(defaults[[section_name]][[param_name]]) && 
                   is.list(config[[section_name]][[param_name]])) {
          # Nested parameters
          for (nested_param in names(defaults[[section_name]][[param_name]])) {
            if (is.null(config[[section_name]][[param_name]][[nested_param]])) {
              config[[section_name]][[param_name]][[nested_param]] <- 
                defaults[[section_name]][[param_name]][[nested_param]]
            }
          }
        }
      }
    }
  }
  
  return(config)
}

#' Comprehensive Configuration Validator
#'
#' Validates configuration structure, values, and interdependencies
#'
#' @param config Configuration list to validate
#' @return List with validation results (valid: boolean, errors: character vector)
validate_config_comprehensive <- function(config) {
  errors <- c()
  
  if (is.null(config) || !is.list(config)) {
    return(list(valid = FALSE, errors = "Configuration must be a list"))
  }
  
  # Validate simulation section
  if ("simulation" %in% names(config)) {
    sim <- config$simulation
    if (!is.null(sim$time_horizon) && (!is.numeric(sim$time_horizon) || sim$time_horizon <= 0)) {
      errors <- c(errors, "simulation$time_horizon must be a positive number")
    }
    if (!is.null(sim$population_size) && (!is.numeric(sim$population_size) || sim$population_size <= 0)) {
      errors <- c(errors, "simulation$population_size must be a positive number")
    }
    if (!is.null(sim$seed) && (!is.numeric(sim$seed) || length(sim$seed) != 1)) {
      errors <- c(errors, "simulation$seed must be a single numeric value")
    }
  }
  
  # Validate costs section
  if ("costs" %in% names(config)) {
    costs <- config$costs
    if (is.list(costs$tka_primary)) {
      if (is.list(costs$tka_primary$hospital_stay)) {
        if (!is.null(costs$tka_primary$hospital_stay$value) && 
            (!is.numeric(costs$tka_primary$hospital_stay$value) || costs$tka_primary$hospital_stay$value < 0)) {
          errors <- c(errors, "Cost values must be non-negative")
        }
      }
    }
    if (is.list(costs$tka_revision)) {
      if (is.list(costs$tka_revision$hospital_stay)) {
        if (!is.null(costs$tka_revision$hospital_stay$value) && 
            (!is.numeric(costs$tka_revision$hospital_stay$value) || costs$tka_revision$hospital_stay$value < 0)) {
          errors <- c(errors, "Revision cost values must be non-negative")
        }
      }
    }
  }
  
  # Validate utilities section
  if ("utilities" %in% names(config)) {
    utils <- config$utilities
    for (util_name in c("kl0", "kl1", "kl2", "kl3", "kl4", "post_tka")) {
      if (!is.null(utils[[util_name]]) && 
          (!is.numeric(utils[[util_name]]) || utils[[util_name]] < 0 || utils[[util_name]] > 1)) {
        errors <- c(errors, paste0("utilities$", util_name, " must be between 0 and 1"))
      }
    }
  }
  
  # Validate risks section
  if ("risks" %in% names(config)) {
    risks <- config$risks
    for (risk_name in c("tka_annual", "revision_annual", "dvt_prob", "pji_prob")) {
      if (!is.null(risks[[risk_name]]) && 
          (!is.numeric(risks[[risk_name]]) || risks[[risk_name]] < 0 || risks[[risk_name]] > 1)) {
        errors <- c(errors, paste0("risks$", risk_name, " must be between 0 and 1"))
      }
    }
  }
  
  return(list(valid = length(errors) == 0, errors = errors))
}

#' Save Configuration with Validation
#'
#' Saves configuration to file after validation
#'
#' @param config Configuration list to save
#' @param file_path Path where to save the configuration
#' @param validate Whether to validate before saving
#' @return TRUE if successful
#' @export
save_config_safe <- function(config, file_path, validate = TRUE) {
  if (validate) {
    validation_result <- validate_config_comprehensive(config)
    if (!validation_result$valid) {
      stop("Config validation failed before saving:\n",
           paste(validation_result$errors, collapse = "\n"))
    }
  }
  
  yaml::write_yaml(config, file_path)
  return(TRUE)
}

#' Update Configuration Section
#'
#' Updates a specific section of the configuration safely
#'
#' @param config Base configuration
#' @param section_name Name of section to update
#' @param new_values New values for the section
#' @return Updated configuration
#' @export
update_config_section_safe <- function(config, section_name, new_values) {
  if (!is.list(config)) {
    stop("Config must be a list")
  }
  
  if (!is.character(section_name) || length(section_name) != 1) {
    stop("section_name must be a single character string")
  }
  
  if (!is.list(new_values)) {
    stop("new_values must be a list")
  }
  
  # Update the section
  if (section_name %in% names(config)) {
    config[[section_name]] <- merge_lists_recursive(config[[section_name]], new_values)
  } else {
    config[[section_name]] <- new_values
  }
  
  # Validate updated configuration
  validation_result <- validate_config_comprehensive(config)
  if (!validation_result$valid) {
    warning("Updated configuration has validation warnings:\n",
            paste(validation_result$errors, collapse = "\n"))
  }
  
  return(config)
}

# Helper function for recursive list merging
merge_lists_recursive <- function(base_list, update_list) {
  for (item_name in names(update_list)) {
    if (is.list(update_list[[item_name]]) && is.list(base_list[[item_name]])) {
      base_list[[item_name]] <- merge_lists_recursive(base_list[[item_name]], update_list[[item_name]])
    } else {
      base_list[[item_name]] <- update_list[[item_name]]
    }
  }
  
  return(base_list)
}