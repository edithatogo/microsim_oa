pkgname <- "ausoa"
source(file.path(R.home("share"), "R", "examples-header.R"))
options(warn = 1)
library('ausoa')

base::assign(".oldSearch", base::search(), pos = 'CheckExEnv')
base::assign(".old_wd", base::getwd(), pos = 'CheckExEnv')
cleanEx()
nameEx("apply_policy_levers")
### * apply_policy_levers

flush(stderr()); flush(stdout())

### Name: apply_policy_levers
### Title: Apply Policy Levers to Model Parameters
### Aliases: apply_policy_levers

### ** Examples

# params <- load_config("config/coefficients.yaml")
# sim_config <- load_config("config/simulation.yaml")
# modified_params <- apply_policy_levers(params, sim_config$policy_levers)



### * <FOOTER>
###
cleanEx()
options(digits = 7L)
base::cat("Time elapsed: ", proc.time() - base::get("ptime", pos = 'CheckExEnv'),"\n")
grDevices::dev.off()
###
### Local variables: ***
### mode: outline-minor ***
### outline-regexp: "\\(> \\)?### [*]+" ***
### End: ***
quit('no')
