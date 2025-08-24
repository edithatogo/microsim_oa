#' Initialize KL Grades
#'
#' This function initializes the Kellgren-Lawrence (KL) grades for the population
#' based on their osteoarthritis (OA) status.
#'
#' @param am A data.frame of the attribute matrix.
#' @param utilities A list of utility coefficients.
#' @param initial_kl_grades A list of initial KL grade probabilities.
#' @return A data.frame with the attribute matrix updated with KL grades.
#' @export
#' @export
#' @export
initialize_kl_grades <- function(am, utilities, initial_kl_grades) {
  # % add KL levels
  am$kl0 <- ifelse(am$oa == 1, 1, 0)

  # kl = zeros(n,1);
  # randkl = rand(n,1);
  randkl <- runif(nrow(am), 0, 1)

  # am.kl2 = kl;
  # am.kl3 = kl;
  # am.kl4 = kl;

  am$kl2 <- 0
  am$kl3 <- 0
  am$kl4 <- 0

  Prob_KL2 <- initial_kl_grades$p_KL2init
  Prob_KL3 <- initial_kl_grades$p_KL3init

  print("Prob_KL2:")
  print(Prob_KL2)
  print("Prob_KL3:")
  print(Prob_KL3)

  # allocate to KL levels based on random number and OA status
  am$kl4[randkl > (Prob_KL2 + Prob_KL3)] <- am$oa[randkl > (Prob_KL2 + Prob_KL3)]
  am$kl3[(randkl > Prob_KL2) & (randkl <= (Prob_KL2 + Prob_KL3))] <-
    am$oa[(randkl > Prob_KL2) & (randkl <= (Prob_KL2 + Prob_KL3))]
  am$kl2[randkl <= Prob_KL2] <- am$oa[randkl <= Prob_KL2]

  # set impcat of KL levels on SF6D
  am$sf6d <- 1
  am$sf6d <- am$sf6d - (utilities$kl_grades$kl4 * am$kl4)
  am$sf6d <- am$sf6d - (utilities$kl_grades$kl3 * am$kl3)
  am$sf6d <- am$sf6d - (utilities$kl_grades$kl2 * am$kl2)

  # am.kl_score = kl;
  # am.kl_score = am.kl_score + 2.*am.kl2 + 3.*am.kl3 + 4.*am.kl4;
  am$kl_score <- 0
  am$kl_score <- am$kl_score + 2 * am$kl2 + 3 * am$kl3 + 4 * am$kl4

  return(am)
}
