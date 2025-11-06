# AUS-OA: Osteoarthritis Health Economics Microsimulation Model

> **⚠️ FORK NOTICE**: This repository is a fork of the original [AUS-OA project](https://github.com/UnimelbHealthEconomics/AUS_OA_public). This enhanced version includes significant improvements focused on osteoarthritis health economics modeling. For the original upstream repository, please visit: [https://github.com/UnimelbHealthEconomics/AUS_OA_public](https://github.com/UnimelbHealthEconomics/AUS_OA_public)

AUS-OA is a dynamic discrete-time microsimulation model specifically designed for osteoarthritis (OA) health economics and policy evaluation in Australia. It provides policymakers and researchers with advanced capacity to evaluate the clinical, economic, and quality-of-life impacts of OA interventions across Australia.

<!-- CI/CD badges -->
<!-- Badges -->
[![R-CMD-check](https://github.com/edithatogo/microsim_oa/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/edithatogo/microsim_oa/actions/workflows/R-CMD-check.yaml)
[![pkgdown](https://github.com/edithatogo/microsim_oa/actions/workflows/pkgdown.yaml/badge.svg)](https://github.com/edithatogo/microsim_oa/actions/workflows/pkgdown.yaml)
[![Test Coverage](https://codecov.io/gh/edithatogo/microsim_oa/branch/main/graph/badge.svg)](https://codecov.io/gh/edithatogo/microsim_oa)
[![CodeFactor](https://www.codefactor.io/repository/github/edithatogo/microsim_oa/badge)](https://www.codefactor.io/repository/github/edithatogo/microsim_oa)
[![License: GPL v3](https://img.shields.io/badge/License-GPLv3-blue.svg)](https://www.gnu.org/licenses/gpl-3.0)

**Documentation:** https://edithatogo.github.io/microsim_oa/

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
| **Core OA Simulation Engine**                |        âœ        |       âœ        |
| - OA Progression Modeling                    |        âœ        |       âœ        |
| - TKA & Revision Surgery Modelling           |        âœ        |       âœ        |
| - Basic Attribute Tracking (Age, Sex, BMI)   |        âœ        |       âœ        |
| **OA-Specific Complications**                |        âŒ        |       âœ        |
| - PJI (Periprosthetic Joint Infection)        |        âŒ        |       âœ        |
| - DVT (Deep Vein Thrombosis)                 |        âŒ        |       âœ        |
| - TKA Revision Risk Modeling                 |        âŒ        |       âœ        |
| **OA Health Economics**                      |                  |                 |
| - OA-Specific Cost-Effectiveness Analysis    |        âŒ        |       âœ        |
| - Australian Healthcare System Modeling      |        âŒ        |       âœ        |
| - QALY Calculation (SF-6D) for OA            |        âŒ        |       âœ        |
| **OA Data Integration**                      |        âŒ        |       âœ        |
| - AIHW OA Prevalence Data                    |        âŒ        |       âœ        |
| - OAI Longitudinal OA Data                   |        âŒ        |       âœ        |
| - ABS Demographic Data for OA Epidemiology   |        âŒ        |       âœ        |
| **OA Policy Analysis**                       |        âŒ        |       âœ        |
| - Public vs Private OA Treatment Pathways    |        âŒ        |       âœ        |
| - OA Surgery Waiting List Dynamics           |        âŒ        |       âœ        |
| - OA Intervention Policy Levers              |        âŒ        |       âœ        |

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
| - 
env for Reproducible Environments       |        âŒ        |       âœ        |
| **Performance**                              |                  |                 |
| - Parallel Processing                        |        âŒ        |       âœ        |
| **Documentation & Research Support**         |                  |                 |
| - Comprehensive Dataset Documentation        |        âŒ        |       âœ        |
### OA-Focused Tutorials & Educational Content
| - **Tutorial 1**: OA Population Health Modeling |        âŒ        |       âœ        |
| - **Tutorial 2**: OA Healthcare Utilization Analysis |        âŒ        |       âœ        |
| - **Tutorial 3**: OA Disease Progression Modeling |        âŒ        |       âœ        |
| - **Tutorial 4**: Geographic OA Health Disparities |        âŒ        |       âœ        |
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

2.  **Install dependencies:** This project uses 
env to manage dependencies. Open the AUS-OA.Rproj file in RStudio, and 
env should automatically start installing the required packages. If not, run the following command in the R console:
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

-   **Dependency Management:** 
env is used to ensure a reproducible environment.
-   **Testing:** 	estthat is used for unit testing. You can run the tests using the 
un_tests.R script in the scripts/ directory.
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

## Educational Tutorials

This enhanced fork includes a comprehensive tutorial series demonstrating AUS-OA capabilities:

### Tutorial 1: Basic Population Health Modeling
- **Location**: `tutorials/tutorial_01_basic_modeling/`
- **Focus**: Data exploration, statistical analysis, basic modeling
- **Data**: Synthetic Australian health survey data
- **Skills**: R programming, data visualization, logistic regression

### Tutorial 2: Healthcare Utilization Analysis
- **Location**: `tutorials/tutorial_02_healthcare_utilization/`
- **Focus**: Healthcare costs, utilization patterns, cost-effectiveness
- **Data**: Synthetic Medicare and hospital utilization data
- **Skills**: Cost analysis, disparity assessment, CEA methods

### Upcoming Tutorials
- **Tutorial 3**: Longitudinal Disease Progression Modeling
- **Tutorial 4**: Geographic Health Disparities Analysis

Each tutorial includes:
- Complete exercise materials
- R scripts for data generation and analysis
- Comprehensive solutions
- Data visualization examples
- Policy implications and recommendations

### Getting Started with Tutorials

```bash
# Navigate to tutorial directory
cd tutorials/tutorial_01_basic_modeling/

# Run the analysis script
Rscript scripts/tutorial_01_analysis.R

# Or work through exercises interactively
# Open tutorial_exercises.Rmd in RStudio
```

## Citation

If you use this model in your research, please cite it as follows:

`
AUS-OA Team (2025). A Microsimulation Model of Osteoarthritis in Australia (Version 2.0.0) [Computer software]. https://github.com/edithatogo/microsim_oa
`

For more details and source references, see docs/CITATIONS.md.

## License

This project is licensed under the GPL-3.0 License. See the LICENSE file for details.
