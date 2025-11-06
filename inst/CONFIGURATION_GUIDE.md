# Configuration Management for AUS-OA

## Overview

AUS-OA provides a comprehensive configuration management system that allows for flexible parameterization of simulation models. The system uses YAML files for external configuration and provides validation, merging, and management utilities.

## Key Features

1. **External Configuration**: All key parameters are stored in YAML files
2. **Parameter Validation**: Automatic validation of configuration values
3. **Environment-Specific Overrides**: Different configurations for dev/test/prod
4. **Template System**: Reusable configuration templates
5. **Schema Validation**: Ensures configuration file structure

## Configuration Structure

The main configuration file (`config/default_config.yaml`) follows this structure:

```yaml
# Simulation parameters
simulation:
  time_horizon: 20
  start_year: 2025
  population_size: 10000
  random_seed: 12345
  verbose: true

# Cost parameters
costs:
  tka_primary:
    hospital_stay:
      value: 15000
      perspective: "healthcare_system"
    patient_gap:
      value: 2000
      perspective: "patient"
  tka_revision:
    hospital_stay:
      value: 20000
      perspective: "healthcare_system"
    patient_gap:
      value: 2500
      perspective: "patient"

# Utility parameters  
utilities:
  kl0: 0.85
  kl1: 0.80
  kl2: 0.72
  kl3: 0.65
  kl4: 0.55
  post_tka: 0.78
  dead: 0.0

# Risk parameters
risks:
  tka_annual: 0.02
  revision_annual: 0.03
  dvt_prob: 0.05
  pji_prob: 0.01

# Pathway parameters
pathways:
  public_wait_time: 18  # months
  private_wait_time: 0.5  # months
  referral_threshold: 0.7

# Intervention parameters
interventions:
  default_uptake_rate: 0.5
  effectiveness_multiplier: 1.0
```

## Loading Configuration

Configuration files are loaded using the `load_config()` function:

```r
# Load default configuration
config <- load_config()

# Load custom configuration
custom_config <- load_config("path/to/custom_config.yaml")

# Load configuration with environment-specific overrides
prod_config <- load_config(config_path = "config/prod_config.yaml")
```

## Validating Configuration

All configuration files are automatically validated during loading:

```r
# Validate returns a list with errors if any are found
validation_result <- validate_config(config)

if (length(validation_result$errors) > 0) {
  stop("Configuration validation failed: ", 
       paste(validation_result$errors, collapse = "; "))
}
```

## Dynamic Configuration

You can create and modify configuration programmatically:

```r
# Create configuration from parameters
dynamic_config <- create_config_from_params(
  time_horizon = 30,
  population_size = 5000,
  start_year = 2026,
  tka_cost = 18000
)

# Update specific sections
updated_config <- update_config_section(
  config = dynamic_config,
  section_name = "simulation",
  new_values = list(
    time_horizon = 25,
    verbose = FALSE
  )
)
```

## Environment-Specific Parameters

You can set environment-specific parameters by using environment variables:

```r
# Set parameters based on environment
if (Sys.getenv("AUSOA_ENVIRONMENT") == "production") {
  config$simulation$population_size <- 50000
  config$simulation$verbose <- FALSE
} else {
  config$simulation$population_size <- 1000  # Smaller for testing
  config$simulation$verbose <- TRUE
}
```

## Best Practices

1. **Use External Files**: Keep configurations in YAML files, not code
2. **Validate Inputs**: Always validate configuration values
3. **Document Options**: Include comments in configuration files
4. **Provide Defaults**: Always have sensible default values
5. **Use Templates**: Create configuration templates for common scenarios

## Troubleshooting

Common configuration issues:

- Missing required fields
- Invalid data types
- Out-of-range values
- Incorrect file paths

Check the configuration validation messages for specific error details.