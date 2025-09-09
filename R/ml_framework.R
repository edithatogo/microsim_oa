      # Comorbidity score
      # comorbidity_score = comorbidities

      # KL grade severity
      # kl_severity = case_when(
      #   kl_grade %in% c(0, 1) ~ "mild",
      #   kl_grade %in% c(2, 3) ~ "moderate",
      #   kl_grade >= 4 ~ "severe"
      # )
#'
#' Key Components:
#' - Predictive Modeling Framework: ML models for outcome prediction
#' - Parameter Estimation: Bayesian and ML-based calibration
#' - Advanced Analytics: Clustering, pattern recognition, reinforcement learning
#' - Model Validation: Explainable AI and performance monitoring

#' Load Required ML Packages
load_ml_packages <- function() {
  required_packages <- c(
    "caret", "randomForest", "xgboost", "glmnet", "e1071",
    "rpart", "gbm", "nnet", "kernlab", "party",
    "mlr3", "mlr3learners", "mlr3tuning", "mlr3pipelines",
    "DALEX", "iml", "vip", "pdp", "lime",
    "bnlearn", "rstan", "rstanarm", "brms",
    "cluster", "mclust", "dbscan", "factoextra",
    "ReinforcementLearning", "MDPtoolbox"
  )

  installed <- required_packages %in% installed.packages()[, "Package"]
  if (any(!installed)) {
    missing <- required_packages[!installed]
    message("Installing missing ML packages: ", paste(missing, collapse = ", "))
    install.packages(missing, dependencies = TRUE)
  }

  # Load packages
  lapply(required_packages, library, character.only = TRUE)
  message("All ML packages loaded successfully")
}

#' Initialize ML Framework
#'
#' @param config Configuration list
#' @return ML framework configuration
initialize_ml_framework <- function(config) {
  ml_config <- list()

  # ML framework settings
  ml_config$framework <- list(
    random_seed = 12345,
    cv_folds = 5,
    cv_repeats = 3,
    performance_metric = "RMSE",
    parallel_processing = TRUE,
    n_cores = parallel::detectCores() - 1
  )

  # Model settings
  ml_config$models <- list(
    predictive = list(
      enabled = TRUE,
      algorithms = c("rf", "xgb", "glmnet", "svm"),
      tune_length = 10
    ),
    calibration = list(
      enabled = TRUE,
      methods = c("bayesian", "ml_calibration"),
      mcmc_iterations = 2000
    ),
    clustering = list(
      enabled = TRUE,
      methods = c("kmeans", "hierarchical", "dbscan"),
      max_clusters = 10
    )
  )

  # Feature engineering
  ml_config$features <- list(
    patient_characteristics = c("age", "sex", "bmi", "comorbidities"),
    clinical_factors = c("kl_grade", "previous_surgeries", "smoking_status"),
    treatment_factors = c("implant_type", "approach", "prophylaxis"),
    outcome_variables = c("complications", "revisions", "qaly", "costs")
  )

  # Validation settings
  ml_config$validation <- list(
    test_split = 0.2,
    cross_validation = TRUE,
    performance_metrics = c("accuracy", "precision", "recall", "f1", "auc"),
    calibration_plots = TRUE,
    feature_importance = TRUE
  )

  return(ml_config)
}

#' Create Feature Engineering Pipeline
#'
#' @param patient_data Patient data for feature engineering
#' @param config ML configuration
#' @return Processed feature matrix
create_feature_pipeline <- function(patient_data, config) {

  # Extract features
  features <- config$features

  # Basic feature engineering (idempotent - safe to run multiple times)
  processed_data <- patient_data %>%

    # Age categories (handle edge cases)
    mutate(
      age = ifelse(is.na(age), median(age, na.rm = TRUE), age),
      age_category = cut(age, breaks = c(-Inf, 50, 65, 75, 85, Inf),
                        labels = c("young", "middle", "senior", "elderly", "very_elderly"),
                        include.lowest = TRUE),

      # BMI categories (handle edge cases)
      bmi = ifelse(is.na(bmi), median(bmi, na.rm = TRUE), bmi),
      bmi_category = cut(bmi, breaks = c(-Inf, 18.5, 25, 30, 35, Inf),
                        labels = c("underweight", "normal", "overweight", "obese", "severely_obese"),
                        include.lowest = TRUE),

      # Comorbidity score (handle missing comorbidity columns)
      comorbidity_score = if("comorbidities" %in% colnames(.)) comorbidities else 0,

      # KL grade severity
      kl_severity = case_when(
        kl_grade %in% c(0, 1) ~ "mild",
        kl_grade %in% c(2, 3) ~ "moderate",
        kl_grade >= 4 ~ "severe"
      )
    ) %>%

    # One-hot encoding for categorical variables
    mutate(
      sex_male = as.numeric(sex == "male"),
      sex_female = as.numeric(sex == "female"),

      approach_anterior = as.numeric(surgical_approach == "anterior"),
      approach_posterior = as.numeric(surgical_approach == "posterior"),
      approach_lateral = as.numeric(surgical_approach == "lateral"),

      implant_cemented = as.numeric(implant_type == "cemented"),
      implant_uncemented = as.numeric(implant_type == "uncemented"),
      implant_hybrid = as.numeric(implant_type == "hybrid")
    )

  # Select final features
  feature_cols <- c(
    features$patient_characteristics,
    features$clinical_factors,
    features$treatment_factors,
    # Engineered features
    "age_category", "bmi_category", "comorbidity_score", "kl_severity",
    "sex_male", "sex_female",
    "approach_anterior", "approach_posterior", "approach_lateral",
    "implant_cemented", "implant_uncemented", "implant_hybrid"
  )

  # Ensure all columns exist
  available_cols <- intersect(feature_cols, colnames(processed_data))
  if (length(available_cols) != length(feature_cols)) {
    missing_cols <- setdiff(feature_cols, colnames(processed_data))
    warning("Missing feature columns: ", paste(missing_cols, collapse = ", "))
  }

  feature_matrix <- processed_data[, available_cols, drop = FALSE]

  # Handle missing values
  feature_matrix <- feature_matrix %>%
    mutate(across(where(is.numeric), ~ifelse(is.na(.), median(., na.rm = TRUE), .))) %>%
    mutate(across(where(is.factor), ~ifelse(is.na(.), names(sort(table(.), decreasing = TRUE))[1], .)))

  return(list(
    feature_matrix = feature_matrix,
    processed_data = processed_data,
    feature_names = available_cols
  ))
}

#' Train Predictive Models for Patient Outcomes
#'
#' @param training_data Training data with features and outcomes
#' @param outcome_var Outcome variable to predict
#' @param config ML configuration
#' @return Trained models and performance metrics
train_predictive_models <- function(training_data, outcome_var, config) {

  # Prepare data
  features <- training_data$feature_matrix
  outcome <- training_data$processed_data[[outcome_var]]

  # Remove missing outcomes
  valid_idx <- !is.na(outcome)
  features <- features[valid_idx, ]
  outcome <- outcome[valid_idx]

  # Determine problem type and appropriate metric
  n_unique <- length(unique(outcome))
  is_classification <- is.factor(outcome) || (is.numeric(outcome) && n_unique == 2)

  if (is_classification) {
    # Convert to factor for classification
    if (!is.factor(outcome)) {
      outcome <- factor(outcome, levels = c(0, 1), labels = c("no", "yes"))
    }
    performance_metric <- "Accuracy"
    summary_function <- caret::twoClassSummary
    class_probs <- TRUE
  } else {
    # Regression
    performance_metric <- "RMSE"
    summary_function <- caret::defaultSummary
    class_probs <- FALSE
  }

  message(sprintf("Training ML models for %s prediction (type: %s, metric: %s)...",
                  outcome_var,
                  ifelse(is_classification, "classification", "regression"),
                  performance_metric))

  # Create training control
  train_control <- caret::trainControl(
    method = "cv",
    number = config$framework$cv_folds,
    repeats = if(!is.null(config$framework$cv_repeats)) config$framework$cv_repeats else 1,
    savePredictions = "final",
    classProbs = class_probs,
    summaryFunction = summary_function
  )

  # Model specifications
  models <- list()

  # Random Forest
  if ("rf" %in% config$models$predictive$algorithms) {
    message("Training Random Forest model...")
    models$rf <- caret::train(
      x = features,
      y = outcome,
      method = "rf",
      trControl = train_control,
      tuneLength = config$models$predictive$tune_length,
      metric = performance_metric,
      importance = TRUE
    )
  }

  # XGBoost
  if ("xgb" %in% config$models$predictive$algorithms) {
    message("Training XGBoost model...")
    models$xgb <- caret::train(
      x = features,
      y = outcome,
      method = "xgbTree",
      trControl = train_control,
      tuneLength = config$models$predictive$tune_length,
      metric = performance_metric
    )
  }

  # Elastic Net
  if ("glmnet" %in% config$models$predictive$algorithms) {
    message("Training Elastic Net model...")
    models$glmnet <- caret::train(
      x = features,
      y = outcome,
      method = "glmnet",
      trControl = train_control,
      tuneLength = config$models$predictive$tune_length,
      metric = performance_metric
    )
  }

  # Support Vector Machine
  if ("svm" %in% config$models$predictive$algorithms) {
    message("Training SVM model...")
    models$svm <- caret::train(
      x = features,
      y = outcome,
      method = "svmRadial",
      trControl = train_control,
      tuneLength = config$models$predictive$tune_length,
      metric = performance_metric
    )
  }

  # Model ensemble (simple averaging)
  if (length(models) > 1) {
    message("Creating model ensemble...")
    ensemble_result <- create_model_ensemble(models, features, outcome)

    if (!is.null(ensemble_result)) {
      models$ensemble <- ensemble_result
      message("Ensemble created successfully with ", length(ensemble_result$base_models), " base models")
    } else {
      warning("Ensemble creation failed, proceeding without ensemble")
    }
  }

  # Performance comparison
  message("Creating performance comparison...")
  performance <- tryCatch({
    caret::resamples(models)
  }, error = function(e) {
    warning("Error in resamples(): ", e$message)
    message("Models in list: ", paste(names(models), collapse = ", "))
    for (model_name in names(models)) {
      model <- models[[model_name]]
      message("Model ", model_name, " class: ", class(model)[1])
      if (is.list(model) && "predictions" %in% names(model)) {
        message("  Ensemble model with predictions length: ", length(model$predictions))
      }
    }
    return(NULL)
  })

  message("Training completed successfully")
  return(list(
    models = models,
    performance = performance,
    training_data = list(features = features, outcome = outcome),
    config = config
  ))
}

#' Create Model Ensemble
#'
#' @param models List of trained models
#' @param features Feature matrix
#' @param outcome Outcome vector
#' @return Ensemble model
create_model_ensemble <- function(models, features, outcome) {

  message("Starting ensemble creation with ", length(models), " models for ", ifelse(is.factor(outcome), "classification", "regression"))

  # Get predictions from each model
  predictions <- lapply(names(models), function(model_name) {
    model <- models[[model_name]]
    tryCatch({
      if (is.factor(outcome)) {
        # For classification, get class predictions
        pred <- predict(model, newdata = features, type = "raw")
        # Ensure predictions are factors with correct levels
        if (!is.factor(pred)) {
          pred <- factor(pred, levels = levels(outcome))
        }
        message("Model ", model_name, ": ", length(pred), " predictions, levels: ", paste(levels(pred), collapse = ", "))
        pred
      } else {
        # For regression, get numeric predictions
        pred <- as.numeric(predict(model, newdata = features))
        message("Model ", model_name, ": ", length(pred), " numeric predictions")
        pred
      }
    }, error = function(e) {
      warning("Prediction failed for model ", model_name, ": ", e$message)
      return(NULL)
    })
  })

  names(predictions) <- names(models)

  # Remove any NULL predictions
  valid_predictions <- predictions[!sapply(predictions, is.null)]
  message("Valid predictions from ", length(valid_predictions), " models")

  if (length(valid_predictions) == 0) {
    warning("No valid predictions for ensemble creation")
    return(NULL)
  }

  # Simple averaging for regression, majority vote for classification
  if (is.numeric(outcome)) {
    # Regression ensemble
    pred_matrix <- do.call(cbind, valid_predictions)
    ensemble_pred <- rowMeans(pred_matrix, na.rm = TRUE)
  } else {
    # Classification ensemble (majority vote)
    pred_matrix <- do.call(cbind, valid_predictions)

    ensemble_pred <- apply(pred_matrix, 1, function(x) {
      # Remove NA values
      x <- x[!is.na(x)]
      if (length(x) == 0) return(levels(outcome)[1])  # Return first level if no valid predictions

      # Get most frequent prediction
      tbl <- table(x)
      if (length(tbl) == 0) return(levels(outcome)[1])  # Return first level if table is empty

      names(tbl)[which.max(tbl)]
    })

    ensemble_pred <- factor(ensemble_pred, levels = levels(outcome))
  }

  # Calculate ensemble performance
  valid_idx <- !is.na(ensemble_pred)
  if (sum(valid_idx) == 0) {
    warning("No valid ensemble predictions")
    return(NULL)
  }

  ensemble_performance <- list(
    predictions = ensemble_pred,
    actual = outcome,
    rmse = if(is.numeric(outcome)) sqrt(mean((ensemble_pred - outcome)^2, na.rm = TRUE)) else NA,
    accuracy = if(is.factor(outcome)) mean(ensemble_pred == outcome, na.rm = TRUE) else NA
  )

  return(list(
    predictions = ensemble_pred,
    performance = ensemble_performance,
    base_models = names(models)
  ))
}

#' Generate Model Interpretability Report
#'
#' @param trained_models Trained ML models
#' @param feature_data Feature data
#' @param output_dir Output directory
#' @return Interpretability report
generate_interpretability_report <- function(trained_models, feature_data, output_dir = "output") {

  if (!dir.exists(output_dir)) {
    dir.create(output_dir, recursive = TRUE)
  }

  report <- list()

  # Feature importance for each model
  for (model_name in names(trained_models$models)) {
    model <- trained_models$models[[model_name]]

    if (model_name == "ensemble") next

    # Variable importance
    if ("varImp" %in% names(model)) {
      importance <- caret::varImp(model)
      report[[paste0(model_name, "_importance")]] <- importance
    }

    # Partial dependence plots for top features
    if ("finalModel" %in% names(model) && "xNames" %in% names(model)) {
      top_features <- caret::varImp(model)$importance %>%
        arrange(desc(Overall)) %>%
        head(5) %>%
        rownames()

      pdp_plots <- list()
      for (feature in top_features) {
        try({
          pdp_plot <- pdp::partial(model$finalModel,
                                 pred.var = feature,
                                 train = feature_data)
          pdp_plots[[feature]] <- pdp_plot
        })
      }
      report[[paste0(model_name, "_pdp")]] <- pdp_plots
    }
  }

  # Save report
  report_file <- file.path(output_dir, "ml_interpretability_report.rds")
  saveRDS(report, file = report_file)

  return(list(
    report = report,
    file = report_file,
    timestamp = Sys.time()
  ))
}
