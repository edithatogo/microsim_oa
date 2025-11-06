# Configuration validation utilities for AUS-OA package

#' Validate AUS-OA Configuration Objects
#'
#' Validates the structure and content of configuration objects used throughout the AUS-OA model.
#' Checks for required sections, parameter validity, and cross-parameter consistency.
#' 
#' @param config The configuration object to validate
#' @return A list with 'valid' (logical) and 'errors' (character vector) elements
#' @export
validate_ausoa_config <- function(config) {
  errors <- c()
  
  if (is.null(config)) {
    return(list(valid = FALSE, errors = "Configuration is NULL"))
  }
  
  # Check required top-level sections
  required_sections <- c("simulation", "costs", "utilities", "risks")
  missing_sections <- setdiff(required_sections, names(config))
  
  if (length(missing_sections) > 0) {
    errors <- c(errors, paste("Missing required configuration sections:", 
                              paste(missing_sections, collapse = ", ")))
  }
  
  # Validate simulation section if present
  if ("simulation" %in% names(config) && is.list(config$simulation)) {
    sim_config <- config$simulation
    
    # Validate time parameters
    if (!is.null(sim_config$time_horizon)) {
      if (!is.numeric(sim_config$time_horizon) || sim_config$time_horizon <= 0) {
        errors <- c(errors, "simulation$time_horizon must be a positive number")
      }
    }
    
    if (!is.null(sim_config$start_year)) {
      if (!is.numeric(sim_config$start_year) || sim_config$start_year < 1900 || sim_config$start_year > 2100) {
        errors <- c(errors, "simulation$start_year must be a valid year (1900-2100)")
      }
    }
    
    if (!is.null(sim_config$population_size)) {
      if (!is.numeric(sim_config$population_size) || sim_config$population_size <= 0) {
        errors <- c(errors, "simulation$population_size must be a positive number")
      }
    }
  }
  
  # Validate costs section if present
  if ("costs" %in% names(config) && is.list(config$costs)) {
    cost_config <- config$costs
    
    if ("tka_primary" %in% names(cost_config) && is.list(cost_config$tka_primary)) {
      primary_costs <- cost_config$tka_primary
      
      if ("hospital_stay" %in% names(primary_costs) && is.list(primary_costs$hospital_stay)) {
        hosp_cost <- primary_costs$hospital_stay
        if (!is.null(hosp_cost$value) && (!is.numeric(hosp_cost$value) || hosp_cost$value < 0)) {
          errors <- c(errors, "Cost values must be non-negative")
        }
      }
    }
    
    if ("tka_revision" %in% names(cost_config) && is.list(cost_config$tka_revision)) {
      rev_costs <- cost_config$tka_revision
      
      if ("hospital_stay" %in% names(rev_costs) && is.list(rev_costs$hospital_stay)) {
        hosp_cost <- rev_costs$hospital_stay
        if (!is.null(hosp_cost$value) && (!is.numeric(hosp_cost$value) || hosp_cost$value < 0)) {
          errors <- c(errors, "Cost values must be non-negative")
        }
      }
    }
  }
  
  # Validate utilities section if present
  if ("utilities" %in% names(config) && is.list(config$utilities)) {
    util_config <- config$utilities
    
    # Check for required utility values
    required_utils <- c("kl0", "kl1", "kl2", "kl3", "kl4", "post_tka", "dead")
    missing_utils <- setdiff(required_utils, names(util_config))
    if (length(missing_utils) > 0) {
      errors <- c(errors, paste("Missing required utility values:", 
                                paste(missing_utils, collapse = ", ")))
    }
    
    # Validate utility ranges (should be between 0 and 1)
    util_names <- intersect(required_utils, names(util_config))
    for (util_name in util_names) {
      util_val <- util_config[[util_name]]
      if (is.numeric(util_val) && (util_val < 0 || util_val > 1)) {
        errors <- c(errors, paste("Utility", util_name, "must be between 0 and 1, got", util_val))
      }
    }
  }
  
  # Validate risks section if present
  if ("risks" %in% names(config) && is.list(config$risks)) {
    risk_config <- config$risks
    
    # Validate probability ranges
    prob_params <- c("dvt_prob", "pji_prob")
    for (param in prob_params) {
      if (!is.null(risk_config[[param]])) {
        param_val <- risk_config[[param]]
        if (is.numeric(param_val) && (param_val < 0 || param_val > 1)) {
          errors <- c(errors, paste("Risk parameter", param, "must be between 0 and 1"))
        }
      }
    }
  }
  
  return(list(valid = length(errors) == 0, errors = errors))
}

#' Load and Validate Configuration
#'
#' Loads a configuration file and validates its structure and content.
#'
#' @param config_path Path to the configuration file (YAML format)
#' @param validate Whether to perform validation (default: TRUE)
#' @return The loaded and validated configuration list
#' @export
load_and_validate_config <- function(config_path, validate = TRUE) {
  # Check if file exists
  if (!file.exists(config_path)) {
    stop("Configuration file does not exist: ", config_path)
  }
  
  # Check file extension
  if (!grepl("\\.(ya?ml)$", tolower(config_path))) {
    warning("Config file may not be in expected YAML format: ", config_path)
  }
  
  # Load the configuration
  config <- tryCatch({
    yaml::read_yaml(config_path)
  }, error = function(e) {
    stop("Failed to load configuration from '", config_path, "': ", e$message)
  })
  
  # Validate if requested
  if (validate) {
    validation_result <- validate_ausoa_config(config)
    if (!validation_result$valid) {
      stop("Configuration validation failed:\n", 
           paste("-", validation_result$errors, collapse = "\n"))
    }
  }
  
  return(config)
}

#' Merge Configuration with Defaults
#'
#' Merges a custom configuration with default values, ensuring all required parameters are present.
#'
#' @param custom_config Custom configuration values
#' @param default_config Default configuration to use for missing values
#' @return A complete configuration with defaults filled in where needed
#' @export
merge_config_defaults <- function(custom_config, default_config = get_default_config()) {
  # Use recursive function to merge nested lists
  merged_config <- merge_lists_recursive(default_config, custom_config)
  
  # Validate the merged result
  validation_result <- validate_ausoa_config(merged_config)
  if (!validation_result$valid) {
    warning("Merged configuration has validation issues:\n", 
            paste("-", validation_result$errors, collapse = "\n"))
  }
  
  return(merged_config)
}

# Helper function for recursive list merging
merge_lists_recursive <- function(base, overrides) {
  # Get names of overrides
  override_names <- names(overrides)
  
  # Process each override
  for (name in override_names) {
    if (name %in% names(base) && 
        is.list(overrides[[name]]) && 
        is.list(base[[name]])) {
      # Recursively merge nested lists
      base[[name]] <- merge_lists_recursive(base[[name]], overrides[[name]])
    } else {
      # Replace or add the value
      base[[name]] <- overrides[[name]]
    }
  }
  
  return(base)
}

#' Get Default Configuration Values
#'
#' Returns the default configuration values for AUS-OA.
#'
#' @return A configuration list with default values
#' @export
get_default_config <- function() {
  return(list(
    simulation = list(
      time_horizon = 20,
      start_year = 2025,
      population_size = 1000,
      random_seed = 12345,
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
      tka_annual = 0.02,
      revision_annual = 0.03,
      dvt_prob = 0.05,
      pji_prob = 0.01
    ),
    pathways = list(
      public_wait_time = 18,  # months
      private_wait_time = 0.5,  # months
      referral_threshold = 0.7
    ),
    interventions = list(
      default_uptake_rate = 0.5,
      effectiveness_multiplier = 1.0
    )
  ))
}

#' Generate Configuration Template
#'
#' Creates a configuration template with all possible parameters and their descriptions.
#'
#' @param output_path Path where to save the template file
#' @return Path to the generated template file
#' @export
generate_config_template <- function(output_path = "ausoa_config_template.yaml") {
  template_config <- get_default_config()
  
  # Add comments to the config
  comment_attribute(template_config$simulation, 
                   "Simulation parameters - time horizon (years), start year, and population size")
  comment_attribute(template_config$costs, 
                   "Cost parameters in dollars, with perspective (healthcare_system, patient, societal)")
  comment_attribute(template_config$utilities, 
                   "Utility weights for different health states (0=completely unhealthy, 1=perfect health)")
  comment_attribute(template_config$risks, 
                   "Risk parameters as annual probabilities (0-1)")
  comment_attribute(template_config$pathways, 
                   "Pathway parameters for public/private healthcare systems")
  comment_attribute(template_config$interventions, 
                   "Intervention parameters for policy analysis")
  
  # Write to YAML
  yaml::write_yaml(template_config, output_path)
  
  message("Configuration template generated at: ", output_path)
  return(output_path)
}

#' Update Configuration Section
#'
#' Updates a specific section of the configuration.
#'
#' @param config Current configuration object
#' @param section_name Name of the section to update
#' @param updates Named list of updates for the section
#' @return Updated configuration object
#' @export
update_config_section <- function(config, section_name, updates) {
  if (!is.list(config)) {
    stop("Configuration must be a list")
  }
  
  if (!is.list(updates)) {
    stop("Updates must be provided as a list")
  }
  
  if (section_name %in% names(config) && is.list(config[[section_name]])) {
    # Update existing section
    config[[section_name]] <- merge_lists_recursive(config[[section_name]], updates)
  } else {
    # Create new section
    config[[section_name]] <- updates
  }
  
  return(config)
}

#' Get Configuration Section
#'
#' Safely extracts a section from the configuration with error handling.
#'
#' @param config Configuration object
#' @param section_name Name of the section to extract
#' @param default Default value to return if section is missing
#' @return The requested configuration section or default value
#' @export
get_config_section <- function(config, section_name, default = list()) {
  if (!is.list(config)) {
    warning("Configuration is not a list, returning default")
    return(default)
  }
  
  if (!section_name %in% names(config)) {
    warning("Configuration section '", section_name, "' not found, returning default")
    return(default)
  }
  
  return(config[[section_name]])
}

# Export functions
validate_config <- validate_ausoa_config
load_config_validated <- load_and_validate_config
merge_with_defaults <- merge_config_defaults
get_default_cfg <- get_default_config
update_cfg_section <- update_config_section
get_cfg_section <- get_config_section