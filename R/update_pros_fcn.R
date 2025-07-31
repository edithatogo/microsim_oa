#' Update Patient-Reported Outcomes (PROs)
#'
#' This function updates the pain and function scores for each individual in
#' the attribute matrix based on events in the current cycle.
#'
#' @param am_new A data.table representing the attribute matrix with the
#'   latest events for the current cycle.
#' @param cycle.coefficents A list of model coefficients.
#'
#' @return The `am_new` data.table with updated `pain` and `function_score` columns.
#' @export
update_pros_fcn <- function(am_new, cycle.coefficents) {
  
  # Declare variables to avoid R CMD check notes
  oa <- dead <- pain <- function_score <- tka <- NULL
  
  # --- State-Based Progression ---
  # For those with OA, assume a slight worsening of pain and function each year.
  am_new[oa == 1 & dead == 0, pain := pain + 1]
  am_new[oa == 1 & dead == 0, function_score := function_score + 0.5]
  
  # --- Event-Based Changes ---
  # For those who received a TKA in this cycle, assume a significant improvement.
  am_new[tka == 1, pain := pain * 0.4] # 60% reduction in pain
  am_new[tka == 1, function_score := function_score * 0.5] # 50% improvement in function
  
  # Ensure scores stay within a plausible 0-100 range
  am_new[, pain := pmin(pmax(pain, 0), 100)]
  am_new[, function_score := pmin(pmax(function_score, 0), 100)]
  
  return(am_new)
}
