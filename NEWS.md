# ausoa NEWS

## 2.0.1 (2025-09-10)

### New Features
- **Comprehensive Dataset Documentation**: Added extensive documentation for 50+ public OA datasets
  - `docs/DATASET_DOCUMENTATION_OVERVIEW.md`: Complete overview of dataset resources
  - `docs/OA_DATASETS_QUICK_GUIDE.md`: Quick reference for immediate dataset use
  - `docs/PUBLIC_OA_DATASETS.md`: Detailed catalog of public OA datasets
  - `docs/OA_DATASETS_SUMMARY.md`: Summary table of all datasets
  - `docs/DATA_INTEGRATION_EXAMPLES.md`: Practical integration tutorials
- **Enhanced Features Matrix**: Updated `docs/FEATURE_MATRIX_V4.md` with comprehensive feature documentation
- **External Data Integration**: Improved support for integrating public OA datasets with model calibration and validation

### Documentation Improvements
- Updated README.md with dataset documentation references
- Enhanced features matrix in README.md to reflect current capabilities
- Improved package citation and attribution information
- Added comprehensive research support documentation

### Package Maintenance
- Updated maintainer information to Dylan Mordaunt (dylan.mordaunt@vuw.ac.nz)
- Improved package metadata and citation format
- Enhanced research attribution and citation support

## 2.0.0 (2024-12-XX)

### Major Changes
- **Waiting List Module**: Implemented comprehensive waiting list dynamics with clinical prioritization, capacity constraints, and wait time impact modeling
- **Enhanced Cost Calculations**: Improved cost calculation functions with proper societal cost allocation
- **Performance Optimization**: Completed profiling and optimization of simulation code
- **Documentation**: Generated complete pkgdown documentation site with function references
- **Maintainer Update**: Dylan Mordaunt (dylan.mordaunt@vuw.ac.nz) is now the package maintainer

### Bug Fixes
- Fixed informal care cost calculation to only apply to OA patients (person 4 test case)
- Added missing waiting list parameters to regression test to prevent "argument length zero" errors
- Resolved test failures in calculate_costs_fcn and test-regression

### Testing Improvements
- All unit tests now pass (157 PASS, 0 FAIL)
- Enhanced test coverage for cost calculations and simulation regression
- Improved test reliability with proper parameter setup

### Documentation
- Complete pkgdown site generated at `docs/`
- Function reference documentation for all exported functions
- Added `docs/PUBLIC_OA_DATASETS.md`: Comprehensive guide to public OA datasets
- Added `docs/MOCK_DATA_GUIDE.md`: Explanation of mock data usage in tests
- NEWS.md updated with release notes
- **Maintainer Update**: Dylan Mordaunt (dylan.mordaunt@vuw.ac.nz) is now the package maintainer

## 2.0.0 (development)

- Plot helpers now use tidy-eval with `.data[[...]]` instead of deprecated `aes_string()`.
- Tests assert ggplot objects via `expect_s3_class()`.
- Linting narrowed to safe checks over `R/` and made CI-friendly.
- Silenced zero-length `hr_mort` warning by default (opt-in with `options(ausoa.warn_zero_length_hr_mort = TRUE)`).
- Resolved tidyselect deprecation warnings in `f_plot_distribution()`.
