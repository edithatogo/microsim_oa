#' Apply Policy Levers to Model Parameters
#'
#' This function modifies a list of model parameters (including coefficients,
#' costs, and utilities) based on a set of enabled policy levers defined in the
#' simulation configuration.
#'
#' @param params A list containing all model parameters (e.g., the output of `load_config`).
#' @param policy_levers A list of policy lever objects from the simulation configuration.
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
      if (length(path) == 1) {
        original_value <- lst[[path[1]]]
        
        new_value <- switch(
          operation,
          "multiply" = original_value * value,
          "add" = original_value + value,
          "replace" = value,
          {
            warning(paste("Unknown operation:", operation, "- Skipping this effect."))
            original_value
          }
        )
        lst[[path[1]]] <- new_value
      } else {
        if (!path[1] %in% names(lst)) {
          if (operation == "replace") {
            lst[[path[1]]] <- list()
          } else {
            warning(paste("Target path not found:", paste(path, collapse = "."), "- Skipping."))
            return(lst)
          }
        }
        lst[[path[1]]] <- modify_nested_list(lst[[path[1]]], path[-1], operation, value)
      }
      return(lst)
    }
    
    params <- modify_nested_list(params, target_parts, effect$operation, effect$value)
  }
  
  return(params)
}