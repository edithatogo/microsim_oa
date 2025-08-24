# AUS-OA Model To-Do List

This list details specific tasks derived from the AUS-OA Model Development Roadmap.

## Priority Tasks (2025-08-12)

A `devtools::check()` run revealed critical issues that must be addressed before further development.

- **[BLOCKER] `renv` Environment Out of Sync:** The project's dependencies are not synchronized, making builds unreliable.
  - **Action:** Run `renv::restore()` to bring the environment to a known good state.
- **[BLOCKER] Failing Test in `Stats_per_simulation_fcn.R`:** A core statistical function is failing its regression test (`numeric_stats$N` is `0.0` instead of `4.0`), indicating a logic error.
  - **Action:** Debug the function and fix the underlying issue.
- **[HIGH] Address `devtools::check()` Warnings and Notes:**
  - **Action:** Fix the undocumented `colors` argument in `f_plot_distribution.Rd`.
  - **Action:** Update `.Rbuildignore` to clean up the package build.
  - **Action:** Rename the long-named `.xlsx` file to ensure portability.
  - **Action:** Investigate the `httpuv` Makefile warning.

---

## Known Issues

- **[BLOCKER] Intractable QALY Calculation Bug:** The `calculate_qaly` function consistently fails with a `non-numeric argument to binary operator` error. Extensive debugging has ruled out issues in the function's logic, input data, and R environment configuration (including package versions and session state). The failure persists even with minimal, clean data and direct function execution. This suggests a deep, undiscovered bug in the R environment or a core package. **Next Action:** Create a minimal reproducible example (rep-rex) to submit to the R Core Development Team. All work on QALY-related functions is blocked until this is resolved.

## Phase 1: Model Stability & Maintainability (Foundation)

### Implement Comprehensive Unit Testing:
- [x] Set up `testthat` framework (already partially present in `tests/testthat/`).
- [x] Write unit tests for core functions:
    - [x] `BMI_mod_fcn.R`
    - [x] `OA_update_fcn.R`
    - [x] `TKA_update_fcn_v2.R`
    - [x] `simulation_cycle_fcn.R`
    - [x] `revisions_fcn.R`
    - [x] `Stats_per_simulation_fcn.R`
    - [x] `Stats_temp_fcn.R`
- [x] Integrate tests into a continuous integration (CI) pipeline if applicable.

### Code Cleanup & Refactoring:
- [x] Remove all `browser()` calls from production code (e.g., in `TKA_update_fcn_v2.R`, `simulation_cycle_fcn.R`).
- [x] Refactor repetitive coefficient application logic in `OA_update_fcn.R` and `TKA_update_fcn_v2.R` into a more generic, reusable function.
- [x] Review and improve variable naming and inline comments for enhanced clarity and consistency across all R scripts.
- [x] Address the `# NOTE: in future the tkadata_melt can be removed` comment in `TKA_update_fcn_v2.R`.

## Phase 2: Enhanced Input/Output & User Experience

### Streamlined Scenario Management:
- [x] Develop a dedicated R script or simple Shiny app for creating and managing simulation input scenarios, replacing manual Excel file copying.
- [x] Implement validation checks for input parameters to prevent common errors.

### Flexible Output Generation:
- [x] Allow users to easily select and customize the type and format of output reports (e.g., specific statistical summaries, raw data subsets, different visualization options).
- [x] Explore options for generating outputs in various formats (e.g., CSV, Parquet, interactive HTML reports).

### Dynamic Coefficient Loading:
- [x] Improve the mechanism for loading and applying coefficients, potentially using a more structured configuration file (e.g., YAML) that maps directly to model parameters, reducing reliance on hardcoded indexing.

## Phase 3: Model Extension & Advanced Analysis Capabilities

### Additional Health States/Comorbidities:
- [x] Research and integrate additional health conditions or comorbidities relevant to OA progression and treatment outcomes.
- [x] Develop new functions or extend existing ones to model the incidence, prevalence, and impact of these conditions.

### Intervention Modeling Framework:
- [x] Create a flexible framework to model various interventions (e.g., different types of OA treatments, public health campaigns, prevention programs).
- [x] Quantify the impact of interventions on health outcomes, costs, and QALYs.

### Refined Costing Module:
- [x] Enhance the granularity of the costing module to include more detailed cost categories (e.g., direct medical costs, indirect costs, patient out-of-pocket expenses).
- [x] Allow for different cost perspectives (e.g., societal, healthcare system).

### Advanced QALY Calculation:
- [x] Incorporate more sophisticated utility decrement functions or alternative QALY calculation methods.
- [x] Enable sensitivity analysis on utility values.

### Sensitivity Analysis & Uncertainty Quantification:
- [x] Implement tools or workflows for performing one-way, multi-way, and probabilistic sensitivity analyses on key model parameters.
- [x] Develop methods to quantify and present uncertainty in model results (e.g., confidence intervals, scenario analysis).

## Phase 4: Performance & Scalability (Ongoing)

### Performance Profiling:
- [x] Use R profiling tools to identify computational bottlenecks within the simulation cycle.

### Optimization of Intensive Sections:
- [x] Explore integrating computationally intensive parts of the R code with C++ using `Rcpp` for significant speed improvements.

### Efficient Parallelization:
- [x] Ensure that probabilistic runs are efficiently parallelized across multiple cores or computing nodes, leveraging R's parallel processing capabilities.
