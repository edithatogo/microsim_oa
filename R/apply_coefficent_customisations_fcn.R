#' Apply customisations to model coefficients
#'
#' This function adjusts a set of model coefficients based on custom
#' proportional reduction factors. It iterates through a customisation dataset,
#' matches coefficients, and applies the specified reduction.
#'
#' @param cycle.coefficents A data.frame or list containing the model
#'   coefficients for the current cycle.
#' @param cust_data A data.frame containing the customisation rules. It must
#'   have columns 'covariate_set' and 'proportion_reduction'.
#' @param coeff_prefix_cycle A character string prefix for the coefficient names
#'   in `cycle.coefficents` (e.g., "c").
#' @param coeff_prefix_cust A character string prefix for the coefficient names
#'   in `cust_data` (e.g., "cal").
#'
#' @return The `cycle.coefficents` object with the customisations applied.
#' @export
apply_coefficent_customisations <- function(cycle.coefficents, cust_data, coeff_prefix_cycle, coeff_prefix_cust) {
  
  cust_data$proportion_reduction <- as.numeric(cust_data$proportion_reduction)
  
  for (i in 1:nrow(cust_data)) {
    covariate_name_cust <- cust_data$covariate_set[i]
    reduction_value <- cust_data$proportion_reduction[i]
    
    # Construct the full coefficient name for the cycle
    covariate_name_cycle <- sub(paste0(coeff_prefix_cust, "_"), "", covariate_name_cust)
    full_coeff_name_cycle <- paste0(coeff_prefix_cycle, "_", covariate_name_cycle)
    
    # Check if the column exists in cycle.coefficents
    if (full_coeff_name_cycle %in% names(cycle.coefficents)) {
      # Apply the reduction
      cycle.coefficents[[full_coeff_name_cycle]] <- cycle.coefficents[[full_coeff_name_cycle]] * reduction_value
    }
  }
  
  return(cycle.coefficents)
}
