# STATS FUNCTIONS
#-------------------------------------------------------------------------------
# FUNCTION: Get percentages and frequencies of binary variables by group

# # Pre-cleaning
# # If you want to use this function to get percentages for those who are
# # alive, you would need to filter the data using filter(dead==0).
# 
# # Specifying the group_vars argument:
# # Example group_vars=c("year", "sex", "age_group")

f_get_percent_N_from_binary <- function(df, group_vars) {
  require(dplyr)
  
  # Select the required columns and filter values in (0, 1)
  df_filtered <- df %>%
    select(all_of(group_vars), where(~all(.x %in% c(0,1))))
  
  # Group by specified variables and calculate summary statistics
  summary_stats <- df_filtered %>%
    group_by(across(all_of(group_vars))) %>%
    summarise(
      across(
        where(~all(.x %in% c(0,1))),
        list(
          percent = ~mean(.x, na.rm = TRUE),
          frequency = ~sum(.x == 1, na.rm = TRUE)
        )
      )
    ) %>%
    ungroup() %>%
    mutate(
      across(
        .cols = -c({{ group_vars }}),
        ~round(.x * 100, 2)
      )
    )
  
  return(summary_stats)
}

f_get_means_freq_sum <- function(df, group_vars) {
  require(dplyr)
  
  # Select the required columns and filter values in (0, 1)
  df_filtered <- df 
  # Group by specified variables and calculate summary statistics
  summary_stats <- df_filtered %>%
    group_by(across(all_of(group_vars))) %>%
    summarise(
      across(
        where(is.numeric),
        list(
          mean = ~mean(.x, na.rm = TRUE),
          frequency = ~sum(.x == 1, na.rm = TRUE),
          sum = ~sum(.x, na.rm = TRUE)
        )
      )
    ) %>%
    ungroup() 
  
  return(summary_stats)
}

## BMI SUMMARY
BMI_summary_data <- function(am_all) {
  
  # remove all individuals who are dead in the cycle
  am_all <- am_all[which(am_all$dead == 0),]
  
  # in the 2022 format,
  BMI_by_sex_and_year <- am_all[,c("age", "sex", "year", "bmi")]
  # create matching age_bands
  BMI_by_sex_and_year$age_cat <- cut(BMI_by_sex_and_year$age,
                                     breaks = c(0,18,25,35,45,55,65,75,1000))
  
  # create a flag for overweight and obese, check defintion
  BMI_by_sex_and_year$overweight_obese <- ifelse(BMI_by_sex_and_year$bmi >=25, TRUE, FALSE)
  
  BMI_by_sex_and_year <- BMI_by_sex_and_year %>%
    group_by(year, age_cat, sex) %>%
    summarise(prop_overweight_obese = sum(overweight_obese)/n())
  
  # not interested in the younger age brackets, and the cohort ages out of them
  # given it is fixed, remove all age brackets below 35
  
  BMI_by_sex_and_year <- BMI_by_sex_and_year[which(BMI_by_sex_and_year$age_cat != "(0,18]"),]
  BMI_by_sex_and_year <- BMI_by_sex_and_year[which(BMI_by_sex_and_year$age_cat != "(18,25]"),]
  BMI_by_sex_and_year <- BMI_by_sex_and_year[which(BMI_by_sex_and_year$age_cat != "(25,35]"),]
  
  BMI_by_sex_and_year$age_cat <- fct_recode(BMI_by_sex_and_year$age_cat,
                                            "35–44" = "(35,45]",
                                            "45–54" = "(45,55]",
                                            "55–64" = "(55,65]",
                                            "65–74" = "(65,75]",
                                            "75 years and over" = "(75,1e+03]")
  
  BMI_by_sex_and_year$sex <- as.factor(BMI_by_sex_and_year$sex)
  BMI_by_sex_and_year$sex <- fct_recode(BMI_by_sex_and_year$sex,
                                        "Male" = "[1] Male",
                                        "Female" = "[2] Female")
  
  
  BMI_by_sex_and_year$source <- "Simulated"
  
  return(BMI_by_sex_and_year)
}

BMI_summary_plot <- function(percent_overweight_and_obesity_by_sex_joint,
                             BMI_by_sex_and_year,
                             current.mod.value) {
  
  # remove the lower age-brackets from the comparison data
  percent_overweight_and_obesity_by_sex_joint <- percent_overweight_and_obesity_by_sex_joint[which(percent_overweight_and_obesity_by_sex_joint$age_cat != "18–24"),]
  percent_overweight_and_obesity_by_sex_joint <- percent_overweight_and_obesity_by_sex_joint[which(percent_overweight_and_obesity_by_sex_joint$age_cat != "25–34"),]
  percent_overweight_and_obesity_by_sex_joint$age_cat <- as.factor(percent_overweight_and_obesity_by_sex_joint$age_cat)
  
  # remove any age brackets not represented in the BMI data
  percent_overweight_and_obesity_by_sex_joint <- percent_overweight_and_obesity_by_sex_joint[which(percent_overweight_and_obesity_by_sex_joint$age_cat %in% BMI_by_sex_and_year$age_cat),]
  
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
  p <- ggplot(cycle.plotting.data[which(cycle.plotting.data$source ==  "Observed"),], aes(x =year, y = prop_overweight_obese , color = age_cat))
  
  print(p + geom_point() +
          geom_errorbar( aes(ymin = lower_CI, ymax = upper_CI  , color = age_cat, width = 0.2), alpha = 0.5) +
          geom_line(data = cycle.plotting.data[which(cycle.plotting.data$source ==  "Simulated"),],
                    aes(x = year, y = prop_overweight_obese * 100, color = age_cat, group = age_cat))+
          facet_wrap(age_cat~sex) +
          theme(legend.position = "bottom", axis.text.x = element_text(angle = 45, hjust = 1)) +
          scale_x_continuous(breaks=seq(min(cycle.plotting.data$year),max(cycle.plotting.data$year),2)))
  
  ggsave(paste0("output_figures/BMI_validation_modval_",current.mod.value,".png"))
}

BMI_summary_RMSE <- function(percent_overweight_and_obesity_by_sex_joint,
                             BMI_by_sex_and_year,
                             current.mod.value) {
  
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
  
  # merge observed and simulated data
  cycle.assessment.data <- rbind(cycle.assessment.data, percent_overweight_and_obesity_by_sex_joint)
  
  cycle.assessment.data$upper_CI <- NULL
  cycle.assessment.data$lower_CI <- NULL
  
  # get the % difference between the simulated and observed data
  cycle.assessment.data <- cycle.assessment.data %>%
    group_by(year, age_cat, sex) %>%
    arrange(source) %>%
    summarise(observed = prop_overweight_obese[1],
              simulated = prop_overweight_obese[2],
              diff_simulated_observed = (observed-simulated),
              diff_simulated_observed_2 = diff_simulated_observed^2) %>%
    ungroup()
  
  cycle.assessment.data <- cycle.assessment.data[which(is.na(cycle.assessment.data$diff_simulated_observed) == FALSE),]
  
  cycle.assessment.data <- cycle.assessment.data %>%
    group_by(age_cat, sex) %>%
    summarise(RMSE = sqrt(mean(diff_simulated_observed_2)))
  
  return(cycle.assessment.data)
}


## OA SUMMARY
OA_summary_fcn <- function(am_all) {
  Z <- 
    am_all %>% 
    filter(dead==0&age>34) %>% 
    select(year,sex,starts_with('age'),oa) %>% 
    # The age cat groups do not match with the validation data
    # so we need to re-calculate the age groups
    mutate(
      age_group =
        case_when(
          age>34 & age <= 44 ~ '35-44',
          age > 44 & age <= 54 ~ '45-54',
          age > 54 & age <= 64 ~ '55-64',
          age > 64 & age <= 74 ~ '65-74',
          age > 74 ~ '75+'
        ),
      sex = str_replace(sex, "\\[\\d+\\] ", ""),
      sex = ifelse(sex=='Female','Females','Males')
    ) %>% 
    select(sex,year,age,age_group,oa) 
  
  ZZ <- 
    bind_rows(
      ### Percent by age and sex
      Z %>% 
        group_by(year,sex,age_group) %>% 
        summarise(percent=mean(oa,na.rm=TRUE)) %>% 
        mutate(percent=percent*100) ,
      
      ### Percent by age all
      Z %>% 
        group_by(year,age_group) %>% 
        summarise(percent=mean(oa,na.rm=TRUE)) %>% 
        mutate(percent=percent*100) %>% 
        mutate(sex='All'),
      
      ### Percent by sex all age
      Z %>% 
        group_by(year,sex) %>% 
        summarise(percent=mean(oa,na.rm=TRUE)) %>% 
        mutate(percent=percent*100) %>% 
        mutate(age_group='All ages'),
      
      ### Percent all
      Z %>% 
        group_by(year) %>% 
        summarise(percent=mean(oa,na.rm=TRUE)) %>% 
        mutate(percent=percent*100) %>% 
        mutate(age_group='All ages',sex='All')
    ) %>% 
    mutate(Source='Model')
  
}