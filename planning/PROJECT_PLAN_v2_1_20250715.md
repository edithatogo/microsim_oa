# AUS-OA Model v2 Project Plan

**File Version:** 1
**Date:** 2025-07-15

## 1. Project Vision

To re-develop the AUS-OA model into a robust, transparent, performant, and policy-relevant platform (V2) that meets the needs of diverse stakeholders and adheres to the highest standards of software engineering and health economic modeling.

## 2. Key Phases & High-Level Timeline

The project is divided into three main phases, with an estimated timeline.

| Phase | Title                                       | Estimated Duration |
| :---- | :------------------------------------------ | :----------------- |
| 1     | Architectural Relaunch & Foundational Cap. | 6 Weeks            |
| 2     | Expanding the Scope of Analysis             | 8 Weeks            |
| 3     | User Experience & Dissemination             | 6 Weeks            |

## 3. Gantt Chart

This Gantt chart provides a visual representation of the project timeline and dependencies.
(`*` = 1 Week)

| Task ID | Task Name                               | Week 1 | Week 2 | Week 3 | Week 4 | Week 5 | Week 6 | Week 7-14 | Week 15-20 |
| :------ | :-------------------------------------- | :----: | :----: | :----: | :----: | :----: | :----: | :-------: | :--------: |
| **P1.1**  | **SE Best Practices**                   |        |        |        |        |        |        |           |            |
| 1.1.1   | R Package & `renv` Setup                | `****` |        |        |        |        |        |           |            |
| 1.1.2   | CI/CD Pipeline (GitHub Actions)         |        | `****` |        |        |        |        |           |            |
| 1.1.3   | Dockerization                           |        |        | `****` |        |        |        |           |            |
| 1.1.4   | Agile Board Setup                       | `**`   |        |        |        |        |        |           |            |
| **P1.2**  | **Configuration**                       |        |        |        |        |        |        |           |            |
| 1.2.1   | Externalize Params to YAML              |        | `****` | `****` |        |        |        |           |            |
| **P1.3**  | **Performance**                         |        |        |        |        |        |        |           |            |
| 1.3.1   | Profiling & `data.table` Refactor       |        |        |        | `****` | `****` |        |           |            |
| 1.3.2   | Switch to Parquet I/O                   |        |        |        |        | `****` |        |           |            |
| **P1.4**  | **Module Expansion**                    |        |        |        |        |        |        |           |            |
| 1.4.1   | Costing & Pharmacy Modules              |        |        |        |        |        | `****` |           |            |
| 1.4.2   | Surgery & Revision Module               |        |        |        |        |        | `****` |           |            |
| **P2**    | **Phase 2: Analysis Expansion**         |        |        |        |        |        |        | `********`  |            |
| **P3**    | **Phase 3: UX & Dissemination**         |        |        |        |        |        |        |           | `******`   |


## 4. Phase 1 Detailed Plan (Weeks 1-6)

### Week 1: Project Setup & Structure
*   **Goal:** Establish a robust, professional software engineering foundation.
*   **Tasks:**
    *   [1.1.1] Convert the project into a formal R package.
    *   [1.1.1] Initialize `renv` and create the initial dependency lockfile.
    *   [1.1.4] Set up the GitHub Projects board and populate it with all issues from the TODO list.
*   **Deliverable:** A structured R package with all existing code refactored into the `R/` directory and a populated project board.

### Week 2: Automation & Configuration
*   **Goal:** Automate testing and begin decoupling parameters from code.
*   **Tasks:**
    *   [1.1.2] Implement the GitHub Actions CI workflow.
    *   [1.2.1] Design the YAML configuration structure.
    *   [1.2.1] Begin refactoring functions to read parameters from the config object.
*   **Deliverable:** A working CI pipeline that runs on every push. A draft `config.yaml` file.

### Week 3: Reproducibility & Configuration
*   **Goal:** Ensure perfect reproducibility and complete the parameter decoupling.
*   **Tasks:**
    *   [1.1.3] Create and test the `Dockerfile`.
    *   [1.2.1] Finish refactoring all code to be driven by the YAML configuration files.
*   **Deliverable:** A working `Dockerfile`. A fully externalized configuration system.

### Week 4: Performance Profiling & Optimization
*   **Goal:** Identify and begin to address performance bottlenecks.
*   **Tasks:**
    *   [1.3.1] Profile the simulation engine using `profvis`.
    *   [1.3.1] Begin refactoring the most critical data manipulation functions to use `data.table`.
*   **Deliverable:** A profiling report. Initial functions converted to `data.table`.

### Week 5: Completing Performance Overhaul
*   **Goal:** Finalize the performance optimization work for Phase 1.
*   **Tasks:**
    *   [1.3.1] Complete the `data.table` refactoring.
    *   [1.3.2] Convert all data I/O to use the Parquet format.
*   **Deliverable:** A fully `data.table`-based simulation engine. All input data converted to Parquet.

### Week 6: Foundational Module Expansion
*   **Goal:** Build the core new modules for costing and interventions.
*   **Tasks:**
    *   [1.4.1] Implement the new, flexible Costing and Pharmacy modules.
    *   [1.4.2] Implement the enhanced Surgery and Revision modules.
*   **Deliverable:** Working, tested V2 versions of the core new modules.

---
