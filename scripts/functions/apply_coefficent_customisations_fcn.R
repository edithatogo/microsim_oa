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