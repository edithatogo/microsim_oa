
# load data from spreadsheet
coefficent_mod_values <- 
  read_excel(input_file, sheet = "customise_coefficents") %>%
  filter(!is.na(Mod_value))


# setup equation customisation variables
eq_cust <- list()


# # BMI equation customisation
# current.BMI.mod.value <- c(0.7, # modification for males <50
#                            1, # modification for males >=50
#                            0.6, # modification for females, <50
#                            0.6, # modification for females, high ses >=50
#                            0.6) # modification for females, low ses >=50)

# two columns, covarate set name and the proportion reduction in effect
BMI_cust <- as.data.frame(matrix(c("c1", coefficent_mod_values$Mod_value[which(coefficent_mod_values$Variable_label == "c1")],
                                   "c2", coefficent_mod_values$Mod_value[which(coefficent_mod_values$Variable_label == "c2")],
                                   "c3", coefficent_mod_values$Mod_value[which(coefficent_mod_values$Variable_label == "c3")],
                                   "c4", coefficent_mod_values$Mod_value[which(coefficent_mod_values$Variable_label == "c4")],
                                   "c5", coefficent_mod_values$Mod_value[which(coefficent_mod_values$Variable_label == "c5")]),
                                 ncol = 2, byrow = TRUE))

names(BMI_cust) <- c("covariate_set", "proportion_reduction")

eq_cust[["BMI"]] <- BMI_cust

# OA equation customisation

#current.OA.mod.values <- c(0.81, # modification for c6_cons
#                           1.3, # modification for c6_age1
#                           0.05, # modification for c6_age3
#                           0.05, # modification for c6_age4
#                           0.01, # modification for c6_age5
#                           0.5) # modification for c6_sex

OA_cust <- as.data.frame(matrix(c("c6_cons", coefficent_mod_values$Mod_value[which(coefficent_mod_values$Variable_label == "c6_cons")],
                                  "c6_age1m", coefficent_mod_values$Mod_value[which(coefficent_mod_values$Variable_label == "c6_age1m")],
                                  "c6_age2m", coefficent_mod_values$Mod_value[which(coefficent_mod_values$Variable_label == "c6_age2m")],
                                  "c6_age3m", coefficent_mod_values$Mod_value[which(coefficent_mod_values$Variable_label == "c6_age3m")],
                                  "c6_age4m", coefficent_mod_values$Mod_value[which(coefficent_mod_values$Variable_label == "c6_age4m")],
                                  "c6_age5m", coefficent_mod_values$Mod_value[which(coefficent_mod_values$Variable_label == "c6_age5m")],
                                  "c6_age1f", coefficent_mod_values$Mod_value[which(coefficent_mod_values$Variable_label == "c6_age1f")],
                                  "c6_age2f", coefficent_mod_values$Mod_value[which(coefficent_mod_values$Variable_label == "c6_age2f")],
                                  "c6_age3f", coefficent_mod_values$Mod_value[which(coefficent_mod_values$Variable_label == "c6_age3f")],
                                  "c6_age4f", coefficent_mod_values$Mod_value[which(coefficent_mod_values$Variable_label == "c6_age4f")],
                                  "c6_age5f", coefficent_mod_values$Mod_value[which(coefficent_mod_values$Variable_label == "c6_age5f")]),
                                ncol = 2, byrow = TRUE))

names(OA_cust) <- c("covariate_set", "proportion_reduction")

eq_cust[["OA"]] <- OA_cust

# TKR equation customisation
# note customisation is at the coefficient level, not the equation level as with BMI


current.TKR.mod.values <- c(1, # modification for c9_age
                            1, # modification for c9_age2
                            1, # modification for c9_drugoa
                            1, # modification for c9_ccount
                            1, # modification for c9_mhc
                            1, # modification for c9_tkr
                            1) # modification for c9_cons

TKR_cust <- as.data.frame(matrix(c("c9_age", coefficent_mod_values$Mod_value[which(coefficent_mod_values$Variable_label == "c9_age")],
                                   "c9_age2", coefficent_mod_values$Mod_value[which(coefficent_mod_values$Variable_label == "c9_age2")],
                                   "c9_drugoa", coefficent_mod_values$Mod_value[which(coefficent_mod_values$Variable_label == "c9_drugoa")],
                                   "c9_ccount", coefficent_mod_values$Mod_value[which(coefficent_mod_values$Variable_label == "c9_ccount")],
                                   "c9_mhc", coefficent_mod_values$Mod_value[which(coefficent_mod_values$Variable_label == "c9_mhc")],
                                   "c9_tkr", coefficent_mod_values$Mod_value[which(coefficent_mod_values$Variable_label == "c9_tkr")],
                                   "c9_cons", coefficent_mod_values$Mod_value[which(coefficent_mod_values$Variable_label == "c9_cons")]),
                                 ncol = 2, byrow = TRUE))


names(TKR_cust) <- c("covariate_set", "proportion_reduction")

eq_cust[["TKR"]] <- TKR_cust

