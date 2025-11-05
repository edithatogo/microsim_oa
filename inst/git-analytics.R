# Git analytics for AUS-OA repository
# Using gert for Git operations analytics (equivalent to gitpandas concept)

library(gert)
library(dplyr)

# Function to analyze Git history and generate statistics
analyze_git_history <- function(repo_path = ".") {
  # Get commit history
  commits <- git_log(repo = repo_path, max_count = 1000)
  
  # Create a data frame with commit information
  commit_df <- data.frame(
    hash = sapply(commits, function(x) x$hash),
    author = sapply(commits, function(x) x$author$name),
    author_email = sapply(commits, function(x) x$author$email),
    date = sapply(commits, function(x) x$author$time),
    message = sapply(commits, function(x) x$message),
    stringsAsFactors = FALSE
  )
  
  # Convert date to proper format
  commit_df$date <- as.POSIXct(commit_df$date, origin = "1970-01-01")
  
  # Calculate basic statistics
  stats <- list(
    total_commits = nrow(commit_df),
    unique_authors = length(unique(commit_df$author)),
    first_commit = min(commit_df$date),
    latest_commit = max(commit_df$date),
    commit_frequency = table(format(commit_df$date, "%Y-%m")),
    top_authors = sort(table(commit_df$author), decreasing = TRUE)[1:5]
  )
  
  return(list(data = commit_df, stats = stats))
}

# Function to analyze file changes
analyze_file_changes <- function(repo_path = ".") {
  # Get list of all files in the repo
  all_files <- list.files(repo_path, recursive = TRUE)
  r_files <- all_files[grep("\\.(R|r)$", all_files)]
  
  # For each R file, get change statistics
  file_stats <- data.frame(
    file_path = r_files,
    lines_of_code = NA,
    last_modified = NA,
    stringsAsFactors = FALSE
  )
  
  # Calculate basic file metrics
  for (i in seq_along(r_files)) {
    full_path <- file.path(repo_path, r_files[i])
    if (file.exists(full_path)) {
      # Count lines of code
      file_content <- readLines(full_path, warn = FALSE)
      file_stats$lines_of_code[i] <- sum(nchar(file_content) > 0)  # Non-empty lines
      
      # Get last modified time
      file_stats$last_modified[i] <- file.mtime(full_path)
    }
  }
  
  return(file_stats)
}

# Function to generate a development activity report
generate_dev_report <- function(repo_path = ".") {
  # Get Git history analysis
  git_analysis <- analyze_git_history(repo_path)
  file_analysis <- analyze_file_changes(repo_path)
  
  # Calculate monthly activity
  monthly_activity <- git_analysis$data %>%
    mutate(month = format(date, "%Y-%m")) %>%
    group_by(month) %>%
    summarise(
      commits = n(),
      authors = n_distinct(author),
      .groups = 'drop'
    ) %>%
    arrange(desc(month))
  
  # Create report
  report <- list(
    git_stats = git_analysis$stats,
    monthly_activity = monthly_activity,
    file_summary = list(
      total_files = nrow(file_analysis),
      total_lines = sum(file_analysis$lines_of_code, na.rm = TRUE),
      largest_files = head(file_analysis[order(file_analysis$lines_of_code, decreasing = TRUE), ], 10)
    )
  )
  
  return(report)
}

# Function to check git status
check_git_status <- function(repo_path = ".") {
  status <- git_status(repo = repo_path)
  
  # Check for uncommitted changes
  has_changes <- length(status$staged) > 0 || length(status$unstaged) > 0 || length(status$untracked) > 0
  
  return(list(
    clean = !has_changes,
    staged_files = status$staged,
    unstaged_files = status$unstaged,
    untracked_files = status$untracked
  ))
}

# Example usage:
# report <- generate_dev_report(".") 
# print(paste("Total commits:", report$git_stats$total_commits))
# print(paste("Unique authors:", report$git_stats$unique_authors))