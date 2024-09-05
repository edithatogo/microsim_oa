# % Load synthetic dataset
am <- read_csv(simpop_file,show_col_types = F)

# % Set up attribute matrix with additional variables
# % add id
# id = 1:n;
# am.id = transpose(id);
am$id <- 1:nrow(am)

# % add year
am$year <- as.numeric(startyear)


# % add mortality
am$dead <- 0

# % add tka willingness
am$willing <- 0

# % add tka in given year
am$tkayear <- 0

# % add previous tka
am$tka <- 0
am$tka1 <- 0
am$tka2 <- 0

# % time since tka
am$agetka1 <- 0
am$agetka2 <- 0


# % add rev
am$rev1 <- 0
am$rev <- 0

# % add complication
am$comp <- 0

# % add inpatient rehab
am$ir <- 0

# % Set up factor variables for matrix algebra
am$male <- ifelse(am$sex == "[1] Male",1,0)
am$female <- ifelse(am$sex == "[2] Female",1,0)


# % age_cat factor variables
age_edges <- c(min(am$age)-1, 45, 55, 65, 75, 150)
am$age_cat <- cut(am$age, breaks = age_edges, include.lowest = TRUE)

am$age044 <- ifelse(am$age_cat == levels(am$age_cat)[1],1,0)
am$age4554 <- ifelse(am$age_cat == levels(am$age_cat)[2],1,0)
am$age5564 <- ifelse(am$age_cat == levels(am$age_cat)[3],1,0)
am$age6574 <- ifelse(am$age_cat == levels(am$age_cat)[4],1,0)
am$age75 <- ifelse(am$age_cat == levels(am$age_cat)[5],1,0)

# % BMI calibrator (HILDA BMI low relative to population) - calibrated
# % for 2013
am$bmiorig <- am$bmi
am$bmi <- ifelse(am$bmi < 5, 19.5, am$bmi)
am$bmi <- ifelse(am$bmi < 9 , 18.5, am$bmi)
am$bmi <- ifelse(am$bmi < 11, 17.5, am$bmi)
am$bmi <- ifelse(am$bmi < 12, 16.5, am$bmi)

bmi_cal <-  1 + am$age044 * .05 +
  am$age4554 * .06 +
  am$age5564 * .05 +
  am$age6574 * am$male * .05 +
  am$age6574 * am$female * .025 +
  am$age75 * am$male * -.025

am$bmi <- am$bmi * bmi_cal

# % Groupings for categorising output
bmi_edges <- c(0, 25, 30, 35, 40, 100)
am$bmi_cat <- cut(am$bmi, breaks = bmi_edges, include.lowest = TRUE)

am$bmi024 <- ifelse(am$bmi_cat == levels(am$bmi_cat)[1],1,0)
am$bmi2529 <- ifelse(am$bmi_cat == levels(am$bmi_cat)[2],1,0)
am$bmi3034 <- ifelse(am$bmi_cat == levels(am$bmi_cat)[3],1,0)
am$bmi3539 <- ifelse(am$bmi_cat == levels(am$bmi_cat)[4],1,0)
am$bmi40 <- ifelse(am$bmi_cat == levels(am$bmi_cat)[5],1,0)

# % QALY - initialise to first year HRQOL
# am.qaly = am.sf6d;
am$qaly <- am$sf6d

# % transition vars
am$oai <- 0
am$oap <- 0
am$tkai <- 0
am$qx <- 0
am$hr_mort <- 0
am$tka_dqol <- 0


# Revision vars
am$rev_lpv <- 0
am$ASA2 <- 1
am$ASA3 <- 0
am$ASA4_5 <- 0
am$blcv1 <- 0
am$blcv2 <- 0
am$log_cum_haz1 <- 0
am$log_cum_haz2 <- 0
am$cum_haz1 <- 0
am$cum_haz2 <- 0
am$rev_haz1 <- 0
am$rev_haz2 <- 0
am$r1 <- 0
am$r2 <- 0
am$revision1 <- 0
am$revision2 <- 0
am$ch_old1 <- 0
am$ch_old2 <- 0
am$revi <- 0

## Identifier for public hospital
am$public=ifelse(am$phi==1,0,1)

## TKA benefit variables
am$tka_ben_above_threshold <- 0
am$tka_dqol_in_cycle <- 0

write_parquet(am,here('input','population','am.parquet'))