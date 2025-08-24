#' Load YAML Configuration Files
#'
#' This function loads all YAML configuration files from a specified directory,
#' validates their structure, and combines them into a single list object.
#'
#' @param config_path The path to the directory containing the YAML files.
#'   Defaults to the 'config' directory in the project root.
#'
#' @return A nested list containing all configuration parameters.
#' @importFrom yaml read_yaml
#' @importFrom purrr map reduce
#' @export
load_config <- function(config_path = "config") {
  if (dir.exists(config_path)) {
    # Get all .yaml files in the directory
    yaml_files <- list.files(
      path = config_path,
      pattern = "\\.yaml$",
      full.names = TRUE
    )

    # Read each YAML file into a list
    config_list <- purrr::map(yaml_files, yaml::read_yaml)

    # Combine all lists into one.
    config <- purrr::reduce(config_list, c)
  } else if (file.exists(config_path)) {
    # If it's a file, just read that one file
    config <- yaml::read_yaml(config_path)
  } else {
    stop("Path does not exist: ", config_path)
  }

  # --- Add Validation Here ---
  # (e.g., check for required sections, validate data types)
  # For now, we'll just return the combined list.

  return(config)
}

#' Get Parameters for a Specific Analysis Type
#'
#' This function extracts the relevant parameter values from the configuration
#' based on the analysis type (e.g., 'live' for deterministic runs).
#'
#' @param config A nested list containing all configuration parameters.
#' @param analysis_type The type of analysis ('live' or 'psa').
#'
#' @return A nested list containing the selected parameter values.
#' @importFrom stats rnorm
#' @export
get_params <- function(config, analysis_type = "live") {
  params <- list()

  if (analysis_type == "live") {
    # Extract the 'live' value from each parameter
    params <- purrr::map_depth(config, 2, ~ .x$live)
  } else if (analysis_type == "psa") {
    # Sample from the specified distribution for each parameter
    params <- purrr::map_depth(config, 2, ~ {
      if ("distribution" %in% names(.x) && .x$distribution == "normal") {
        rnorm(1, mean = .x$live, sd = .x$std_error)
      } else {
        .x$live
      }
    })
  } else {
    stop("Invalid analysis type specified.")
  }

  # Specific logic to correctly structure the revision model coefficients
  if (!is.null(params$revision_model)) {
    rev_coeffs <- params$revision_model
    params$revision_model <- list(
      linear_predictor = list(
        age = rev_coeffs$age,
        female = rev_coeffs$female,
        bmi = rev_coeffs$bmi,
        public = rev_coeffs$public
      ),
      early_hazard = list(
        intercept = rev_coeffs$early_intercept
      ),
      late_hazard = list(
        intercept = rev_coeffs$late_intercept,
        log_time = rev_coeffs$log_time
      )
    )
  }

  return(params)
}
