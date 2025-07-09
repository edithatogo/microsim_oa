# PREP DATA TO COMPARE WITH MODEL OUTPUT
# This is a stand-alone script that does not need to be run everytime we run
# the model. Instead, we just need to load the cleaned data when we want to
# compare the model output with the data.


## LIBRARIES
# Install pacman if it is not already installed
if (!require("pacman")) install.packages("pacman")
# Use pacman to load and install packages as needed
p_load(
  here, # for file paths
  reshape2, # for melting data
  readxl, # for reading in excel files
  tidyverse, # for data manipulation
  janitor, # for cleaning data
  fy # for financial year conversion
)
options(dplyr.summarise.inform = FALSE) # turn off dplyr summarise info

#-------------------------------------------------------------------------------
## BMI DATA (Code from Josh)
### data for 2014-15
### https://www.abs.gov.au/ausstats/subscriber.nsf/log?openagent&4364055001do008_20142015.xls&4364.0.55.001&Data%20Cubes&4B20A1660EBE0012CA257F150009F9F3&0&2014-15&08.12.2015&Previous
bmi_2015 <- read_excel("supporting_data/raw_data/Obesity_2014_2015.xls",
  sheet = "Table_8_1"
)

bmi_2015 <- bmi_2015[c(5, 35, 36, 67, 68), c(1:8, 10:11, 13)]
bmi_2015$sex <- c("sex", "Male", "Male", "Female", "Female")
bmi_2015[1, 1] <- "Desc"

names(bmi_2015) <- as.character(bmi_2015[1, ])
bmi_2015 <- bmi_2015[2:5, ]

bmi_2015 <- melt(bmi_2015, id.vars = c("Desc", "sex"))

bmi_2015$value <- as.numeric(bmi_2015$value)

bmi_2015 <- bmi_2015 %>%
  group_by(variable, sex) %>%
  summarise(mean = value[which(Desc != "Total")] /
    as.numeric(value[Desc == "Total"]))

bmi_2015$lower_CI <- bmi_2015$upper_CI <- NA

bmi_2015$year <- 2015
bmi_2015 <- as.data.frame(bmi_2015)

names(bmi_2015)[1] <- "age_cat"

bmi_2015 <- bmi_2015[, c(
  "age_cat", "mean", "lower_CI", "upper_CI", "sex",
  "year"
)]


bmi_2015 <- bmi_2015[which(bmi_2015$age_cat != "18–24"), ]
bmi_2015 <- bmi_2015[which(bmi_2015$age_cat != "25–34"), ]
bmi_2015 <- bmi_2015[which(bmi_2015$age_cat != "75–84"), ]

bmi_2015 <- bmi_2015[which(bmi_2015$age_cat != "85 years\nand over"), ]
bmi_2015 <- bmi_2015[which(bmi_2015$age_cat != "Total 18 years and over"), ]

bmi_2015$age_cat <- fct_recode(bmi_2015$age_cat,
  "75 years and over" = "75 years \nand over"
)


bmi_2015$mean <- bmi_2015$mean * 100


### data for 2017-18
### https://www.aihw.gov.au/getmedia/410bb660-bf9c-4ad0-a67e-0ce29e4e95eb/aihw-phe-251-overweight-obesity-data-tables.xlsx.aspx
### access and organise 2020 BMI data
bmi_2018 <- read_excel("supporting_data/raw_data/aihw-phe-251-overweight-and-obesity-2020-data-tables.xlsx",
  sheet = "Table S2", n_max = 12
)


bmi_2018_male <- bmi_2018[4:11, c(1, 8:9)]
names(bmi_2018_male) <- c("age_cat", "mean", "CI")

### split the string in the bmi_2018_male$CI string by the '-' symbol and
### create two new variables
cis <- unlist(bmi_2018_male$CI)
cis <- str_split(cis, "–")
cis <- matrix(unlist(cis), ncol = 2, byrow = TRUE)

bmi_2018_male$CI <- NULL

bmi_2018_male <- cbind(bmi_2018_male, cis)

bmi_2018_male$sex <- "Male"
names(bmi_2018_male) <- c("age_cat", "mean", "lower_CI", "upper_CI", "sex")


bmi_2018_female <- bmi_2018[4:11, c(1, 17:18)]
names(bmi_2018_female) <- c("age_cat", "mean", "CI")

### split the string in the bmi_2018_female$CI string by the '-' symbol and
### create two new variables
cis <- unlist(bmi_2018_female$CI)
cis <- str_split(cis, "–")
cis <- matrix(unlist(cis), ncol = 2, byrow = TRUE)

bmi_2018_female$CI <- NULL

bmi_2018_female <- cbind(bmi_2018_female, cis)

bmi_2018_female$sex <- "Female"
names(bmi_2018_female) <- c("age_cat", "mean", "lower_CI", "upper_CI", "sex")

bmi_2018 <- rbind(
  bmi_2018_male,
  bmi_2018_female
)

bmi_2018$year <- 2018

bmi_2018$mean <- as.numeric(bmi_2018$mean)
bmi_2018$lower_CI <- as.numeric(bmi_2018$lower_CI)
bmi_2018$upper_CI <- as.numeric(bmi_2018$upper_CI)

# rm(overweight_or_obese_by_age_sex_2018_female,
#    overweight_or_obese_by_age_sex_2018_male,
#    CIs)


### load validation to match
bmi_2022 <- read_excel("supporting_data/raw_data/Proportion of adults who were overweight or obese by age and sex, 2022.xlsx",
  n_max = 8
)

bmi_2022_male <- bmi_2022[2:8, 1:4]
bmi_2022_male$sex <- "Male"
names(bmi_2022_male) <- c("age_cat", "mean", "lower_CI", "upper_CI", "sex")

bmi_2022_female <- bmi_2022[2:8, c(1, 5:7)]
bmi_2022_female$sex <- "Female"
names(bmi_2022_female) <- c("age_cat", "mean", "lower_CI", "upper_CI", "sex")

bmi_2022 <- rbind(
  bmi_2022_male,
  bmi_2022_female
)


bmi_2022 <- as.data.frame(bmi_2022)

bmi_2022[, 2] <- as.numeric(bmi_2022[, 2])
bmi_2022[, 3] <- as.numeric(bmi_2022[, 3])
bmi_2022[, 4] <- as.numeric(bmi_2022[, 4])

bmi_2022$year <- 2022

overweight_or_obese_by_age_sex <- rbind(bmi_2022)


### merge three difference datasets

bmi_data <- rbind(
  bmi_2015,
  bmi_2018
)

bmi_data <- rbind(
  bmi_data,
  bmi_2022
)

### Save the data
write_csv(bmi_data, here("supporting_data", "Cleaned_validation_data_BMI.csv"))

#-------------------------------------------------------------------------------

# TKR DATA
## Load data
tkr_data <-
  readxl::read_excel(here("supporting_data", "raw_data", "TKR_raw.xlsx")) %>%
  # Clean names
  janitor::clean_names() %>%
  rename(rate = hospitalisations_per_100_000_population) %>%
  # Need only TKR from arthritis
  filter(procedure == "total knee replacement for osteoarthritis") %>%
  # Age groups
  # Dont need 45+ years
  filter(age != "45+ years") %>%
  # Age is in a wierd format...
  mutate(
    age_group =
      case_when(
        age < 45 ~ "< 45",
        age >= 45 & age < 55 ~ "45-54",
        age >= 55 & age < 65 ~ "55-64",
        age >= 65 & age < 75 ~ "65-74",
        age >= 75 ~ "75+"
      ),
    age_group = ifelse(is.na(age_group), "All ages", age_group)
  ) %>%
  relocate(age_group, .after = age) %>%
  # Get total hospitalization for new age group
  group_by(year, sex, age_group) %>%
  mutate(tot_hosp = sum(hospitalisations)) %>%
  # We need to work out total population
  mutate(pop = (hospitalisations * 100000) / rate) %>%
  # Get total population for new age group
  mutate(tot_pop = sum(pop)) %>%
  # Get rate for new age group
  mutate(rate = (tot_hosp * 100000) / tot_pop) %>%
  # Select necessary variables
  select(sex, age_group, year, rate) %>%
  # Just some cleaning up for nicer tables and graphs...
  filter(row_number() == 1) %>%
  mutate(
    year = fy2yr(year),
    age_group =
      factor(
        age_group,
        levels = c("< 45", "45-54", "55-64", "65-74", "75+", "All ages")
      )
  ) %>%
  arrange(sex, age_group, year) %>%
  group_by(sex, age_group) %>%
  # Normalize to 2011
  mutate(
    base = max(ifelse(year == 2011, rate, 0)),
    tkr = rate / base
  ) %>%
  mutate(
    sex = ifelse(sex == "Females", "Female", sex),
    sex = ifelse(sex == "Males", "Male", sex)
  )

write_csv(tkr_data, here("supporting_data", "Cleaned_validation_data_TKR.csv"))


#-------------------------------------------------------------------------------
# OA DATA
## Function to load data
f_temp <- function(sheet_name, file_name) {
  z_data <-
    read_excel(
      here("supporting_data", "raw_data", file_name),
      sheet = sheet_name,
      skip = 5, col_names = TRUE
    ) %>%
    filter(`...1` == "Osteoarthritis") %>%
    clean_names() %>%
    select(
      x35_44, x45_54, x55_64, x65_74, x75_years_and_over,
      total_all_ages
    ) %>%
    mutate(across(everything(), as.numeric))
}

## 2022 Proportions
file_name <- "NHSDC03.xlsx"
z_data <-
  bind_rows(
    f_temp("Table 3.3_Proportions Persons", file_name) %>%
      mutate(sex = "All"),
    f_temp("Table 3.7_Proportions Males", file_name) %>%
      mutate(sex = "Males"),
    f_temp("Table 3.11_Proportions Females", file_name) %>%
      mutate(sex = "Females"),
  ) %>%
  relocate(sex) %>%
  pivot_longer(-c(sex), names_to = "age_group", values_to = "percent")


## 2022 CI
zz_data <-
  bind_rows(
    f_temp("Table 3.4_MoEs Persons", file_name) %>%
      mutate(sex = "All"),
    f_temp("Table 3.8_MOEs Males", file_name) %>%
      mutate(sex = "Males"),
    f_temp("Table 3.12_MOEs Females", file_name) %>%
      mutate(sex = "Females"),
  ) %>%
  relocate(sex) %>%
  pivot_longer(-c(sex), names_to = "age_group", values_to = "moe")

validate_oa_1 <-
  full_join(z_data, zz_data, by = c("sex", "age_group")) %>%
  mutate(
    lower_CI = percent - moe,
    upper_CI = percent + moe,
    year = 2022,
    age_group = str_remove(age_group, "x"),
    age_group = str_replace(age_group, "_", "-"),
    age_group = ifelse(age_group == "75-years_and_over", "75+", age_group),
    age_group = ifelse(age_group == "total-all_ages", "All ages", age_group)
  ) %>%
  select(-moe)

## 2015 proportions and CI
file_name <- "NHS 201415 4364055001do003_20142015.xls"
z_data <-
  bind_rows(
    f_temp("Table_3_3 Proportions, persons", file_name) %>%
      mutate(sex = "All"),
    f_temp("Table_3_7 Proportions, males", file_name) %>%
      mutate(sex = "Males"),
    f_temp("Table_3_11 Proportions, females", file_name) %>%
      mutate(sex = "Females"),
  ) %>%
  relocate(sex) %>%
  pivot_longer(-c(sex), names_to = "age_group", values_to = "percent")

zz_data <-
  bind_rows(
    f_temp("Table_3_4 MoEs, persons", file_name) %>%
      mutate(sex = "All"),
    f_temp("Table_3_8 MoEs, males", file_name) %>%
      mutate(sex = "Males"),
    f_temp("Table_3_12 MoEs, females", file_name) %>%
      mutate(sex = "Females"),
  ) %>%
  relocate(sex) %>%
  pivot_longer(-c(sex), names_to = "age_group", values_to = "moe")

validate_oa_2 <-
  full_join(z_data, zz_data, by = c("sex", "age_group")) %>%
  mutate(
    lower_CI = percent - moe,
    upper_CI = percent + moe,
    year = 2015,
    age_group = str_remove(age_group, "x"),
    age_group = str_replace(age_group, "_", "-"),
    age_group = ifelse(age_group == "75-years_and_over", "75+", age_group),
    age_group = ifelse(age_group == "total-all_ages", "All ages", age_group)
  ) %>%
  select(-moe)

## 2018 proportions and CI
## This file needs a different skip
f_temp <- function(sheet_name, file_name) {
  z_data <-
    read_excel(
      here("supporting_data", "raw_data", file_name),
      sheet = sheet_name,
      skip = 6, col_names = TRUE
    ) %>%
    filter(`...1` == "Osteoarthritis") %>%
    clean_names() %>%
    select(
      x35_44, x45_54, x55_64, x65_74, x75_years_and_over,
      total_all_ages
    ) %>%
    mutate(across(everything(), as.numeric))
}


file_name <- "NHS 201718 4364055001do003_20172018.xls"
z_data <-
  bind_rows(
    f_temp("Table 3.3_Proportions, persons", file_name) %>%
      mutate(sex = "All"),
    f_temp("Table 3.7_Proportions, males", file_name) %>%
      mutate(sex = "Males"),
    f_temp("Table 3.11_Proportions, females", file_name) %>%
      mutate(sex = "Females"),
  ) %>%
  relocate(sex) %>%
  pivot_longer(-c(sex), names_to = "age_group", values_to = "percent")

zz_data <-
  bind_rows(
    f_temp("Table 3.4_MoEs, Persons", file_name) %>%
      mutate(sex = "All"),
    f_temp("Table 3.8_MoEs, males", file_name) %>%
      mutate(sex = "Males"),
    f_temp("Table 3.12_MoEs, females", file_name) %>%
      mutate(sex = "Females"),
  ) %>%
  relocate(sex) %>%
  pivot_longer(-c(sex), names_to = "age_group", values_to = "moe")

validate_oa_3 <-
  full_join(z_data, zz_data, by = c("sex", "age_group")) %>%
  mutate(
    lower_CI = percent - moe,
    upper_CI = percent + moe,
    year = 2018,
    age_group = str_remove(age_group, "x"),
    age_group = str_replace(age_group, "_", "-"),
    age_group = ifelse(age_group == "75-years_and_over", "75+", age_group),
    age_group = ifelse(age_group == "total-all_ages", "All ages", age_group)
  ) %>%
  select(-moe)

## Join all together
validate_oa <-
  bind_rows(validate_oa_1, validate_oa_2, validate_oa_3) %>%
  mutate(Source = "Data")

write_csv(
  validate_oa,
  here("supporting_data", "Cleaned_validation_data_OA.csv")
)
