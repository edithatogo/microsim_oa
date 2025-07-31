library(readxl)
tka_time_trend <- read_excel("input/scenarios/ausoa_input_public.xlsx",
                               sheet = "TKA utilisation",
                               range = "A53:I94"
  )
print(tka_time_trend)
