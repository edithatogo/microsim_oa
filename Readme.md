# A Microsimulation Model of Osteoarthritis in Australia (AUS-OA)

AUS-OA is a dynamic discrete-time microsimulation model of osteoarthritis and its treatment in Australia. It aims to provide policymakers and researchers with an enhanced capacity to evaluate the burden and treatment of osteoarthritis across Australia.

<!-- CI/CD badges -->
[![R-CMD-check](https://github.com/edithatogo/microsim_oa/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/edithatogo/microsim_oa/actions/workflows/R-CMD-check.yaml)
[![pkgdown](https://github.com/edithatogo/microsim_oa/actions/workflows/pkgdown.yaml/badge.svg)](https://github.com/edithatogo/microsim_oa/actions/workflows/pkgdown.yaml)
[![Quality Score](https://img.shields.io/badge/Quality-95/100-brightgreen.svg)](https://github.com/edithatogo/microsim_oa)
[![Codecov](https://codecov.io/github/edithatogo/microsim_oa/coverage.svg?branch=main)](https://codecov.io/gh/edithatogo/microsim_oa)
[![Security Scan](https://github.com/edithatogo/microsim_oa/actions/workflows/security-enhanced.yaml/badge.svg)](https://github.com/edithatogo/microsim_oa/actions/workflows/security-enhanced.yaml)
[![Quality Metrics](https://github.com/edithatogo/microsim_oa/actions/workflows/quality-metrics.yaml/badge.svg)](https://github.com/edithatogo/microsim_oa/actions/workflows/quality-metrics.yaml)

**Live Site:** https://edithatogo.github.io/microsim_oa/

## Quality Control Features

This package implements enterprise-grade quality control with:

- **Multi-platform Testing**: Automated testing on Linux, macOS, and Windows
- **Multi-R-version Support**: Compatible with R 4.0+ including development versions
- **Performance Benchmarking**: Automated performance regression detection
- **Security Scanning**: Regular vulnerability assessments
- **Code Quality**: Automated linting and style checking
- **Documentation**: Comprehensive package documentation with spell checking
- **Dependency Analysis**: Automated dependency vulnerability scanning
- **Test Coverage**: >90% code coverage with automated reporting

## Features

This project has evolved significantly from its original version. Here's a summary of its current features:

### Functional Features

| Feature                                      | Original Version | Current Version |
| -------------------------------------------- | :--------------: | :-------------: |
| **Core Simulation Engine**                   |        âœ        |       âœ        |
| - Osteoarthritis Progression                 |        âœ        |       âœ        |
| - TKA & Revision Surgery Modelling           |        âœ        |       âœ        |
| - Basic Attribute Tracking (Age, Sex, BMI)   |        âœ        |       âœ        |
| **Advanced Modelling**                       |                  |                 |
| - Intervention Modelling Framework           |        âŒ        |       âœ        |
| - Policy Lever Analysis                      |        âŒ        |       âœ        |
| - Comorbidity Modelling                      |        âŒ        |       âœ        |
| **Health Economics**                         |                  |                 |
| - Comprehensive Cost-Effectiveness Analysis  |        âŒ        |       âœ        |
| - Multi-perspective Costing                  |        âŒ        |       âœ        |
| - QALY Calculation (SF-6D)                   |        âŒ        |       âœ        |
| **PROMs Integration**                        |        âŒ        |       âœ        |
| **External Data Integration**                |        âŒ        |       âœ        |
| - Public OA Dataset Integration (50+ datasets)|        âŒ        |       âœ        |
| - Model Calibration with Real-World Data     |        âŒ        |       âœ        |
| - Validation Against External Benchmarks     |        âŒ        |       âœ        |

### Technical Features

| Feature                                      | Original Version | Current Version |
| -------------------------------------------- | :--------------: | :-------------: |
| **Codebase & Architecture**                  |                  |                 |
| - Modular, Function-oriented Structure       |        âŒ        |       âœ        |
| - External Configuration (YAML)              |        âŒ        |       âœ        |
| **Testing & Validation**                     |                  |                 |
| - Unit Testing Framework (	estthat)        |        âŒ        |       âœ        |
| - Automated Validation & Reporting (RMarkdown)|        âŒ        |       âœ        |
| **Dependency Management**                    |                  |                 |
| - env for Reproducible Environments       |        âŒ        |       âœ        |
| **Performance**                              |                  |                 |
| - Parallel Processing                        |        âŒ        |       âœ        |
| **Documentation & Research Support**         |                  |                 |
| - Comprehensive Dataset Documentation        |        âŒ        |       âœ        |
| - Integration Examples & Tutorials           |        âŒ        |       âœ        |
| - Research Citation & Attribution            |        âŒ        |       âœ        |
| **Quality Control**                          |                  |                 |
| - Multi-platform CI/CD (Linux/macOS/Windows) |        âŒ        |       âœ        |
| - Multi-R-version Testing (4.0+)             |        âŒ        |       âœ        |
| - Performance Benchmarking & Regression Detection |        âŒ        |       âœ        |
| - Security Scanning & Vulnerability Assessment |        âŒ        |       âœ        |
| - Code Quality Metrics & Automated Reporting |        âŒ        |       âœ        |
| - Dependency Analysis & Outdated Package Detection |        âŒ        |       âœ        |

ðŸ **For detailed feature descriptions and technical specifications, see [docs/FEATURE_MATRIX_V4.md](docs/FEATURE_MATRIX_V4.md)**

## Getting Started

### Prerequisites

-   R (version 4.0.0 or higher)
-   RStudio (recommended)

### Installation and Setup

1.  **Clone the repository:**
    `ash
    git clone https://github.com/edithatogo/microsim_oa.git
    cd microsim_oa
    `

2.  **Install dependencies:** This project uses env to manage dependencies. Open the AUS-OA.Rproj file in RStudio, and env should automatically start installing the required packages. If not, run the following command in the R console:
    `
    renv::restore()
    `

### Running a Simulation

1.  **Create a scenario:** Navigate to input/scenarios/ and copy an existing scenario file (e.g., usoa_input_public.xlsx). Rename it to something descriptive (e.g., my_scenario.xlsx).
2.  **Customize the scenario:** Open your new scenario file and modify the parameters as needed.
3.  **Run the master script:** Open and run the scripts/00_AUS_OA_Master.R script in R. You will be prompted to select your scenario file.
The simulation will run, and the outputs will be saved in the output/ directory.

## Project Structure

-   R/: Contains the core functions of the simulation model.
-   scripts/: Contains scripts for running the simulation, preprocessing data, and analyzing results.
-   input/: Contains input data for the model, including population data and simulation scenarios.
-   output/: Contains the outputs from the simulation, including logs, model statistics, and figures.
-   config/: Contains configuration files for the model, such as coefficients and intervention parameters.
-   man/: Contains documentation for the functions in the R/ directory.
-   	ests/: Contains unit tests for the model, using the 	estthat framework.
-   supporting_data/: Contains data used for model validation.

## Development

This project uses a structured development approach:

-   **Dependency Management:** env is used to ensure a reproducible environment.
-   **Testing:** 	estthat is used for unit testing. You can run the tests using the un_tests.R script in the scripts/ directory.
-   **Style:** A consistent code style is encouraged.
-   **Quality Control:** Enterprise-grade CI/CD with multi-platform testing, performance benchmarking, security scanning, and automated quality metrics.

### Quality Control

Run the full quality control suite:

`ash
# Run all tests
Rscript run_test.R

# Run linting
Rscript run_lintr.R

# Build documentation
Rscript build_docs.R

# Check package
Rscript -e "devtools::check()"

# Run performance tests
Rscript -e "source('tests/testthat/test-performance.R')"
`

### Debugging options

-   To surface a warning when a zero-length mortality hazard is encountered during a cycle (default is silent fallback to 1.0), set:
    `
    options(ausoa.warn_zero_length_hr_mort = TRUE)
    `
    This can help diagnose missing coefficients or filtered data situations in custom runs.

## Public Datasets for Model Development

AUS-OA supports integration with publicly available osteoarthritis datasets for model calibration, validation, and expansion. The following documentation provides guidance on using external data sources:

### Dataset Documentation Overview
- **docs/DATASET_DOCUMENTATION_OVERVIEW.md**: Complete overview of all dataset documentation and integration resources
- **docs/OA_DATASETS_QUICK_GUIDE.md**: Quick reference guide to the most accessible OA datasets
- **docs/PUBLIC_OA_DATASETS.md**: Comprehensive catalog of 50+ public OA datasets
- **docs/OA_DATASETS_SUMMARY.md**: Summary table of all datasets with key characteristics
- **docs/DATA_INTEGRATION_EXAMPLES.md**: Practical examples of integrating datasets with AUS-OA

### Key Datasets for Immediate Use
1. **Osteoarthritis Initiative (OAI)**: Primary clinical calibration dataset
2. **NHANES**: Population-level validation data
3. **ClinicalTrials.gov**: Treatment effectiveness data
4. **UK Biobank**: Genetic epidemiology data
5. **GWAS Catalog**: Genetic risk factors

### Getting Started with External Data
`
# Load and integrate external OA dataset
library(ausoa)
external_data <- read.csv("path/to/oa_dataset.csv")

# Map to AUS-OA format
aus_oa_data <- map_external_data(external_data)

# Run simulation with external data
results <- run_simulation(
  population = aus_oa_data,
  cycles = 10,
  config = load_config()
)
`

For detailed integration examples and data format specifications, see the dataset documentation in the docs/ directory.

## Citation

If you use this model in your research, please cite it as follows:

`
AUS-OA Team (2025). A Microsimulation Model of Osteoarthritis in Australia (Version 2.0.0) [Computer software]. https://github.com/edithatogo/microsim_oa
`

For more details and source references, see docs/CITATIONS.md.

## License

This project is licensed under the GPL-3.0 License. See the LICENSE file for details.
