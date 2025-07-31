# inspect_am_curr.R
am_curr_after_oa <- readRDS("am_curr_after_oa.rds")
am_curr <- am_curr_after_oa$am_curr
str(am_curr)
summary(am_curr)
sapply(am_curr, function(x) sum(is.na(x)))
