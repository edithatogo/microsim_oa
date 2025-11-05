# Tutorial 4: Geographic Health Disparities Analysis

## Overview

This tutorial explores geographic patterns in osteoarthritis (OA) prevalence and healthcare access across Australian states and territories. You'll learn to analyze spatial health disparities, create choropleth maps, perform spatial autocorrelation analysis, and develop spatial regression models to understand how geographic factors influence health outcomes and healthcare utilization.

## Learning Objectives

By the end of this tutorial, you will be able to:

1. **Load and explore geographic health data** - Understand spatial data structures and geographic variables
2. **Analyze basic geographic patterns** - Examine health outcomes and healthcare access by state and remoteness area
3. **Create choropleth maps** - Visualize geographic health disparities using mapping techniques
4. **Perform spatial autocorrelation analysis** - Identify geographic clustering and hot spots
5. **Develop spatial regression models** - Model geographic effects on health outcomes
6. **Draw policy implications** - Understand geographic health equity and resource allocation

## Prerequisites

- Basic R programming knowledge
- Familiarity with tidyverse packages
- Understanding of statistical concepts (correlation, regression)
- Knowledge of geographic concepts (remoteness, spatial patterns)

## Required Packages

```r
install.packages(c("tidyverse", "sf", "ggplot2", "spdep", "spatialreg",
                   "leaflet", "RColorBrewer", "scales", "aus_oa_public"))
```

## Tutorial Structure

### Exercise 1: Loading and Exploring Geographic Health Data
- Load geographic health dataset
- Examine data structure and completeness
- Assess data quality by geographic variables

### Exercise 2: Basic Geographic Patterns
- Analyze state-level health outcomes
- Examine remoteness area differences
- Explore socioeconomic geographic patterns

### Exercise 3: Choropleth Mapping
- Create basic choropleth maps of health outcomes
- Map healthcare access patterns
- Visualize socioeconomic indicators geographically

### Exercise 4: Spatial Autocorrelation Analysis
- Calculate Moran's I for spatial clustering
- Identify geographic hot spots and cold spots
- Analyze spatial patterns in health outcomes

### Exercise 5: Spatial Regression Analysis
- Develop ordinary least squares regression models
- Model geographic effects on health outcomes
- Analyze healthcare access disparities

### Exercise 6: Policy Implications and Recommendations
- Analyze geographic health policy challenges
- Develop resource allocation recommendations
- Assess health equity across geographic areas

## Data Description

The tutorial uses synthetic geographic health data (`geographic_health_data.rds`) containing:

- **Patient demographics**: Age, sex, geographic location (latitude/longitude)
- **Geographic variables**: State, remoteness area, urban/rural classification
- **Socioeconomic factors**: Household income, education level, employment status, SEIFA score
- **Health outcomes**: Osteoarthritis diagnosis and severity
- **Healthcare access**: Distance to GP, specialist, and hospital services
- **Healthcare utilization**: GP visits, specialist visits, hospitalizations, total costs

## Key Geographic Concepts

### Remoteness Areas
- **Major Cities**: High population density, good healthcare access
- **Regional**: Moderate population density, variable healthcare access
- **Remote**: Low population density, limited healthcare access

### Spatial Autocorrelation
- **Moran's I**: Measures spatial clustering (values from -1 to 1)
- **Hot spots**: Areas with significantly higher than expected values
- **Cold spots**: Areas with significantly lower than expected values

### Geographic Health Disparities
- **Access disparities**: Differences in healthcare service availability
- **Outcome disparities**: Variations in health outcomes by geographic area
- **Socioeconomic disparities**: Geographic patterns in income and education

## Files in This Tutorial

```
tutorial_04_geographic_disparities/
├── tutorial_exercises.Rmd          # Main tutorial exercises
├── data/
│   └── geographic_health_data.rds  # Geographic health dataset
├── scripts/
│   ├── generate_geographic_data.R  # Data generation script
│   └── simple_generate_data.R      # Simplified data generation
├── solutions/
│   └── tutorial_04_solutions.R     # Complete solutions
└── README.md                       # This file
```

## Getting Started

1. **Set up your R environment**:
   ```r
   # Install required packages
   install.packages(c("tidyverse", "sf", "ggplot2", "spdep", "spatialreg",
                      "leaflet", "RColorBrewer", "scales"))

   # Load the aus_oa_public package
   library(aus_oa_public)
   ```

2. **Navigate to the tutorial directory**:
   ```r
   setwd("tutorials/tutorial_04_geographic_disparities")
   ```

3. **Load the tutorial data**:
   ```r
   geographic_data <- readRDS("data/geographic_health_data.rds")
   ```

4. **Open the tutorial exercises**:
   - Open `tutorial_exercises.Rmd` in RStudio
   - Work through each exercise step by step
   - Refer to `tutorial_04_solutions.R` for complete solutions

## Expected Outcomes

After completing this tutorial, you should understand:

- How geographic factors influence health outcomes
- Methods for visualizing spatial health data
- Techniques for identifying geographic health disparities
- Approaches to spatial statistical analysis
- Policy implications of geographic health patterns

## Advanced Topics for Further Study

- **Spatial econometrics**: Advanced spatial regression techniques
- **Geographic information systems (GIS)**: Professional mapping tools
- **Network analysis**: Modeling healthcare service networks
- **Real-time spatial analysis**: Using GPS and mobile health data
- **Policy evaluation**: Assessing geographic health interventions

## Troubleshooting

### Common Issues

1. **Package installation problems**:
   ```r
   # Try installing from CRAN
   install.packages("spdep")

   # Or install specific version
   install.packages("spdep", version = "1.2-8")
   ```

2. **Data loading issues**:
   ```r
   # Check file path
   list.files("data/")

   # Alternative loading method
   geographic_data <- read.csv("data/geographic_health_data.csv")
   ```

3. **Memory issues with large datasets**:
   ```r
   # Sample data for testing
   sample_data <- geographic_data[sample(nrow(geographic_data), 10000), ]
   ```

### Getting Help

- Check the solutions file for working code examples
- Review the AUS-OA package documentation
- Consult R spatial analysis resources
- Join the health economics research community

## Next Steps

After completing this tutorial:

1. **Apply these techniques** to real health data in your research
2. **Explore advanced spatial methods** for more complex analyses
3. **Consider geographic factors** in your health policy recommendations
4. **Contribute to the field** by sharing your geographic health insights

## License and Attribution

This tutorial is part of the AUS-OA Public package.
Data is synthetic and generated for educational purposes.
Based on research from the University of Melbourne Health Economics group.

---

*Happy learning! This tutorial will equip you with essential skills for geographic health disparities analysis.*
