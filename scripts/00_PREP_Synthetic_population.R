# PREPARE ATTRIBUTE MATRIX TO LOAD INTO THE MODEL
# This script prepares the am matrix for the model starting with the raw data.
# It then runs the synthetic population generator. Afterwards, the dataset
# is cleaned and saved as a parquet file. This saves the model from
# running the prep code each time it runs.
#-------------------------------------------------------------------------------

# EXTRACT AND CLEAN HILDA DATA.
# (To be completed later. FOr now, we use the already cleaned csv file)


#-------------------------------------------------------------------------------

# RUN THE SYNTHETIC POPULATION GENERATOR
p_load(simPop, haven, tidyr, dplyr, party,synthpop,here)
## STATA dataset
synpop_wave <- read.csv(input_data)
synpop_wave <- synpop_wave[,c("age","sex","bmi","oa","sf6d",
                              "phi","year12","drugoa","drugmh","mhc","state",
                              "ccount", "hhrhid", "hhweight")]

# adjust weighting (leaving as is will create full population)
synpop_wave$hhweight <- synpop_wave$hhweight/pop_weight
# calibration - HILDA weights seem to have a shortfall. Use for model. 
synpop_wave$hhweight <- scale_HILDA*synpop_wave$hhweight
# testing
#synpop_wave$hhweight <- 10

# format data
synpop_wave$state <- as.factor(synpop_wave$state)
synpop_wave$oa <- as.factor(synpop_wave$oa)
synpop_wave$phi <- as.factor(synpop_wave$phi)
synpop_wave$year12 <- as.factor(synpop_wave$year12)
synpop_wave$drugoa <- as.factor(synpop_wave$drugoa)
synpop_wave$drugmh <- as.factor(synpop_wave$drugmh)
synpop_wave$ccount <- as.factor(synpop_wave$ccount)
synpop_wave$mhc <- as.factor(synpop_wave$mhc)

# SIMULATING DATASET ------------------------------------------------------

## Selecting variable to define population
inp <- specifyInput(data = synpop_wave,
                    hhid = "hhrhid",
                    strata = "state",
                    weight = "hhweight")

## Generating structure of synthetic population
simPop <- simStructure(inp,
                       method = "direct",
                       basicHHvars = c("age","sex"))

simPop <- simCategorical(simPop,
                         additional = c("oa","phi","year12","ccount", "mhc", "drugoa","drugmh"),
                         method="distribution", nr_cpus=1)

# 
# regModel = ~ age + sex + bmi

simPop <- simContinuous(simPop,
                        additional = "bmi",
                        #regModel = regModel,
                        upper = 200000,
                        nr_cpus = 1)


simPop <- simContinuous(simPop,
                        additional = "sf6d",
                        #regModel = regModel,
                        upper = 200000,
                        equidist = FALSE,
                        nr_cpus = 1)


## Call population
mysim <- data.frame(popData(simPop))
mysim <- mysim[,c("state", "age", "sex", "bmi", "oa", "mhc", "ccount", "sf6d", 
                  "phi", "year12", "drugoa", "drugmh")]
# Check number of NAs
na_count <-sum(is.na(mysim))
print(na_count)
# Either re-run or set to zero
mysim[is.na(mysim)] <- 0

# Export data frame to a CSV file
write.csv(mysim, file = 
            here(simpop_file), 
          row.names = FALSE)
