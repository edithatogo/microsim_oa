# Data Integration Examples: Using Public OA Datasets with AUS-OA

This document provides practical examples of how to integrate publicly available OA datasets with the AUS-OA microsimulation model.

## Example 1: Osteoarthritis Initiative (OAI) Integration

### Step 1: Download OAI Data
```r
# Visit: https://nda.nih.gov/oai/
# Download clinical datasets:
# - allclinical00.csv (baseline clinical data)
# - allclinical01.csv (year 1 follow-up)
# - allclinical02.csv (year 2 follow-up)
# - ... up to year 8
```

### Step 2: Data Preparation
```r
library(data.table)
library(dplyr)

# Load baseline clinical data
oai_baseline <- fread("allclinical00.csv")

# Select relevant variables for AUS-OA
aus_oa_baseline <- oai_baseline %>%
  select(
    ID,                    # Patient ID
    AGE,                   # Age
    SEX,                   # Gender (1=Male, 2=Female)
    BMI = V00BMI,         # BMI
    HEIGHT = V00HEIGHT,   # Height (cm)
    WEIGHT = V00WEIGHT,   # Weight (kg)
    RACE,                  # Race/ethnicity
    EDUCATION,             # Education level
    EMPLOYMENT,            # Employment status
    INCOME,                # Income level
    SMOKING,               # Smoking status
    PAIN = V00WOMKP,      # WOMAC pain score
    FUNCTION = V00WOMKF,  # WOMAC function score
    STIFFNESS = V00WOMKS, # WOMAC stiffness score
    KL_GRADE_R = V00XRKL, # Kellgren-Lawrence grade (right knee)
    KL_GRADE_L = V00XLKL  # Kellgren-Lawrence grade (left knee)
  ) %>%
  mutate(
    # Convert to AUS-OA format
    sex = ifelse(SEX == 1, "Male", "Female"),
    oa_diagnosis = ifelse(KL_GRADE_R >= 2 | KL_GRADE_L >= 2, 1, 0),
    kl_grade = pmax(KL_GRADE_R, KL_GRADE_L, na.rm = TRUE),
    pain_score = PAIN / 20 * 10,  # Convert WOMAC (0-20) to 0-10 scale
    function_score = (100 - FUNCTION) / 100 * 100,  # Convert to 0-100 scale
    tka_status = 0,  # Will be updated from follow-up data
    comorbidity_count = 0  # Placeholder
  ) %>%
  select(
    id = ID,
    age = AGE,
    sex,
    bmi = BMI,
    oa_diagnosis,
    kl_grade,
    pain_score,
    function_score,
    tka_status,
    comorbidity_count
  )

# Save processed data
fwrite(aus_oa_baseline, "oai_baseline_aus_oa.csv")
```

### Step 3: Longitudinal Data Integration
```r
# Load follow-up data to track TKA procedures
oai_followup <- fread("allclinical08.csv")  # Year 8 data

# Extract TKA information
tka_data <- oai_followup %>%
  select(
    ID,
    TKA_R = V08XRSURG,    # Right knee surgery
    TKA_L = V08XLSURG,    # Left knee surgery
    TKA_DATE_R = V08XRSDT, # Surgery date right
    TKA_DATE_L = V08XLSDT  # Surgery date left
  ) %>%
  mutate(
    tka_status = ifelse(TKA_R == 1 | TKA_L == 1, 1, 0),
    tka_year = case_when(
      TKA_R == 1 ~ as.numeric(substr(TKA_DATE_R, 1, 4)),
      TKA_L == 1 ~ as.numeric(substr(TKA_DATE_L, 1, 4)),
      TRUE ~ NA_real_
    )
  ) %>%
  select(id = ID, tka_status, tka_year)

# Merge with baseline data
aus_oa_complete <- aus_oa_baseline %>%
  left_join(tka_data, by = "id") %>%
  mutate(
    tka_status = coalesce(tka_status.y, tka_status.x),
    revi = 0  # Placeholder for revision data
  ) %>%
  select(-tka_status.x, -tka_status.y)
```

### Step 4: AUS-OA Model Integration
```r
library(ausoa)

# Load configuration
config <- load_config()

# Run simulation with OAI data
results <- run_simulation(
  population = aus_oa_complete,
  cycles = 20,
  config = config
)

# Generate summary statistics
summary_stats <- OA_summary_fcn(results$final_population)

# Plot results
f_plot_trend_overall(summary_stats, "oa_prevalence")
f_plot_trend_age_sex(summary_stats, "tka_incidence")
```

## Example 2: NHANES Integration

### Step 1: Download NHANES Data
```r
# Visit: https://www.cdc.gov/nchs/nhanes/
# Download datasets:
# - Demographics (DEMO)
# - Medical Conditions (MCQ)
# - Body Measures (BMX)
# - Physical Functioning (PFQ)
```

### Step 2: Data Processing
```r
# Load NHANES datasets
demo <- fread("DEMO.csv")      # Demographics
mcq <- fread("MCQ.csv")        # Medical conditions
bmx <- fread("BMX.csv")        # Body measures
pfq <- fread("PFQ.csv")        # Physical functioning

# Merge datasets
nhanes_data <- demo %>%
  left_join(mcq, by = "SEQN") %>%
  left_join(bmx, by = "SEQN") %>%
  left_join(pfq, by = "SEQN")

# Extract OA-related variables
aus_oa_nhanes <- nhanes_data %>%
  select(
    SEQN,                  # Respondent ID
    RIDAGEYR,             # Age in years
    RIAGENDR,             # Gender
    BMXBMI,               # BMI
    MCQ160F,              # Arthritis diagnosis
    MCQ160B,              # Age at arthritis diagnosis
    MCQ160C,              # Which joints affected
    PFQ061B,              # Difficulty walking
    PFQ061C,              # Difficulty bending/stooping
    PFQ061D               # Difficulty standing
  ) %>%
  mutate(
    id = as.character(SEQN),
    age = RIDAGEYR,
    sex = ifelse(RIAGENDR == 1, "Male", "Female"),
    bmi = BMXBMI,
    oa_diagnosis = ifelse(MCQ160F == 1, 1, 0),
    kl_grade = NA,  # Not available in NHANES
    pain_score = NA, # Not directly available
    function_score = case_when(
      PFQ061B == 1 | PFQ061C == 1 | PFQ061D == 1 ~ 60,  # Some difficulty
      PFQ061B == 2 | PFQ061C == 2 | PFQ061D == 2 ~ 30,  # Much difficulty
      PFQ061B == 3 | PFQ061C == 3 | PFQ061D == 3 ~ 10,  # Unable to do
      TRUE ~ 100  # No difficulty
    ),
    tka_status = 0,  # Not available
    comorbidity_count = 0  # Placeholder
  ) %>%
  select(
    id, age, sex, bmi, oa_diagnosis,
    kl_grade, pain_score, function_score,
    tka_status, comorbidity_count
  ) %>%
  filter(!is.na(age), !is.na(sex), !is.na(bmi))
```

## Example 3: ClinicalTrials.gov Integration

### Step 1: Download Trial Data
```r
# Visit: https://clinicaltrials.gov/
# Search for: "osteoarthritis knee"
# Download results as CSV
```

### Step 2: Extract Treatment Effects
```r
# Load clinical trials data
trials <- fread("clinical_trials_oa.csv")

# Extract relevant trials
oa_trials <- trials %>%
  filter(
    grepl("osteoarthritis", Conditions, ignore.case = TRUE),
    grepl("knee", Conditions, ignore.case = TRUE),
    grepl("Completed", Status)
  )

# Extract treatment information
treatment_data <- oa_trials %>%
  select(
    NCT_Number,
    Title,
    Interventions,
    Primary_Outcome,
    Enrollment,
    Start_Date,
    Completion_Date
  )

# Parse intervention types
treatment_effects <- treatment_data %>%
  mutate(
    intervention_type = case_when(
      grepl("placebo", Interventions, ignore.case = TRUE) ~ "placebo",
      grepl("NSAID", Interventions, ignore.case = TRUE) ~ "nsaid",
      grepl("chondroitin", Interventions, ignore.case = TRUE) ~ "chondroitin",
      grepl("glucosamine", Interventions, ignore.case = TRUE) ~ "glucosamine",
      grepl("exercise", Interventions, ignore.case = TRUE) ~ "exercise",
      grepl("physical therapy", Interventions, ignore.case = TRUE) ~ "physical_therapy",
      TRUE ~ "other"
    )
  )

# Calculate average effects by intervention type
intervention_summary <- treatment_effects %>%
  group_by(intervention_type) %>%
  summarise(
    n_trials = n(),
    avg_enrollment = mean(Enrollment, na.rm = TRUE),
    completion_rate = sum(grepl("Completed", Status)) / n()
  )
```

## Example 4: GWAS Catalog Integration

### Step 1: Download GWAS Data
```r
# Visit: https://www.ebi.ac.uk/gwas/
# Search for: "osteoarthritis"
# Download associations
```

### Step 2: Process Genetic Data
```r
# Load GWAS associations
gwas_data <- fread("gwas_associations_oa.tsv")

# Filter for high-confidence associations
oa_snps <- gwas_data %>%
  filter(
    grepl("osteoarthritis", `DISEASE/TRAIT`, ignore.case = TRUE),
    P.VALUE < 1e-6,  # Genome-wide significance
    !is.na(OR.or.BETA)  # Has effect size
  ) %>%
  select(
    SNP = SNPS,
    CHR_ID,
    CHR_POS,
    `DISEASE/TRAIT`,
    P.VALUE,
    OR = OR.or.BETA,
    SE = SE,
    RISK_ALLELE = RISK.ALLELE,
    RISK_ALLELE_FREQ = RISK.ALLELE.FREQ
  )

# Create genetic risk score components
genetic_risk_factors <- oa_snps %>%
  mutate(
    risk_score_weight = -log10(P.VALUE) * sign(log(OR)),
    gene_region = case_when(
      CHR_ID == 1 ~ "Chromosome 1",
      CHR_ID == 2 ~ "Chromosome 2",
      # Add more chromosome mappings as needed
      TRUE ~ paste("Chromosome", CHR_ID)
    )
  ) %>%
  select(SNP, CHR_ID, CHR_POS, OR, risk_score_weight, gene_region)
```

## Example 5: GEO Data Integration

### Step 1: Download Expression Data
```r
# Visit: https://www.ncbi.nlm.nih.gov/geo/
# Search for: "osteoarthritis cartilage"
# Download series matrix files
```

### Step 2: Process Gene Expression Data
```r
library(limma)
library(Biobase)

# Load GEO data (example with simulated data structure)
# In practice, you would use GEOquery package
geo_data <- fread("GSE12345_series_matrix.txt", skip = 60)  # Skip headers

# Process expression data
expression_matrix <- as.matrix(geo_data[, -1])  # Remove probe IDs
rownames(expression_matrix) <- geo_data$ID_REF

# Create phenotype data
pheno_data <- data.frame(
  sample_id = colnames(expression_matrix),
  oa_status = c(rep("OA", 10), rep("Normal", 10)),  # Example grouping
  age = sample(45:85, 20, replace = TRUE),
  sex = sample(c("Male", "Female"), 20, replace = TRUE)
)

# Create ExpressionSet object
eset <- ExpressionSet(
  assayData = expression_matrix,
  phenoData = AnnotatedDataFrame(pheno_data)
)

# Differential expression analysis
design <- model.matrix(~ oa_status + age + sex, data = pData(eset))
fit <- lmFit(eset, design)
fit <- eBayes(fit)

# Extract top differentially expressed genes
top_genes <- topTable(fit, coef = "oa_statusOA", n = 100)
```

## Integration with AUS-OA Configuration

### Step 1: Update Model Parameters
```r
# Load base configuration
config <- load_config()

# Update parameters based on integrated data
config$coefficients$progression_rate <- list(
  baseline = 0.02,  # From OAI longitudinal data
  age_effect = 0.001,  # From NHANES age analysis
  bmi_effect = 0.005   # From OAI BMI associations
)

# Update treatment effects from clinical trials
config$interventions$chondroitin <- list(
  pain_reduction = 0.3,      # From meta-analysis
  function_improvement = 0.2,
  duration_months = 6
)

# Save updated configuration
yaml::write_yaml(config, "config/updated_config.yaml")
```

### Step 2: Validation Against External Data
```r
# Compare model outputs with external benchmarks
validation_results <- validate_model(
  model_results = results,
  external_data = nhanes_data,
  metrics = c("prevalence", "incidence", "treatment_rates")
)

# Generate validation report
validation_report <- generate_validation_report(
  validation_results,
  output_file = "validation_report.html"
)
```

## Best Practices for Data Integration

### 1. Data Quality Assessment
```r
# Check for missing data patterns
missing_summary <- aus_oa_data %>%
  summarise_all(~ sum(is.na(.))) %>%
  gather(variable, missing_count) %>%
  mutate(missing_percent = missing_count / nrow(aus_oa_data) * 100)

# Visualize missing data
library(ggplot2)
ggplot(missing_summary, aes(x = reorder(variable, missing_percent),
                           y = missing_percent)) +
  geom_bar(stat = "identity") +
  coord_flip() +
  labs(title = "Missing Data by Variable",
       x = "Variable", y = "Missing (%)")
```

### 2. Cross-Validation
```r
# Split data for training/validation
set.seed(123)
train_indices <- sample(1:nrow(aus_oa_data), 0.7 * nrow(aus_oa_data))
train_data <- aus_oa_data[train_indices, ]
validation_data <- aus_oa_data[-train_indices, ]

# Train model on subset
model_fit <- calibrate_model(
  training_data = train_data,
  config = config
)

# Validate on held-out data
validation_metrics <- validate_model(
  model = model_fit,
  validation_data = validation_data
)
```

### 3. Sensitivity Analysis
```r
# Test model sensitivity to different data sources
sensitivity_results <- list()

for (data_source in c("OAI", "NHANES", "ClinicalTrials")) {
  # Load different datasets
  test_data <- load_dataset(data_source)

  # Run simulation
  results <- run_simulation(
    population = test_data,
    cycles = 10,
    config = config
  )

  # Store results
  sensitivity_results[[data_source]] <- results
}

# Compare results across data sources
comparison_plot <- compare_sensitivity_results(sensitivity_results)
```

## Troubleshooting Common Issues

### Issue 1: Variable Name Mismatches
```r
# Standardize variable names across datasets
variable_mapping <- list(
  "AGE" = "age",
  "SEX" = "sex",
  "BMI" = "bmi",
  "OA_DIAGNOSIS" = "oa_diagnosis",
  "PAIN_SCORE" = "pain_score",
  "FUNCTION_SCORE" = "function_score"
)

# Apply mapping
standardized_data <- rename_variables(
  data = raw_data,
  mapping = variable_mapping
)
```

### Issue 2: Missing Data Handling
```r
# Multiple imputation for missing values
library(mice)

# Identify variables with missing data
missing_vars <- names(aus_oa_data)[colSums(is.na(aus_oa_data)) > 0]

# Perform imputation
imputed_data <- mice(
  aus_oa_data[, missing_vars],
  m = 5,  # Number of imputations
  method = "pmm"  # Predictive mean matching
)

# Extract completed dataset
complete_data <- complete(imputed_data, 1)
```

### Issue 3: Data Scale Harmonization
```r
# Harmonize different scales across datasets
harmonize_scales <- function(data) {
  data %>%
    mutate(
      # Convert WOMAC pain (0-20) to 0-10 scale
      pain_score = if("pain_womac" %in% names(.)) {
        pain_womac / 20 * 10
      } else {
        pain_score
      },

      # Convert SF-36 physical function (0-100) to 0-100 scale
      function_score = if("sf36_pf" %in% names(.)) {
        sf36_pf
      } else {
        function_score
      }
    )
}
```

## Resources and Further Reading

- **AUS-OA Documentation**: See main package documentation
- **Data Integration Guidelines**: Refer to `docs/PUBLIC_OA_DATASETS.md`
- **Statistical Methods**: See `docs/STATISTICAL_METHODS.md`
- **Validation Framework**: See `docs/VALIDATION_FRAMEWORK.md`

---

*This document provides practical examples for integrating public OA datasets with the AUS-OA microsimulation model. For specific technical questions, contact the package maintainer.*
