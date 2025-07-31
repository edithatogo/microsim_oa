# AUS-OA Model Development Roadmap

This roadmap outlines key phases for enhancing the AUS-OA microsimulation model, focusing on stability, usability, and expanded analytical capabilities.

## Phase 1: Model Stability & Maintainability (Foundation)

**Objective:** Ensure the model is robust, testable, and easy to maintain for future development.

**Key Tasks:**

*   **Implement Comprehensive Unit Testing:**
    *   [x] Set up `testthat` framework (already partially present in `tests/testthat/`).
    *   [x] Write unit tests for core functions:
        *   [x] `BMI_mod_fcn.R`
        *   [x] `OA_update_fcn.R`
        *   [x] `TKA_update_fcn_v2.R`
        *   [x] `simulation_cycle_fcn.R`
        *   [x] `revisions_fcn.R`
        *   [x] `Stats_per_simulation_fcn.R`
        *   [x] `Stats_temp_fcn.R`
    *   [x] Integrate tests into a continuous integration (CI) pipeline if applicable.
*   **Code Cleanup & Refactoring:**
    *   [x] Remove all `browser()` calls from production code (e.g., in `TKA_update_fcn_v2.R`, `simulation_cycle_fcn.R`).
    *   [x] Refactor repetitive coefficient application logic in `OA_update_fcn.R` and `TKA_update_fcn_v2.R` into a more generic, reusable function.
    *   [x] Review and improve variable naming and inline comments for enhanced clarity and consistency across all R scripts.
    *   [x] Address the `# NOTE: in future the tkadata_melt can be removed` comment in `TKA_update_fcn_v2.R`.

## Phase 2: Enhanced Input/Output & User Experience

**Objective:** Improve the ease of use for setting up simulations and analyzing results, making the model more accessible.

**Key Tasks:**

*   **Streamlined Scenario Management:**
    *   [x] Develop a dedicated R script or simple Shiny app for creating and managing simulation input scenarios, replacing manual Excel file copying.
    *   [x] Implement validation checks for input parameters to prevent common errors.
*   **Flexible Output Generation:**
    *   [x] Allow users to easily select and customize the type and format of output reports (e.g., specific statistical summaries, raw data subsets, different visualization options).
    *   [x] Explore options for generating outputs in various formats (e.g., CSV, Parquet, interactive HTML reports).
*   **Dynamic Coefficient Loading:**
    *   [x] Improve the mechanism for loading and applying coefficients, potentially using a more structured configuration file (e.g., YAML) that maps directly to model parameters, reducing reliance on hardcoded indexing.

## Phase 3: Model Extension & Advanced Analysis Capabilities

**Objective:** Expand the model's scope to include more detailed health states, interventions, and advanced analytical features.

**Key Tasks:**

*   **Additional Health States/Comorbidities:**
    *   [x] Research and integrate additional health conditions or comorbidities relevant to OA progression and treatment outcomes.
    *   [x] Develop new functions or extend existing ones to model the incidence, prevalence, and impact of these conditions.
*   **Intervention Modeling Framework:**
    *   [x] Create a flexible framework to model various interventions (e.g., different types of OA treatments, public health campaigns, prevention programs).
    *   [x] Quantify the impact of interventions on health outcomes, costs, and QALYs.
*   **Refined Costing Module:**
    *   [x] Enhance the granularity of the costing module to include more detailed cost categories (e.g., direct medical costs, indirect costs, patient out-of-pocket expenses).
    *   [x] Allow for different cost perspectives (e.g., societal, healthcare system).
*   **Advanced QALY Calculation:**
    *   [x] Incorporate more sophisticated utility decrement functions or alternative QALY calculation methods.
    *   [x] Enable sensitivity analysis on utility values.
*   **Sensitivity Analysis & Uncertainty Quantification:**
    *   [x] Implement tools or workflows for performing one-way, multi-way, and probabilistic sensitivity analyses on key model parameters.
    *   [x] Develop methods to quantify and present uncertainty in model results (e.g., confidence intervals, scenario analysis).

## Phase 4: Performance & Scalability (Ongoing)

**Objective:** Optimize the model for larger populations and more complex simulations, ensuring efficient execution.

**Key Tasks:**

*   **Performance Profiling:**
    *   [x] Use R profiling tools to identify computational bottlenecks within the simulation cycle.
*   **Optimization of Intensive Sections:**
    *   [x] Explore integrating computationally intensive parts of the R code with C++ using `Rcpp` for significant speed improvements.
*   **Efficient Parallelization:**
    *   [x] Ensure that probabilistic runs are efficiently parallelized across multiple cores or computing nodes, leveraging R's parallel processing capabilities.