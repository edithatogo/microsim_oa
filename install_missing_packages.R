# Install missing packages for AUS-OA project
packages_to_install <- c(
  "arrow",
  "covr",
  "doParallel",
  "forcats",
  "foreach",
  "fy",
  "ggplot2",
  "gt",
  "haven",
  "here",
  "janitor",
  "kableExtra",
  "lintr",
  "logr",
  "pacman",
  "party",
  "quarto",
  "readr",
  "readxl",
  "reshape2",
  "scales",
  "simPop",
  "synthpop",
  "tidyr",
  "tidyverse",
  "websocket",
  "writexl"
)

# Install packages one by one to handle errors gracefully
for (pkg in packages_to_install) {
  tryCatch({
    message(paste("Installing", pkg, "..."))
    install.packages(pkg)
    message(paste("Successfully installed", pkg))
  }, error = function(e) {
    message(paste("Failed to install", pkg, ":", e$message))
  })
}
