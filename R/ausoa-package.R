#' Ausoa: A Microsimulation Model of Osteoarthritis in Australia
#'
#' @description
#' The AUS-OA package implements a dynamic discrete time microsimulation model 
#' specifically designed for osteoarthritis (OA) health economics and policy 
#' evaluation in Australia. It provides policymakers and researchers with 
#' advanced capacity to evaluate the clinical, economic, and quality-of-life 
#' impacts of OA interventions across Australia.
#'
#' @details
#' The package provides:
#' \itemize{
#'   \item Core simulation engine for OA progression modeling
#'   \item TKA (Total Knee Arthroplasty) and revision surgery modeling
#'   \item OA-specific complication modeling (PJI, DVT, etc.)
#'   \item Australian healthcare system modeling for cost-effectiveness
#'   \item QALY calculation (SF-6D) for OA-specific outcomes
#'   \item Data integration capabilities for multiple OA datasets
#'   \item Public vs private OA treatment pathway analysis
#'   \item OA surgery waiting list dynamics modeling
#'   \item OA intervention policy lever controls
#' }
#'
#' @section Core Functions:
#' The main functions for running simulations include:
#' \itemize{
#'   \item \code{\link{simulation_cycle_fcn}} - Main simulation cycle function
#'   \item \code{\link{calculate_costs_fcn}} - Cost calculation engine
#'   \item \code{\link{calculate_qaly}} - Quality-adjusted life year calculation
#'   \item \code{\link{apply_interventions}} - Apply policy interventions
#'   \item \code{\link{load_config}} - Load configuration files
#' }
#'
#' @section Data Integration:
#' The package supports integration with public OA datasets:
#' \itemize{
#'   \item Osteoarthritis Initiative (OAI) for clinical calibration
#'   \item NHANES for population-level validation
#'   \item AIHW OA Prevalence Data
#'   \item ABS Demographic Data for OA Epidemiology
#' }
#'
#' @seealso 
#' \code{\link{simulation_cycle_fcn}}, \code{\link{calculate_costs_fcn}}, 
#' \code{\link{calculate_qaly}}, \code{\link{apply_interventions}}
#'
#' @keywords internal
"_PACKAGE"
#' @name ausoa-package
#' @aliases ausoa
NULL