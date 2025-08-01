% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/simulation_cycle_fcn.R
\name{simulation_cycle_fcn}
\alias{simulation_cycle_fcn}
\title{Run a Single Microsimulation Cycle}
\usage{
simulation_cycle_fcn(
  am_curr,
  cycle.coefficents,
  am_new,
  age_edges,
  bmi_edges,
  am,
  mort_update_counter,
  lt,
  eq_cust,
  summary_TKR_observed_diff
)
}
\arguments{
\item{am_curr}{A data.frame representing the attribute matrix for the current
cycle (time \code{t}).}

\item{cycle.coefficents}{A list or data.frame of all model coefficients for
the cycle.}

\item{am_new}{A data.frame representing the attribute matrix for the next
cycle (time \code{t+1}), which will be populated by this function.}

\item{age_edges}{A numeric vector defining the break points for age categories.}

\item{bmi_edges}{A numeric vector defining the break points for BMI categories.}

\item{am}{A data.frame, presumably the full attribute matrix (used for mortality).
Note: The usage of this parameter seems unusual and might need review.}

\item{mort_update_counter}{A counter variable for the mortality loop.
Note: The usage of this parameter seems unusual and might need review.}

\item{lt}{A data.frame representing the life table used for mortality calculations.}

\item{eq_cust}{A list of data.frames containing customisation factors for
the model equations (BMI, TKR, OA).}
}
\value{
A list containing three elements:
\item{am_curr}{The \code{am_curr} data.frame with intermediate calculations.}
\item{am_new}{The fully updated \code{am_new} data.frame for the next cycle.}
\item{summ_tka_risk}{A summary data.frame of TKA risk calculations.}
}
\description{
This is the main function that drives the microsimulation for a single year (cycle).
It orchestrates the updates for BMI, osteoarthritis, comorbidities, TKA,
mortality, and other individual attributes.
}
