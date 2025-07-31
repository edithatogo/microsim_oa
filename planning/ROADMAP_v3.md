# AUS-OA Model v3 Development Roadmap

**File Version:** 1
**Date:** 2025-07-31

## Preamble

This roadmap outlines the strategic development plan for Version 3 of the AUS-OA microsimulation model, building upon the v2.0-beta release. The goal of V3 is to enhance the model's analytical depth, broaden its economic and social scope, and make it more accessible to end-users.

---

## Phase 1: Completing the Core Engine & Expanding Scope

**Objective:** Finalize the core V2 engine, incorporate more complex system interactions, and answer deeper policy questions.

**Key Pillars:**

*   **Pillar 1.1: Finalize Core Engine**
    *   Transition all data I/O from CSV/Excel to the efficient Parquet format using the `arrow` package.
    *   Finalize the granular costing module to map events to specific **MBS and PBS item numbers**, calculate patient out-of-pocket costs, and include methodologies for productivity and informal care costs. **Discounting will be an explicit feature.**
    *   Fully integrate Patient-Reported Outcomes (PROs) as a primary driver of model progression.

*   **Pillar 1.2: Deepening Clinical & System Realism**
    *   Model key surgical complications (e.g., PJI, DVT).
    *   **Health System Capacity Module:** Add the ability to model system capacity constraints and waiting list dynamics.
    *   Differentiate between **public and private** care pathways and their associated costs and outcomes.

*   **Pillar 1.3: Broadening the Economic & Social Perspective**
    *   Integrate the impact on carers (informal care costs, quality of life).
    *   Model the link to the residential aged care system.
    *   Analyze equity and access, using new geographic (remoteness) and socioeconomic variables in the synthetic population.

*   **Pillar 1.4: Advanced Analytics & Validation**
    *   Implement a comprehensive framework for Probabilistic Sensitivity Analysis (PSA), **with standard outputs like Cost-Effectiveness Acceptability Curves (CEACs).**
    *   Explore replacing a core statistical process with a Machine Learning model (e.g., GBM for progression), including Explainable AI (XAI) analysis.
    *   **Performance Review & `Rcpp`:** Profile the new V2 engine and implement `Rcpp` for the top 1-2 bottlenecks if required.

---

## Phase 2: User Experience & Dissemination

**Objective:** Make the model's power accessible to different audiences and translate its findings into actionable insights.

**Key Pillars:**

*   **Pillar 2.1: Scenario & Results Management**
    *   Develop a simple Shiny application to act as a graphical user interface (GUI) for setting up simulation scenarios and exploring high-level results.
    *   Create a suite of standardized reporting functions to generate tables, figures, and reports.
    *   **Develop a Standard Operating Procedure (SOP) for evaluating a new intervention.**

*   **Pillar 2.2: Stakeholder-Specific Outputs**
    *   Develop an "Executive Dashboard" output summarizing key findings for policymakers.
    *   Create an R Markdown template for HTA-compliant reports (for both PBAC and MSAC).
    *   Produce plain-language summaries and fact sheets for consumers and advocacy groups.
    *   **Develop analysis to support a "National OA Strategy" policy case.**

*   **Pillar 2.3: Documentation & Publication**
    *   Develop comprehensive technical documentation for the model and its API.
    *   Create tutorials and vignettes on how to use the R package and run simulations.
    *   Prepare and submit multiple manuscripts for peer-reviewed publication.

---
