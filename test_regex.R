library(stringi)
test_string <- "Male[1]"
corrected_string <- stri_replace_all_regex(test_string, "\\[[0-9]+\\]", "")
print(corrected_string)

