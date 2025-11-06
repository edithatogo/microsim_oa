# Configuration management for AUS-OA package
#
# This file defines the main configuration structure for the AUS-OA package
# with validation and default values

# Define default configuration values
default_config <- list(
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
)

# Function to create configuration from parameters
create_config_from_parameters <- function(
  time_horizon = 20,
  population_size = 1000,
  tka_primary_cost = 15000,
  start_year = 2025,
  verbose = TRUE,
  custom_params = NULL
) {
  # Create config from defaults
  config <- default_config
  
  # Override with specified parameters
  config$simulation$time_horizon <- time_horizon
  config$simulation$population_size <- population_size
  config$simulation$start_year <- start_year
  config$simulation$verbose <- verbose
  config$costs$tka_primary$hospital_stay$value <- tka_primary_cost
  
  # Apply custom parameters if provided
  if (is.list(custom_params)) {
    config <- merge_lists(config, custom_params)
  }
  
  return(config)
}

# Recursive function to merge two lists
merge_lists <- function(base, overrides) {
  # Get names of overrides
  override_names <- names(overrides)
  
  # Process each override
  for (name in override_names) {
    if (is.list(overrides[[name]]) && is.list(base[[name]])) {
      # Recursively merge nested lists
      base[[name]] <- merge_lists(base[[name]], overrides[[name]])
    } else {
      # Replace with override value
      base[[name]] <- overrides[[name]]
    }
  }
  
  return(base)
}

# Function to save configuration
save_config <- function(config, file_path) {
  # Validate config before saving
  validation_errors <- validate_config(config)
  if (length(validation_errors) > 0) {
    stop("Configuration validation failed:\n", paste("-", validation_errors, collapse = "\n"))
  }
  
  # Use yaml for human-readable format
  yaml::write_yaml(config, file_path)
  cat("Configuration saved to:", file_path, "\n")
}

# Function to load and validate configuration
load_and_validate_config <- function(file_path) {
  # Check if file exists
  if (!file.exists(file_path)) {
    stop("Configuration file does not exist: ", file_path)
  }
  
  # Load the file
  config <- tryCatch({
    yaml::read_yaml(file_path)
  }, error = function(e) {
    stop("Failed to load YAML configuration from '", file_path, "': ", e$message)
  })
  
  # Validate the loaded configuration
  validation_errors <- validate_config(config)
  if (length(validation_errors) > 0) {
    stop("Loaded configuration validation failed:\n", paste("-", validation_errors, collapse = "\n"))
  }
  
  cat("Configuration loaded and validated from:", file_path, "\n")
  return(config)
}

# Get default configuration
get_default_config <- function() {
  return(default_config)
}

# Get specific configuration section
get_config_section <- function(config, section_name) {
  if (is.null(config) || !is.list(config)) {
    stop("Invalid configuration object")
  }
  
  if (!section_name %in% names(config)) {
    available_sections <- paste(names(config), collapse = ", ")
    stop("Section '", section_name, "' not found in configuration. Available sections: ", available_sections)
  }
  
  return(config[[section_name]])
}

# Update specific configuration section
update_config_section <- function(config, section_name, new_values) {
  if (is.null(config) || !is.list(config)) {
    stop("Invalid configuration object")
  }
  
  if (is.null(new_values) || !is.list(new_values)) {
    stop("New values must be provided as a list")
  }
  
  if (section_name %in% names(config)) {
    # Merge existing and new values
    config[[section_name]] <- merge_lists(config[[section_name]], new_values)
  } else {
    # Add new section
    config[[section_name]] <- new_values
  }
  
  return(config)
}

# Validate entire configuration
validate_entire_config <- function(config) {
  errors <- c()
  
  if (is.null(config) || !is.list(config)) {
    return(c("Configuration must be a list"))
  }
  
  # Validate required sections
  required_sections <- c("simulation", "costs", "utilities")
  for (section in required_sections) {
    if (!section %in% names(config)) {
      errors <- c(errors, paste("Missing required configuration section:", section))
    }
  }
  
  # Validate specific fields in each section
  if ("simulation" %in% names(config)) {
    sim <- config$simulation
    if (is.null(sim$time_horizon) || !is.numeric(sim$time_horizon) || sim$time_horizon <= 0) {
      errors <- c(errors, "simulation$time_horizon must be a positive number")
    }
    if (is.null(sim$population_size) || !is.numeric(sim$population_size) || sim$population_size <= 0) {
      errors <- c(errors, "simulation$population_size must be a positive number")
    }
  }
  
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
  }
  
  return(errors)
}

# Export functions
#' @export
create_config_from_parameters

#' @export
save_config

#' @export
load_and_validate_config

#' @export
get_default_config

#' @export
get_config_section

#' @export
update_config_section

#' @export
validate_entire_config