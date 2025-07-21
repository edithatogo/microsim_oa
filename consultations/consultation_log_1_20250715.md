# Consultation Log: AUS-OA Microsimulation Model v2

**File Version:** 1
**Date:** 2025-07-15

---

## Stakeholder Consultation: Professor of Orthopaedics

**Date of Consultation:** 2025-07-15

### 1. What would you want from a microsimulation model on osteoarthritis?

As an orthopaedic surgeon and researcher, my primary interest is in the entire patient journey, from diagnosis to end-stage disease and surgical intervention. I would want a model that can accurately simulate:

*   **Disease Progression:** The model should capture the heterogeneity of OA progression. Not just KL grades, but also factors like pain, function, and quality of life. Can we model the likelihood of a patient with KL grade 2 OA and minimal pain remaining stable for 5 years versus another who progresses rapidly to needing a joint replacement?
*   **Surgical Outcomes:** The model needs to go beyond just "had a TKR". It should include probabilities of complications (e.g., infection, DVT, stiffness), revision surgeries (and the reasons for revision), and the long-term functional outcomes post-surgery. How does the SF-6D change 1, 5, and 10 years post-op?
*   **Patient Stratification:** I need to be able to identify and analyze subgroups. For example, what are the outcomes for patients under 55 who receive a TKR versus those over 75? What about the impact of obesity or specific comorbidities on surgical success?

### 2. What are your policy questions that could be answered by a microsimulation?

My policy questions revolve around optimizing surgical care and resource allocation.

*   **Optimal Timing for TKR:** This is the holy grail. Can the model help us identify the "sweet spot" for TKR? If we operate too early, we risk a younger patient needing multiple revisions. If we wait too long, the patient's health may decline, making surgery riskier and recovery more difficult. The model could simulate lifetime outcomes for cohorts undergoing surgery at different disease stages.
*   **Resource Allocation for Revisions:** Revision surgeries are a huge cost to the healthcare system. The model could project the future burden of revision TKRs based on current surgical rates and patient demographics. This would be invaluable for long-term planning in hospitals and for federal budget allocation.
*   **Impact of Implant Choice:** While the current model doesn't include this, a future version could. If we could model the differential long-term survival of various implant types, we could answer questions about the cost-effectiveness of using more expensive, but potentially longer-lasting, implants.

### 3. What improvements would you like from the model?

*   **Granularity in Surgical Variables:**
    *   **Revisions:** Don't just model *if* a revision happens. Model *why* (e.g., aseptic loosening, infection, instability). This has huge implications for prevention and treatment.
    *   **Post-operative Complications:** Add modules for key complications like periprosthetic joint infection (PJI), deep vein thrombosis (DVT), and persistent pain. These are major drivers of cost and poor outcomes.
*   **Inclusion of Pre-operative Factors:** The model should more explicitly account for factors that we know influence surgical outcomes, such as pre-operative physiotherapy, mental health status, and social support.
*   **Long-term Implant Survivorship:** Can we incorporate registry data (e.g., from the AOANJRR) to model implant survival more accurately over 15-20 year horizons? This would be a major step forward.
*   **Health Economic Outputs:** I want to see outputs that are directly relevant to my discussions with hospital administrators and policymakers. Things like "cost per QALY gained for TKR in obese vs. non-obese patients" or "projected number of revision surgeries in 2035".

---

## Stakeholder Consultation: Professor of Rheumatology

**Date of Consultation:** 2025-07-15

### 1. What would you want from a microsimulation model on osteoarthritis?

My focus is on the non-operative management of osteoarthritis and understanding the disease from a systemic and inflammatory perspective. My interest is primarily in the phase *before* a patient gets to the surgeon.

*   **Pharmacological Management:** The model must have a robust representation of pharmacological treatments. This includes analgesics (paracetamol, NSAIDs), and potential future disease-modifying osteoarthritis drugs (DMOADs). It should model not just the efficacy but also the side effects and adherence over time.
*   **Non-Pharmacological Management:** It's critical to model the impact of interventions like physiotherapy, weight loss programs, and patient education. These are the cornerstones of rheumatological management.
*   **Pain and Function Trajectories:** I am less concerned with the KL grade and more with the patient's experience. The model should be able to simulate trajectories of pain (e.g., using WOMAC or VAS scores) and physical function over time, and how these are influenced by various treatments.
*   **Inflammatory Phenotypes:** A sophisticated model would differentiate between different OA phenotypes. For example, could we model an "inflammatory OA" phenotype that might respond better to certain anti-inflammatory drugs? This is forward-thinking, but it's where the field is heading.

### 2. What are your policy questions that could be answered by a microsimulation?

*   **Cost-Effectiveness of DMOADs:** When a new DMOAD is developed, the key policy question will be its cost-effectiveness. A microsimulation is the *perfect* tool for this. We could model the long-term impact of a DMOAD on delaying or preventing TKR, and weigh that against its cost to determine its value for the PBS.
*   **Optimal Treatment Pathways:** What is the most effective sequence of treatments for a typical patient? Should we be more aggressive with weight loss interventions early? When is the right time to introduce NSAIDs, considering their potential cardiovascular and GI side effects? The model could simulate thousands of patients on different pathways to find the optimal strategy.
*   **Impact of Public Health Interventions:** What would be the long-term impact of a national campaign to reduce obesity by 5% on the incidence and progression of OA? The model could provide quantitative answers to justify such public health policies.

### 3. What improvements would you like from the model?

*   **Detailed Pharmacy Module:** The model needs a much more detailed pharmacy module. It should include different classes of drugs, model adherence rates, and incorporate the probability of adverse events.
*   **Dynamic Treatment Switching:** Patients don't stay on one treatment forever. The model should allow for treatment switching based on efficacy (or lack thereof) and side effects. For example, if a patient's pain is not controlled on paracetamol, they might switch to an NSAID.
*   **Integration of Patient-Reported Outcomes (PROs):** The model should be driven more by PROs like pain and function, rather than just radiographic imaging (KL grade). This better reflects the clinical reality of how we manage patients.
*   **Ability to Model New Interventions:** The model's structure should be flexible enough to easily add new interventions as they are developed, particularly new classes of drugs. This would make it an invaluable tool for HTA bodies like the PBAC.

---

## Stakeholder Consultation: Professor of Health Economics

**Date of Consultation:** 2025-07-15

### 1. What would you want from a microsimulation model on osteoarthritis?

From a health economics perspective, a microsimulation model is a decision-making tool. Its value lies in its ability to conduct rigorous, person-level cost-utility analysis over a lifetime horizon.

*   **Detailed Costing Module:** The model must have a comprehensive and transparent costing module. This needs to break down costs into categories: direct medical (GP visits, specialist visits, drugs, surgery, rehab), direct non-medical (e.g., patient travel), and indirect costs (productivity losses). All costs should be clearly sourced and discountable.
*   **QALY Framework:** The core outcome must be the Quality-Adjusted Life Year (QALY). The model needs to use a validated utility measure (SF-6D is a good start) and apply decrements and increments associated with disease progression, events (like a TKR or a complication), and treatments.
*   **Multiple Perspectives:** The model should be able to report results from different perspectives. The healthcare system perspective is standard, but a societal perspective that includes productivity costs is crucial for understanding the full economic burden of OA.
*   **Head-to-Head Comparisons:** The ultimate purpose is to compare the cost-effectiveness of different strategies. The model must be able to simulate a cohort of patients under a "standard of care" scenario and compare it to one or more "new intervention" scenarios, reporting the incremental cost-effectiveness ratio (ICER).

### 2. What are your policy questions that could be answered by a microsimulation?

My questions are fundamentally about value for money and allocative efficiency.

*   **Cost-Effectiveness of Everything:** What is the ICER of introducing a new DMOAD versus current care? What is the ICER of a publicly funded, nationwide weight-loss program for at-risk individuals? What is the ICER of using a more expensive but longer-lasting joint implant? These are the questions that Treasury and PBAC/MSAC want answered.
*   **Budget Impact Analysis (BIA):** Beyond cost-effectiveness, what is the *affordability*? If we approve a new, expensive drug, what will be the net impact on the health budget over the next 5-10 years? A BIA is a standard requirement for reimbursement submissions, and this model should be able to produce one.
*   **Equity and Distributional Effects:** Who benefits from current and proposed interventions? Does a new treatment primarily benefit a specific socioeconomic group? The model could analyze the distribution of costs and QALYs across different population subgroups (e.g., by income, geography, or education level) to assess the equity implications of a policy change.

### 3. What improvements would you like from the model?

*   **Formalize the Costing Module:** Create a dedicated, auditable costing module. All costs should be in a separate input file, clearly sourced (e.g., MBS item numbers, PBS drug costs, literature), and with dates, so they can be easily inflated or discounted.
*   **Productivity Costs:** This is a major omission in many models. Incorporate a module to estimate productivity losses due to absenteeism (time off work) and presenteeism (reduced productivity while at work) for patients in the workforce.
*   **Sensitivity Analysis Capabilities:** The model *must* be able to perform robust sensitivity analyses. This includes one-way sensitivity analysis on key parameters, multi-way analysis on related parameters, and, most importantly, Probabilistic Sensitivity Analysis (PSA) using Monte Carlo simulation. The outputs should include cost-effectiveness planes and cost-effectiveness acceptability curves (CEACs).
*   **Transparency and Validation:** The model's code and assumptions need to be exceptionally well-documented to be credible for HTA submissions. It should be validated against external data sources wherever possible (e.g., comparing modeled TKR rates to national registry data).

---

## Stakeholder Consultation: Professor of Health Policy

**Date of Consultation:** 2025-07-15

### 1. What would you want from a microsimulation model on osteoarthritis?

My perspective is on the broader health system and how we can design and implement effective, equitable, and sustainable policies for chronic diseases like OA.

*   **System-Level Interactions:** I want a model that can capture the interactions between different parts of the health system. How does a change in primary care (e.g., a new GP management plan for OA) affect downstream demand for specialist services and hospital admissions?
*   **Equity and Access:** The model must be able to analyze issues of equity. Are there disparities in access to care (e.g., TKR) based on geographic location (rural vs. urban), socioeconomic status, or insurance status (public vs. private)? The model should be able to quantify these gaps.
*   **Workforce Planning:** The model could be a powerful tool for workforce planning. Given the aging population, what will be the demand for orthopaedic surgeons, rheumatologists, and physiotherapists in 2040?
*   **Long-Term Policy Evaluation:** I need a tool that can look beyond the immediate 5-year budget cycle. A microsimulation is perfect for evaluating the long-term (20-30 year) health and economic consequences of a policy decision made today.

### 2. What are your policy questions that could be answered by a microsimulation?

*   **Models of Care Evaluation:** What is the most effective and cost-effective model of care for OA? Should we be investing more in multidisciplinary primary care clinics, or focusing on streamlining access to surgery? The model could compare different "what-if" scenarios representing different models of care.
*   **Impact of Private Health Insurance:** What is the role and impact of private health insurance on the OA care pathway? Does it lead to earlier access to surgery? Does it create a two-tiered system? The model could explore the consequences of changes to private health insurance regulations.
*   **Prevention vs. Treatment:** This is a classic policy dilemma. What is the long-term return on investment from funding preventative health measures (like public campaigns for weight loss or exercise) compared to funding more treatments and surgeries? The model can provide the evidence base to support shifts in funding towards prevention.
*   **Closing the Gap for Underserved Populations:** If we identify that rural patients have lower rates of TKR, the model could be used to quantify the health and economic benefits of specific interventions aimed at closing that gap (e.g., telehealth consultations, travel subsidies, or outreach clinics).

### 3. What improvements would you like from the model?

*   **Geographic and Socioeconomic Data:** The synthetic population needs to be enriched with more detailed geographic (e.g., RA-codes for remoteness) and socioeconomic (e.g., SEIFA index) variables. This is essential for any meaningful equity analysis.
*   **Health System Capacity Constraints:** A truly advanced model would include capacity constraints. For example, there's a limit to how many surgeries can be performed. The model could include waiting list dynamics to provide a more realistic picture of access to care.
*   **Policy Levers as Inputs:** The model should be designed so that policy "levers" are explicit and easy to change. For example, the MBS rebate for a consultation, the PBS co-payment for a drug, or the budget for a public health program should be easily modifiable input parameters.
*   **Clear Communication of Results:** The outputs need to be translated for a policy audience. Instead of just ICERs and QALYs, provide executive summaries with clear, actionable messages. For example: "Investing $1 in Program X is projected to save $3 in hospital costs and add Y healthy life years over the next decade."

---

## Stakeholder Consultation: Pharmaceutical Executive (Osteoarthritis Drugs)

**Date of Consultation:** 2025-07-15

### 1. What would you want from a microsimulation model on osteoarthritis?

Our primary goal is to demonstrate the value of our products to regulators, payers, and clinicians. A credible, independent microsimulation model is an essential tool for this.

*   **A Platform for HTA Submissions:** We need a model that is considered best-practice and is trusted by bodies like the Pharmaceutical Benefits Advisory Committee (PBAC). It needs to be able to generate the core cost-utility analysis that forms the basis of a reimbursement submission.
*   **Market Sizing and Forecasting:** The model should be able to accurately estimate the size of the eligible patient population for our drugs, both now and in the future. This is critical for our internal forecasting and business planning.
*   **Demonstration of Value Beyond Efficacy:** It's not enough to show that our drug reduces pain. We need to show that this reduction in pain translates into long-term benefits. The model can help us quantify how our drug impacts disease progression, delays surgery, reduces the need for other medications (e.g., opioids), and improves a patient's quality of life and ability to work.
*   **Comparator Scenarios:** The model must be able to accurately represent the current standard of care to serve as a baseline (the "main comparator" in PBAC terms). It should also be flexible enough to model comparisons against other potential future competitor products.

### 2. What are your policy questions that could be answered by a microsimulation?

Our policy questions are focused on securing market access and demonstrating the value proposition of our products.

*   **What is the cost-effectiveness of our new DMOAD?** This is the number one question. We need to be able to present a robust ICER to the PBAC, supported by extensive sensitivity analyses.
*   **What is the budget impact of listing our drug on the PBS?** We need to provide the government with a credible estimate of the financial impact of subsidizing our drug. The model can help us show not just the upfront cost of the drug, but also the potential downstream cost-offsets from avoided surgeries or other treatments.
*   **In which patient subgroup is our drug most effective?** Perhaps our drug provides exceptional value in a specific subgroup (e.g., patients with inflammatory OA, or those at high risk of rapid progression). The model can help us identify these "high-responder" groups, which could support a targeted reimbursement submission.
*   **What is the long-term value of treatment?** A clinical trial might be two years long, but a microsimulation can extrapolate those results over a patient's lifetime. This allows us to demonstrate the long-term value of our drug in terms of QALYs gained and costs saved, which might not be apparent in the short term.

### 3. What improvements would you like from the model?

*   **Modular Drug Intervention:** The model needs a "slot" where we can easily insert the characteristics of a new drug. This would include its efficacy (e.g., effect size on pain, function, or structural progression), its cost, its side-effect profile, and patient adherence rates.
*   **Adherence and Persistence Modeling:** It's crucial to model adherence realistically. The model should incorporate data on how patient adherence to a chronic medication wanes over time, as this has a major impact on real-world effectiveness and cost-effectiveness.
*   **Link to Downstream Costs:** The model must be able to translate clinical benefits into economic ones. For example, if our drug reduces pain, the model should be able to link that to a reduction in GP visits, opioid use, and an increase in productivity, all of which have economic value.
*   **Alignment with HTA Guidelines:** The model's structure, assumptions, and outputs should be closely aligned with the official guidelines for PBAC submissions in Australia. This includes things like the choice of discount rate, the perspective of the analysis, and the way uncertainty is presented. This would make the model "submission-ready" and highly valuable to us.

---

## Stakeholder Consultation: Medical Device Executive (Orthopaedic Implants)

**Date of Consultation:** 2025-07-15

### 1. What would you want from a microsimulation model on osteoarthritis?

Our focus is on the value of surgical intervention and the technology used therein. We see this model as a key tool to demonstrate the long-term benefits of joint replacement and the superiority of our specific implant technologies.

*   **Demonstration of TKR Value:** The model needs to powerfully demonstrate the immense value of total knee replacement (TKR) as a health intervention. It should clearly show the significant improvements in quality of life (QALYs) and function when patients move from end-stage OA to a successful primary TKR.
*   **Implant Survivorship and Revision Rates:** This is critical for us. The model must be able to differentiate between implants based on their long-term survivorship. We invest heavily in R&D to create implants that last longer, and we need the model to quantify the economic and health benefits of a lower revision rate.
*   **Technology-Specific Outcomes:** Can the model be adapted to show the value of new technologies? For example, can it model the impact of robotic-assisted surgery on complication rates and implant alignment, and then link that to better long-term outcomes? Or the benefits of using cementless implants in younger, more active patients?
*   **Market Dynamics:** We need to understand the future demand for primary and revision TKR. The model's projections are essential for our production planning, sales forecasting, and strategic investments.

### 2. What are your policy questions that could be answered by a microsimulation?

Our policy questions are aimed at ensuring robust funding for joint replacement and demonstrating the value of premium technologies to payers like private health insurers and public systems.

*   **What is the long-term economic benefit of using a premium implant with a 5% lower revision rate at 15 years?** The model can quantify this by simulating the avoided costs and the QALYs saved from preventing revision surgeries. This is a powerful argument for hospitals and insurers.
*   **What is the budget impact of expanding TKR access to a wider patient population?** We can use the model to show that while expanding access might increase upfront costs, it could lead to long-term savings by improving patient function and reducing the need for other forms of care.
*   **Is robotic-assisted surgery cost-effective?** This is a major question in orthopaedics. The model could be used to conduct a formal cost-effectiveness analysis, weighing the higher upfront cost of the robotic system against potential benefits like lower revision rates and faster recovery.
*   **How does the timing of surgery impact lifetime healthcare costs?** We can use the model to support the argument that timely surgical intervention, before a patient's health deteriorates significantly, is not only better for the patient but also more economically prudent for the health system in the long run.

### 3. What improvements would you like from the model?

*   **Detailed Revision Module:** The model needs a sophisticated revision module. It should be able to take implant-specific survival curves as an input (e.g., from the AOANJRR) and model the probability of revision over time.
*   **Link between Technology and Outcomes:** This is the key. We need to be able to model how specific technologies (implants, surgical techniques) affect key parameters in the model. For example, `Input: Use of Implant X` -> `Parameter: 15-year revision probability decreases by 5%`.
*   **Private vs. Public Setting:** The model should differentiate between care in public and private hospitals. This includes differences in costs, waiting times, and potentially the types of implants used. This is crucial for understanding the Australian market.
*   **Scenario Analysis for New Technology:** The model should be structured to make it easy to run "what-if" scenarios for new technologies that are on the horizon. This would allow us to build a value case for our R&D pipeline *before* the products even come to market.

---

## Stakeholder Consultation: Policy Maker (Medicare Benefits Schedule - MBS)

**Date of Consultation:** 2025-07-15

### 1. What would you want from a microsimulation model on osteoarthritis?

My focus is on the services provided by clinicians—GPs, specialists, surgeons, and allied health professionals. The MBS provides subsidies for these services. I need a tool that can help me understand the current and future demand for these services and the implications of any changes to the MBS.

*   **Service Utilisation Forecasts:** The model must be able to project the future utilisation of specific MBS item numbers related to OA care. This includes GP consultations, specialist attendances, diagnostic imaging, and, of course, the surgical procedure item numbers for TKR.
*   **Link between Population Health and Service Demand:** I need to understand how changes in the population's health (e.g., rising obesity rates) will translate into demand for MBS-funded services.
*   **A Model of the Care Pathway:** The model should represent the typical patient journey through the healthcare system, showing the sequence and frequency of different MBS-subsidised services they are likely to use as their OA progresses.
*   **Costings Based on MBS Rebates:** The model's costing module, from my perspective, must be directly linked to MBS item numbers and their scheduled fees and rebates.

### 2. What are your policy questions that could be answered by a microsimulation?

My questions are about managing the sustainability of the MBS and ensuring that the services we subsidise represent good value for the taxpayer.

*   **What would be the financial impact of changing the rebate for a specific service?** For example, if we increased the rebate for a long GP consultation to encourage better chronic disease management, what would be the net impact on MBS expenditure, and would it lead to a reduction in downstream surgical costs?
*   **What is the projected growth in TKR procedures over the next 15 years?** This is a critical question for the government's long-term budget planning. The model's projections would be a key input into this process.
*   **Are there more cost-effective ways to deliver care?** The model could be used to compare the cost-effectiveness of different models of care. For example, is it more cost-effective to fund more physiotherapy sessions (allied health items) to delay or prevent the need for a very expensive TKR?
*   **What is the impact of co-payments and out-of-pocket costs?** The model could be used to explore how patient out-of-pocket costs affect their likelihood of accessing care, and what the downstream consequences are for their health and future costs to the system.

### 3. What improvements would you like from the model?

*   **Detailed MBS Item Number Module:** The model needs a detailed module that maps clinical events (e.g., a GP visit, a knee x-ray, a TKR) to specific MBS item numbers. This mapping needs to be transparent and easily updatable as the MBS changes.
*   **Distinction between Public and Private Costs:** It's crucial that the model can distinguish between the cost to the government (the MBS rebate), the cost to private insurers, and the out-of-pocket cost to the patient. This is essential for understanding the full financial picture.
*   **Modeling of GP and Specialist Behaviour:** A more advanced model would incorporate how clinicians' behaviour might change in response to policy changes. For example, how would referral rates to surgeons change if a new non-operative treatment becomes available?
*   **Clear, Actionable Outputs for Government:** The model's outputs need to be presented in a way that is directly useful for government briefing notes and budget papers. This means clear forecasts of service utilisation and expenditure, with all assumptions clearly stated.

---

## Stakeholder Consultation: Policy Maker (Pharmaceutical Benefits Scheme - PBS)

**Date of Consultation:** 2025-07-15

### 1. What would you want from a microsimulation model on osteoarthritis?

My role is to advise on which medicines should be subsidised for Australians, based on their clinical effectiveness, safety, and cost-effectiveness. A high-quality microsimulation model is one of the most important tools for this process.

*   **A PBAC-Compliant Framework:** The model must be built from the ground up to be consistent with the PBAC's guidelines. This means it needs to be able to conduct a cost-utility analysis, use a lifetime horizon, apply the correct discount rates, and be able to compare a proposed medicine to the appropriate main comparator.
*   **Accurate Representation of the Treatment Algorithm:** The model needs to accurately reflect the current clinical management of OA in Australia. Where would a new drug fit in? Would it replace an existing treatment, or be used as an add-on? This "place in therapy" is a critical consideration.
*   **Robust Pharmacoeconomic Analysis:** The model must be able to generate the key outputs for a PBAC submission: a calculation of the incremental cost-effectiveness ratio (ICER), and a comprehensive budget impact analysis (BIA).
*   **Uncertainty Analysis:** It is absolutely essential that the model can perform extensive sensitivity analyses, particularly a probabilistic sensitivity analysis (PSA), to explore the impact of uncertainty in the model's parameters on the final ICER.

### 2. What are your policy questions that could be answered by a microsimulation?

My questions are the core questions that the PBAC asks of every new medicine seeking reimbursement.

*   **Is this new medicine cost-effective?** For a given price, does the proposed medicine provide enough health benefit (in terms of QALYs gained) to be considered a good value for money for the Australian taxpayer? The model's ICER output is the direct answer to this.
*   **What is the financial impact on the PBS?** How much will this new medicine cost the PBS over the forward estimates (the next 5 years)? The model's BIA is the direct answer to this. We need to know the gross cost, any cost-offsets from other displaced drugs, and the net impact.
*   **Are there specific patient populations where this medicine is particularly cost-effective?** The model could help us to identify if a medicine should be restricted to a specific subgroup of patients in whom it provides the most benefit, allowing for a more targeted and affordable listing.
*   **What are the long-term consequences of listing this drug?** The model can help us understand the long-term health and economic consequences that go beyond the time horizon of the clinical trials, such as the potential to delay costly knee replacement surgeries.

### 3. What improvements would you like from the model?

*   **Transparency and Replicability:** For the model to be credible, its methods, assumptions, and data sources must be impeccably documented and transparent. An ideal model would be one where we could, in theory, replicate the results ourselves.
*   **Flexibility to Define Comparators:** The model must be flexible enough to allow us to define the appropriate "main comparator" as per the PBAC guidelines. This might be the current standard of care, or another medicine.
*   **Standardised Outputs for HTA:** The model should be able to generate its outputs (ICERs, CEACs, BIA tables) in a format that is directly usable in our internal reports and submissions to the PBAC.
*   **Validation Against Real-World Data:** The model's credibility would be significantly enhanced if its outputs (e.g., predicted rates of drug utilisation) could be validated against real-world PBS data for other listed medicines.

---

## Stakeholder Consultation: Australian Commonwealth Health Minister

**Date of Consultation:** 2025-07-15

### 1. What would you want from a microsimulation model on osteoarthritis?

As Health Minister, I am accountable to the public and to my cabinet colleagues. I need clear, concise, and politically relevant information to make major decisions about health funding and priorities. I don't have time for complex academic outputs.

*   **High-Level Strategic Insights:** I need a tool that can give me the "big picture". What is the future burden of osteoarthritis in Australia? What are the key drivers of cost? Where are the biggest opportunities to improve patient outcomes and get better value for the taxpayer's dollar?
*   **Clear Policy Options:** The model should be able to present me with clear, understandable "what-if" scenarios. For example: "Minister, Option A is to invest $100 million in a new preventative health program. Our modeling shows this will prevent 5,000 knee replacements over the next decade, saving the budget $150 million. Option B is to list a new drug..."
*   **Politically Relevant Outputs:** The outputs need to speak to the issues that matter to the public and the government. This means focusing on things like waiting lists for surgery, out-of-pocket costs for patients, and the overall sustainability of Medicare and the PBS.
*   **A Trustworthy Evidence Base:** When I stand up in Parliament or in front of the media to announce a new health policy, I need to be able to say that it is based on the best possible evidence. A credible, independent model like this provides a key part of that evidence base.

### 2. What are your policy questions that could be answered by a microsimulation?

My questions are about making the big strategic choices for the health portfolio.

*   **Prevention vs. Cure:** Where should I direct the next big investment in osteoarthritis? Should I be funding more research into a cure, subsidising more treatments, or investing in large-scale public health campaigns to reduce obesity and encourage exercise? I need to know the return on investment for each of these strategies.
*   **Tackling Waiting Lists:** Public hospital waiting lists for knee replacements are a major political issue. The model could be used to explore the effectiveness of different strategies to reduce these waiting lists, and to project the future demand that we need to plan for.
*   **Reducing Out-of-Pocket Costs:** Patients are concerned about rising out-of-pocket costs. The model could help us to understand the drivers of these costs and to evaluate the impact of different policies aimed at reducing the financial burden on families.
*   **What is the long-term plan for OA?** I need a long-term, strategic plan for how we are going to manage this growing chronic disease. The model can provide the evidence base for a 10-20 year national strategy for osteoarthritis.

### 3. What improvements would you like from the model?

*   **An "Executive Dashboard" Output:** I need a one-page summary. This should have key metrics presented in clear, graphical formats: projected number of Australians with OA, total annual cost to the government, average out-of-pocket cost per patient, projected number of knee replacements.
*   **Clear Communication of Uncertainty:** I need to understand the risks. When the model gives me a projection, it should also give me a best-case and worst-case scenario, so I understand the range of possible outcomes.
*   **Ability to Model Election Commitments:** My team needs to be able to use the model to quickly cost and evaluate the potential impact of new policy ideas or election commitments during a campaign or budget process. This means the model needs to be agile and responsive.
*   **Focus on "The Why":** The model needs to help me explain *why* we are making a particular policy decision. The outputs should be framed as a narrative that I can use to communicate the benefits of our policies to the public. For example, "We are investing in this new program because our modeling shows it will mean 10,000 fewer Australians will need surgery, and they will be able to stay in the workforce for longer."

---

## Stakeholder Consultation: Consumer with Osteoarthritis

**Date of Consultation:** 2025-07-15

### 1. What would you want from a microsimulation model on osteoarthritis?

I'm not a scientist, but I live with this disease every day. I want a tool that can help doctors and the government understand what it's really like for us and make decisions that actually help.

*   **Focus on What Matters to Us:** It's not about x-ray results. It's about my pain, my ability to walk to the shops, to play with my grandkids, to sleep through the night. I want the model to be based on these real-life things.
*   **A Crystal Ball:** I want to know what my future might look like. If I lose 10 kilos, what difference will that really make to my pain in 5 years? If I start this new drug, what are the chances it will help me avoid a knee replacement? The model could be used to create personalized forecasts that my doctor could discuss with me.
*   **Fairness:** I want to know that everyone is getting a fair go. It doesn't seem right if someone in the city can get a knee replacement in 3 months, but I have to wait 2 years because I live in a regional town. The model should be able to show where these inequalities are.
*   **Hope for New Treatments:** I want to see that the model is being used to properly check if new drugs and treatments are worth it, so that the best ones can be made available to us as quickly as possible.

### 2. What are your policy questions that could be answered by a microsimulation?

*   **What will reduce my out-of-pocket costs?** Seeing the GP, the specialist, the physio, the chemist... it all adds up. I want to know which policies will actually leave more money in my pocket at the end of the month.
*   **What will help me get the right treatment at the right time?** Why does it take so long to see a specialist? What can be done to shorten the waiting lists for surgery? I want the model to help find solutions to these delays.
*   **Is it better to fund physio and weight loss programs or more surgery?** I'd rather avoid surgery if I can. I want to see the government properly looking at whether it would be better to fund more allied health services to help us manage our OA without an operation.
*   **Will this new drug actually make a difference to my life?** When a new drug comes out, I want to know if it's really better than what we already have. The model should be able to show the real-world difference it would make to my pain and my ability to do things.

### 3. What improvements would you like from the model?

*   **Include Patient Voices:** When you're building the model, you should talk to people with OA to make sure it reflects our real experiences. Our priorities might be different from the doctors' priorities.
*   **Measure Things We Care About:** Don't just measure costs and QALYs. Can you measure things like "number of days unable to work" or "ability to walk 500 metres"? These are the things that have a real impact on our lives.
*   **Make the Results Understandable:** The results of the model should be explained in plain English. Create fact sheets or a website that explains what the model found and what it means for people like me.
*   **Focus on the Whole Person:** OA doesn't just affect my knees. It affects my mental health, my social life, my ability to work. A good model would try to capture some of these broader impacts.

---

## Stakeholder Consultation: Osteoarthritis Advocacy Organisation

**Date of Consultation:** 2025-07-15

### 1. What would you want from a microsimulation model on osteoarthritis?

Our mission is to advocate for the millions of Australians living with OA. We need a powerful evidence-generating tool to support our advocacy work and to hold policymakers to account.

*   **A Tool to Quantify the National Burden:** We need authoritative, up-to-date figures on the true scale of the OA problem in Australia. The model should be able to provide us with statistics on the prevalence, economic cost (including productivity losses and informal care), and the impact on quality of life.
*   **Evidence for Policy "Asks":** When we go to Canberra to ask for policy changes, we need more than just stories. We need hard data. The model should be able to directly model our policy proposals, so we can say: "Our analysis shows that investing in this program will improve the lives of X hundred thousand people and save the economy Y billion dollars."
*   **A Platform to Highlight Inequities:** The model must be able to shine a light on the inequities in OA care. We need to be able to clearly show the disparities in access, treatment, and outcomes based on where people live, their income, or their cultural background.
*   **A Focus on Prevention and Non-Surgical Management:** There is a massive and under-recognized gap in the support available for non-surgical OA management. We want the model to be able to demonstrate the huge potential value of investing in physiotherapy, dietetics, exercise physiology, and patient education.

### 2. What are your policy questions that could be answered by a microsimulation?

*   **What is the economic case for a National Osteoarthritis Strategy?** We can use the model to show the enormous long-term costs of inaction, and to demonstrate the significant return on investment from a coordinated, national approach to OA.
*   **How can we improve access to non-surgical care?** The model could be used to evaluate the cost-effectiveness of different policies to improve access to allied health, such as new MBS item numbers for OA-specific care plans or group sessions.
*   **What is the impact of out-of-pocket costs on patient outcomes?** We can use the model to quantify how out-of-pocket costs act as a barrier to care and lead to poorer long-term health outcomes and higher downstream costs for the government.
*   **How can we promote earlier diagnosis and intervention?** The model could be used to explore the benefits of public awareness campaigns or new screening programs aimed at identifying at-risk individuals earlier and getting them into preventative care pathways.

### 3. What improvements would you like from the model?

*   **Inclusion of Informal Care Costs:** A major cost of OA is the informal care provided by family members. The model should include a module to estimate the economic value of this informal care, as it represents a huge and often hidden part of the total burden of the disease.
*   **Outputs Designed for Advocacy:** We need outputs that are easy to use in our reports, submissions, and media releases. This means clear, compelling charts and infographics, and key "headline" statistics that are easy for the public and politicians to understand.
*   **Collaboration and Transparency:** We would want to be involved in the model's development process to ensure that it reflects the lived experience of people with OA. The model's assumptions and limitations should also be communicated clearly and transparently to maintain its credibility.
*   **Benchmarking Australia's Performance:** A future version of the model could be used to benchmark Australia's performance in OA care against other similar countries. This would be a powerful tool for advocating for improvements to our health system.

---

## Stakeholder Consultation: Family Member of Someone with Osteoarthritis

**Date of Consultation:** 2025-07-15

### 1. What would you want from a microsimulation model on osteoarthritis?

Seeing my mother struggle with OA has been really hard. It affects our whole family. I want a tool that helps decision-makers see the ripple effects of this disease.

*   **Show the Impact on Carers:** The model needs to show that it's not just the person with OA who is affected. I've had to take time off work to take my mum to appointments. My own health has been affected by the stress. The model should try to capture this "carer burden".
*   **A Better Way to Make Decisions:** It feels like we're just stumbling through the dark. The doctors say different things. I want the model to help create clearer guidelines and pathways so that families like mine know what the best options are.
*   **Information for Families:** The model's results could be used to create better information resources for families. It could help us understand what to expect, what treatments are available, and how we can best support our loved ones.
*   **Focus on Independence:** The thing we want most is for my mum to maintain her independence for as long as possible. The model should focus on outcomes that measure this – like the ability to live at home, to drive, to do her own shopping.

### 2. What are your policy questions that could be answered by a microsimulation?

*   **What support is available for carers?** The model could be used to show the value of policies that support carers, such as respite care or financial assistance. It could show that supporting carers helps the person with OA to stay at home for longer, which saves the government money on residential aged care.
*   **How can we make the home safer?** What is the value of funding home modifications, like ramps and handrails? The model could show how these small investments can prevent falls, reduce hospital admissions, and improve quality of life.
*   **What is the best way to manage pain?** I worry about the strong painkillers my mum is on. I want to know if there are safer, more effective ways to manage her pain. The model could compare the long-term outcomes of different pain management strategies.
*   **Does it matter where you live?** We live in a small town, and I know my mum doesn't have access to the same services as people in the city. I want the model to show what a difference this makes, and to help find ways to make care fairer for everyone.

### 3. What improvements would you like from the model?

*   **Include Carer Outcomes:** The model should try to measure the impact on carers. This could include things like the financial cost of caring, the impact on the carer's own health and quality of life, and the number of hours of informal care provided.
*   **Model the Impact on Aged Care:** The model should be linked to the aged care system. It should be able to show how better management of OA could reduce the number of people who need to go into residential aged care, which is a huge cost to the government and something most families want to avoid.
*   **Look at the Whole Household:** A really clever model would look at the whole household, not just the individual. How does one person's OA affect the income and health of the whole family?
*   **Translate Results into Practical Advice:** The findings should be used to create practical guides for families. For example, a guide on "How to navigate the health system with OA" or "What to expect after a knee replacement".

---

## Technical Consultation: Professor of Data Science

**Date of Consultation:** 2025-07-15

I have reviewed the structure and approach of the AUS-OA microsimulation model. My advice is predicated on the constraints that the input data must remain the same and the core language must be R.

### SWOT Analysis

**Strengths:**

*   **Microsimulation Approach:** This is a powerful, state-of-the-art technique. The ability to model individual-level heterogeneity, complex interactions, and path dependency is a significant strength compared to simpler cohort models.
*   **R-Based:** R is an excellent choice for this type of statistical modeling. It has an unparalleled ecosystem of packages for data manipulation (`dplyr`), statistics, and visualization (`ggplot2`).
*   **Probabilistic Nature:** The model's use of random draws to simulate events and progression is a robust way to capture the stochastic nature of disease and to support probabilistic sensitivity analysis.

**Weaknesses:**

*   **Static Coefficients:** The current model appears to rely on coefficients derived from regression models that are static. The relationships between variables might change over time or across different subgroups in ways that are not captured by a single set of coefficients.
*   **Data Silos:** The model logic (R scripts) is tightly coupled to the data structures (data frames). This makes it brittle. A change in one part of the code can have unforeseen consequences elsewhere.
*   **Scalability:** While R is great, base R code can be slow, especially with nested loops which are common in microsimulation. As the model complexity grows or the population size increases, performance will become a major issue.
*   **Implicit Assumptions:** Many of the model's assumptions are likely buried within the R code itself. This makes it hard to audit, validate, and update the model's logic.

**Opportunities:**

*   **Machine Learning for Progression:** Instead of using traditional regression coefficients, we could use more advanced machine learning models (e.g., Gradient Boosting Machines, Random Forests) to predict disease progression and treatment outcomes. These models can capture complex, non-linear relationships in the data, potentially leading to more accurate predictions.
*   **Dynamic Parameter Updates:** The model could be designed to dynamically update its parameters as new data becomes available. For example, it could incorporate a Bayesian framework where the model's parameters are treated as distributions that are updated over time.
*   **Cloud Computing for Scalability:** We can leverage the cloud for large-scale simulations. By containerizing the R environment (using Docker), we can easily run hundreds or thousands of simulation instances in parallel on a cloud platform like AWS or Azure. This is essential for large-scale PSA.
*   **Agent-Based Modeling (ABM):** For a truly cutting-edge model, we could move towards an agent-based model. In an ABM, the "agents" (patients) could have more complex behaviors and decision rules (e.g., based on their social network or local environment), which would allow us to model system dynamics in a more sophisticated way.

**Threats:**

*   **"Black Box" Problem:** If we use more complex machine learning models, we risk turning the simulation into a "black box". We need to use techniques from Explainable AI (XAI) (e.g., SHAP values, LIME) to ensure that we can understand and explain *why* the model is making its predictions.
*   **Technical Debt:** The current codebase, with its interconnected scripts, is accumulating technical debt. Without a significant refactoring, it will become increasingly difficult and risky to modify or extend the model in the future.
*   **Computational Cost:** More advanced methods are more computationally expensive. We need to be mindful of the trade-off between model complexity and the time and cost required to run the simulations.

### Advice for V2

1.  **Decouple Model Logic from Data:** The first and most important step is to refactor the code to separate the model's logic from the data it operates on. The model's parameters (all coefficients, transition probabilities, costs, etc.) should be stored in external, human-readable configuration files (e.g., YAML or JSON). The R code should read in this configuration at the start of a simulation run. This makes the model more transparent, flexible, and easier to update.
2.  **Explore ML for Core Processes:** For V2, I would strongly recommend replacing at least one of the core regression-based prediction modules (e.g., the OA progression module) with a machine learning model. We could train a GBM model on the same input data to predict the probability of progressing from one KL grade to the next, based on a richer set of predictor variables. We would need to use XAI techniques to ensure we can still understand the drivers of progression.
3.  **Embrace Functional Programming:** The code should be refactored to use a more functional programming style. This means writing small, pure functions that take data as input and return transformed data as output, without causing side effects. This makes the code easier to test, debug, and parallelize. The `purrr` package from the Tidyverse would be very helpful here.
4.  **Prepare for Parallelization:** The simulation should be designed from the ground up to be parallelizable. This means ensuring that each simulation run is completely independent of the others. The main simulation function should take a seed value as an argument to ensure reproducibility. This will allow us to use R's `future` or `parallel` packages to run the simulations in parallel, both locally and on the cloud.

---

## Technical Consultation: Professor of Computer Science

**Date of Consultation:** 2025-07-15

My review focuses on the computational aspects of the model, such as performance, algorithms, and data structures. The constraints of using R and the existing input data are noted.

### SWOT Analysis

**Strengths:**

*   **Vectorization:** R's greatest strength is its ability to perform vectorized operations. The use of `dplyr` and other Tidyverse tools suggests that the model is likely leveraging this for efficiency in data manipulation.
*   **Open Source:** The use of an open-source language and ecosystem is a major strength. It allows for transparency, collaboration, and access to a vast array of community-developed tools.
*   **Modularity (in theory):** The code is broken down into different files and functions. This provides a basic level of modularity, which is a good starting point.

**Weaknesses:**

*   **Performance of Loops:** The core of a microsimulation is a loop over time and a loop over individuals. In R, loops can be notoriously slow, especially if they are not implemented carefully.
*   **Memory Management:** R loads all data into memory. For a large synthetic population or a model with many state variables, this can lead to very high memory usage, potentially exceeding the capacity of a standard desktop machine.
*   **Data I/O:** The model appears to rely on reading and writing CSV files and Excel files. This is slow and inefficient for large datasets.
*   **Lack of Formal Data Structures:** The use of standard R data frames is flexible but lacks the formal structure and efficiency of more specialized data structures.

**Opportunities:**

*   **Performance Optimization with `data.table`:** The `data.table` package is a game-changer for performance in R. It is a highly efficient, in-memory data manipulation tool that is significantly faster than `dplyr` or base R for large datasets. Refactoring the core simulation loop to use `data.table` would likely provide a massive performance boost.
*   **Efficient Data Storage with Parquet:** Instead of CSVs, the model should use a more efficient, columnar data format like Apache Parquet. Parquet files are smaller, faster to read and write, and are the standard for large-scale data analysis.
*   **Code Compilation:** R code can be compiled for a performance boost. The `compiler` package (which comes with R) can be used to compile functions, and for even greater speed, key functions could be re-written in C++ and integrated using `Rcpp`.
*   **API for the Model:** We could wrap the entire simulation model in an API (e.g., using the `plumber` package). This would decouple the model's execution from the user interface, allowing us to build different front-ends (like a Shiny app or a web dashboard) that all communicate with the same, stable model backend.

**Threats:**

*   **Package Obsolescence:** The R ecosystem moves quickly. The model relies on a number of external packages, which may become outdated or unsupported over time. This creates a maintenance burden.
*   **Memory Limits:** As the desired population size or model complexity grows, we may hit a hard wall in terms of what can be done on a single machine due to R's in-memory nature.
*   **Algorithmic Complexity:** If the model's logic becomes more complex (e.g., with more interactions between agents), the computational complexity could increase exponentially, making the simulation infeasible to run.

### Advice for V2

1.  **Adopt `data.table`:** My strongest recommendation is to refactor the core data manipulation parts of the simulation to use the `data.table` package. The syntax is different from `dplyr`, but the performance gains for this type of work are undeniable. This should be the highest priority for improving the model's computational efficiency.
2.  **Use `Rcpp` for Bottlenecks:** Profile the code to identify the slowest parts of the simulation loop. These "hot spots" are prime candidates for being re-written in C++ using the `Rcpp` package. Even re-writing one or two small, critical functions in C++ can have a dramatic impact on the overall run time.
3.  **Switch to Parquet for Data I/O:** All intermediate and final data outputs should be saved in the Parquet format. The `arrow` package in R provides excellent support for this. This will make the model faster and more scalable.
4.  **Implement a Caching System:** Some calculations might be repeated unnecessarily across different simulation runs. Implement a caching system (e.g., using the `memoise` package) to store the results of computationally expensive functions, so they only need to be calculated once. This would be particularly useful in the sensitivity analysis phase.

---

## Technical Consultation: Professor of Software Engineering

**Date of Consultation:** 2025-07-15

My focus is on the process, architecture, and maintainability of the software project. A microsimulation model is a complex piece of software, and it should be treated as such.

### SWOT Analysis

**Strengths:**

*   **Existing Codebase:** There is a working model, which is a great starting point. It's much easier to refactor existing code than to start from a blank slate.
*   **Clear Purpose:** The model has a clear and important purpose, which helps to focus development efforts.
*   **Use of Git:** The project is already under version control with Git, which is a fundamental best practice.

**Weaknesses:**

*   **Lack of a Formal Architecture:** The project appears to be a collection of scripts that are sourced and run in a specific order. This is not a scalable or maintainable architecture. There is no clear separation of concerns (e.g., data access, model logic, presentation).
*   **Insufficient Testing:** While some tests have been added, the test coverage is likely very low. The tests also seem to be focused on individual functions rather than testing the behavior of the model as a whole (integration testing).
*   **Manual Project Management:** The project management seems to be manual, relying on Word documents and informal processes. This is inefficient and prone to error.
*   **Dependency Management:** The project relies on a number of R packages, but there is no robust system for managing these dependencies (e.g., `renv`). This will lead to reproducibility problems.

**Opportunities:**

*   **Adopt a Package Structure:** The entire project should be refactored into a formal R package. This is the standard way to develop and distribute R code. It provides a clear structure, helps with documentation and testing, and makes it easy for others to use the model.
*   **Continuous Integration/Continuous Deployment (CI/CD):** We can set up a CI/CD pipeline (e.g., using GitHub Actions) to automate the process of testing, building, and even deploying the model. Every time a change is pushed to the repository, the full suite of tests would be run automatically.
*   **Containerization with Docker:** The entire software environment (the specific version of R, all the required packages, and the model code itself) should be encapsulated in a Docker container. This guarantees that the model will run the same way on any machine, which is the gold standard for reproducibility.
*   **Agile Project Management:** The project should be managed using an agile methodology (like Scrum or Kanban). This would involve breaking the work down into small, manageable tasks, tracking progress on a project board (e.g., GitHub Projects), and having regular (simulated) "sprints" to deliver incremental improvements.

**Threats:**

*   **Code Rot:** Without a robust architecture and automated testing, the code will "rot" over time. It will become harder and harder to make changes without introducing new bugs.
*   **"Works on My Machine" Syndrome:** Without a proper dependency management and containerization strategy, we will constantly run into problems where the model works for one person but not for another, due to differences in their software environments.
*   **Key Person Risk:** If the model's logic is only understood by one or two people, the project is at high risk if those people leave. A well-structured, well-documented, and well-tested codebase mitigates this risk.

### Advice for V2

1.  **Refactor into an R Package:** This is the most critical step. The project should be converted into a formal R package with a standard directory structure (`R/`, `man/`, `tests/`, etc.). All functions should be properly documented using `roxygen2`. This will provide a solid foundation for all other improvements.
2.  **Implement `renv` for Dependency Management:** The `renv` package should be used to create a project-specific library of all the R packages that the model depends on. This ensures that anyone who works on the project will be using the exact same versions of all packages, which is crucial for reproducibility.
3.  **Set Up a CI/CD Pipeline with GitHub Actions:** Create a workflow in GitHub Actions that automatically runs the full `testthat` suite every time a commit is pushed to the repository. This will provide immediate feedback on whether a change has broken anything. The workflow could also build the R package and run the model on a small test case.
4.  **Use Docker for a Reproducible Environment:** Create a `Dockerfile` that defines the complete software environment for the model. This file should be version-controlled along with the rest of the code. This is the ultimate guarantee of reproducibility and makes it much easier to deploy the model on other systems (like a cloud server).
5.  **Adopt Agile Project Management:** Use a tool like GitHub Projects to create a Kanban board to manage the project's tasks. All the suggestions from these consultations should be broken down into individual "issues" or "user stories" and tracked on this board. This will provide a clear and transparent view of the project's status and priorities.

---
