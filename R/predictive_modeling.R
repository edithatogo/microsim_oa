#' Predictive Modeling for Patient Outcomes
#'
#' This module implements machine learning models for predicting patient outcomes
#' in the AUS-OA microsimulation model, including complication risks and treatment responses.
#'
#' Key Functions:
#' - predict_complication_risk(): ML models for PJI, DVT, revision risks
#' - predict_treatment_response(): Personalized treatment effectiveness
#' - create_risk_stratification(): Patient clustering for risk groups
#' - validate_predictions(): Model performance assessment

#' Predict Complication Risk Using ML Models
#'
#' @param patient_data Patient characteristics and treatment data
#' @param complication_type Type of complication ("pji", "dvt", "revision")
#' @param ml_config ML configuration
#' @return Risk predictions with uncertainty estimates
predict_complication_risk <- function(patient_data, complication_type = "pji", ml_config) {

  # Load ML framework
  source("R/ml_framework.R")

  # Prepare features
  # Handle different config structures
  if ("coefficients" %in% names(ml_config)) {
    feature_config <- ml_config$coefficients$ml
  } else {
    feature_config <- ml_config
  }

  feature_pipeline <- create_feature_pipeline(patient_data, feature_config)
  features <- feature_pipeline$feature_matrix

  # Define outcome based on complication type
  outcome_var <- switch(complication_type,
                       "pji" = "pji_risk",
                       "dvt" = "dvt_risk",
                       "revision" = "revision_risk",
                       stop("Unknown complication type"))

  # Check if outcome data exists
  if (!(outcome_var %in% colnames(patient_data))) {
    warning("Outcome variable ", outcome_var, " not found in data. Using synthetic data for demonstration.")
    # Create synthetic outcome for demonstration
    set.seed(12345)
    patient_data[[outcome_var]] <- rbinom(nrow(patient_data), 1, 0.05)  # 5% baseline risk
  }

  # Prepare training data
  training_data <- list(
    feature_matrix = features,
    processed_data = patient_data
  )

  # Train predictive models
  message("Training ML models for ", complication_type, " risk prediction...")
  trained_models <- train_predictive_models(training_data, outcome_var, ml_config)

  # Generate predictions
  predictions <- list()

  for (model_name in names(trained_models$models)) {
    model <- trained_models$models[[model_name]]

    if (model_name == "ensemble") {
      pred <- model$predictions
    } else {
      pred <- predict(model, newdata = features)
    }

    predictions[[model_name]] <- pred
  }

  # Calculate prediction uncertainty
  prediction_stats <- calculate_prediction_uncertainty(predictions, patient_data[[outcome_var]])

  # Risk stratification
  risk_groups <- create_risk_stratification(predictions$ensemble, n_groups = 3)

  return(list(
    predictions = predictions,
    trained_models = trained_models,
    prediction_stats = prediction_stats,
    risk_groups = risk_groups,
    complication_type = complication_type,
    feature_importance = extract_feature_importance(trained_models),
    timestamp = Sys.time()
  ))
}

#' Calculate Prediction Uncertainty
#'
#' @param predictions List of model predictions
#' @param actual_outcomes Actual outcomes (if available)
#' @return Uncertainty statistics
calculate_prediction_uncertainty <- function(predictions, actual_outcomes = NULL) {

  stats <- list()

  # Prediction variance across models
  if (length(predictions) > 1) {
    pred_matrix <- do.call(cbind, predictions)
    stats$prediction_variance <- apply(pred_matrix, 1, var, na.rm = TRUE)
    stats$prediction_sd <- sqrt(stats$prediction_variance)
    stats$coefficient_of_variation <- stats$prediction_sd / rowMeans(pred_matrix, na.rm = TRUE)
  }

  # Confidence intervals (assuming normal distribution)
  if (is.numeric(predictions[[1]])) {
    pred_mean <- rowMeans(do.call(cbind, predictions), na.rm = TRUE)
    pred_se <- apply(do.call(cbind, predictions), 1, sd, na.rm = TRUE)

    stats$ci_lower <- pred_mean - 1.96 * pred_se
    stats$ci_upper <- pred_mean + 1.96 * pred_se
    stats$prediction_mean <- pred_mean
  }

  # Calibration assessment (if actual outcomes available)
  if (!is.null(actual_outcomes)) {
    stats$calibration <- assess_calibration(predictions, actual_outcomes)
  }

  return(stats)
}

#' Create Risk Stratification Groups
#'
#' @param predictions Risk predictions
#' @param n_groups Number of risk groups
#' @return Risk stratification results
create_risk_stratification <- function(predictions, n_groups = 3) {

  # Convert predictions to risk scores
  if (is.factor(predictions)) {
    risk_scores <- as.numeric(predictions == levels(predictions)[2])  # Assume second level is positive
  } else {
    risk_scores <- as.numeric(predictions)
  }

  # Create risk groups using quantiles
  # Remove NA and infinite values
  risk_scores_clean <- risk_scores[is.finite(risk_scores)]

  if (length(risk_scores_clean) == 0) {
    warning("No valid risk scores for stratification")
    return(list(
      risk_groups = factor(rep("Unknown", length(risk_scores))),
      risk_scores = risk_scores,
      group_stats = data.frame(),
      group_breaks = numeric(0),
      n_groups = n_groups
    ))
  }

  group_breaks <- quantile(risk_scores_clean, probs = seq(0, 1, length.out = n_groups + 1))

  # Ensure unique breaks
  if (length(unique(group_breaks)) < (n_groups + 1)) {
    min_val <- min(risk_scores_clean)
    max_val <- max(risk_scores_clean)
    if (is.finite(min_val) && is.finite(max_val) && min_val < max_val) {
      group_breaks <- seq(min_val, max_val, length.out = n_groups + 1)
    } else {
      warning("Cannot create risk groups due to invalid risk score range")
      return(list(
        risk_groups = factor(rep("Unknown", length(risk_scores))),
        risk_scores = risk_scores,
        group_stats = data.frame(),
        group_breaks = numeric(0),
        n_groups = n_groups
      ))
    }
  }

  risk_groups <- cut(risk_scores, breaks = group_breaks,
                    labels = paste0("Risk_Group_", 1:n_groups),
                    include.lowest = TRUE)

  # Group statistics
  group_stats <- data.frame(
    group = levels(risk_groups),
    n_patients = table(risk_groups),
    mean_risk = tapply(risk_scores, risk_groups, mean),
    median_risk = tapply(risk_scores, risk_groups, median),
    risk_range = tapply(risk_scores, risk_groups, function(x) paste(round(range(x), 3), collapse = " - "))
  )

  return(list(
    risk_groups = risk_groups,
    risk_scores = risk_scores,
    group_stats = group_stats,
    group_breaks = group_breaks,
    n_groups = n_groups
  ))
}

#' Extract Feature Importance from Trained Models
#'
#' @param trained_models Trained ML models
#' @return Feature importance summary
extract_feature_importance <- function(trained_models) {

  importance_summary <- list()

  for (model_name in names(trained_models$models)) {
    model <- trained_models$models[[model_name]]

    if (model_name == "ensemble") next

    # Extract variable importance
    if ("varImp" %in% methods(class(model))) {
      try({
        importance <- caret::varImp(model)
        importance_summary[[model_name]] <- importance
      })
    }
  }

  # Aggregate importance across models
  if (length(importance_summary) > 1) {
    # Simple averaging of importance scores
    all_features <- unique(unlist(lapply(importance_summary, function(x) rownames(x$importance))))

    aggregated_importance <- data.frame(
      feature = all_features,
      mean_importance = sapply(all_features, function(feature) {
        scores <- sapply(importance_summary, function(model_imp) {
          if (feature %in% rownames(model_imp$importance)) {
            return(model_imp$importance[feature, 1])
          } else {
            return(0)
          }
        })
        mean(scores, na.rm = TRUE)
      })
    )

    aggregated_importance <- aggregated_importance[order(aggregated_importance$mean_importance, decreasing = TRUE), ]

    importance_summary$aggregated <- aggregated_importance
  }

  return(importance_summary)
}

#' Assess Model Calibration
#'
#' @param predictions Model predictions
#' @param actual_outcomes Actual outcomes
#' @return Calibration assessment
assess_calibration <- function(predictions, actual_outcomes) {

  calibration <- list()

  # Hosmer-Lemeshow test for calibration
  if (is.numeric(predictions[[1]]) && length(unique(actual_outcomes)) == 2) {
    # For binary outcomes with continuous predictions
    pred_probs <- predictions$ensemble  # Use ensemble predictions

    if (is.numeric(pred_probs)) {
      # Remove NA and infinite values
      pred_probs_clean <- pred_probs[is.finite(pred_probs)]

      if (length(pred_probs_clean) == 0) {
        warning("No valid prediction probabilities for calibration")
        return(calibration)
      }

      # Create deciles - ensure unique breaks
      quantile_breaks <- quantile(pred_probs_clean, probs = seq(0, 1, 0.1))

      # Ensure unique breaks (handle case where many identical values exist)
      if (length(unique(quantile_breaks)) < 11) {
        # If not enough unique quantiles, create evenly spaced breaks
        min_val <- min(pred_probs_clean)
        max_val <- max(pred_probs_clean)
        if (is.finite(min_val) && is.finite(max_val) && min_val < max_val) {
          quantile_breaks <- seq(min_val, max_val, length.out = 11)
        } else {
          warning("Cannot create calibration deciles due to invalid prediction range")
          return(calibration)
        }
      }

      deciles <- cut(pred_probs, breaks = quantile_breaks,
                    include.lowest = TRUE, labels = 1:10)

      observed <- tapply(actual_outcomes, deciles, mean)
      expected <- tapply(pred_probs, deciles, mean)

      # Hosmer-Lemeshow statistic
      hl_stat <- sum((observed - expected)^2 / (expected * (1 - expected) / table(deciles)))
      hl_p_value <- pchisq(hl_stat, df = 8, lower.tail = FALSE)

      calibration$hosmer_lemeshow <- list(
        statistic = hl_stat,
        p_value = hl_p_value,
        well_calibrated = hl_p_value > 0.05
      )
    }
  }

  # Brier score
  if (is.numeric(predictions[[1]])) {
    pred_probs <- rowMeans(do.call(cbind, predictions), na.rm = TRUE)
    brier_score <- mean((pred_probs - actual_outcomes)^2)
    calibration$brier_score <- brier_score
  }

  return(calibration)
}

#' Predict Treatment Response Using ML
#'
#' @param patient_data Patient data with treatment information
#' @param outcome_var Outcome variable (e.g., "qaly_gain", "pain_reduction")
#' @param ml_config ML configuration
#' @return Treatment response predictions
predict_treatment_response <- function(patient_data, outcome_var = "qaly_gain", ml_config) {

  # Load ML framework
  source("R/ml_framework.R")

  # Prepare features
  # Handle different config structures
  if ("coefficients" %in% names(ml_config)) {
    feature_config <- ml_config$coefficients$ml
  } else {
    feature_config <- ml_config
  }

  feature_pipeline <- create_feature_pipeline(patient_data, feature_config)
  features <- feature_pipeline$feature_matrix

  # Check if outcome data exists
  if (!(outcome_var %in% colnames(patient_data))) {
    warning("Outcome variable ", outcome_var, " not found. Creating synthetic data.")
    set.seed(12345)
    patient_data[[outcome_var]] <- rnorm(nrow(patient_data), 0.5, 0.2)  # Synthetic QALY gain
  }

  # Prepare training data
  training_data <- list(
    feature_matrix = features,
    processed_data = patient_data
  )

  # Train models
  message("Training ML models for treatment response prediction...")
  trained_models <- train_predictive_models(training_data, outcome_var, ml_config)

  # Generate predictions
  predictions <- lapply(trained_models$models, function(model) {
    if (inherits(model, "list") && "predictions" %in% names(model)) {
      return(model$predictions)  # Ensemble model
    } else {
      return(predict(model, newdata = features))
    }
  })

  # Treatment effectiveness analysis
  effectiveness <- analyze_treatment_effectiveness(predictions, patient_data)

  return(list(
    predictions = predictions,
    trained_models = trained_models,
    effectiveness = effectiveness,
    outcome_var = outcome_var,
    feature_importance = extract_feature_importance(trained_models),
    timestamp = Sys.time()
  ))
}

#' Analyze Treatment Effectiveness
#'
#' @param predictions Treatment response predictions
#' @param patient_data Patient data with treatment information
#' @return Treatment effectiveness analysis
analyze_treatment_effectiveness <- function(predictions, patient_data) {

  effectiveness <- list()

  # Compare effectiveness by treatment type
  if ("implant_type" %in% colnames(patient_data)) {
    treatment_comparison <- list()

    for (treatment in unique(patient_data$implant_type)) {
      treatment_idx <- patient_data$implant_type == treatment
      treatment_predictions <- lapply(predictions, function(pred) pred[treatment_idx])

      treatment_comparison[[treatment]] <- list(
        n_patients = sum(treatment_idx),
        mean_response = mean(treatment_predictions$ensemble, na.rm = TRUE),
        response_variability = sd(treatment_predictions$ensemble, na.rm = TRUE)
      )
    }

    effectiveness$treatment_comparison <- treatment_comparison
  }

  # Identify high responders vs low responders
  ensemble_pred <- predictions$ensemble
  response_quantiles <- quantile(ensemble_pred, c(0.25, 0.75))

  effectiveness$high_responders <- list(
    threshold = response_quantiles[2],
    n_patients = sum(ensemble_pred >= response_quantiles[2]),
    proportion = mean(ensemble_pred >= response_quantiles[2])
  )

  effectiveness$low_responders <- list(
    threshold = response_quantiles[1],
    n_patients = sum(ensemble_pred <= response_quantiles[1]),
    proportion = mean(ensemble_pred <= response_quantiles[1])
  )

  return(effectiveness)
}

#' Validate ML Model Performance
#'
#' @param ml_results ML model results
#' @param validation_data Validation data
#' @param metrics Performance metrics to calculate
#' @return Validation results
validate_ml_performance <- function(ml_results, validation_data, metrics = c("rmse", "mae", "r_squared")) {

  message("Starting validate_ml_performance")
  message("ml_results names: ", paste(names(ml_results), collapse = ", "))
  message("trained_models names: ", paste(names(ml_results$trained_models), collapse = ", "))
  message("complication_type: ", ml_results$complication_type)

  validation <- list()

  # Prepare validation features
  source("R/ml_framework.R")
  ml_config <- ml_results$trained_models$config
  val_features <- create_feature_pipeline(validation_data, ml_config)$feature_matrix

  message("Validation features dimensions: ", paste(dim(val_features), collapse = " x "))

  # Generate predictions on validation data
  validation_predictions <- list()

  for (model_name in names(ml_results$trained_models$models)) {
    model <- ml_results$trained_models$models[[model_name]]

    if (model_name == "ensemble") {
      # For ensemble, use simple averaging of other model predictions
      ensemble_preds <- lapply(names(ml_results$trained_models$models)[names(ml_results$trained_models$models) != "ensemble"],
                              function(m) predict(ml_results$trained_models$models[[m]], newdata = val_features))
      validation_predictions[[model_name]] <- rowMeans(do.call(cbind, ensemble_preds), na.rm = TRUE)
    } else {
      validation_predictions[[model_name]] <- predict(model, newdata = val_features)
    }
  }

  # Calculate performance metrics
  # Determine outcome variable from complication type
  outcome_var <- switch(ml_results$complication_type,
                       "pji" = "pji_risk",
                       "dvt" = "dvt_risk",
                       "revision" = "revision_risk",
                       "qaly_gain")

  actual_outcomes <- validation_data[[outcome_var]]

  for (model_name in names(validation_predictions)) {
    pred <- validation_predictions[[model_name]]

    model_metrics <- list()

    if ("rmse" %in% metrics && is.numeric(pred) && is.numeric(actual_outcomes)) {
      model_metrics$rmse <- sqrt(mean((pred - actual_outcomes)^2, na.rm = TRUE))
    }

    if ("mae" %in% metrics && is.numeric(pred) && is.numeric(actual_outcomes)) {
      model_metrics$mae <- mean(abs(pred - actual_outcomes), na.rm = TRUE)
    }

    if ("r_squared" %in% metrics && is.numeric(pred) && is.numeric(actual_outcomes)) {
      model_metrics$r_squared <- cor(pred, actual_outcomes, use = "complete.obs")^2
    }

    if ("accuracy" %in% metrics && (is.factor(pred) || is.factor(actual_outcomes))) {
      model_metrics$accuracy <- mean(pred == actual_outcomes, na.rm = TRUE)
    }

    validation[[model_name]] <- model_metrics
  }

  # Overall validation summary
  message("Validation list names: ", paste(names(validation), collapse = ", "))
  message("Validation list lengths: ", paste(sapply(validation, length), collapse = ", "))

  validation$summary <- list(
    best_model = names(validation)[which.max(sapply(validation, function(x) {
      message("Model metrics for ", names(validation)[which(sapply(validation, identical, x))], ": ", paste(names(x), collapse = ", "))
      if (!is.null(x$r_squared)) {
        return(x$r_squared)
      } else if (!is.null(x$accuracy)) {
        return(x$accuracy)
      } else {
        return(0)
      }
    }))],
    n_validation_samples = nrow(validation_data),
    validation_timestamp = Sys.time()
  )

  return(validation)
}

#' Predict Treatment Response Using ML Models
#'
#' @param patient_data Patient characteristics and treatment data
#' @param outcome_var Outcome variable to predict (e.g., "qaly_gain")
#' @param ml_config ML configuration
#' @return Treatment response predictions with effectiveness analysis
predict_treatment_response <- function(patient_data, outcome_var = "qaly_gain", ml_config) {

  # Load ML framework
  source("R/ml_framework.R")

  # Prepare features
  # Handle different config structures
  if ("coefficients" %in% names(ml_config)) {
    feature_config <- ml_config$coefficients$ml
  } else {
    feature_config <- ml_config
  }

  feature_pipeline <- create_feature_pipeline(patient_data, feature_config)
  features <- feature_pipeline$feature_matrix

  # Check if outcome data exists
  if (!(outcome_var %in% colnames(patient_data))) {
    warning("Outcome variable ", outcome_var, " not found in data. Using synthetic data for demonstration.")
    # Create synthetic outcome for demonstration
    set.seed(12345)
    if (outcome_var == "qaly_gain") {
      patient_data[[outcome_var]] <- rnorm(nrow(patient_data), 0.6, 0.1)  # Mean QALY gain around 0.6
    } else {
      patient_data[[outcome_var]] <- rnorm(nrow(patient_data), 0, 1)  # Generic numeric outcome
    }
  }

  # Prepare training data
  training_data <- list(
    feature_matrix = features,
    processed_data = patient_data
  )

  # Train predictive models
  message("Training ML models for treatment response prediction...")
  trained_models <- train_predictive_models(training_data, outcome_var, ml_config)

  # Generate predictions
  predictions <- list()

  for (model_name in names(trained_models$models)) {
    model <- trained_models$models[[model_name]]

    if (model_name == "ensemble") {
      pred <- model$predictions
    } else {
      pred <- predict(model, newdata = features)
    }

    predictions[[model_name]] <- pred
  }

  message("Generated predictions for ", length(predictions), " models")

  # Calculate prediction uncertainty
  prediction_stats <- calculate_prediction_uncertainty(predictions, patient_data[[outcome_var]])

  # Treatment effectiveness analysis
  effectiveness <- analyze_treatment_effectiveness(predictions, patient_data)

  return(list(
    predictions = predictions,
    trained_models = trained_models,
    prediction_stats = prediction_stats,
    effectiveness = effectiveness,
    outcome_var = outcome_var,
    feature_importance = extract_feature_importance(trained_models),
    timestamp = Sys.time()
  ))
}

#' Analyze Treatment Effectiveness
#'
#' @param predictions Model predictions
#' @param patient_data Patient data with treatment information
#' @return Effectiveness analysis results
analyze_treatment_effectiveness <- function(predictions, patient_data) {

  effectiveness <- list()

  # Use ensemble predictions for analysis
  ensemble_preds <- predictions$ensemble

  if (!is.null(ensemble_preds) && length(ensemble_preds) > 0) {
    # Effectiveness by treatment type
    if ("implant_type" %in% colnames(patient_data) && length(unique(patient_data$implant_type)) > 1) {
      tryCatch({
        effectiveness$by_implant <- tapply(ensemble_preds, patient_data$implant_type,
                                          function(x) mean(x, na.rm = TRUE))
      }, error = function(e) {
        warning("Could not analyze effectiveness by implant type: ", e$message)
        effectiveness$by_implant <- NULL
      })
    }

    # Effectiveness by surgical approach
    if ("surgical_approach" %in% colnames(patient_data) && length(unique(patient_data$surgical_approach)) > 1) {
      tryCatch({
        effectiveness$by_approach <- tapply(ensemble_preds, patient_data$surgical_approach,
                                           function(x) mean(x, na.rm = TRUE))
      }, error = function(e) {
        warning("Could not analyze effectiveness by surgical approach: ", e$message)
        effectiveness$by_approach <- NULL
      })
    }

    # Overall effectiveness statistics
    tryCatch({
      effectiveness$overall <- list(
        mean_effectiveness = mean(ensemble_preds, na.rm = TRUE),
        sd_effectiveness = sd(ensemble_preds, na.rm = TRUE),
        median_effectiveness = median(ensemble_preds, na.rm = TRUE),
        range_effectiveness = range(ensemble_preds, na.rm = TRUE)
      )
    }, error = function(e) {
      warning("Could not calculate overall effectiveness statistics: ", e$message)
      effectiveness$overall <- NULL
    })
  }

  return(effectiveness)
}
