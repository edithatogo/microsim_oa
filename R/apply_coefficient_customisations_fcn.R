#' Apply customisations to model coefficients
#'
#' This function adjusts a set of model coefficients based on custom
#' proportional reduction factors. It iterates through a customisation dataset,
#' matches coefficients, and applies the specified reduction.
#'
#' @param cycle_coefficients A data.frame or list containing the model
#'   coefficients for the current cycle.
#' @param customisation_data A data.frame containing the customisation rules. It must
#'   have columns 'covariate_set' and 'proportion_reduction'.
#' @param coeff_prefix_cycle A character string prefix for the coefficient names
#'   in `cycle_coefficients` (e.g., "c").
#' @param coeff_prefix_cust A character string prefix for the coefficient names
#'   in `customisation_data` (e.g., "cal").
#'
#' @return The `cycle_coefficients` object with the customisations applied.
#' @export
apply_coefficient_customisations <- function(cycle_coefficients,
                                             customisation_data,
                                             coeff_prefix_cycle,
                                             coeff_prefix_cust) {
  if (nrow(customisation_data) == 0) {
    return(cycle_coefficients)
  }
  customisation_data$proportion_reduction <-
    as.numeric(customisation_data$proportion_reduction)

  for (i in seq_len(nrow(customisation_data))) {
    covariate_name_cust <- customisation_data$covariate_set[i]
    reduction_value <- customisation_data$proportion_reduction[i]

    # Construct the full coefficient name for the cycle
    covariate_name_cycle <-
      sub(paste0(coeff_prefix_cust, "_"), "", covariate_name_cust)
    full_coeff_name_cycle <-
      paste0(coeff_prefix_cycle, "_", covariate_name_cycle)

    # Check if the column exists in cycle_coefficients
    if (full_coeff_name_cycle %in% names(cycle_coefficients)) {
      # Apply the reduction
      cycle_coefficients[[full_coeff_name_cycle]] <-
        cycle_coefficients[[full_coeff_name_cycle]] * reduction_value
    }
  }

  cycle_coefficients
}
