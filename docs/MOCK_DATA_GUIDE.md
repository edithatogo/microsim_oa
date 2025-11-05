# Mock Data in AUS-OA Package

## Overview

The AUS-OA package contains mock data in test files, but the main library functions are designed to load data from external files. This document explains the purpose and usage of mock data in the package.

## Mock Data Locations

### Test Files
Mock data is primarily found in the `tests/testthat/` directory and serves the following purposes:

1. **Unit Testing**: Small, controlled datasets to test individual functions
2. **Function Validation**: Ensure functions produce expected outputs
3. **Edge Case Testing**: Test functions with specific input scenarios

### Examples of Mock Data Usage

#### Cost Calculation Testing (`test-calculate_costs_fcn.R`)
```r
# Mock patient data for testing cost calculations
am_new <- data.table(
  tka = c(1, 0, 1, 0, 1),        # TKA status
  revi = c(0, 0, 1, 0, 0),       # Revision status
  oa = c(1, 1, 1, 0, 1),         # OA diagnosis
  dead = c(0, 0, 0, 0, 0),       # Mortality status
  ir = c(1, 0, 1, 0, 0),         # Inpatient rehab
  comp = c(0, 0, 0, 0, 1),       # Complications
  comorbidity_cost = c(10, 20, 30, 40, 50),
  intervention_cost = c(0, 0, 0, 0, 0)
)
```

#### Configuration Testing
```r
# Mock cost configuration for testing
costs_config <- list(
  costs = list(
    tka_primary = list(
      hospital_stay = list(value = 18000, perspective = "healthcare_system"),
      patient_gap = list(value = 2000, perspective = "patient")
    ),
    # ... additional cost parameters
  )
)
```

## Main Library Data Loading

The main AUS-OA functions are designed to load data from external files:

### Configuration Files
- **Location**: `inst/config/` directory
- **Format**: YAML files
- **Purpose**: Model parameters, cost estimates, intervention effects
- **Loading**: `load_config()` function

### Population Data
- **Location**: External data files (RDS, CSV, etc.)
- **Format**: Data.table/data.frame with required columns
- **Purpose**: Initial population characteristics
- **Loading**: `readRDS()`, `read.csv()`, or custom functions

### Example Data Loading
```r
# Load configuration
config <- load_config()

# Load population data
population <- readRDS("path/to/population_data.rds")

# Load external datasets
external_data <- read.csv("path/to/external_dataset.csv")
```

## Data Integration

### Required Data Structure
For integration with AUS-OA, datasets should include:

#### Core Demographic Variables
- `id`: Unique patient identifier
- `age`: Age in years
- `sex`: Gender (Male/Female)
- `bmi`: Body mass index

#### Clinical Variables
- `oa`: OA diagnosis (0/1)
- `kl_grade`: Kellgren-Lawrence grade (0-4)
- `pain`: Pain score (0-10)
- `function_score`: Functional assessment (0-100)

#### Treatment Variables
- `tka`: Total knee arthroplasty status (0/1)
- `revi`: Revision surgery status (0/1)
- `comp`: Complication status (0/1)

#### Economic Variables
- `qaly`: Quality-adjusted life years
- `healthcare_cost`: Healthcare costs
- `productivity_loss`: Productivity costs

## Best Practices

### For Package Users
1. **Use External Data**: Load real population data for production use
2. **Validate Data Structure**: Ensure data matches required format
3. **Test with Mock Data**: Use test files to understand expected data structure
4. **Document Data Sources**: Keep track of data origins and versions

### For Package Developers
1. **Minimal Mock Data**: Use smallest possible datasets for testing
2. **Realistic Values**: Ensure mock data represents realistic scenarios
3. **Comprehensive Coverage**: Test edge cases and common scenarios
4. **Documentation**: Document mock data purpose and structure

## Data Sources

For real data integration, see the companion document:
- `docs/PUBLIC_OA_DATASETS.md`: Comprehensive guide to public OA datasets

## Contact

For questions about data integration:
- **Maintainer**: Dylan Mordaunt <dylan.mordaunt@vuw.ac.nz>
- **Repository**: https://github.com/edithatogo/microsim_oa

---

*Last updated: September 10, 2025*
