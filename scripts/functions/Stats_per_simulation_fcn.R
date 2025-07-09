# EXTRACT STATISTICS FROM THE RESULT
stats_per_simulation <- function(sim_number, group_vars) {
  Z <- sim_storage[[sim_number]] %>%
    filter(dead == 0) %>%
    filter(age >= 45) %>%
    mutate(
      age_group = case_when(
        age > 44 & age <= 54 ~ "45-54",
        age > 54 & age <= 64 ~ "55-64",
        age > 64 & age <= 74 ~ "65-74",
        age > 74 ~ "75+"
      ),
      bmi_overweight_or_obese = ifelse(bmi >= 25, 1, 0),
      bmi_obese = ifelse(bmi >= 30, 1, 0)
    ) %>%
    group_by(across(all_of(group_vars)))

  Freq <- Z %>%
    summarise(
      across(
        where(is.numeric),
        ~ sum(.x == 1, na.rm = TRUE)
      )
    ) %>%
    pivot_longer(
      cols = -all_of(group_vars),
      names_to = "variable", values_to = "N"
    )

  Means <- Z %>%
    summarise(
      across(
        where(is.numeric),
        ~ mean(.x, na.rm = TRUE)
      )
    ) %>%
    pivot_longer(
      cols = -all_of(group_vars),
      names_to = "variable", values_to = "Mean"
    )

  Sum <- Z %>%
    summarise(
      across(
        where(is.numeric),
        ~ sum(.x, na.rm = TRUE)
      )
    ) %>%
    pivot_longer(
      cols = -all_of(group_vars),
      names_to = "variable", values_to = "Sum"
    )

  Stats <- Freq %>%
    full_join(Means, by = c(all_of(group_vars), "variable")) %>%
    full_join(Sum, by = c(all_of(group_vars), "variable")) %>%
    mutate(sim_number = sim_number)

  return(Stats)
}
