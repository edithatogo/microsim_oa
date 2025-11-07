"Get Percentages and Frequencies of Binary Variables
"
#' Calculates the percentage and frequency of binary (0/1) variables for each
#' level of specified grouping variables.
#'
#' @param df A data.frame containing the data.
#' @param group_vars A character vector of variable names to group by.
#' @return A data.frame with summary statistics (percentage and frequency) for
#'   each binary variable and group combination.
#' @importFrom dplyr select group_by summarise ungroup mutate across all_of ends_with starts_with where
#' @importFrom magrittr %>%
#' @export
f_get_percent_N_from_binary <- function(df, group_vars) {
  # Select the required columns and filter values in (0, 1)
  df_filtered <- df %>%
    select(all_of(group_vars), where(~ all(.x %in% c(0, 1))))

  # Group by specified variables and calculate summary statistics
  summary_stats <- df_filtered %>%
    group_by(across(all_of(group_vars))) %>%
    summarise(
      across(
        where(~ all(.x %in% c(0, 1))),
        list(
          percent = ~ mean(.x, na.rm = TRUE),
          frequency = ~ sum(.x == 1, na.rm = TRUE)
        )
      )
    ) %>%
    ungroup()

  # Round percentage columns to 2 decimal places
  summary_stats <- summary_stats %>%
    mutate(
      across(
        .cols = ends_with("_percent"),
        ~ round(.x * 100, 2)
      )
    )

  return(summary_stats)
}

#' Get Mean, Frequency, and Sum of Numeric Variables
#'
#' Calculates the mean, frequency (count of 1s), and sum for all numeric
#' variables for each level of specified grouping variables.
#'
#' @param df A data.frame containing the data.
#' @param group_vars A character vector of variable names to group by.
#' @return A data.frame with summary statistics (mean, frequency, sum) for
#'   each numeric variable and group combination.
#' @importFrom dplyr group_by summarise ungroup across all_of
#' @export
f_get_means_freq_sum <- function(df, group_vars) {
  # Select the required columns and filter values in (0, 1)
  df_filtered <- df
  # Group by specified variables and calculate summary statistics
  summary_stats <- df_filtered %>%
    group_by(across(all_of(group_vars))) %>%
    summarise(
      across(
        where(is.numeric),
        list(
          mean = ~ mean(.x, na.rm = TRUE),
          frequency = ~ sum(.x == 1, na.rm = TRUE),
          sum = ~ sum(.x, na.rm = TRUE)
        )
      )
    ) %>%
    ungroup()

  return(summary_stats)
}

#' Summarise BMI Data
#'
#' Processes the full simulation output to calculate the proportion of the
#' population that is overweight or obese, stratified by year, age category,
#' and sex.
#'
#' @param am_all A data.frame representing the full simulation output, containing
#'   data for all individuals over all cycles.
#' @return A data.frame with the summarised BMI statistics.
#' @importFrom dplyr group_by summarise n
#' @importFrom forcats fct_recode
#' @export
BMI_summary_data <- function(am_all) {
  # Declare variables to avoid R CMD check notes
  dead <- age <- bmi <- year <- age_cat <- sex <- overweight_obese <- NULL

  # remove all individuals who are dead in the cycle
  am_all <- am_all[which(am_all$dead == 0), ]

  # in the 2022 format,
  BMI_by_sex_and_year <- am_all[, c("age", "sex", "year", "bmi")]
  # create matching age_bands
  BMI_by_sex_and_year$age_cat <- cut(BMI_by_sex_and_year$age,
    breaks = c(0, 18, 25, 35, 45, 55, 65, 75, 1000)
  )

  # create a flag for overweight and obese, check defintion
  BMI_by_sex_and_year$overweight_obese <- ifelse(BMI_by_sex_and_year$bmi >= 25, TRUE, FALSE)

  # Clean sex labels of forms like "[1] Male" -> "Male"
  BMI_by_sex_and_year$sex <-
    stringr::str_squish(
      stringr::str_remove_all(BMI_by_sex_and_year$sex, "\\[[0-9]+\\]")
    )

  BMI_by_sex_and_year <- BMI_by_sex_and_year %>%
    group_by(year, age_cat, sex) %>%
    summarise(prop_overweight_obese = sum(overweight_obese) / n())

  # not interested in the younger age brackets, and the cohort ages out of them
  # given it is fixed, remove all age brackets below 35

  BMI_by_sex_and_year <- BMI_by_sex_and_year[which(BMI_by_sex_and_year$age_cat != "(0,18]"), ]
  BMI_by_sex_and_year <- BMI_by_sex_and_year[which(BMI_by_sex_and_year$age_cat != "(18,25]"), ]
  BMI_by_sex_and_year <- BMI_by_sex_and_year[which(BMI_by_sex_and_year$age_cat != "(25,35]"), ]

  BMI_by_sex_and_year$age_cat <- fct_recode(BMI_by_sex_and_year$age_cat,
    "35-44" = "(35,45]",
    "45-54" = "(45,55]",
    "55-64" = "(55,65]",
    "65-74" = "(65,75]",
    "75 years and over" = "(75,1e+03]"
  )

  BMI_by_sex_and_year$sex <- as.factor(BMI_by_sex_and_year$sex)
  BMI_by_sex_and_year$sex <- fct_recode(BMI_by_sex_and_year$sex,
    "Male" = "Male",
    "Female" = "Female"
  )


  BMI_by_sex_and_year$source <- "Simulated"

  return(BMI_by_sex_and_year)
}

#' Plot BMI Summary Data for Validation
#'
#' Creates a plot comparing simulated BMI statistics against observed data,
#' faceted by age category and sex.
#'
#' @param percent_overweight_and_obesity_by_sex_joint A data.frame of observed
#'   BMI data.
#' @param BMI_by_sex_and_year A data.frame of simulated BMI data, typically from
#'   `BMI_summary_data()`.
#' @param current.mod.value A value used to create a unique filename for the saved plot.
#' @return A ggplot object is printed to the console and a file is saved to disk.
#' @import ggplot2
#' @importFrom ragg agg_png
#' @export
BMI_summary_plot <- function(percent_overweight_and_obesity_by_sex_joint,
                             BMI_by_sex_and_year,
                             current.mod.value) {
  # Declare variables to avoid R CMD check notes
  year <- prop_overweight_obese <- age_cat <- lower_CI <- upper_CI <- sex <- NULL

  # remove the lower age-brackets from the comparison data
  percent_overweight_and_obesity_by_sex_joint <-
    percent_overweight_and_obesity_by_sex_joint[which(
      percent_overweight_and_obesity_by_sex_joint$age_cat != "18-24"
    ), ]
  percent_overweight_and_obesity_by_sex_joint <-
    percent_overweight_and_obesity_by_sex_joint[which(
      percent_overweight_and_obesity_by_sex_joint$age_cat != "25-34"
    ), ]
  percent_overweight_and_obesity_by_sex_joint$age_cat <-
    as.factor(percent_overweight_and_obesity_by_sex_joint$age_cat)

  # remove any age brackets not represented in the BMI data
  percent_overweight_and_obesity_by_sex_joint <-
    percent_overweight_and_obesity_by_sex_joint[which(
      percent_overweight_and_obesity_by_sex_joint$age_cat %in% BMI_by_sex_and_year$age_cat
    ), ]

  percent_overweight_and_obesity_by_sex_joint$source <- "Observed"
  names(percent_overweight_and_obesity_by_sex_joint)[2] <- "prop_overweight_obese"

  # setup plotting data
  cycle.plotting.data <- rbind(BMI_by_sex_and_year, percent_overweight_and_obesity_by_sex_joint)

  cycle.plotting.data$year <- as.numeric(cycle.plotting.data$year)


  # percent_overweight_and_obesity_by_sex_joint$year <- factor(percent_overweight_and_obesity_by_sex_joint$year,
  #                                                            ordered = TRUE,
  #                                                            levels = year_seq)
  #
  # BMI_by_sex_and_year$year <- factor(BMI_by_sex_and_year$year,
  #                                    ordered = TRUE,
  #                                    levels = year_seq)
  #
  p <- ggplot(
    cycle.plotting.data[which(cycle.plotting.data$source == "Observed"), ],
    aes(x = year, y = prop_overweight_obese, color = age_cat)
  )

  plot_object <- p + geom_point() +
    geom_errorbar(aes(ymin = lower_CI, ymax = upper_CI, color = age_cat, width = 0.2), alpha = 0.5) +
    geom_line(
      data = cycle.plotting.data[which(cycle.plotting.data$source == "Simulated"), ],
      aes(x = year, y = prop_overweight_obese * 100, color = age_cat, group = age_cat)
    ) +
    facet_wrap(age_cat ~ sex) +
    theme(legend.position = "bottom", axis.text.x = element_text(angle = 45, hjust = 1)) +
    scale_x_continuous(breaks = seq(min(cycle.plotting.data$year), max(cycle.plotting.data$year), 2))

  print(plot_object)

  ggsave(
    filename = paste0("output_figures/BMI_validation_modval_", current.mod.value, ".png"),
    plot = plot_object,
    device = ragg::agg_png,
    width = 10,
    height = 8,
    dpi = 300
  )
}

#' Calculate RMSE for BMI Summary
#'
#' Calculates the Root Mean Squared Error (RMSE) between simulated and observed
#' BMI data to quantify model fit.
#'
#' @param percent_overweight_and_obesity_by_sex_joint A data.frame of observed
#'   BMI data.
#' @param BMI_by_sex_and_year A data.frame of simulated BMI data, typically from
#'   `BMI_summary_data()`.
#' @param current.mod.value (Not used) A value intended for file naming, currently
#'   has no effect in the function.
#' @return A data.frame containing the RMSE values, grouped by age category and sex.
#' @importFrom dplyr group_by arrange summarise ungroup
#' @export
BMI_summary_RMSE <- function(percent_overweight_and_obesity_by_sex_joint,
                             BMI_by_sex_and_year,
                             current.mod.value) {
  # Declare variables to avoid R CMD check notes
  year <- prop_overweight_obese <- age_cat <- sex <- observed <- simulated <-
    diff_simulated_observed <- diff_simulated_observed_2 <- NULL

  # gather data to assess % agreement
  cycle.assessment.data <- BMI_by_sex_and_year[which(BMI_by_sex_and_year$year == 2015 |
    BMI_by_sex_and_year$year == 2018 |
    BMI_by_sex_and_year$year == 2022), ]


  # convert cycle assessment prop to % for comparison
  cycle.assessment.data$prop_overweight_obese <- cycle.assessment.data$prop_overweight_obese * 100

  cycle.assessment.data$source <- "Simulated"

  # add source flag
  percent_overweight_and_obesity_by_sex_joint$source <- "Observed"


  # change name for consistency
  names(percent_overweight_and_obesity_by_sex_joint)[2] <- "prop_overweight_obese"

  # Ensure columns match before rbind
  percent_overweight_and_obesity_by_sex_joint$lower_CI <- NULL
  percent_overweight_and_obesity_by_sex_joint$upper_CI <- NULL
  common_cols <- intersect(names(cycle.assessment.data), names(percent_overweight_and_obesity_by_sex_joint))
  cycle.assessment.data <- cycle.assessment.data[, common_cols]
  percent_overweight_and_obesity_by_sex_joint <- percent_overweight_and_obesity_by_sex_joint[, common_cols]


  # merge observed and simulated data
  cycle.assessment.data <- rbind(cycle.assessment.data, percent_overweight_and_obesity_by_sex_joint)

  # get the % difference between the simulated and observed data
  cycle.assessment.data <- cycle.assessment.data %>%
    group_by(year, age_cat, sex) %>%
    arrange(source) %>%
    summarise(
      observed = prop_overweight_obese[1],
      simulated = prop_overweight_obese[2],
      diff_simulated_observed = (observed - simulated),
      diff_simulated_observed_2 = diff_simulated_observed^2
    ) %>%
    ungroup()

  cycle.assessment.data <- cycle.assessment.data[which(is.na(cycle.assessment.data$diff_simulated_observed) == FALSE), ]

  cycle.assessment.data <- cycle.assessment.data %>%
    group_by(age_cat, sex) %>%
    summarise(RMSE = sqrt(mean(diff_simulated_observed_2)))

  return(cycle.assessment.data)
}


#' Summarise Osteoarthritis (OA) Data
#'
#' Processes the full simulation output to calculate the prevalence of OA,
#' stratified by year, age group, and sex.
#'
#' @param am_all A data.frame representing the full simulation output.
#' @return A data.frame with the summarised OA prevalence statistics.
#' @importFrom dplyr filter select mutate group_by summarise bind_rows case_when
#' @export
OA_summary_fcn <- function(am_all) {
  # Declare variables to avoid R CMD check notes
  dead <- age <- year <- sex <- oa <- age_group <- percent <- NULL

  Z <-
    am_all %>%
    filter(dead == 0 & age > 34) %>%
    select(year, sex, starts_with("age"), oa) %>%
    # The age cat groups do not match with the validation data
    # so we need to re-calculate the age groups
    mutate(
      age_group =
        case_when(
          age > 34 & age <= 44 ~ "35-44",
          age > 44 & age <= 54 ~ "45-54",
          age > 54 & age <= 64 ~ "55-64",
          age > 64 & age <= 74 ~ "65-74",
          age > 74 ~ "75+"
        ),
      sex = stringr::str_squish(stringr::str_remove_all(sex, "\\[[0-9]+\\]"))
    ) %>%
    mutate(
      sex = ifelse(sex == "Female", "Females", "Males")
    ) %>%
    select(sex, year, age, age_group, oa)

  ZZ <-
    bind_rows(
      ### Percent by age and sex
      Z %>%
        group_by(year, sex, age_group) %>%
        summarise(percent = mean(oa, na.rm = TRUE)) %>%
        mutate(percent = percent * 100),

      ### Percent by age all
      Z %>%
        group_by(year, age_group) %>%
        summarise(percent = mean(oa, na.rm = TRUE)) %>%
        mutate(percent = percent * 100) %>%
        mutate(sex = "All"),

      ### Percent by sex all age
      Z %>%
        group_by(year, sex) %>%
        summarise(percent = mean(oa, na.rm = TRUE)) %>%
        mutate(percent = percent * 100) %>%
        mutate(age_group = "All ages"),

      ### Percent all
      Z %>%
        group_by(year) %>%
        summarise(percent = mean(oa, na.rm = TRUE)) %>%
        mutate(percent = percent * 100) %>%
        mutate(age_group = "All ages", sex = "All")
    ) %>%
    mutate(Source = "Model")

  return(ZZ)
}
