# run_lintr.R
#
# Lints the project, and returns a non-zero exit code if there are any issues.

main <- function() {
  if (!require("lintr")) {
    install.packages("lintr", repos = "http://cran.us.r-project.org")
  }

  linters_to_use <- lintr::linters_with_defaults(
    line_length_linter = lintr::line_length_linter(120),
    assignment_linter = lintr::assignment_linter(),
    commas_linter = lintr::commas_linter(),
    semicolon_linter = lintr::semicolon_linter()
  )

  violations <- lintr::lint_dir(
    path = ".",
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
