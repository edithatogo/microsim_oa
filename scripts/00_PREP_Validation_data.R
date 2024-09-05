# PREP DATA TO COMPARE WITH MODEL OUTPUT
# This is a stand-alone script that does not need to be run everytime we run
# the model. Instead, we just need to load the cleaned data when we want to
# compare the model output with the data.


## LIBRARIES
# Install pacman if it is not already installed
if (!require("pacman")) install.packages("pacman")
# Use pacman to load and install packages as needed
p_load(
  here,       # for file paths
  reshape2,   # for melting data
  readxl,     # for reading in excel files
  tidyverse,  # for data manipulation
  janitor,    # for cleaning data
  fy          # for financial year conversion
)
options(dplyr.summarise.inform = FALSE) # turn off dplyr summarise info

#-------------------------------------------------------------------------------
## BMI DATA (Code from Josh)
### data for 2014-15
### https://www.abs.gov.au/ausstats/Subscriber.nsf/log?openagent&4364055001do008_20142015.xls&4364.0.55.001&Data%20Cubes&4B20A1660EBE0012CA257F150009F9F3&0&2014-15&08.12.2015&Previous
percent_overweight_and_obesity_by_sex_2015 <- read_excel("supporting_data/raw_data/Obesity_2014_2015.xls", 
                                                         sheet = "Table_8_1")

percent_overweight_and_obesity_by_sex_2015 <- percent_overweight_and_obesity_by_sex_2015[c(5,35,36,67,68),c(1:8,10:11,13)]
percent_overweight_and_obesity_by_sex_2015$sex <-  c("sex","Male","Male","Female","Female")
percent_overweight_and_obesity_by_sex_2015[1,1] <- "Desc"

names(percent_overweight_and_obesity_by_sex_2015) <- as.character(percent_overweight_and_obesity_by_sex_2015[1,])
percent_overweight_and_obesity_by_sex_2015 <- percent_overweight_and_obesity_by_sex_2015[2:5,]

percent_overweight_and_obesity_by_sex_2015 <- melt(percent_overweight_and_obesity_by_sex_2015, id.vars = c("Desc","sex"))

percent_overweight_and_obesity_by_sex_2015$value <- as.numeric(percent_overweight_and_obesity_by_sex_2015$value)

percent_overweight_and_obesity_by_sex_2015 <- percent_overweight_and_obesity_by_sex_2015 %>%
  group_by(variable,sex) %>%
  summarise(mean = value[which(Desc != "Total")] /as.numeric(value[Desc == "Total"]))

percent_overweight_and_obesity_by_sex_2015$lower_CI <- percent_overweight_and_obesity_by_sex_2015$upper_CI <- NA

percent_overweight_and_obesity_by_sex_2015$year <- 2015
percent_overweight_and_obesity_by_sex_2015 <- as.data.frame(percent_overweight_and_obesity_by_sex_2015)

names(percent_overweight_and_obesity_by_sex_2015)[1] <- "age_cat"

percent_overweight_and_obesity_by_sex_2015 <- percent_overweight_and_obesity_by_sex_2015[,c("age_cat","mean","lower_CI","upper_CI","sex","year")]


percent_overweight_and_obesity_by_sex_2015 <- percent_overweight_and_obesity_by_sex_2015[which(percent_overweight_and_obesity_by_sex_2015$age_cat != "18–24"),]
percent_overweight_and_obesity_by_sex_2015 <- percent_overweight_and_obesity_by_sex_2015[which(percent_overweight_and_obesity_by_sex_2015$age_cat != "25–34"),]
percent_overweight_and_obesity_by_sex_2015 <- percent_overweight_and_obesity_by_sex_2015[which(percent_overweight_and_obesity_by_sex_2015$age_cat != "75–84"),]

percent_overweight_and_obesity_by_sex_2015 <- percent_overweight_and_obesity_by_sex_2015[which(percent_overweight_and_obesity_by_sex_2015$age_cat != "85 years\nand over"),]
percent_overweight_and_obesity_by_sex_2015 <- percent_overweight_and_obesity_by_sex_2015[which(percent_overweight_and_obesity_by_sex_2015$age_cat != "Total 18 years and over"),]

percent_overweight_and_obesity_by_sex_2015$age_cat <- fct_recode(percent_overweight_and_obesity_by_sex_2015$age_cat,
                                                                 "75 years and over" = "75 years \nand over")


percent_overweight_and_obesity_by_sex_2015$mean <- percent_overweight_and_obesity_by_sex_2015$mean * 100

### data for 2017-18
### https://www.aihw.gov.au/getmedia/410bb660-bf9c-4ad0-a67e-0ce29e4e95eb/aihw-phe-251-overweight-obesity-data-tables.xlsx.aspx
### access and organise 2020 BMI data
percent_overweight_and_obesity_by_sex_2018 <- read_excel("supporting_data/raw_data/aihw-phe-251-overweight-and-obesity-2020-data-tables.xlsx", 
                                                         sheet = "Table S2", n_max = 12)


percent_overweight_and_obesity_by_sex_2018_male <- percent_overweight_and_obesity_by_sex_2018[4:11,c(1,8:9)]
names(percent_overweight_and_obesity_by_sex_2018_male) <- c("age_cat", "mean","CI")

### split the string in the percent_overweight_and_obesity_by_sex_2018_male$CI string by the '-' symbol and create two new variables
CIs <- unlist(percent_overweight_and_obesity_by_sex_2018_male$CI)
CIs <- str_split(CIs, "–")
CIs <- matrix(unlist(CIs),ncol = 2, byrow = TRUE)

percent_overweight_and_obesity_by_sex_2018_male$CI <- NULL

percent_overweight_and_obesity_by_sex_2018_male <- cbind(percent_overweight_and_obesity_by_sex_2018_male, CIs)

percent_overweight_and_obesity_by_sex_2018_male$sex <- "Male"
names(percent_overweight_and_obesity_by_sex_2018_male) <- c("age_cat", "mean","lower_CI","upper_CI","sex")


percent_overweight_and_obesity_by_sex_2018_female <- percent_overweight_and_obesity_by_sex_2018[4:11,c(1,17:18)]
names(percent_overweight_and_obesity_by_sex_2018_female) <- c("age_cat", "mean","CI")

### split the string in the percent_overweight_and_obesity_by_sex_2018_female$CI string by the '-' symbol and create two new variables
CIs <- unlist(percent_overweight_and_obesity_by_sex_2018_female$CI)
CIs <- str_split(CIs, "–")
CIs <- matrix(unlist(CIs),ncol = 2, byrow = TRUE)

percent_overweight_and_obesity_by_sex_2018_female$CI <- NULL

percent_overweight_and_obesity_by_sex_2018_female <- cbind(percent_overweight_and_obesity_by_sex_2018_female, CIs)

percent_overweight_and_obesity_by_sex_2018_female$sex <- "Female"
names(percent_overweight_and_obesity_by_sex_2018_female) <- c("age_cat", "mean","lower_CI","upper_CI","sex")

percent_overweight_and_obesity_by_sex_2018 <- rbind(percent_overweight_and_obesity_by_sex_2018_male,
                                                    percent_overweight_and_obesity_by_sex_2018_female)

percent_overweight_and_obesity_by_sex_2018$year <- 2018

percent_overweight_and_obesity_by_sex_2018$mean <- as.numeric(percent_overweight_and_obesity_by_sex_2018$mean)
percent_overweight_and_obesity_by_sex_2018$lower_CI <- as.numeric(percent_overweight_and_obesity_by_sex_2018$lower_CI)
percent_overweight_and_obesity_by_sex_2018$upper_CI <- as.numeric(percent_overweight_and_obesity_by_sex_2018$upper_CI)

# rm(percent_overweight_and_obesity_by_sex_2018_female,
#    percent_overweight_and_obesity_by_sex_2018_male,
#    CIs)


### load validation to match
percent_overweight_or_obese_by_age_and_sex_2022 <- read_excel("supporting_data/raw_data/Proportion of adults who were overweight or obese by age and sex, 2022.xlsx",
                                                              n_max = 8)

percent_overweight_or_obese_by_age_and_sex_2022_male <- percent_overweight_or_obese_by_age_and_sex_2022[2:8,1:4]
percent_overweight_or_obese_by_age_and_sex_2022_male$sex <- "Male"
names(percent_overweight_or_obese_by_age_and_sex_2022_male) <- c("age_cat", "mean","lower_CI","upper_CI","sex")

percent_overweight_or_obese_by_age_and_sex_2022_female <- percent_overweight_or_obese_by_age_and_sex_2022[2:8,c(1,5:7)]
percent_overweight_or_obese_by_age_and_sex_2022_female$sex <- "Female"
names(percent_overweight_or_obese_by_age_and_sex_2022_female) <- c("age_cat", "mean","lower_CI","upper_CI","sex")

percent_overweight_or_obese_by_age_and_sex_2022 <- rbind(percent_overweight_or_obese_by_age_and_sex_2022_male,
                                                         percent_overweight_or_obese_by_age_and_sex_2022_female)


percent_overweight_or_obese_by_age_and_sex_2022 <- as.data.frame(percent_overweight_or_obese_by_age_and_sex_2022)

percent_overweight_or_obese_by_age_and_sex_2022[,2] <- as.numeric(percent_overweight_or_obese_by_age_and_sex_2022[,2])
percent_overweight_or_obese_by_age_and_sex_2022[,3] <- as.numeric(percent_overweight_or_obese_by_age_and_sex_2022[,3])
percent_overweight_or_obese_by_age_and_sex_2022[,4] <- as.numeric(percent_overweight_or_obese_by_age_and_sex_2022[,4])

percent_overweight_or_obese_by_age_and_sex_2022$year <- 2022

#rm(percent_overweight_or_obese_by_age_and_sex_2022_female,percent_overweight_or_obese_by_age_and_sex_2022_male)



percent_overweight_or_obese_by_age_and_sex <- rbind(percent_overweight_or_obese_by_age_and_sex_2022)


### merge three difference datasets

BMI_data <- rbind(percent_overweight_and_obesity_by_sex_2015,
                                                     percent_overweight_and_obesity_by_sex_2018)

BMI_data <- rbind(BMI_data,
                                                     percent_overweight_or_obese_by_age_and_sex_2022)

### Clean up memory and rename the dataframe to a shorter name
# rm(percent_overweight_and_obesity_by_sex_2015,percent_overweight_and_obesity_by_sex_2018,
#    percent_overweight_or_obese_by_age_and_sex_2022,
#    percent_overweight_or_obese_by_age_and_sex)


### Save the data
write_csv(BMI_data, here("supporting_data","Cleaned_validation_data_BMI.csv"))

#-------------------------------------------------------------------------------

# TKR DATA
## Load data
A <- 
  readxl::read_excel(here("supporting_data","raw_data",'TKR_raw.xlsx')) %>% 
  # Clean names
  janitor::clean_names() %>% 
  rename(rate=hospitalisations_per_100_000_population) %>%
  # Need only TKR from arthritis
  filter(procedure=='total knee replacement for osteoarthritis') %>% 
  # Age groups
  # Dont need 45+ years
  filter(age!='45+ years')%>%
  # Age is in a wierd format...
  mutate(age=str_extract(age,'\\d+'),
         age=as.integer(age),
         age_group=
           case_when(
             age<45 ~ '< 45',
             age>=45 & age<55 ~ '45-54',
             age>=55 & age<65 ~ '55-64',
             age>=65 & age<75 ~ '65-74',
             age>=75 ~ '75+'
           ),
         age_group=ifelse(is.na(age_group),'All ages',age_group)
  ) %>% 
  relocate(age_group,.after=age) %>% 
  # Get total hospitalization for new age group
  group_by(year,sex,age_group) %>% 
  mutate(tot_hosp=sum(hospitalisations)) %>% 
  # We need to work out total population
  mutate(pop=(hospitalisations*100000)/rate) %>% 
  # Get total population for new age group
  mutate(tot_pop=sum(pop)) %>%
  # Get rate for new age group
  mutate(rate=(tot_hosp*100000)/tot_pop) %>%
  # Select necessary variables
  select(sex,age_group,year,rate) %>% 
  # Just some cleaning up for nicer tables and graphs...
  filter(row_number()==1) %>% 
  mutate(year=fy2yr(year),
         age_group=
           factor(age_group,
                  levels=c('< 45','45-54','55-64','65-74','75+','All ages')
           )
  ) %>% 
  arrange(sex,age_group,year) %>%
  group_by(sex,age_group) %>% 
  # Normalize to 2011
  mutate(base=max(ifelse(year==2011,rate,0)),
         tkr=rate/base
  ) %>% 
  mutate(sex=ifelse(sex=='Females','Female',sex),
         sex=ifelse(sex=='Males','Male',sex))

write_csv(A, here("supporting_data","Cleaned_validation_data_TKR.csv"))


#-------------------------------------------------------------------------------
# OA DATA
## Function to load data
f_temp <- function(sheet_name,file_name) {
  Z <- 
    read_excel(
      here("supporting_data","raw_data",file_name),
      sheet = sheet_name,
      skip = 5, col_names = TRUE
    ) %>%
    filter(`...1`=='Osteoarthritis') %>% 
    clean_names() %>% 
    select(x35_44,x45_54,x55_64,x65_74,x75_years_and_over,total_all_ages) %>% 
    mutate(across(everything(),as.numeric)) 
}

## 2022 Proportions
file_name <- 'NHSDC03.xlsx'
Z <- 
  bind_rows(
    f_temp('Table 3.3_Proportions Persons',file_name) %>% 
      mutate(sex='All'),
    f_temp('Table 3.7_Proportions Males',file_name) %>% 
      mutate(sex='Males'),
    f_temp('Table 3.11_Proportions Females',file_name) %>% 
      mutate(sex='Females'),
  ) %>% 
  relocate(sex) %>% 
  pivot_longer(-c(sex),names_to='age_group',values_to='percent') 


## 2022 CI
ZZ <- 
  bind_rows(
    f_temp("Table 3.4_MoEs Persons",file_name) %>% 
      mutate(sex='All'),
    f_temp('Table 3.8_MOEs Males',file_name) %>% 
      mutate(sex='Males'),
    f_temp('Table 3.12_MOEs Females',file_name) %>% 
      mutate(sex='Females'),
  ) %>% 
  relocate(sex) %>% 
  pivot_longer(-c(sex),names_to='age_group',values_to='moe') 

Validate_OA_1 <- 
  full_join(Z,ZZ,by=c('sex','age_group')) %>% 
  mutate(
    lower_CI = percent - moe,
    upper_CI = percent + moe,
    year=2022,
    age_group = str_remove(age_group,'x'),
    age_group = str_replace(age_group,'_', '-'),
    age_group = ifelse(age_group=='75-years_and_over','75+',age_group),
    age_group = ifelse(age_group=='total-all_ages','All ages',age_group)
  ) %>% 
  select(-moe) 

## 2015 proportions and CI
file_name <- 'NHS 201415 4364055001do003_20142015.xls'
Z <- 
  bind_rows(
    f_temp('Table_3_3 Proportions, persons',file_name) %>% 
      mutate(sex='All'),
    f_temp('Table_3_7 Proportions, males',file_name) %>% 
      mutate(sex='Males'),
    f_temp('Table_3_11 Proportions, females',file_name) %>% 
      mutate(sex='Females'),
  ) %>% 
  relocate(sex) %>% 
  pivot_longer(-c(sex),names_to='age_group',values_to='percent') 

ZZ <- 
  bind_rows(
    f_temp("Table_3_4 MoEs, persons",file_name) %>% 
      mutate(sex='All'),
    f_temp('Table_3_8 MoEs, males',file_name) %>% 
      mutate(sex='Males'),
    f_temp('Table_3_12 MoEs, females',file_name) %>% 
      mutate(sex='Females'),
  ) %>% 
  relocate(sex) %>% 
  pivot_longer(-c(sex),names_to='age_group',values_to='moe') 

Validate_OA_2 <- 
  full_join(Z,ZZ,by=c('sex','age_group')) %>% 
  mutate(
    lower_CI = percent - moe,
    upper_CI = percent + moe,
    year=2015,
    age_group = str_remove(age_group,'x'),
    age_group = str_replace(age_group,'_', '-'),
    age_group = ifelse(age_group=='75-years_and_over','75+',age_group),
    age_group = ifelse(age_group=='total-all_ages','All ages',age_group)
  ) %>% 
  select(-moe) 

## 2018 proportions and CI
## This file needs a different skip
f_temp <- function(sheet_name,file_name) {
  Z <- 
    read_excel(
      here("supporting_data","raw_data",file_name),
      sheet = sheet_name,
      skip = 6, col_names = TRUE
    ) %>%
    filter(`...1`=='Osteoarthritis') %>% 
    clean_names() %>% 
    select(x35_44,x45_54,x55_64,x65_74,x75_years_and_over,total_all_ages) %>% 
    mutate(across(everything(),as.numeric)) 
}


file_name <- 'NHS 201718 4364055001do003_20172018.xls'
Z <- 
  bind_rows(
    f_temp('Table 3.3_Proportions, persons',file_name) %>% 
      mutate(sex='All'),
    f_temp('Table 3.7_Proportions, males',file_name) %>% 
      mutate(sex='Males'),
    f_temp('Table 3.11_Proportions, females',file_name) %>% 
      mutate(sex='Females'),
  ) %>% 
  relocate(sex) %>% 
  pivot_longer(-c(sex),names_to='age_group',values_to='percent') 

ZZ <- 
  bind_rows(
    f_temp("Table 3.4_MoEs, Persons",file_name) %>% 
      mutate(sex='All'),
    f_temp('Table 3.8_MoEs, males',file_name) %>% 
      mutate(sex='Males'),
    f_temp('Table 3.12_MoEs, females',file_name) %>% 
      mutate(sex='Females'),
  ) %>% 
  relocate(sex) %>% 
  pivot_longer(-c(sex),names_to='age_group',values_to='moe') 

Validate_OA_3 <- 
  full_join(Z,ZZ,by=c('sex','age_group')) %>% 
  mutate(
    lower_CI = percent - moe,
    upper_CI = percent + moe,
    year=2018,
    age_group = str_remove(age_group,'x'),
    age_group = str_replace(age_group,'_', '-'),
    age_group = ifelse(age_group=='75-years_and_over','75+',age_group),
    age_group = ifelse(age_group=='total-all_ages','All ages',age_group)
  ) %>% 
  select(-moe) 

## Join all together
Validate_OA <- 
  bind_rows(Validate_OA_1,Validate_OA_2,Validate_OA_3) %>% 
  mutate(Source='Data') 

write_csv(Validate_OA,here("supporting_data",'Cleaned_validation_data_OA.csv'))
