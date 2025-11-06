# Memory optimization utilities for AUS-OA package

#' Optimize Data Tables for Memory Efficiency
#'
#' Converts data frames to more memory-efficient formats and optimizes column types.
#'
#' @param dt A data frame or data.table to optimize
#' @return Memory-optimized data table
#' @export
optimize_dt_memory <- function(dt) {
  # Ensure it's a data.table for efficiency
  if (!inherits(dt, "data.table")) {
    data.table::setDT(dt)
  }
  
  # Optimize character columns by converting to factors where beneficial
  for (j in seq_len(ncol(dt))) {
    if (is.character(dt[[j]])) {
      # Only convert to factor if it saves memory (has limited unique values)
      unique_vals <- unique(dt[[j]])
      if (length(unique_vals) / nrow(dt) < 0.5) {  # Only if unique values < 50%
        dt[, (j) := factor(get(names(dt)[j]))]
      }
    }
    # Optimize integer columns that don't need full range
    else if (is.integer(dt[[j]])) {
      max_val <- max(dt[[j]], na.rm = TRUE)
      min_val <- min(dt[[j]], na.rm = TRUE)
      
      if (max_val <= 32767 && min_val >= -32768) {
        dt[, (j) := as.integer16(dt[[j]])]
      } else if (max_val <= 127 && min_val >= -128) {
        dt[, (j) := as.integer8(dt[[j]])]
      }
    }
    # Optimize numeric columns if integers
    else if (is.numeric(dt[[j]]) && all(dt[[j]] == as.integer(dt[[j]]), na.rm = TRUE)) {
      max_val <- max(dt[[j]], na.rm = TRUE)
      min_val <- min(dt[[j]], na.rm = TRUE)
      
      if (max_val <= 32767 && min_val >= -32768) {
        dt[, (j) := as.integer16(dt[[j]])]
      } else if (max_val <= 127 && min_val >= -128) {
        dt[, (j) := as.integer8(dt[[j]])]
      } else {
        dt[, (j) := as.integer32(dt[[j]])]
      }
    }
  }
  
  return(dt)
}

#' Efficient Population Data Generator
#'
#' Generates population data using memory-efficient techniques.
#'
#' @param n Number of individuals to generate
#' @param age_range Age range for population (default: c(40, 85))
#' @param seed Random seed for reproducibility
#' @return Memory-optimized population data.table
#' @export
generate_efficient_population <- function(n, age_range = c(40, 85), seed = NULL) {
  if (!is.null(seed)) set.seed(seed)
  
  # Use data.table for memory efficiency
  pop_dt <- data.table::data.table(
    id = 1:n,
    age = sample(age_range[1]:age_range[2], n, replace = TRUE),
    sex = factor(sample(c("M", "F"), n, replace = TRUE), levels = c("M", "F")),  # Factor for memory
    bmi = round(rnorm(n, mean = 28, sd = 5), 1),
    kl_score = factor(sample(0:4, n, replace = TRUE, 
                            prob = c(0.3, 0.25, 0.2, 0.15, 0.1)),
                    levels = 0:4),  # Factor for memory
    tka_status = factor(sample(c("None", "Primary", "Revision"), 
                              n, replace = TRUE, prob = c(0.8, 0.15, 0.05)),
                       levels = c("None", "Primary", "Revision")),
    qaly = round(runif(n, min = 0.3, max = 1.0), 3),
    year_of_birth = as.integer(Sys.Date() - as.Date(paste0(age_range[2]:age_range[1], "-01-01")) / 365.25)
  )
  
  # Optimize memory further
  data.table::setkey(pop_dt, id)  # Set key for faster lookups
  
  return(pop_dt)
}

#' Memory-Efficient Cost Calculator
#'
#' Calculates costs using memory-efficient operations.
#'
#' @param dt A data table containing the population data
#' @param cost_params A list of cost parameters
#' @return Updated data table with cost columns added
#' @export
calculate_costs_efficient <- function(dt, cost_params) {
  # Optimize input if needed
  if (!inherits(dt, "data.table")) {
    data.table::setDT(dt)
  }
  
  # Use data.table's efficient operations
  dt[, ':=' (
    # Primary TKA costs
    tka_primary_cost = ifelse(tka_status == "Primary", 
                              cost_params$costs$tka_primary$hospital_stay$value, 0),
    
    # Revision TKA costs
    tka_revision_cost = ifelse(tka_status == "Revision", 
                               cost_params$costs$tka_revision$hospital_stay$value, 0),
    
    # Complication costs based on KL score
    complication_cost = case_when(
      kl_score == "4" ~ cost_params$costs$complications$severe$value,
      kl_score == "3" ~ cost_params$costs$complications$moderate$value,
      TRUE ~ cost_params$costs$complications$mild$value
    )
  )]
  
  # Calculate total costs using data.table's efficient sum
  dt[, total_cost := tka_primary_cost + tka_revision_cost + complication_cost]
  
  return(dt)
}

#' Garbage Collection Helper
#'
#' Performs targeted garbage collection and reports memory usage.
#'
#' @param verbose Whether to print memory information
#' @return List with memory information before and after GC
#' @export
manage_memory <- function(verbose = TRUE) {
  # Capture memory before
  mem_before <- gc()
  if (verbose) {
    total_objects <- sum(mem_before[, "Nobjects"])
    total_space <- sum(mem_before[, "Size (Mb)"])
    cat(sprintf("Before GC: %d objects, %.2f MB used\n", total_objects, total_space))
  }
  
  # Force garbage collection
  gc_result <- gc()
  
  # Capture memory after
  mem_after <- gc()
  if (verbose) {
    total_objects <- sum(mem_after[, "Nobjects"])
    total_space <- sum(mem_after[, "Size (Mb)"])
    cat(sprintf("After GC: %d objects, %.2f MB used\n", total_objects, total_space))
  }
  
  return(list(
    before = mem_before,
    after = mem_after,
    freed = sum(mem_before[, "Size (Mb)"]) - sum(mem_after[, "Size (Mb)"])
  ))
}

#' Column Reduction Function
#'
#' Identifies and removes unnecessary columns from datasets to save memory.
#'
#' @param dt Data table to analyze
#' @param keep_cols Character vector of column names to definitely keep
#' @param min_utilization Minimum utilization threshold for keeping columns (0-1)
#' @return Optimized data table with low-utilization columns potentially removed
#' @export
reduce_columns <- function(dt, keep_cols = character(0), min_utilization = 0.05) {
  if (!inherits(dt, "data.table")) {
    data.table::setDT(dt)
  }
  
  col_names <- names(dt)
  cols_to_remove <- character(0)
  
  for (col in col_names) {
    # Skip columns that should be kept
    if (col %in% keep_cols) next
    
    # Check for all-NA columns
    if (all(is.na(dt[[col]]))) {
      cols_to_remove <- c(cols_to_remove, col)
      next
    }
    
    # Count non-NA values
    non_na_count <- sum(!is.na(dt[[col]]))
    utilization <- non_na_count / nrow(dt)
    
    # If utilization is below threshold, mark for removal
    if (utilization < min_utilization) {
      cols_to_remove <- c(cols_to_remove, col)
    }
  }
  
  # Remove identified columns
  if (length(cols_to_remove) > 0) {
    dt[, (cols_to_remove) := NULL]
    if (interactive()) {
      cat("Removed", length(cols_to_remove), "low-utilization columns:\n",
          paste(cols_to_remove, collapse = ", "), "\n")
    }
  }
  
  return(dt)
}

#' Batch Process Function
#'
#' Processes large datasets in batches to limit memory usage.
#'
#' @param data Input data to process
#' @param batch_size Number of rows per batch
#' @param process_function Function to apply to each batch
#' @param ... Additional arguments to pass to the process function
#' @return Combined results from all batches
#' @export
batch_process <- function(data, batch_size = 10000, process_function, ...) {
  n_rows <- nrow(data)
  n_batches <- ceiling(n_rows / batch_size)
  
  results <- list()
  
  for (i in 1:n_batches) {
    start_idx <- (i - 1) * batch_size + 1
    end_idx <- min(i * batch_size, n_rows)
    
    # Extract batch
    batch_data <- data[start_idx:end_idx, ]
    
    # Process batch
    batch_result <- process_function(batch_data, ...)
    
    # Store result
    results[[i]] <- batch_result
    
    # Optional: Report progress and manage memory
    if (i %% 5 == 0) {
      cat(sprintf("Processed batch %d/%d\n", i, n_batches))
      manage_memory(verbose = FALSE)  # Clean up between batches
    }
  }
  
  # Combine results (assuming they're compatible)
  if (is.data.frame(results[[1]])) {
    combined <- data.table::rbindlist(results)
  } else {
    combined <- unlist(results)
  }
  
  return(combined)
}

#' Memory Usage Profiler
#'
#' Profiles memory usage of AUS-OA functions.
#'
#' @param expr Expression to profile
#' @param interval Sampling interval for memory profiler
#' @return Memory profiling results
#' @export
profile_memory_usage <- function(expr, interval = 0.01) {
  # Capture current memory
  start_memory <- utils::object.size(expr)
  
  # Profile memory during execution
  mem_profile <- proftools::profmem(substitute(expr), interval = interval)
  
  # Summarize profile
  summary_stats <- list(
    start_size = start_memory,
    peak_alloc = sum(sapply(mem_profile$alloc, function(x) x$size)),
    total_alloc = sum(abs(sapply(mem_profile$alloc, function(x) x$size))),
    net_alloc = sum(sapply(mem_profile$alloc, function(x) x$size)) - 
                sum(sapply(mem_profile$free, function(x) x$size))
  )
  
  return(list(
    profile = mem_profile,
    summary = summary_stats
  ))
}

# Additional helper functions for memory management

#' Check Available Memory
#'
#' Checks available memory and provides recommendation on safe limits.
#'
#' @return List with memory availability information
#' @export
check_memory_available <- function() {
  # Get system memory info (if possible)
  total_memory <- NA
  available_memory <- NA
  
  # Try to get from system
  tryCatch({
    # This might work on Linux systems
    if (.Platform$OS.type == "unix") {
      mem_info <- system("free -b", intern = TRUE)
      # Parse memory info from free command output
      if (length(mem_info) >= 2) {
        mem_line <- strsplit(mem_info[2], "\\s+")[[1]]
        if (length(mem_line) >= 3) {
          total_memory <- as.numeric(mem_line[2])
          available_memory <- as.numeric(mem_line[4])
        }
      }
    }
  }, error = function(e) {
    # Fallback: just report R session memory info
    memory_used <- gc()[, "Size (Mb)"]
    available_memory <- sum(memory_used)
  })
  
  return(list(
    total_system_bytes = total_memory,
    available_bytes = available_memory,
    recommended_usage_bytes = ifelse(is.na(available_memory), NA, available_memory * 0.5),  # 50% of available
    total_system_mb = total_memory / 1024^2,
    available_mb = available_memory / 1024^2
  ))
}

#' Optimize Simulation Attributes
#'
#' Optimizes attribute matrices for memory efficiency during simulations.
#'
#' @param attributes Matrix of simulation attributes
#' @param compress_flags Whether to compress factor levels
#' @return Memory-optimized attribute matrix
#' @export
optimize_simulation_attributes <- function(attributes, compress_flags = TRUE) {
  if (!inherits(attributes, "data.table")) {
    data.table::setDT(attributes)
  }
  
  # Apply memory optimizations
  if (compress_flags) {
    # Optimize categorical variables
    for (j in seq_len(ncol(attributes))) {
      if (is.factor(attributes[[j]])) {
        # Reduce factor levels to only those present
        attributes[, (j) := factor(get(names(attributes)[j]), 
                                  levels = unique(get(names(attributes)[j])))]
      } else if (is.character(attributes[[j]])) {
        # If character column has few unique values, convert to factor
        unique_vals <- unique(attributes[[j]])
        if (length(unique_vals) / nrow(attributes) < 0.1) {  # Less than 10% unique
          attributes[, (j) := factor(get(names(attributes)[j]))]
        }
      }
    }
  }
  
  return(attributes)
}

# Export functions
#' @export
opt_dt_memory <- optimize_dt_memory

#' @export
gen_efficient_pop <- generate_efficient_population

#' @export
calc_costs_efficient <- calculate_costs_efficient

#' @export
gc_manage <- manage_memory

#' @export
reduce_df_cols <- reduce_columns

#' @export
batch_proc <- batch_process

#' @export
prof_mem_usage <- profile_memory_usage

#' @export
check_mem_avail <- check_memory_available

#' @export
opt_sim_attrs <- optimize_simulation_attributes