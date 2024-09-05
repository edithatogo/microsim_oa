# Get the stats for all simulations
number_of_sims <- length(sim_storage)
p_load(foreach,doParallel)
num_cores <- detectCores() - 1
if(number_of_sims<num_cores){
  num_cores <- number_of_sims
}

cl <- makeCluster(num_cores)
registerDoParallel(cl)

ptm <- proc.time()
Model_stats_list <- 
  foreach(i = 1:number_of_sims, 
          .combine = 'c',
          .packages=c("here","tidyverse")
          ) %dopar% {
            .GlobalEnv$sim_storage <- sim_storage
            source(here('scripts','functions','Stats_per_simulation_fcn.R'))
            Stat <- 
              bind_rows(
              stats_per_simulation(i, c("year", "sex", "age_group")),
              stats_per_simulation(i, c("year", "sex")) %>% 
                mutate(age_group = 'All 45 years and above')
              )
              return(list(Stat))
}
proc.time() - ptm
# Stop the parallel backend
stopCluster(cl)
registerDoSEQ()

# Combine the results from the list into a single data frame
f_get_CI <- 
  function(Z,var,sd, mean, number_of_sims){
    Z %>% 
      mutate(
        se = {{sd}}/sqrt(number_of_sims),
        !!paste0(var, "_lower_CI") := {{ mean }} - 1.96 * se,
        !!paste0(var, "_upper_CI") := {{ mean }} + 1.96 * se
      )
  }



Model_stats <- 
  bind_rows(Model_stats_list) %>% 
  group_by(variable,year,sex,age_group) %>% 
  summarise(
    N_mean = mean(N),
    N_sd = sd(N),
    Mean_mean = mean(Mean),
    Mean_sd = sd(Mean),
    Sum_mean = mean(Sum),
    Sum_sd = sd(Sum)
  ) %>% 
  f_get_CI(.,"N", N_sd, N_mean, number_of_sims) %>%
  f_get_CI(.,"Mean", Mean_sd, Mean_mean, number_of_sims) %>%
  f_get_CI(.,"Sum", Sum_sd, Sum_mean, number_of_sims) %>% 
  # Percentages
  mutate(
    across(
      c(starts_with('Mean')),
      ~ifelse(variable=='oa'|variable=='bmi_overweight_or_obese',
              .*100,.)
    ),
    across(
      c(starts_with('Mean')),
      ~ifelse(variable=='tka',
              .*100000,.) 
      )
    ) %>% 
  # Sex
  mutate(sex=ifelse(str_detect(sex,'Male'),'Male','Female')) %>% 
  # Attach descriptions (variable labels) to the variables
  mutate(
    description =
      case_when(
        variable=='age'~'Age',
        variable=='bmi'~'BMI',
        variable=='bmi_overweight_or_obese'~'BMI overweight or obese',
        variable=='bmi_obese'~'BMI obese',
        variable=='oa'~'OA prevalence',
        variable=='drugoa'~'Using medications for OA',
        variable=='mhc'~'Mental health condition',
        variable=='ccount'~'Comorbidity count',
        variable=='sf6d'~'Health related quality of life',
        variable=='phi'~'Private health insurance',
        variable=='year12'~'Year 12 education (proxy for SES)',
        variable=='drug_oa'~'Using medications for OA',
        variable=='drugmh'~'Using medications for mental health',
        variable=='willing'~'Willing for TKA',
        variable=='tkayear'~'Year of TKA',
        variable=='tka'~'TKA incidence',
        variable=='tka1'~'One TKA prevalence',
        variable=='tka2'~'Two TKAs prevalence',
        variable=='agetka1'~'Age at first TKA',
        variable=='agetka2'~'Age at second TKA',
        variable=='rev'~'Revision incidence',
        variable=='rev1'~'Revision prevalence',
        variable=='comp'~'TKA complication',
        variable=='ir'~'Inpatient rehabilitation after TKA',
        variable=='qaly'~'Quality adjusted life years',
        variable=='oai'~'OA incidence',
        variable=='oacost'~'OA cost',
        variable=='tkacost'~'TKA cost',
        variable=='revcost'~'Revision cost',
        variable=='rehabcost'~'Rehab cost',
        variable=='compcost'~'Complication cost',
        variable=='totalcost'~'Total cost',
        variable=='revision1'~'Revision after first TKA',
        variable=='revision2'~'Revision after second TKA',
        variable=='cum_haz1'~'Cumulative hazard (revision 1)',
        variable=='cum_haz2'~'Cumulative hazard (revision 2)',
        variable=='tka_ben_above_threshold'~'TKA benefit above threshold',
        variable=='tka_dqol_in_cycle'~'Calculated dqol for individuals with TKA in cycle'
      )
  ) %>%  
  relocate(description,.before=variable) 
