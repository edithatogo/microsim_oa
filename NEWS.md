# ausoa NEWS

## 2.0.0 (development)

- Plot helpers now use tidy-eval with `.data[[...]]` instead of deprecated `aes_string()`.
- Tests assert ggplot objects via `expect_s3_class()`.
- Linting narrowed to safe checks over `R/` and made CI-friendly.
- Silenced zero-length `hr_mort` warning by default (opt-in with `options(ausoa.warn_zero_length_hr_mort = TRUE)`).
- Resolved tidyselect deprecation warnings in `f_plot_distribution()`.
