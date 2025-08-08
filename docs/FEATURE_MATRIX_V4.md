# Feature Matrix for Osteoarthritis Health Economic Simulation

This document outlines the feature matrix for a health economic simulation model for osteoarthritis (OA). It is based on a review of existing health economic models for OA.

| Feature Category | Feature Name | Description & Examples | Status in Current Model |
|---|---|---|---|
| **Patient Characteristics** | Demographics | Basic patient information that can influence disease progression and treatment outcomes. Examples: Age, sex, body mass index (BMI). | Implemented |
| | Clinical Status | Baseline clinical measures that define the severity and characteristics of the disease. Examples: Kellgren-Lawrence (KL) grade for radiographic severity, joint space width, pain scores (e.g., WOMAC, VAS), functional status. | Partially Implemented (KL grade, pain, function) |
| | Comorbidities | Co-existing health conditions that can impact costs, quality of life, and treatment choices. Examples: Cardiovascular disease, diabetes, chronic obstructive pulmonary disease (COPD). | Implemented |
| | Risk Factors | Factors that may influence the progression of osteoarthritis. Examples: Genetics, history of joint injury, occupation. | Not Implemented |
| **Interventions** | Pharmacological | Drug therapies aimed at managing symptoms and potentially modifying disease progression. Examples: Non-steroidal anti-inflammatory drugs (NSAIDs), analgesics, corticosteroids, disease-modifying osteoarthritis drugs (DMOADs). | Partially Implemented (new OA drug) |
| | Non-Pharmacological | Therapies that do not involve medication. Examples: Physical therapy, weight management programs, patient education, assistive devices. | Partially Implemented (BMI modification) |
| | Surgical | Invasive procedures for advanced stages of osteoarthritis. Examples: Total knee arthroplasty (TKA), total hip arthroplasty (THA), osteotomy. | Implemented (TKA) |
| **Model Structure** | Model Type | The underlying mathematical framework of the simulation. Examples: Markov model, discrete event simulation, decision tree. | Implemented (Microsimulation) |
| | Health States (for Markov Models) | Distinct stages of the disease that patients can occupy within the model. Examples: Mild OA, Moderate OA, Severe OA, Post-TKA, Death. | Implemented (OA status, TKA status, death) |
| | Cycle Length | The time interval at which the model updates patient transitions between health states. Example: 1 year. | Implemented (1 year) |
| | Time Horizon | The total duration over which the simulation is run. Example: Lifetime, 20 years. | Implemented (configurable) |
| **Model Parameters** | Transition Probabilities | The likelihood of moving from one health state to another within a given cycle. These are influenced by patient characteristics and interventions. | Implemented |
| | Treatment Effects | The impact of interventions on clinical outcomes and disease progression. Examples: Reduction in pain scores, improvement in function, delay in need for surgery. | Implemented |
| | Adverse Events | The probability and consequences of negative outcomes associated with treatments. Examples: Gastrointestinal bleeding with NSAIDs, surgical complications. | Implemented (TKA complications) |
| **Cost Inputs** | Direct Medical Costs | Healthcare expenditures directly related to the management of osteoarthritis. Examples: Physician visits, hospitalizations, surgery, medications, diagnostic imaging, physical therapy. | Partially Implemented (TKA, complications, rehab, interventions) |
| | Direct Non-Medical Costs | Costs incurred by patients and their families as a direct result of the illness. Examples: Transportation to appointments, home modifications, paid caregivers. | Not Implemented |
| | Indirect Costs | The value of lost productivity due to the disease. Examples: Absenteeism (days missed from work), presenteeism (reduced productivity while at work), early retirement. | Not Implemented |
| **Health Outcomes** | Health-Related Quality of Life (HRQoL) | A measure of the impact of the disease and treatments on a patient's well-being. | Implemented |
| | - Generic Instruments | Measures applicable to a wide range of health conditions. Example: EQ-5D, SF-36. | Implemented (SF-6D) |
| | - Disease-Specific Instruments | Measures tailored to the specific symptoms and functional limitations of osteoarthritis. Example: Western Ontario and McMaster Universities Osteoarthritis Index (WOMAC). | Not Implemented |
| | Utility Values | A single index value representing the preference for a particular health state, used to calculate Quality-Adjusted Life Years (QALYs). Derived from HRQoL instruments. | Implemented |
| **Outcome Measures** | Incremental Cost-Effectiveness Ratio (ICER) | The primary output of the simulation, representing the additional cost per QALY gained for one intervention compared to another. | Not Implemented |
| | Quality-Adjusted Life Years (QALYs) | A measure of disease burden that combines both the quantity and the quality of life lived. | Implemented |
| | Total Costs | The overall economic burden of each treatment strategy over the model's time horizon. | Implemented |
