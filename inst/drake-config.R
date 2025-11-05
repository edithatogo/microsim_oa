# Drake configuration file for AUS-OA microsimulation model
# Defines the workflow plan for reproducible builds

library(drake)
library(dplyr)

# Define the workflow plan
make_plan <- function() {
  # Create the main drake plan
  plan <- drake_plan(
    # Load raw data
    raw_population_data = {
      # Load the raw population data
      readr::read_csv(here::here("input", "population_data.csv"))
    },
    
    # Process population data
    processed_population = {
      # Apply data transformations
      raw_population_data %>%
        dplyr::mutate(
          age_group = cut(age, breaks = c(0, 18, 35, 50, 65, 80, Inf),
                          labels = c("0-17", "18-34", "35-49", "50-64", "65-79", "80+"))
        )
    },
    
    # Load model parameters
    model_parameters = {
      # Load parameters from config files
      yaml::read_yaml(here::here("config", "model_parameters.yaml"))
    },
    
    # Run the main simulation
    simulation_results = {
      # Execute the main simulation
      ausoa::run_simulation(
        population_data = processed_population,
        parameters = model_parameters
      )
    },
    
    # Generate summary statistics
    summary_stats = {
      # Create summary statistics from simulation results
      ausoa::calculate_summary_stats(simulation_results)
    },
    
    # Create visualization
    visualization = {
      # Generate plots from results
      ausoa::create_visualizations(summary_stats)
    },
    
    # Export final report
    report = {
      # Create final report
      ausoa::generate_report(
        results = simulation_results,
        summary = summary_stats,
        output_path = here::here("output")
      )
    }
  )
  
  return(plan)
}

# Function to run the workflow
run_workflow <- function() {
  # Load the plan
  plan <- make_plan()
  
  # Run the workflow
  drake::make(plan)
  
  # Return results
  drake::readd(report)
}

# Function to clean cache
clean_cache <- function() {
  drake::clean()
}

# Function to visualize the workflow
visualize_workflow <- function() {
  plan <- make_plan()
  drake::vis_drake_graph(plan)
}