# AUS-OA Package: Getting Started Guide

## Overview

The AUS-OA package is a sophisticated microsimulation model for osteoarthritis (OA) health economics and policy evaluation in Australia. This guide walks you through the basics of using the package.

## Installation

First, install the package:

```r
# Install from GitHub
if (!require("remotes")) install.packages("remotes")
remotes::install_github("edithatogo/microsim_oa")

# Load the package
library(ausoa)
```

## Basic Usage

### Loading Configuration

The package uses YAML configuration files to specify simulation parameters:

```r
# Load default configuration
config <- load_config()

# Or load a specific configuration file
config <- load_config("path/to/your/config.yaml")
```

### Core Functions

The main exported functions include:

- `calculate_costs_fcn()`: Calculate healthcare costs for individuals
- `calculate_qaly()`: Calculate Quality-Adjusted Life Years
- `apply_interventions()`: Apply policy interventions to the population
- `load_config()`: Load configuration parameters
- `apply_coefficient_customisations()`: Apply custom coefficients
- `apply_policy_levers()`: Apply policy changes
- `OA_update()`: Update OA progression status
- `TKA_update_fcn()`: Update Total Knee Arthroplasty status

### Example Analysis

Here's a simple example of using the package:

```r
# Create a small test dataset
test_data <- data.frame(
  id = 1:100,
  age = sample(50:85, 100, replace = TRUE),
  sex = sample(c(0, 1), 100, replace = TRUE),
  bmi = rnorm(100, mean = 28, sd = 5),
  kl_score = sample(0:4, 100, replace = TRUE)
)

# Calculate costs
cost_result <- calculate_costs_fcn(test_data, config)
head(cost_result)

# Apply an intervention
intervention_params <- list(
  enabled = TRUE,
  interventions = list(
    example_intervention = list(
      type = "bmi_modification",
      start_year = 2025,
      end_year = 2030,
      parameters = list(uptake_rate = 0.5, bmi_change = -2.0)
    )
  )
)

# This is just an example - actual parameters will depend on your analysis
```

## Quality Control Features

The package includes extensive quality control measures:

- Comprehensive test coverage with testthat
- Performance benchmarks using bench
- Code quality checks with lintr
- Memory optimization utilities
- Parallel processing capabilities

## Documentation

- Function documentation: Access with `?function_name` after loading the package
- Vignettes: Detailed usage examples in the `vignettes/` directory
- Online documentation: Available at https://edithatogo.github.io/microsim_oa/

## Next Steps

For more advanced usage, check out the vignettes:

```r
# List all available vignettes
vignette(package = "ausoa")

# View a specific vignette
vignette("getting_started", package = "ausoa")
```

## Support

For support, please visit the GitHub repository:
https://github.com/edithatogo/microsim_oa

## Citation

If you use this package in your research, please cite it appropriately:

```
AUS-OA Team (2025). AUS-OA: A Microsimulation Model of Osteoarthritis in Australia (Version 2.2.1) [R package]. https://github.com/edithatogo/microsim_oa
```

This tutorial provides a basic introduction to the AUS-OA package. For advanced features and complete documentation, please refer to the other vignettes and the package documentation.