# A Microsimulation Model of Osteoarthritis in Australia (AUS-OA)

AUS-OA is a dynamic discrete-time microsimulation model of osteoarthritis and its treatment in Australia. It aims to provide policymakers and researchers with an enhanced capacity to evaluate the burden and treatment of osteoarthritis across Australia.

<!-- CI/CD badges -->
[![R-CMD-check](https://github.com/edithatogo/microsim_oa/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/edithatogo/microsim_oa/actions/workflows/R-CMD-check.yaml)
[![pkgdown](https://github.com/edithatogo/microsim_oa/actions/workflows/pkgdown.yaml/badge.svg)](https://github.com/edithatogo/microsim_oa/actions/workflows/pkgdown.yaml)

## Features

This project has evolved significantly from its original version. Here's a summary of its current features:

### Functional Features

| Feature                                      | Original Version | Current Version |
| -------------------------------------------- | :--------------: | :-------------: |
| **Core Simulation Engine**                   |        ✅        |       ✅        |
| - Osteoarthritis Progression                 |        ✅        |       ✅        |
| - TKA & Revision Surgery Modelling           |        ✅        |       ✅        |
| - Basic Attribute Tracking (Age, Sex, BMI)   |        ✅        |       ✅        |
| **Advanced Modelling**                       |                  |                 |
| - Intervention Modelling Framework           |        ❌        |       ✅        |
| - Policy Lever Analysis                      |        ❌        |       ✅        |
| - Comorbidity Modelling                      |        ❌        |       ✅        |
| **Health Economics**                         |                  |                 |
| - Comprehensive Cost-Effectiveness Analysis  |        ❌        |       ✅        |
| - Multi-perspective Costing                  |        ❌        |       ✅        |
| - QALY Calculation (SF-6D)                   |        ❌        |       ✅        |
| **PROMs Integration**                        |        ❌        |       ✅        |

### Technical Features

| Feature                                      | Original Version | Current Version |
| -------------------------------------------- | :--------------: | :-------------: |
| **Codebase & Architecture**                  |                  |                 |
| - Modular, Function-oriented Structure       |        ❌        |       ✅        |
| - External Configuration (YAML)              |        ❌        |       ✅        |
| **Testing & Validation**                     |                  |                 |
| - Unit Testing Framework (`testthat`)        |        ❌        |       ✅        |
| - Automated Validation & Reporting (RMarkdown)|        ❌        |       ✅        |
| **Dependency Management**                    |                  |                 |
| - `renv` for Reproducible Environments       |        ❌        |       ✅        |
| **Performance**                              |                  |                 |
| - Parallel Processing                        |        ❌        |       ✅        |

## Getting Started

### Prerequisites

-   R (version 4.0.0 or higher)
-   RStudio (recommended)

### Installation and Setup

1.  **Clone the repository:**
    ```bash
    git clone https://github.com/edithatogo/microsim_oa.git
    cd microsim_oa
    ```

2.  **Install dependencies:** This project uses `renv` to manage dependencies. Open the `AUS-OA.Rproj` file in RStudio, and `renv` should automatically start installing the required packages. If not, run the following command in the R console:
    ```r
    renv::restore()
    ```

### Running a Simulation

1.  **Create a scenario:** Navigate to `input/scenarios/` and copy an existing scenario file (e.g., `ausoa_input_public.xlsx`). Rename it to something descriptive (e.g., `my_scenario.xlsx`).
2.  **Customize the scenario:** Open your new scenario file and modify the parameters as needed.
3.  **Run the master script:** Open and run the `scripts/00_AUS_OA_Master.R` script in R. You will be prompted to select your scenario file.

The simulation will run, and the outputs will be saved in the `output/` directory.

## Project Structure

-   `R/`: Contains the core functions of the simulation model.
-   `scripts/`: Contains scripts for running the simulation, preprocessing data, and analyzing results.
-   `input/`: Contains input data for the model, including population data and simulation scenarios.
-   `output/`: Contains the outputs from the simulation, including logs, model statistics, and figures.
-   `config/`: Contains configuration files for the model, such as coefficients and intervention parameters.
-   `man/`: Contains documentation for the functions in the `R/` directory.
-   `tests/`: Contains unit tests for the model, using the `testthat` framework.
-   `supporting_data/`: Contains data used for model validation.

## Development

This project uses a structured development approach:

-   **Dependency Management:** `renv` is used to ensure a reproducible environment.
-   **Testing:** `testthat` is used for unit testing. You can run the tests using the `run_tests.R` script in the `scripts/` directory.
-   **Style:** A consistent code style is encouraged.

## Citation

If you use this model in your research, please cite it as follows:

```
AUS-OA Team (2025). A Microsimulation Model of Osteoarthritis in Australia (Version 2.0.0) [Computer software]. https://github.com/edithatogo/microsim_oa
```

For more details and source references, see `docs/CITATIONS.md`.

## License

This project is licensed under the GPL-3.0 License. See the `LICENSE` file for details.
