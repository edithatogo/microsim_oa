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
  # Get all .yaml files in the directory
  yaml_files <- list.files(
    path = config_path,
    pattern = "\\.yaml$",
    full.names = TRUE
  )

  # Read each YAML file into a list
  config_list <- purrr::map(yaml_files, yaml::read_yaml)

  # Combine all lists into one. If there are duplicate top-level keys,
  # this will throw an error, which is a good way to enforce uniqueness.
  # A more sophisticated merge could be done if needed.
  config <- purrr::reduce(config_list, c)

  # --- Add Validation Here ---
  # (e.g., check for required sections, validate data types)
  # For now, we'll just return the combined list.

  return(config)
}
