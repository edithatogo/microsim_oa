# setup equations for the simulations,
# options for point estimates or for probabilistic sampling from distribution

library(stringr)
library(reshape2)

# load coefficent data
pin <- read_excel(input_file,
  sheet = "Parameter inputs", range = "A6:K500"
) %>%
  filter(!is.na(Parameter))


pin <- pin[which(is.na(pin$Parameter) == FALSE), ]

# modify variable name
names(pin)[which(names(pin) == "Standard Error")] <- "standard_error"

# get equation families to allocate sample sizes
pin$equation_family <- NA

for (split_counter in 1:nrow(pin)) {
  pin$equation_family[split_counter] <- str_split_1(pin$Parameter[split_counter], "_")[1]
}

# load observed data on TKR rates in the population by age and gender
tkadata <- read_excel(input_file,
  sheet = "TKA utilisation", range = "A7:I48"
)

tkadata_melt <- melt(tkadata, id.vars = "Year")
# sample sizes

# C1-5 hr_BMI_mort and hr_SEP_mort based on the health survey data, from the appendix
# The study populations for deriving equations for annual weight (BMI) gain included data on 7508 persons aged between 20 and 59 from the 1995 National Nutrition Survey (NNS) and 9850 persons aged between 37 and 76 from the 2011/12 National Health survey who had full data on height, weight and education and were not pregnant.

# indivdual eqs for seperate populations, but impossible to separate so
# will use collective n for all equations to calculate SD

# n = 7508 + 9850 = 17358

# information from Chris on other equations
# C6 (Analysis of HILDA) 13,834
# C7 (Analysis of OAI) 1,925
# C8 (Analysis of OAI and literature - no age or BMI effects), 887
# C9 (Based on Sharm's work with HR by KL score addition) 201,462
# C15 (Specific analysis of SMART) 2,420
# C16 (Specific analysis of SMART) 2,420
# C17 (Specific analysis of SMART) 2,420

sample_sizes <- as.data.frame(matrix(c(
  "c1", 17358 / 5,
  "c2", 17358 / 5,
  "c3", 17358 / 5,
  "c4", 17358 / 5,
  "c5", 17358 / 5,
  "c6", 13834,
  "c7", 1925,
  "c8", 887,
  "c9", 201462,
  "c15", 2420,
  "c16", 2420,
  "c17", 2420,
  "hr", 17358
), ncol = 2, byrow = TRUE))

names(sample_sizes) <- c("family", "sample_size")
sample_sizes$sample_size <- as.numeric(sample_sizes$sample_size)


# setup a data frame to take the individulised coeffients
cycle.coefficents <- as.data.frame(matrix(NA, ncol = nrow(pin), nrow = nrow(am)))


if (probabilistic == TRUE) {
  print("Assigning coefficients probabilistic where distribution specified")
  # undertake random draw for each individual for each coefficent
  for (coeff_counter in 1:nrow(pin)) {
    
    names(cycle.coefficents)[coeff_counter] <- pin[coeff_counter, 1]

    if (is.na(pin[coeff_counter, "Distribution"]) == FALSE) {
      if (tolower(pin[coeff_counter, "Distribution"]) == "normal") {
        mean <- as.numeric(pin[coeff_counter, "Mean"])
        current_sample_size <- sample_sizes$sample_size[which(sample_sizes$family == pin$equation_family[coeff_counter])]

        standard_deviation <- pin$standard_error[coeff_counter] # abs(sqrt(current_sample_size) * pin$standard_error[coeff_counter]/3.92)

        cycle.coefficents[, coeff_counter] <- rnorm(
          nrow(cycle.coefficents),
          mean, standard_deviation
        )
      } else {
        cycle.coefficents[, coeff_counter] <- pin[coeff_counter, "Live"]
      }
    } else {
      cycle.coefficents[, coeff_counter] <- pin[coeff_counter, "Live"]
    }
  }
} else {
  print("Assigning coefficients based on point estimate (ie not probabilistic")

  for (coeff_counter in 1:nrow(pin)) {
    names(cycle.coefficents)[coeff_counter] <- pin[coeff_counter, 1]

    # print(names(cycle.coefficents)[coeff_counter])

    cycle.coefficents[, coeff_counter] <- pin[coeff_counter, "Live"]
  }
}
