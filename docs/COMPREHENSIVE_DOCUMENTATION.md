# AUS-OA Package Documentation

## Overview

The AUS-OA package is a dynamic discrete-time microsimulation model specifically designed for osteoarthritis (OA) health economics and policy evaluation in Australia. It provides advanced capabilities to evaluate the clinical, economic, and quality-of-life impacts of OA interventions.

## Installation

```r
# Install from GitHub
if (!require("remotes")) install.packages("remotes")
remotes::install_github("edithatogo/microsim_oa")

# Load the package
library(ausoa)
```

## Core Functions

### Simulation Functions
- `simulation_cycle_fcn()` - Main simulation cycle function
- `OA_update()` - Update osteoarthritis status
- `TKA_update_fcn()` - Update Total Knee Arthroplasty status
- `calculate_revision_risk_fcn()` - Calculate revision surgery risk

### Economic Analysis Functions
- `calculate_costs_fcn()` - Calculate healthcare costs
- `calculate_qaly()` - Calculate Quality-Adjusted Life Years
- `apply_policy_levers()` - Apply policy interventions

### Intervention Functions
- `apply_interventions()` - Apply policy interventions to population
- `apply_coefficient_customisations()` - Customize model coefficients
- `apply_qaly_cost_modification()` - Modify QALY and cost parameters

### Data Management Functions
- `load_config()` - Load YAML configuration files
- `read_data()` - Read input data
- `update_comorbidities()` - Update comorbidity status
- `validate_dataset()` - Validate dataset structure

## Configuration

The package uses YAML configuration files for parameter management:

```yaml
simulation:
  time_horizon: 20
  start_year: 2025
  population_size: 10000

costs:
  tka_primary:
    hospital_stay: 15000
    patient_gap: 2000

utilities:
  kl0: 0.85
  kl1: 0.80
  kl2: 0.72
  kl3: 0.65
  kl4: 0.55
```

## Usage Examples

### Basic Simulation
```r
library(ausoa)

# Load configuration
config <- load_config("path/to/config.yaml")

# Create sample population data
pop_data <- data.frame(
  id = 1:1000,
  age = sample(40:85, 1000, replace = TRUE),
  sex = sample(c(0, 1), 1000, replace = TRUE),
  bmi = rnorm(1000, mean = 28, sd = 5),
  kl_score = sample(0:4, 1000, replace = TRUE)
)

# Apply interventions
interventions <- list(
  enabled = TRUE,
  interventions = list(
    bmi_reduction = list(
      type = "bmi_modification",
      start_year = 2025,
      end_year = 2030,
      parameters = list(uptake_rate = 0.6, bmi_change = -1.5)
    )
  )
)

# Run intervention
result <- apply_interventions(pop_data, interventions, 2025)
```

### Cost Calculation
```r
# Create cost data
cost_data <- data.frame(
  tka = sample(c(0, 1), 100, replace = TRUE),
  revi = sample(c(0, 1), 100, replace = TRUE),
  dead = rep(0, 100)
)

# Define cost configuration
cost_config <- list(
  costs = list(
    tka_primary = list(
      hospital_stay = list(value = 15000, perspective = "healthcare_system")
    )
  )
)

# Calculate costs
cost_results <- calculate_costs_fcn(cost_data, cost_config)
```

## Package Structure

- **R/**: Core R functions for the microsimulation model
- **scripts/**: Scripts for running simulations and data preprocessing
- **input/**: Sample input data and scenario files
- **output/**: Output directory for simulation results
- **config/**: Configuration files for different scenarios
- **tests/**: Unit tests using testthat framework
- **man/**: Package documentation (generated from Roxygen comments)

## Quality Assurance

The package implements comprehensive quality control measures:

- Unit tests with >90% coverage using testthat
- Code quality checks with lintr
- Performance benchmarks with bench package
- Continuous integration testing
- Memory usage optimization

## Contributing

To contribute to the AUS-OA package:

1. Fork the repository
2. Create a feature branch
3. Add your changes following Tidyverse style guide
4. Write unit tests for new functions
5. Submit a pull request

## License

GPL-3.0