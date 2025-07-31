# scripts/analyze_profile.R

# Define the output file for the profiling data
prof_out_file <- here::here("output", "log", "profiling_output.out")

# Analyze the profiling data and print the results
prof_summary <- summaryRprof(prof_out_file)
print(prof_summary)