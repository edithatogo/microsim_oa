#' Apply Policy Levers to Model Parameters
#'
#' This function modifies a list of model parameters (including coefficients,
#' costs, and utilities) based on a set of enabled policy levers defined in the
#' simulation configuration.
#'
#' @param params A list containing all model parameters (e.g., the output of
#'   `load_config`).
#' @param policy_levers A list of policy lever objects from the simulation
#'   configuration.
#'
#' @return The modified list of parameters.
#' @export
#'
#' @examples
#' # params <- load_config("config/coefficients.yaml")
#' # sim_config <- load_config("config/simulation.yaml")
#' # modified_params <- apply_policy_levers(params, sim_config$policy_levers)
apply_policy_levers <- function(params, policy_levers) {
  enabled_lever <- NULL
  for (lever in policy_levers) {
    if (isTRUE(lever$enabled)) {
      enabled_lever <- lever
      break
    }
  }

  if (is.null(enabled_lever) || enabled_lever$name == "No Intervention") {
    return(params)
  }

  message(paste("Applying policy lever:", enabled_lever$name))

  for (effect in enabled_lever$effects) {
    target_parts <- strsplit(effect$target, "\\.")[[1]]

    # Use a recursive function to navigate and modify the nested list
    modify_nested_list <- function(lst, path, operation, value) {
      # Base case: we are at the target's parent
      if (length(path) == 1) {
        target_name <- path[1]

        # Check for unknown operation first
        if (!operation %in% c("multiply", "add", "replace")) {
            warning(paste("Unknown operation:", operation, "- Skipping this effect."))
            return(lst)
        }

        # Check for non-existent target for non-replace operations
        if (!target_name %in% names(lst) && operation != "replace") {
          warning(paste("Target '", target_name, "' not found. Skipping '", operation, "' operation.", sep = ""))
          return(lst)
        }

        original_value <- lst[[target_name]] # Will be NULL if it doesn't exist (for 'replace')

        new_value <- switch(operation,
          "multiply" = original_value * value,
          "add"      = original_value + value,
          "replace"  = value
        )
        lst[[target_name]] <- new_value
        return(lst)
      }

      # Recursive step
      parent_name <- path[1]
      child_path <- path[-1]

      # If a parent in the path doesn't exist
      if (!parent_name %in% names(lst)) {
         if (operation == "replace") {
            lst[[parent_name]] <- list() # Create it
         } else {
            warning(paste("Target path '", paste(path, collapse="."), "' not found. Skipping '", operation, "' operation.", sep=""))
            return(lst)
         }
      }

      lst[[parent_name]] <- modify_nested_list(lst[[parent_name]], child_path, operation, value)
      return(lst)
    }

    params <-
      modify_nested_list(params, target_parts, effect$operation, effect$value)
  }

  params
}
