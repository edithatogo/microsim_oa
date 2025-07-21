# Consultation Log: AUS-OA Microsimulation Model v2 - Plan Review

**File Version:** 2
**Date:** 2025-07-15

---

## Stakeholder Consultation: Professor of Orthopaedics (Plan Review)

**Date of Consultation:** 2025-07-15

**Documents Reviewed:**
*   `ROADMAP_v2_1_20250715.md`
*   `TODO_v2_1_20250715.md`
*   `PROJECT_PLAN_v2_1_20250715.md`

### Feedback on the V2 Plan

This is an excellent and comprehensive plan. The structure is logical, and the technical foundation laid out in Phase 1 is exactly what's needed to support the clinical complexity we discussed.

*   **Positive Feedback:**
    *   I am very pleased to see the "Surgical & Revisions Module" (Pillar 1.4) included in the very first phase. This is critical. The plan to model revision reasons and incorporate implant survivorship data is perfect.
    *   The expansion to include key complications like PJI and DVT in Phase 2 is also a high priority for me, so I am glad to see it captured.
    *   The focus on software engineering best practices gives me confidence that the resulting model will be robust and credible.

*   **Suggestions for Improvement / Clarification:**
    *   **Priority of PROs:** The plan lists the integration of Patient-Reported Outcomes (PROs) in Phase 2. I would argue this is a **Phase 1 priority**. The decision to operate is often based as much on the patient's pain and function as it is on their KL grade. For the "Optimal Timing for TKR" question to be answered properly, the model needs to be driven by PROs from the very beginning. I would strongly advocate for moving this task from Pillar 2.1 to Pillar 1.4.
    *   **Timeline:** The 6-week timeline for Phase 1 seems ambitious, given the scale of the architectural refactoring and module development. While I appreciate the ambition, we should be realistic about the time required to get this foundational phase right.

*   **Overall Assessment:** I am very happy with this plan. If the priority of PRO integration can be addressed, I would fully endorse it.

---

## Stakeholder Consultation: Professor of Rheumatology (Plan Review)

**Date of Consultation:** 2025-07-15

**Documents Reviewed:**
*   `ROADMAP_v2_1_20250715.md`
*   `TODO_v2_1_20250715.md`
*   `PROJECT_PLAN_v2_1_20250715.md`

### Feedback on the V2 Plan

This is a very impressive and well-structured plan. It has successfully translated our initial, broad requests into a concrete and logical development roadmap.

*   **Positive Feedback:**
    *   The creation of a dedicated "Detailed Pharmacy Module" in Phase 1 (Pillar 1.4) is excellent. This directly addresses my primary requirement for a more sophisticated representation of pharmacological and non-pharmacological treatments. The plan to include adherence and dynamic switching is crucial.
    *   I strongly support the plan to integrate PROs as key drivers of the model (Pillar 2.1). This aligns the model with modern clinical practice.
    *   The technical architecture, particularly the decoupling of parameters into YAML files, will make it much easier to model new DMOADs as they become available, which is a key use case for me.

*   **Suggestions for Improvement / Clarification:**
    *   **Non-Pharmacological Interventions:** The roadmap mentions these in Phase 2, but the `TODO` list doesn't explicitly list them as a task in the module expansion. I want to ensure that the "Pharmacy Module" is perhaps better named the "Interventions Module" and that it is designed from the outset in Phase 1 to handle both pharmacological (drugs) and non-pharmacological (physio, weight loss) interventions, even if the latter are only fully implemented in Phase 2. The core structure should be there from the beginning.
    *   **Phenotypes:** My suggestion about modeling different OA phenotypes (e.g., inflammatory) is a more advanced topic, and I agree it belongs in a later phase. However, the data structure for the synthetic population should be flexible enough from Phase 1 to allow for the addition of a "phenotype" variable later on without requiring another major refactor.

*   **Overall Assessment:** I am very supportive of this plan. It's a significant step forward. My main suggestion is to ensure the foundational work in Phase 1 is flexible enough to easily accommodate the non-pharmacological and phenotypic aspects planned for Phase 2.

---

## Stakeholder Consultation: Professor of Health Economics (Plan Review)

**Date of Consultation:** 2025-07-15

**Documents Reviewed:**
*   `ROADMAP_v2_1_20250715.md`
*   `TODO_v2_1_20250715.md`
*   `PROJECT_PLAN_v2_1_20250715.md`

### Feedback on the V2 Plan

This is a methodologically sound and robust plan. The emphasis on a rigorous software architecture in Phase 1 is the correct approach and builds credibility for the economic analyses that will follow.

*   **Positive Feedback:**
    *   The plan to build a formal, auditable "Costing Module" and to externalize all costs into configuration files (Pillar 1.4) is exactly what is required. The inclusion of productivity costs is a significant and welcome addition.
    *   The commitment to building a comprehensive framework for Probabilistic Sensitivity Analysis (PSA) in Phase 2 is essential for any serious health economic model.
    *   The software engineering practices, particularly containerization with Docker and dependency management with `renv`, will ensure the model's results are reproducible, which is a cornerstone of high-quality economic evaluation.

*   **Suggestions for Improvement / Clarification:**
    *   **Discounting:** The plan mentions discounting implicitly but it should be an explicit feature of the Costing Module from Phase 1. The module should be able to apply different discount rates for costs and outcomes as per HTA guidelines.
    *   **Perspective:** The plan should explicitly state that the model will be capable of reporting from both a "Healthcare System Perspective" and a "Societal Perspective". This should be a feature of the reporting functions developed in Phase 3, but the necessary cost components (like productivity costs) need to be built in from Phase 1.
    *   **Clarity on HTA outputs:** Phase 3 mentions HTA-compliant templates. It would be beneficial to specify that this includes the generation of cost-effectiveness planes and cost-effectiveness acceptability curves (CEACs) as standard graphical outputs from the PSA.

*   **Overall Assessment:** This plan is excellent. It lays the groundwork for a model that will be capable of producing high-quality, defensible health economic analyses. My suggestions are minor clarifications to ensure full alignment with best practices in economic evaluation. I fully endorse this direction.

---

## Stakeholder Consultation: Professor of Health Policy (Plan Review)

**Date of Consultation:** 2025-07-15

**Documents Reviewed:**
*   `ROADMAP_v2_1_20250715.md`
*   `TODO_v2_1_20250715.md`
*   `PROJECT_PLAN_v2_1_20250715.md`

### Feedback on the V2 Plan

The plan is comprehensive and demonstrates a clear understanding of the need to build a tool that can inform real-world policy. The phased approach is sensible.

*   **Positive Feedback:**
    *   I am very pleased to see the explicit goal of analyzing equity and access in Phase 2, and the prerequisite task of adding geographic and socioeconomic variables to the population. This is crucial for understanding the policy implications for all Australians.
    *   The concept of "Policy Levers" in the configuration (Pillar 1.2) is outstanding. This is exactly what is needed to make the model a practical tool for policy analysis, allowing us to easily model the effects of changing a rebate, funding a new program, etc.
    *   The plan to develop an "Executive Dashboard" and plain-language summaries in Phase 3 shows a commitment to translating complex results into actionable insights, which is often a failing of academic models.

*   **Suggestions for Improvement / Clarification:**
    *   **Waiting Lists / Capacity Constraints:** My previous suggestion to model health system capacity constraints and waiting lists is not explicitly mentioned in the plan. This is a critical component of health policy in Australia. A model that assumes unlimited capacity for surgery is not reflecting reality. I would strongly advocate for adding a "Health System Capacity" module to the scope, perhaps in late Phase 2.
    *   **Models of Care:** The plan doesn't explicitly mention how it will evaluate different "Models of Care". This was a key policy question. The "Policy Levers" are a good start, but the roadmap should acknowledge the goal of using these levers to construct and compare entirely different care pathways (e.g., a GP-led multidisciplinary care model vs. a specialist-led model).

*   **Overall Assessment:** This is a strong plan that is moving in the right direction. It takes the needs of policy-making seriously. My endorsement would be stronger if the plan could explicitly incorporate the modeling of system capacity constraints and make the evaluation of different models of care a more prominent goal.

---

## Stakeholder Consultation: Pharmaceutical Executive (Plan Review)

**Date of Consultation:** 2025-07-15

**Documents Reviewed:**
*   `ROADMAP_v2_1_20250715.md`
*   `TODO_v2_1_20250715.md`
*   `PROJECT_PLAN_v2_1_20250715.md`

### Feedback on the V2 Plan

The proposed plan is impressive in its scope and technical rigor. A model built to this standard would be a highly valuable asset for demonstrating the value of new medicines to HTA bodies.

*   **Positive Feedback:**
    *   The plan to create a modular and flexible "Pharmacy Module" in Phase 1 that can handle new interventions via configuration files is exactly what we need. This is a critical feature.
    *   The commitment to building a robust PSA framework and HTA-compliant outputs (cost-effectiveness planes, etc.) in later phases is essential for our purposes.
    *   The focus on professionalism (R package structure, CI/CD, Docker) gives us confidence that the model will be credible and its results defensible.

*   **Suggestions for Improvement / Clarification:**
    *   **Speed of Adaptation:** Our primary concern is speed. When we are preparing a PBAC submission, we have tight deadlines. The plan is excellent, but we need assurance that the final model is agile. How quickly can a new drug be "slotted in" and a full analysis run? The project plan should perhaps include a specific task in Phase 3 to "Develop a Standard Operating Procedure (SOP) for evaluating a new intervention" to ensure this process is streamlined.
    *   **Comparator Definition:** The plan needs to be explicit that the model can handle not just "standard of care" as a comparator, but also active comparators (i.e., another drug). This is a common requirement for PBAC submissions. This should be a feature of the "Policy Lever" system.

*   **Overall Assessment:** This plan aligns very well with our needs. It outlines the development of a best-in-class model that would be highly useful for generating the evidence required for reimbursement submissions. My suggestions are focused on ensuring the final tool is as agile and flexible as possible to meet the timelines of the HTA process. We fully support this plan.

---

## Stakeholder Consultation: Medical Device Executive (Plan Review)

**Date of Consultation:** 2025-07-15

**Documents Reviewed:**
*   `ROADMAP_v2_1_20250715.md`
*   `TODO_v2_1_20250715.md`
*   `PROJECT_PLAN_v2_1_20250715.md`

### Feedback on the V2 Plan

The plan is robust and the technical overhaul is impressive. It provides a clear pathway to a more powerful and credible model.

*   **Positive Feedback:**
    *   I am extremely pleased to see the "Surgical & Revisions Module" as a core part of Phase 1. The specific mention of incorporating implant survivorship data is the key feature we were looking for.
    *   The plan to model surgical complications in Phase 2 will allow us to demonstrate the value of technologies that can reduce these events.
    *   The overall professionalism of the plan gives us confidence that we can use the model's outputs in our discussions with hospital groups and private health insurers.

*   **Suggestions for Improvement / Clarification:**
    *   **Technology as a "Policy Lever":** The plan talks about policy levers for drugs and government programs. It needs to be made explicit that "technology choice" is also a key lever. The configuration system developed in Phase 1 must be able to accept parameters that define a specific technology's impact (e.g., `implant_X_revision_hazard_ratio: 0.95`). This is the most critical point for us.
    *   **Private vs. Public:** The model needs to differentiate between the public and private sectors. This was in my initial feedback but is not explicitly mentioned in the V2 plan. This is crucial for modeling the Australian system and should be included in the scope, likely as part of the "Equity and Access" work in Phase 2.

*   **Overall Assessment:** The plan is very good and addresses our main requirement around the revisions module. However, for us to fully endorse it, we need to see the concept of "technology choice" treated as a first-class citizen within the model's configuration and scenario analysis capabilities.

---

## Stakeholder Consultation: Policy Maker (MBS) (Plan Review)

**Date of Consultation:** 2025-07-15

**Documents Reviewed:**
*   `ROADMAP_v2_1_20250715.md`
*   `TODO_v2_1_20250715.md`
*   `PROJECT_PLAN_v2_1_20250715.md`

### Feedback on the V2 Plan

The plan is thorough and the proposed architectural changes are sensible. It appears to be creating a more flexible and auditable tool, which is important for us.

*   **Positive Feedback:**
    *   The externalization of parameters into configuration files is a major step forward. The plan to have a `costs.yaml` file that can be linked to MBS item numbers is a key feature.
    *   The ability to model different policy levers will allow us to use the model to explore the potential consequences of changes to MBS rebates or rules.
    *   The focus on performance is good to see, as we often need to analyze multiple scenarios in a short timeframe.

*   **Suggestions for Improvement / Clarification:**
    *   **MBS Module Specificity:** The plan for the "Costing Module" is good, but it needs to be more specific about the MBS. I would recommend a dedicated `mbs.yaml` file that contains a list of relevant item numbers, their scheduled fees, and the rebate amounts. The simulation should then track the *utilisation of these specific items*, not just a generic "cost". This allows us to conduct much more granular analysis and to produce forecasts of MBS expenditure, which is my primary need.
    *   **Out-of-Pocket Costs:** The plan needs to be explicit about how out-of-pocket costs for MBS services will be calculated. This means the model needs to know not just the MBS rebate, but also the average fee charged by clinicians, so it can calculate the patient co-payment. This is a critical policy metric. This should be part of the `mbs.yaml` configuration.

*   **Overall Assessment:** This is a positive development. The plan will create a more useful tool for the MBS team. My endorsement is contingent on the costing module being developed with a specific focus on MBS item number utilisation and the explicit calculation of out-of-pocket costs for patients.

---

## Stakeholder Consultation: Policy Maker (PBS) (Plan Review)

**Date of Consultation:** 2025-07-15

**Documents Reviewed:**
*   `ROADMAP_v2_1_20250715.md`
*   `TODO_v2_1_20250715.md`
*   `PROJECT_PLAN_v2_1_20250715.md`

### Feedback on the V2 Plan

The plan is excellent. The proposed architecture and development process are aligned with best practices and would result in a model that is fit-for-purpose for HTA submissions to the PBAC.

*   **Positive Feedback:**
    *   The entire plan for Phase 1 is superb. The combination of a formal R package, `renv`, CI/CD, Docker, and externalized YAML configurations is precisely the foundation needed to produce a transparent, reproducible, and credible model.
    *   The "Pharmacy Module" (Pillar 1.4) and the plan for a comprehensive PSA framework (Pillar 2.3) directly address the core requirements for a PBAC submission.
    *   The mention of HTA-compliant templates in Phase 3 is also noted and appreciated.

*   **Suggestions for Improvement / Clarification:**
    *   **No major suggestions.** The plan as written is already very well-aligned with our needs. The key will be in the execution.
    *   A minor point would be to ensure the BIA (Budget Impact Analysis) capabilities are considered during the design of the reporting functions in Phase 3. The model will need to report on the number of patients treated, the cost to the PBS, and any cost-offsets, all broken down by year for the first 5 years.

*   **Overall Assessment:** I fully endorse this plan. It is a blueprint for how to build a high-quality health economic model. If executed as described, the resulting tool would be of immense value to the PBAC process.

---

## Stakeholder Consultation: Australian Commonwealth Health Minister (Plan Review)

**Date of Consultation:** 2025-07-15

**Documents Reviewed:**
*   `ROADMAP_v2_1_20250715.md`
*   `TODO_v2_1_20250715.md`
*   `PROJECT_PLAN_v2_1_20250715.md`

### Feedback on the V2 Plan

Thank you for this. It's a lot of technical detail, but my team has briefed me on what it means. It looks like a solid plan to build a much more powerful and useful tool.

*   **Positive Feedback:**
    *   I am very pleased to see that Phase 3 is focused on "User Experience & Dissemination". The plan to create an "Executive Dashboard" and plain-language summaries is exactly what I need. The best model in the world is useless to me if I can't understand what it's telling me.
    *   The "Policy Lever" system sounds very promising. The ability to quickly ask "what-if" questions about different policy ideas is critical for my office.
    *   The overall professionalism gives me confidence that I can trust the results and use them to make and defend our policy decisions.

*   **Suggestions for Improvement / Clarification:**
    *   **Timeliness:** The Gantt chart shows this is a 20-week project. In politics, things move much faster. While I understand that good work takes time, the project team needs to be prepared to provide interim results or run urgent scenarios, even if the full V2 model is not yet complete. The ability to be responsive is key.
    *   **The "So What?":** The plan is very focused on the technical "how". The final reports need to focus on the "so what?". For every analysis, the key takeaway for the government needs to be front and centre. What is the problem, what is the proposed solution, what will it cost, and what are the benefits for Australians?

*   **Overall Assessment:** This looks good. It's a serious plan to build a serious tool. I support it. Just don't get lost in the technical details and forget that the ultimate purpose of this is to help the government make better decisions for the health of the nation. Keep my team updated on your progress.

---

## Stakeholder Consultation: Consumer with Osteoarthritis (Plan Review)

**Date of Consultation:** 2025-07-15

**Documents Reviewed:**
*   `ROADMAP_v2_1_20250715.md`
*   `TODO_v2_1_20250715.md`
*   `PROJECT_PLAN_v2_1_20250715.md`

### Feedback on the V2 Plan

It's very technical, but I appreciate you sharing it with me. I've tried to understand the main points.

*   **Positive Feedback:**
    *   I am really happy to see that "Integrate Patient-Reported Outcomes (PROs)" is in the plan (Pillar 2.1). This is the most important thing for me - that the model is based on how we actually feel, not just what the x-rays say.
    *   The plan to create plain-language summaries and fact sheets in Phase 3 is a great idea. We need information that we can actually use.
    *   It seems like the new model will be much better at looking at different treatment options, which will hopefully help doctors give us better advice.

*   **Suggestions for Improvement / Clarification:**
    *   **When will it help me?** I see that the PROs are in Phase 2, which the chart says is weeks 7-14. That seems a long way away. Like the surgeon, I think this is so important that it should be in Phase 1. The model isn't realistic without it.
    *   **What about the things I care about?** The plan talks a lot about costs and QALYs. I hope you don't forget to measure the other things we talked about, like being able to work, or do your own shopping, or play with your grandkids. I'm not sure where that fits in the plan. It should be made clearer.

*   **Overall Assessment:** It seems like a good plan, and I'm glad you're taking it so seriously. I just want to be sure that the things that matter most to patients - our pain, our function, our quality of life - are at the very heart of the model from the very beginning.

---

## Stakeholder Consultation: Osteoarthritis Advocacy Organisation (Plan Review)

**Date of Consultation:** 2025-07-15

**Documents Reviewed:**
*   `ROADMAP_v2_1_20250715.md`
*   `TODO_v2_1_20250715.md`
*   `PROJECT_PLAN_v2_1_20250715.md`

### Feedback on the V2 Plan

This is an exemplary plan. The structured approach, clear phases, and detailed tasks provide a high degree of confidence that this project will deliver a powerful and much-needed tool for the OA community.

*   **Positive Feedback:**
    *   The plan to include productivity costs, carer impacts, and links to the aged care system (Pillars 1.4 & 2.2) is outstanding. This will allow us to quantify the full societal burden of OA, which is a core part of our advocacy.
    *   The specific inclusion of equity analysis, including geographic and socioeconomic variables (Pillar 2.2), is critical for our work in highlighting and addressing disparities in care.
    *   The commitment to producing accessible outputs, such as plain-language summaries and infographics (Pillar 3.2), will be invaluable for our communication and advocacy campaigns.

*   **Suggestions for Improvement / Clarification:**
    *   **Non-Surgical Management:** I echo the Rheumatology Professor's comments. The plan needs to be clearer about how it will model non-surgical and preventative interventions. The "Pharmacy Module" should be renamed to something like the "Intervention Module" to reflect this broader scope from the outset. We need to be able to model the cost-effectiveness of physiotherapy-led programs with the same rigor as a new drug.
    *   **National Strategy:** The plan is a "how-to" guide for building the model, but one of our key policy questions was the case for a "National Osteoarthritis Strategy". The project plan should include a specific analysis task in Phase 3 to "Simulate the impact of a coordinated National OA Strategy" to ensure this key advocacy goal is not lost.

*   **Overall Assessment:** This is a fantastic plan that has clearly incorporated the feedback from the initial consultation. It provides a pathway to a tool that will be transformative for OA advocacy in Australia. We strongly endorse this plan, with the recommendation to ensure non-surgical interventions are a primary consideration from day one.

---

## Stakeholder Consultation: Family Member (Plan Review)

**Date of Consultation:** 2025-07-15

**Documents Reviewed:**
*   `ROADMAP_v2_1_20250715.md`
*   `TODO_v2_1_20250715.md`
*   `PROJECT_PLAN_v2_1_20250715.md`

### Feedback on the V2 Plan

Thank you for sharing this. It's very detailed. I've tried to focus on the parts that relate to my family's experience.

*   **Positive Feedback:**
    *   I am so glad to see that the plan includes looking at the "impact on carers" and the "link to the residential aged care system" (Pillar 2.2). This shows you have listened to our feedback and are trying to see the bigger picture beyond just the patient.
    *   The idea of creating practical guides and tutorials in Phase 3 is wonderful. Information is so important for families, and this could make a real difference.

*   **Suggestions for Improvement / Clarification:**
    *   **When will the carer part be done?** I see that the carer impact is in Phase 2. I understand that you have to build the basics first, but it's important that this doesn't get forgotten or pushed back if the project runs out of time.
    *   **What about things like home modifications?** I don't see that mentioned in the plan. We were told that things like ramps and handrails could make a big difference in keeping my mum at home. Can the model look at the value of these sorts of practical things? This should be part of the "Intervention Module".

*   **Overall Assessment:** It looks like a very thorough plan. It gives me hope that people are taking this disease seriously and trying to understand all the different ways it affects families. I support it.

---

## Technical Stakeholder Group (Data Science, Comp Sci, Software Eng) (Plan Review)

**Date of Consultation:** 2025-07-15

**Documents Reviewed:**
*   `ROADMAP_v2_1_20250715.md`
*   `TODO_v2_1_20250715.md`
*   `PROJECT_PLAN_v2_1_20250715.md`

### Feedback on the V2 Plan

This is a well-architected and technically sound plan that directly incorporates our collective advice. The emphasis on establishing a professional software engineering foundation before expanding the model's capabilities is the correct and most robust approach.

*   **Positive Feedback:**
    *   **(All):** The decision to make "Pillar 1.1: Software Engineering Best Practices" the absolute first priority is excellent. The combination of converting to an R package, using `renv`, setting up CI/CD, and using Docker will address the major threats of technical debt, non-reproducibility, and code rot. This is a huge step up in professionalism.
    *   **(Data Science):** The plan to decouple the model logic from the data/parameters by using YAML files is a massive improvement and directly addresses my primary concern. The inclusion of a proof-of-concept ML model with XAI in Phase 2 is appropriately ambitious and forward-looking.
    *   **(Computer Science):** The prioritization of performance optimization in Phase 1 is key. The specific tasks to refactor with `data.table` and switch to Parquet I/O are the right choices and will yield significant performance gains.
    *   **(Software Engineering):** The entire plan reads like a proper software development plan. The adoption of agile project management via a Kanban board and issues will bring much-needed structure and transparency to the development process.

*   **Suggestions for Improvement / Clarification:**
    *   **(Software Engineering):** The Gantt chart is a good overview, but the tasks in Phase 1 are not entirely independent. For example, you can't effectively write the `Dockerfile` (1.1.3) until `renv` is initialized (1.1.1) and the package structure is in place. The project plan should perhaps note these dependencies more explicitly.
    *   **(Computer Science):** The plan mentions using `Rcpp` as an opportunity but it is not a specific task in the `TODO` list. While it may not be needed if `data.table` provides sufficient performance, I would suggest adding a specific task in Phase 2 to "Profile the V2 engine and implement `Rcpp` for the top 1-2 bottlenecks if required". This ensures the option is not forgotten.
    *   **(Data Science):** The plan should be explicit that the new R package will have a clear API (Application Programming Interface), i.e., a set of stable, well-documented functions for running the model. This makes it easier for other data scientists to build on top of the model or integrate it into other workflows.

*   **Overall Assessment:** Unanimous and strong endorsement from all technical stakeholders. The plan is ambitious but logical and follows modern best practices for creating complex, data-intensive software. It correctly prioritizes building a robust, maintainable, and reproducible foundation before adding new scientific features. We are confident that a model built this way will be a powerful and credible asset.

---
