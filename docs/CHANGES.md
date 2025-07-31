# New Features and Improvements

This document outlines the major new features and improvements in the current version of the AUS-OA Public model.

### 1. Intervention Modelling

A sophisticated framework has been introduced to model the impact of various health interventions. This allows researchers to assess the potential effects of different strategies on the simulated population. The core logic is implemented in `R/apply_interventions_fcn.R`, which supports interventions like BMI modification and direct adjustments to QALYs and costs.

### 2. Policy Lever Analysis

The model now includes a module for analyzing the effects of different policy levers. This feature, found in `R/apply_policy_levers_fcn.R`, enables the simulation of policy changes and their potential consequences on the model's outcomes.

### 3. Comprehensive Cost-Effectiveness and QALY Analysis

A major enhancement is the inclusion of a detailed cost-effectiveness analysis framework. The model now calculates costs from multiple perspectives (healthcare, patient, and societal) for various events such as surgeries, rehabilitation, and ongoing management of osteoarthritis. In conjunction with this, the model now calculates Quality-Adjusted Life Years (QALYs), allowing for a thorough assessment of the value of different interventions and policies. The relevant functions can be found in `R/calculate_costs_fcn.R` and `R/calculate_qaly_fcn.R`.

### 4. Comorbidity Modelling

The simulation now includes a module to model the development of comorbidities and their associated impact on both costs and QALYs. This is a significant improvement in the model's realism, as it allows for a more accurate representation of the health status of the simulated population. The `R/update_comorbidities_fcn.R` file contains the core logic for this feature.

### 5. Patient-Reported Outcome Measures (PROMs) Integration

While the integration of PROMs is mentioned in the planning documents, the current implementation is primarily focused on the use of the SF-6D utility score for QALY calculations. A more extensive and generic framework for integrating a wider range of PROMs has not yet been implemented.
