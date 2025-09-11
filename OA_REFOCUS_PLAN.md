# AUS-OA Repository Refocus Plan: OA Health Economics Focus

## Executive Summary

This document outlines the revised plan to refocus the AUS-OA repository on osteoarthritis (OA) health economics while preserving essential features that are actually core to OA modeling. The plan maintains ~80% of current functionality while removing only truly generic frameworks.

## Current Repository Assessment

**Total Files:** ~150
**Current Focus:** Broad health economics with OA specialization
**Issue:** Some features marked as "general" are actually core to OA economics

## Revised Feature Assessment

### ✅ KEEP: Core OA Economics Features (80% of Repository)

#### 1. Dataset Acquisition Module
**Files:** `R/dataset_acquisition.R` (336 lines)
**Status:** ✅ KEEP - Essential for OA research
- AIHW Data: Australian OA prevalence and burden data
- ABS Data: Demographic factors for OA epidemiology
- OAI Data: Gold-standard OA longitudinal research data
- NHANES/UK Biobank: Comparative OA studies

#### 2. Predictive Modeling & Machine Learning
**Files:**
- `R/predictive_modeling.R` (643 lines)
- `R/ml_framework.R` (474 lines)
**Status:** ✅ KEEP - Core OA complication prediction
- PJI Risk Modeling (Periprosthetic Joint Infection)
- DVT Risk Modeling (Deep Vein Thrombosis)
- Revision Risk Modeling (TKA revision prediction)
- OA Progression Modeling

#### 3. Public-Private Healthcare Pathways
**Files:** `R/public_private_pathways_module.R` (291 lines)
**Status:** ✅ KEEP - Critical for Australian OA economics
- TKA Surgery Pathways (Public vs Private)
- Cost Differentials in Australian healthcare
- Waiting Time Modeling for OA surgery
- Quality Outcomes by pathway

#### 4. Waiting List Dynamics
**Files:** `R/waiting_list_module.R` (298 lines)
**Status:** ✅ KEEP - Major OA health economics issue
- TKA Prioritization (Clinical urgency scoring)
- Capacity Constraints modeling
- Wait Time Impacts on QALYs and costs
- Equity Analysis in OA access

#### 5. Probabilistic Sensitivity Analysis
**Files:** `R/psa_framework.R` (357 lines)
**Status:** ✅ KEEP - Essential health economics for OA
- OA Treatment Uncertainty modeling
- Probabilistic Cost-Effectiveness Analysis
- Parameter Uncertainty quantification
- OA policy decision support

#### 6. OA-Specific Complications
**Files:**
- `R/dvt_module.R` (277 lines)
- `R/pji_module.R` (275 lines)
- `R/tka_complications_fcn.R` (content TBD)
**Status:** ✅ KEEP - Core OA post-surgical complications

#### 7. Core Simulation Engine
**Files:**
- `R/simulation_cycle_fcn.R`
- `R/OA_update_fcn.R`
- `R/TKA_update_fcn.R`
- `R/TKA_revisions_fcn.R`
**Status:** ✅ KEEP - Essential OA modeling

#### 8. Health Economics Core
**Files:**
- `R/calculate_costs_fcn.R`
- `R/calculate_qaly_fcn.R`
- `R/ceac_enhanced.R`
**Status:** ✅ KEEP - Core OA cost-effectiveness

#### 9. Tutorials (Adapted for OA Focus)
**Directories:**
- `tutorials/tutorial_01_basic_modeling/` - ✅ KEEP & ENHANCE (already OA-focused)
- `tutorials/tutorial_02_healthcare_utilization/` - ✅ KEEP & ADAPT (focus on OA utilization)
- `tutorials/tutorial_03_longitudinal_modeling/` - ✅ KEEP & ADAPT (OA progression trajectories)
- `tutorials/tutorial_04_geographic_disparities/` - ✅ KEEP & ENHANCE (OA geographic patterns)
**Status:** Adapt to emphasize OA applications

### ❌ REMOVE: Truly Generic Features (20% of Repository)

#### 1. Reinforcement Learning Framework
**Files:** `R/reinforcement_learning.R` (769 lines)
**Status:** ❌ REMOVE - Generic RL not specific to OA
**Reason:** Generic framework applicable to any disease, not OA-specific

#### 2. General Bayesian Calibration
**Files:** `R/bayesian_calibration.R` (content TBD)
**Status:** ❌ REMOVE - Generic calibration framework
**Reason:** Generic Bayesian methods, keep OA-specific parameter estimation

#### 3. Advanced Analytics (Generic)
**Files:** `R/advanced_analytics.R` (content TBD)
**Status:** ❌ REMOVE - Generic analytics framework
**Reason:** Generic statistical methods, keep OA-specific analytics

#### 4. General Comorbidities (Non-OA Related)
**Files:** `R/update_comorbidities_fcn.R` (83 lines)
**Status:** ⚠️ PARTIAL REMOVE
**Keep:** OA-related comorbidities (diabetes, cardiovascular disease)
**Remove:** Non-OA comorbidities (cancer, mental health, etc.)

## Implementation Timeline

### Phase 1: Documentation & Planning (Week 1)
- [x] Document revised feature assessment
- [x] Create implementation checklist
- [x] Update repository documentation

### Phase 2: Selective Removal (Week 2) ✅ COMPLETED
- [x] Remove reinforcement learning framework
- [x] Remove generic Bayesian calibration
- [x] Remove generic advanced analytics
- [x] Clean up non-OA comorbidities (determined to be OA-relevant)

### Phase 3: OA Enhancement (Week 3) 🔄 IN PROGRESS
- [x] Enhance OA-specific features (documentation updated)
- [ ] Adapt tutorials for OA focus
- [x] Update documentation and README (completed)
- [ ] Strengthen OA modeling capabilities

### Phase 4: Validation & Testing (Week 4)
- [ ] Test remaining OA functionality
- [ ] Validate against OA research standards
- [ ] Update package documentation
- [ ] Release focused OA version

## Expected Outcomes

### Repository Size Reduction
- **Before:** ~150 files
- **After:** ~120 files (20% reduction)
- **Preserved:** 80% of functionality (core OA economics)

### Enhanced Focus Areas
1. **OA Epidemiology:** AIHW, ABS, OAI data integration
2. **OA Complications:** PJI, DVT, revision risk modeling
3. **OA Healthcare Systems:** Public-private pathways, waiting lists
4. **OA Health Economics:** PSA, CEA, cost-effectiveness analysis
5. **OA Education:** Focused tutorials on OA applications

### Removed Generic Features
1. Generic reinforcement learning framework
2. Generic Bayesian calibration methods
3. Generic advanced analytics
4. Non-OA related comorbidities

## Quality Assurance

### Validation Criteria
- [ ] All core OA simulation functionality preserved
- [ ] OA-specific datasets and models maintained
- [ ] Health economics methods for OA kept
- [ ] Tutorials adapted for OA focus
- [ ] Documentation updated to reflect OA emphasis

### Testing Requirements
- [ ] Core OA simulation runs successfully
- [ ] OA complication models function correctly
- [ ] Health economics analyses work for OA
- [ ] Tutorials execute without errors
- [ ] Package builds and installs correctly

## Success Metrics

1. **Functionality Preserved:** 100% of core OA modeling capabilities
2. **Size Reduction:** 20% reduction in repository size
3. **Focus Enhancement:** Clear OA specialization maintained
4. **Educational Value:** Tutorials focused on OA applications
5. **Research Utility:** Enhanced OA health economics capabilities

## Risk Mitigation

### Potential Issues
1. **Over-removal:** Careful review to avoid removing OA-relevant features
2. **Functionality Loss:** Thorough testing of remaining OA capabilities
3. **Documentation Gaps:** Update all docs to reflect OA focus

### Contingency Plans
1. **Backup Branch:** Maintain full repository in separate branch
2. **Incremental Removal:** Remove features one-by-one with testing
3. **Community Feedback:** Validate changes with OA research community

---

*This plan preserves the essential OA health economics capabilities while removing only truly generic features, resulting in a more focused and maintainable repository.*</content>
<parameter name="filePath">\\wsl.localhost\Ubuntu\home\doughnut\github\aus_oa_public\OA_REFOCUS_PLAN.md
