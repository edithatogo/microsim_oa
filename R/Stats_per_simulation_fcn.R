#' Calculate Statistics for a Single Simulation Run
#'
#' This function takes the output of a single simulation run, filters it for
#' living individuals aged 45 and over, creates derived variables, and then
#' calculates summary statistics (N, Mean, Sum) for all numeric variables,
#' grouped by specified grouping variables.
#'
#' @param sim_storage A list where each element is a data.frame representing
#'   the output of a single simulation run.
#' @param sim_number The index of the simulation run to process from `sim_storage`.
#' @param group_vars A character vector of variable names to group the summary
#'   statistics by (e.g., c("year", "sex", "age_group")).
#'
#' @return A data.frame in long format containing the summary statistics (N,
#'   Mean, Sum) for each variable and group combination for the specified
#'   simulation run.
#' @importFrom dplyr filter mutate group_by summarise across full_join case_when any_of
#' @importFrom tidyr pivot_longer
#' @importFrom rlang .data
#' @importFrom magrittr %>%
#' @export
stats_per_simulation <- function(sim_storage, sim_number, group_vars) {
  # Declare variables to avoid R CMD check notes
  dead <- age <- bmi <- NULL

  Z_filtered <- sim_storage[[sim_number]] %>%
    filter(dead == 0) %>%
    filter(age >= 45)

  if (nrow(Z_filtered) == 0) {
    # Return an empty data frame with the correct structure
    return(
      data.frame(
        variable = character(),
        N = numeric(),
        Mean = numeric(),
        Sum = numeric(),
        sim_number = numeric()
      )
    )
  }

  Z <- Z_filtered %>%
    mutate(
      age_group = case_when(
        age > 44 & age <= 54 ~ "45-54",
        age > 54 & age <= 64 ~ "55-64",
        age > 64 & age <= 74 ~ "65-74",
        age > 74 ~ "75+"
      ),
      bmi_overweight_or_obese = ifelse(bmi >= 25, 1, 0),
      bmi_obese = ifelse(bmi >= 30, 1, 0)
    )

  if (nrow(Z) > 0) {
    Z <- Z %>% group_by(across(any_of(group_vars)))
  }

  # For N, we need to differentiate between binary and continuous variables.
  # For binary (0/1), N is the sum of 1s. For others, it's the count of non-NA values.
  # A simple heuristic is to check if all values are either 0 or 1.
  is_binary <- function(v) {
    all(v %in% c(0, 1, NA))
  }

  N_counts <- Z %>%
    summarise(
      across(
        where(is.numeric),
        ~ if (is_binary(.x)) sum(.x, na.rm = TRUE) else sum(!is.na(.x))
      ),
      .groups = "drop"
    ) %>%
    pivot_longer(
      cols = -any_of(group_vars),
      names_to = "variable", values_to = "N"
    )

  Means <- Z %>%
    summarise(
      across(
        where(is.numeric),
        ~ mean(.x, na.rm = TRUE)
      ),
      .groups = "drop"
    ) %>%
    pivot_longer(
      cols = -any_of(group_vars),
      names_to = "variable", values_to = "Mean"
    )

  Sum <- Z %>%
    summarise(
      across(
        where(is.numeric),
        ~ sum(.x, na.rm = TRUE)
      ),
      .groups = "drop"
    ) %>%
    pivot_longer(
      cols = -any_of(group_vars),
      names_to = "variable", values_to = "Sum"
    )

  Stats <- N_counts %>%
    full_join(Means, by = c(group_vars, "variable")) %>%
    full_join(Sum, by = c(group_vars, "variable")) %>%
    mutate(sim_number = sim_number)

  return(Stats)
}
