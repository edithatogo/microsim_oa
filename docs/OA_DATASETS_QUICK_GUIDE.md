# Quick Guide: Most Accessible OA Datasets for AUS-OA

This guide highlights the **most accessible and immediately useful** publicly available datasets for the AUS-OA microsimulation model. Focus on datasets that are truly open access and don't require extensive approval processes.

## 🏆 **Top Priority Datasets** (Immediate Use)

### 1. **Osteoarthritis Initiative (OAI)**
- **Access Level**: ⭐⭐⭐⭐⭐ **Fully Open**
- **Data Available**: Complete dataset with 4,796 participants
- **Key Features**:
  - 8-year longitudinal follow-up
  - Clinical assessments, X-rays, MRI
  - Pain and function scores
  - Treatment data
- **URL**: https://nda.nih.gov/oai/
- **Use Case**: Primary calibration dataset for AUS-OA
- **Data Format**: Ready-to-use clinical data

### 2. **ClinicalTrials.gov**
- **Access Level**: ⭐⭐⭐⭐⭐ **Fully Open**
- **Data Available**: 10,000+ OA-related trials
- **Key Features**:
  - Treatment outcomes
  - Adverse events
  - Study protocols
  - Patient characteristics
- **URL**: https://clinicaltrials.gov/
- **Use Case**: Treatment effectiveness, safety data
- **Data Format**: Structured trial data

### 3. **NHANES (National Health and Nutrition Examination Survey)**
- **Access Level**: ⭐⭐⭐⭐⭐ **Fully Open**
- **Data Available**: Annual surveys since 1999
- **Key Features**:
  - OA symptoms and diagnoses
  - Functional limitations
  - Demographic data
  - Comorbidity information
- **URL**: https://www.cdc.gov/nchs/nhanes/
- **Use Case**: Population prevalence, risk factors
- **Data Format**: Survey data with SAS/SPSS files

### 4. **UK Biobank**
- **Access Level**: ⭐⭐⭐⭐ **Open with Registration**
- **Data Available**: 500,000+ participants
- **Key Features**:
  - OA diagnoses and progression
  - Genetic data
  - Lifestyle factors
  - Longitudinal follow-up
- **URL**: https://www.ukbiobank.ac.uk/
- **Use Case**: Genetic epidemiology, risk factors
- **Data Format**: Structured health records

### 5. **Gene Expression Omnibus (GEO)**
- **Access Level**: ⭐⭐⭐⭐⭐ **Fully Open**
- **Data Available**: 100+ OA-related studies
- **Key Features**:
  - Gene expression data
  - Microarray and RNA-seq
  - OA vs healthy tissue comparisons
- **URL**: https://www.ncbi.nlm.nih.gov/geo/
- **Use Case**: Biomarker discovery, molecular mechanisms
- **Data Format**: Raw and processed expression data

## 📊 **High-Value Secondary Datasets**

### 6. **GWAS Catalog**
- **Access Level**: ⭐⭐⭐⭐⭐ **Fully Open**
- **Data Available**: 1,000+ OA-associated variants
- **Key Features**:
  - SNP associations
  - Effect sizes
  - Population data
- **URL**: https://www.ebi.ac.uk/gwas/
- **Use Case**: Genetic risk prediction

### 7. **PubChem**
- **Access Level**: ⭐⭐⭐⭐⭐ **Fully Open**
- **Data Available**: 10,000+ OA-related compounds
- **Key Features**:
  - Chemical structures
  - Bioactivities
  - Drug-target interactions
- **URL**: https://pubchem.ncbi.nlm.nih.gov/
- **Use Case**: Drug mechanism studies

### 8. **KEGG Pathways**
- **Access Level**: ⭐⭐⭐⭐⭐ **Fully Open**
- **Data Available**: Curated OA pathways
- **Key Features**:
  - Pathway diagrams
  - Gene interactions
  - Drug targets
- **URL**: https://www.kegg.jp/
- **Use Case**: Systems biology analysis

### 9. **STRING Protein Interactions**
- **Access Level**: ⭐⭐⭐⭐⭐ **Fully Open**
- **Data Available**: OA-related protein networks
- **Key Features**:
  - Interaction networks
  - Functional associations
  - Confidence scores
- **URL**: https://string-db.org/
- **Use Case**: Network analysis of OA pathways

### 10. **DisGeNET**
- **Access Level**: ⭐⭐⭐⭐⭐ **Fully Open**
- **Data Available**: 5,000+ OA gene-disease associations
- **Key Features**:
  - Curated associations
  - Evidence levels
  - Source references
- **URL**: https://www.disgenet.org/
- **Use Case**: Gene prioritization, drug targets

## 🏥 **Clinical & Administrative Data**

### 11. **Medicare Claims (US)**
- **Access Level**: ⭐⭐⭐ **Research Use Files**
- **Data Available**: 65+ population healthcare data
- **Key Features**:
  - OA diagnoses and treatments
  - Healthcare utilization
  - Costs and outcomes
- **URL**: https://www.cms.gov/
- **Use Case**: Healthcare system analysis

### 12. **Australian AIHW Data**
- **Access Level**: ⭐⭐⭐⭐ **Public Reports + Data**
- **Data Available**: National health statistics
- **Key Features**:
  - OA prevalence and incidence
  - Healthcare utilization
  - Cost data
- **URL**: https://www.aihw.gov.au/
- **Use Case**: Australian health system modeling

### 13. **AOANJRR (Australia)**
- **Access Level**: ⭐⭐⭐ **Public Reports**
- **Data Available**: Joint replacement registry
- **Key Features**:
  - TKA procedures and revisions
  - Implant performance
  - Complication rates
- **URL**: https://aoanjrr.sahmri.com/
- **Use Case**: Surgical outcomes, revision rates

## 🔬 **Research Datasets**

### 14. **ArrayExpress**
- **Access Level**: ⭐⭐⭐⭐⭐ **Fully Open**
- **Data Available**: OA functional genomics data
- **Key Features**:
  - Transcriptomics data
  - Proteomics data
  - Epigenomics data
- **URL**: https://www.ebi.ac.uk/arrayexpress/
- **Use Case**: Multi-omics OA research

### 15. **Single Cell Portal**
- **Access Level**: ⭐⭐⭐⭐⭐ **Fully Open**
- **Data Available**: OA single-cell studies
- **Key Features**:
  - Single-cell RNA-seq data
  - Cell type identification
  - Disease-specific changes
- **URL**: https://singlecell.broadinstitute.org/
- **Use Case**: Cellular heterogeneity in OA

## 📋 **Quick Start Integration Guide**

### Step 1: Choose Your Primary Dataset
```r
# For immediate model calibration, start with OAI
# Download clinical data from: https://nda.nih.gov/oai/

# Load and inspect the data
library(data.table)
oai_data <- fread("path/to/oai_clinical_data.csv")
str(oai_data)
```

### Step 2: Data Mapping
```r
# Map OAI variables to AUS-OA format
aus_oa_data <- data.table(
  id = oai_data$ID,
  age = oai_data$AGE,
  sex = oai_data$SEX,
  bmi = oai_data$BMI,
  oa_diagnosis = oai_data$OA_STATUS,
  kl_grade = oai_data$KL_GRADE,
  pain_score = oai_data$PAIN_SCORE,
  function_score = oai_data$FUNCTION_SCORE,
  tka_status = oai_data$TKA_STATUS
)
```

### Step 3: Model Integration
```r
# Load into AUS-OA model
library(ausoa)
config <- load_config()
results <- run_simulation(
  population = aus_oa_data,
  cycles = 10,
  config = config
)
```

## 🎯 **Recommended Workflow**

1. **Start with OAI** for clinical calibration
2. **Add NHANES** for population-level validation
3. **Incorporate ClinicalTrials.gov** for treatment effects
4. **Use GWAS Catalog** for genetic risk factors
5. **Explore GEO** for molecular mechanisms

## 📞 **Getting Help**

- **AUS-OA Documentation**: See `docs/PUBLIC_OA_DATASETS.md` for complete list
- **Data Access Issues**: Check specific dataset websites for access procedures
- **Technical Support**: Contact maintainer for integration questions

---

*Last updated: September 10, 2025*

*This guide focuses on datasets that are immediately accessible for AUS-OA model development and validation.*
