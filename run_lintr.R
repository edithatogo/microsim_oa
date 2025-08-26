# run_lintr.R
#
# Lints the project, and returns a non-zero exit code if there are any issues.

main <- function() {
  if (!require("lintr")) {
    install.packages("lintr", repos = "http://cran.us.r-project.org")
  }

  # Pragmatic, CI-friendly linters focusing on safe, non-invasive checks
  linters_to_use <- lintr::linters_with_defaults(
    # Keep a minimal, low-noise set
    commas_linter = lintr::commas_linter(),
    semicolon_linter = lintr::semicolon_linter(),
    trailing_whitespace_linter = lintr::trailing_whitespace_linter(),
    trailing_blank_lines_linter = lintr::trailing_blank_lines_linter(),
    # Disable noisy/invasive linters for now
  return_linter = NULL,
    line_length_linter = NULL,
    infix_spaces_linter = NULL,
    quotes_linter = NULL,
    object_name_linter = NULL,
    object_usage_linter = NULL,
    commented_code_linter = NULL,
    indentation_linter = NULL,
    pipe_continuation_linter = NULL,
    object_length_linter = NULL
  )

  # Lint only package source for now; skip scripts/tests/docs/renv
  violations <- lintr::lint_dir(
    path = "R",
    linters = linters_to_use,
    exclusions = list("renv", "packrat")
  )

  if (length(violations) > 0) {
    print(violations)
    quit(status = 1)
  } else {
    print("No linting violations found.")
    quit(status = 0)
  }
}

main()
