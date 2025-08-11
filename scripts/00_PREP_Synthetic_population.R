# PREPARE ATTRIBUTE MATRIX TO LOAD INTO THE MODEL
# This script prepares the am matrix for the model starting with the raw data.
# It then runs the synthetic population generator. Afterwards, the dataset
# is cleaned and saved as a parquet file. This saves the model from
# running the prep code each time it runs.
#-------------------------------------------------------------------------------
library(pacman)
# EXTRACT AND CLEAN HILDA DATA.
# (To be completed later. FOr now, we use the already cleaned csv file)


#-------------------------------------------------------------------------------

# RUN THE SYNTHETIC POPULATION GENERATOR
p_load(here)

# Create a dummy data frame with the required columns
my_sim <- data.frame(
  state = "NSW",
  age = 50,
  sex = "Male",
  bmi = 25,
  oa = 0,
  mhc = 0,
  ccount = 0,
  sf6d = 0.8,
  phi = 0,
  year12 = 1,
  drugoa = 0,
  drugmh = 0,
  kl2 = 0,
  kl3 = 0,
  kl4 = 0,
  dead = 0,
  tka = 0,
  tka1 = 0,
  tka2 = 0,
  agetka1 = 0,
  agetka2 = 0,
  rev1 = 0,
  revi = 0,
  pain = 0,
  function_score = 100,
  qaly = 0.8,
  year = 2023,
  d_bmi = 0,
  age044 = 0,
  age4554 = 1,
  age5564 = 0,
  age6574 = 0,
  age75 = 0,
  male = 1,
  female = 0,
  bmi024 = 0,
  bmi2529 = 1,
  bmi3034 = 0,
  bmi3539 = 0,
  bmi40 = 0,
  comp = 0,
  ir = 0,
  public = 0,
  d_sf6d = 0
)

# Export data frame to a CSV file
saveRDS(my_sim, file = here("inst", "extdata", "am_curr_before_oa.rds"))