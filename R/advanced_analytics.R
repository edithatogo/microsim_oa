#' Advanced Analytics Module for AUS-OA
#'
#' This module implements advanced analytics capabilities including:
#' - Patient Clustering and Stratification
#' - Pattern Recognition in Treatment Outcomes
#' - Dimensionality Reduction Techniques
#' - Advanced Feature Selection
#' - Temporal Pattern Analysis
#' - Risk Trajectory Modeling

#' Load Advanced Analytics Packages
load_advanced_analytics_packages <- function() {
  required_packages <- c(
    "cluster", "mclust", "factoextra", "umap", "Rtsne",
    "caret", "Boruta", "FSelectorRcpp", "pROC", "ROCR",
    "longitudinalData", "kml", "traj", "lcmm"
  )

  installed <- required_packages %in% installed.packages()[, "Package"]
  if (any(!installed)) {
    missing <- required_packages[!installed]
    message("Installing missing advanced analytics packages: ", paste(missing, collapse = ", "))
    install.packages(missing, dependencies = TRUE)
  }

  # Load packages
  lapply(required_packages, library, character.only = TRUE)
  message("All advanced analytics packages loaded successfully")
}

#' Initialize Advanced Analytics Framework
#'
#' @param config Configuration list
#' @return Advanced analytics configuration
initialize_advanced_analytics <- function(config) {
  analytics_config <- list()

  # Clustering settings
  analytics_config$clustering <- list(
    methods = c("kmeans", "hierarchical", "gaussian_mixture", "pam"),
    n_clusters_range = 2:10,
    distance_metrics = c("euclidean", "manhattan", "gower"),
    linkage_methods = c("complete", "average", "ward.D2")
  )

  # Dimensionality reduction
  analytics_config$dim_reduction <- list(
    methods = c("pca", "umap", "tsne"),
    n_components_range = 2:10,
    perplexity_range = c(5, 10, 20, 30, 50)
  )

  # Feature selection
  analytics_config$feature_selection <- list(
    methods = c("boruta", "recursive_elimination", "lasso", "information_gain"),
    importance_threshold = 0.05,
    max_features = 20
  )

  # Pattern recognition
  analytics_config$pattern_recognition <- list(
    temporal_window = 12,  # months
    min_pattern_length = 3,
    similarity_threshold = 0.8,
    pattern_types = c("progression", "improvement", "fluctuation", "stable")
  )

  # Validation settings
  analytics_config$validation <- list(
    cv_folds = 5,
    cv_repeats = 3,
    performance_metrics = c("silhouette", "calinski_harabasz", "davies_bouldin")
  )

  return(analytics_config)
}

#' Patient Clustering and Stratification
#'
#' @param patient_data Patient data matrix
#' @param config Advanced analytics configuration
#' @param method Clustering method to use
#' @return Clustering results
perform_patient_clustering <- function(patient_data, config, method = "kmeans") {

  message("Performing patient clustering using ", method)

  # Prepare data (remove non-numeric columns and handle missing values)
  numeric_data <- patient_data[, sapply(patient_data, is.numeric)]
  numeric_data <- na.omit(numeric_data)

  if (nrow(numeric_data) == 0) {
    stop("No valid numeric data available for clustering")
  }

  # Scale data
  scaled_data <- scale(numeric_data)

  clustering_results <- list()
  clustering_results$data <- scaled_data
  clustering_results$method <- method

  if (method == "kmeans") {
    # Determine optimal number of clusters
    wss <- sapply(config$clustering$n_clusters_range,
                  function(k) kmeans(scaled_data, centers = k, nstart = 25)$tot.withinss)

    # Use elbow method to find optimal k
    optimal_k <- find_optimal_clusters_elbow(wss, config$clustering$n_clusters_range)

    # Perform clustering
    kmeans_result <- kmeans(scaled_data, centers = optimal_k, nstart = 25)
    clustering_results$model <- kmeans_result
    clustering_results$clusters <- kmeans_result$cluster
    clustering_results$centers <- kmeans_result$centers
    clustering_results$optimal_k <- optimal_k

  } else if (method == "hierarchical") {
    # Compute distance matrix
    dist_matrix <- dist(scaled_data, method = "euclidean")

    # Perform hierarchical clustering
    hc_result <- hclust(dist_matrix, method = "ward.D2")
    clustering_results$model <- hc_result
    clustering_results$dist_matrix <- dist_matrix

    # Cut tree at optimal height
    optimal_k <- find_optimal_clusters_silhouette(scaled_data, config$clustering$n_clusters_range)
    clustering_results$clusters <- cutree(hc_result, k = optimal_k)
    clustering_results$optimal_k <- optimal_k

  } else if (method == "gaussian_mixture") {
    # Gaussian mixture model clustering
    gmm_result <- Mclust(scaled_data)
    clustering_results$model <- gmm_result
    clustering_results$clusters <- gmm_result$classification
    clustering_results$optimal_k <- gmm_result$G
    clustering_results$bic <- gmm_result$bic

  } else if (method == "pam") {
    # Partitioning Around Medoids
    optimal_k <- find_optimal_clusters_silhouette(scaled_data, config$clustering$n_clusters_range)
    pam_result <- pam(scaled_data, k = optimal_k)
    clustering_results$model <- pam_result
    clustering_results$clusters <- pam_result$cluster
    clustering_results$medoids <- pam_result$medoids
    clustering_results$optimal_k <- optimal_k
  }

  # Calculate cluster validation metrics
  clustering_results$validation <- validate_clustering(scaled_data, clustering_results$clusters, config)

  # Add cluster characteristics
  clustering_results$characteristics <- analyze_cluster_characteristics(
    patient_data, clustering_results$clusters, numeric_data
  )

  return(clustering_results)
}

#' Find Optimal Number of Clusters (Elbow Method)
#'
#' @param wss Within-cluster sum of squares
#' @param k_range Range of k values
#' @return Optimal number of clusters
find_optimal_clusters_elbow <- function(wss, k_range) {
  # Calculate second differences to find elbow
  second_diff <- diff(diff(wss))

  # Find the point where the second difference is maximum
  elbow_point <- which.max(second_diff) + 1

  optimal_k <- k_range[elbow_point]

  # Ensure optimal_k is reasonable
  if (optimal_k < 2) optimal_k <- 2
  if (optimal_k > length(k_range)) optimal_k <- length(k_range)

  return(optimal_k)
}

#' Find Optimal Number of Clusters (Silhouette Method)
#'
#' @param data Scaled data matrix
#' @param k_range Range of k values
#' @return Optimal number of clusters
find_optimal_clusters_silhouette <- function(data, k_range) {
  silhouette_scores <- sapply(k_range, function(k) {
    if (k >= 2 && k < nrow(data)) {
      km <- kmeans(data, centers = k, nstart = 25)
      ss <- silhouette(km$cluster, dist(data))
      mean(ss[, 3])
    } else {
      -1
    }
  })

  optimal_k <- k_range[which.max(silhouette_scores)]
  return(optimal_k)
}

#' Validate Clustering Results
#'
#' @param data Scaled data matrix
#' @param clusters Cluster assignments
#' @param config Configuration
#' @return Validation metrics
validate_clustering <- function(data, clusters, config) {

  validation <- list()

  # Silhouette score
  if (length(unique(clusters)) > 1) {
    sil <- silhouette(clusters, dist(data))
    validation$silhouette_score <- mean(sil[, 3])
  } else {
    validation$silhouette_score <- NA
  }

  # Calinski-Harabasz index
  if (length(unique(clusters)) > 1) {
    validation$calinski_harabasz <- cluster.stats(dist(data), clusters)$ch
  } else {
    validation$calinski_harabasz <- NA
  }

  # Davies-Bouldin index
  if (length(unique(clusters)) > 1) {
    validation$davies_bouldin <- cluster.stats(dist(data), clusters)$dunn
  } else {
    validation$davies_bouldin <- NA
  }

  return(validation)
}

#' Analyze Cluster Characteristics
#'
#' @param original_data Original patient data
#' @param clusters Cluster assignments
#' @param numeric_data Numeric data used for clustering
#' @return Cluster characteristics
analyze_cluster_characteristics <- function(original_data, clusters, numeric_data) {

  characteristics <- list()

  for (cluster_id in unique(clusters)) {
    cluster_data <- original_data[clusters == cluster_id, ]
    cluster_numeric <- numeric_data[clusters == cluster_id, ]

    characteristics[[paste0("cluster_", cluster_id)]] <- list(
      size = nrow(cluster_data),
      proportion = nrow(cluster_data) / nrow(original_data),
      means = colMeans(cluster_numeric, na.rm = TRUE),
      sds = apply(cluster_numeric, 2, sd, na.rm = TRUE),
      ranges = apply(cluster_numeric, 2, range, na.rm = TRUE)
    )
  }

  return(characteristics)
}

#' Dimensionality Reduction
#'
#' @param data Data matrix
#' @param config Configuration
#' @param method Reduction method
#' @param n_components Number of components
#' @return Reduced dimensionality data
perform_dimensionality_reduction <- function(data, config, method = "pca", n_components = 2) {

  message("Performing dimensionality reduction using ", method)

  # Prepare data
  numeric_data <- data[, sapply(data, is.numeric)]
  numeric_data <- na.omit(numeric_data)
  scaled_data <- scale(numeric_data)

  reduction_results <- list()
  reduction_results$method <- method
  reduction_results$n_components <- n_components
  reduction_results$original_data <- scaled_data

  if (method == "pca") {
    # Principal Component Analysis
    pca_result <- prcomp(scaled_data, center = TRUE, scale. = TRUE)
    reduction_results$model <- pca_result
    reduction_results$reduced_data <- pca_result$x[, 1:n_components]
    reduction_results$explained_variance <- pca_result$sdev^2 / sum(pca_result$sdev^2)
    reduction_results$loadings <- pca_result$rotation[, 1:n_components]

  } else if (method == "umap") {
    # UMAP dimensionality reduction
    umap_result <- umap(scaled_data, n_components = n_components)
    reduction_results$model <- umap_result
    reduction_results$reduced_data <- umap_result$layout

  } else if (method == "tsne") {
    # t-SNE dimensionality reduction
    perplexity <- min(config$dim_reduction$perplexity_range[
      config$dim_reduction$perplexity_range < nrow(scaled_data) / 3
    ])

    tsne_result <- Rtsne(scaled_data, dims = n_components, perplexity = perplexity)
    reduction_results$model <- tsne_result
    reduction_results$reduced_data <- tsne_result$Y
  }

  return(reduction_results)
}

#' Advanced Feature Selection
#'
#' @param data Feature matrix
#' @param target Target variable
#' @param config Configuration
#' @param method Feature selection method
#' @return Selected features
perform_advanced_feature_selection <- function(data, target, config, method = "boruta") {

  message("Performing advanced feature selection using ", method)

  # Prepare data
  feature_data <- data[, sapply(data, is.numeric)]
  feature_data <- na.omit(feature_data)

  if (nrow(feature_data) == 0) {
    stop("No valid numeric data available for feature selection")
  }

  feature_results <- list()
  feature_results$method <- method
  feature_results$original_features <- colnames(feature_data)

  if (method == "boruta") {
    # Boruta feature selection
    boruta_result <- Boruta(feature_data, target, doTrace = 0)
    feature_results$model <- boruta_result
    feature_results$selected_features <- getSelectedAttributes(boruta_result)
    feature_results$important_features <- getSelectedAttributes(boruta_result, withTentative = TRUE)
    feature_results$rejected_features <- getSelectedAttributes(boruta_result, withTentative = FALSE)

  } else if (method == "recursive_elimination") {
    # Recursive feature elimination
    control <- rfeControl(functions = rfFuncs, method = "cv", number = 5)
    rfe_result <- rfe(feature_data, target, sizes = c(1:ncol(feature_data)), rfeControl = control)
    feature_results$model <- rfe_result
    feature_results$selected_features <- predictors(rfe_result)
    feature_results$optimal_subset_size <- rfe_result$optsize

  } else if (method == "lasso") {
    # LASSO feature selection
    lasso_model <- cv.glmnet(as.matrix(feature_data), target, alpha = 1)
    coef_lasso <- coef(lasso_model, s = "lambda.min")
    selected <- which(coef_lasso[-1] != 0)  # Exclude intercept
    feature_results$model <- lasso_model
    feature_results$selected_features <- colnames(feature_data)[selected]
    feature_results$coefficients <- coef_lasso[selected + 1]

  } else if (method == "information_gain") {
    # Information gain feature selection
    weights <- information.gain(target ~ ., data = cbind(feature_data, target = target))
    important_features <- names(weights)[weights > config$feature_selection$importance_threshold]
    feature_results$model <- weights
    feature_results$selected_features <- important_features[1:min(length(important_features), config$feature_selection$max_features)]
  }

  return(feature_results)
}

#' Pattern Recognition in Treatment Trajectories
#'
#' @param longitudinal_data Longitudinal patient data
#' @param config Configuration
#' @return Pattern recognition results
recognize_treatment_patterns <- function(longitudinal_data, config) {

  message("Recognizing treatment patterns in longitudinal data")

  pattern_results <- list()

  # Group data by patient
  patient_groups <- split(longitudinal_data, longitudinal_data$patient_id)

  # Analyze patterns for each patient
  patient_patterns <- lapply(patient_groups, function(patient_data) {
    analyze_patient_trajectory(patient_data, config)
  })

  pattern_results$patient_patterns <- patient_patterns

  # Identify common patterns across patients
  pattern_results$common_patterns <- identify_common_patterns(patient_patterns, config)

  # Cluster patients based on trajectory patterns
  pattern_results$trajectory_clusters <- cluster_trajectory_patterns(patient_patterns, config)

  return(pattern_results)
}

#' Analyze Individual Patient Trajectory
#'
#' @param patient_data Single patient's longitudinal data
#' @param config Configuration
#' @return Trajectory analysis
analyze_patient_trajectory <- function(patient_data, config) {

  trajectory <- list()

  # Sort by time
  patient_data <- patient_data[order(patient_data$time), ]

  # Calculate trajectory metrics
  trajectory$length <- nrow(patient_data)
  trajectory$duration <- max(patient_data$time) - min(patient_data$time)
  trajectory$outcome_range <- range(patient_data$outcome, na.rm = TRUE)
  trajectory$outcome_trend <- calculate_trend(patient_data$outcome, patient_data$time)

  # Identify pattern type
  trajectory$pattern_type <- classify_trajectory_pattern(
    patient_data$outcome, patient_data$time, config
  )

  # Calculate pattern characteristics
  trajectory$characteristics <- calculate_pattern_characteristics(
    patient_data$outcome, patient_data$time
  )

  return(trajectory)
}

#' Calculate Trend in Trajectory
#'
#' @param outcome Outcome values
#' @param time Time points
#' @return Trend analysis
calculate_trend <- function(outcome, time) {
  if (length(outcome) < 3) return(list(slope = NA, r_squared = NA))

  model <- lm(outcome ~ time)
  slope <- coef(model)[2]
  r_squared <- summary(model)$r.squared

  return(list(slope = slope, r_squared = r_squared))
}

#' Classify Trajectory Pattern
#'
#' @param outcome Outcome values
#' @param time Time points
#' @param config Configuration
#' @return Pattern classification
classify_trajectory_pattern <- function(outcome, time, config) {

  if (length(outcome) < config$pattern_recognition$min_pattern_length) {
    return("insufficient_data")
  }

  # Calculate trend
  trend <- calculate_trend(outcome, time)

  # Calculate variability
  variability <- sd(outcome, na.rm = TRUE) / mean(outcome, na.rm = TRUE)

  # Classify pattern
  if (abs(trend$slope) < 0.01) {
    pattern <- "stable"
  } else if (trend$slope > 0.01) {
    pattern <- "progression"
  } else {
    pattern <- "improvement"
  }

  # Check for fluctuation
  if (variability > 0.2 && abs(trend$slope) < 0.05) {
    pattern <- "fluctuation"
  }

  return(pattern)
}

#' Calculate Pattern Characteristics
#'
#' @param outcome Outcome values
#' @param time Time points
#' @return Pattern characteristics
calculate_pattern_characteristics <- function(outcome, time) {

  characteristics <- list()

  # Basic statistics
  characteristics$mean <- mean(outcome, na.rm = TRUE)
  characteristics$sd <- sd(outcome, na.rm = TRUE)
  characteristics$min <- min(outcome, na.rm = TRUE)
  characteristics$max <- max(outcome, na.rm = TRUE)

  # Rate of change
  if (length(outcome) > 1) {
    characteristics$rate_of_change <- diff(outcome) / diff(time)
    characteristics$avg_rate_of_change <- mean(characteristics$rate_of_change, na.rm = TRUE)
  }

  # Stability measures
  characteristics$coefficient_of_variation <- characteristics$sd / characteristics$mean

  return(characteristics)
}

#' Identify Common Patterns Across Patients
#'
#' @param patient_patterns List of patient pattern analyses
#' @param config Configuration
#' @return Common pattern analysis
identify_common_patterns <- function(patient_patterns, config) {

  common_patterns <- list()

  # Extract pattern types
  pattern_types <- sapply(patient_patterns, function(p) p$pattern_type)

  # Count pattern frequencies
  common_patterns$pattern_distribution <- table(pattern_types)

  # Calculate pattern characteristics summary
  characteristics_matrix <- do.call(rbind, lapply(patient_patterns, function(p) {
    c(p$characteristics$mean, p$characteristics$sd, p$characteristics$avg_rate_of_change)
  }))

  colnames(characteristics_matrix) <- c("mean_outcome", "sd_outcome", "avg_rate_change")

  common_patterns$characteristics_summary <- list(
    means = colMeans(characteristics_matrix, na.rm = TRUE),
    sds = apply(characteristics_matrix, 2, sd, na.rm = TRUE)
  )

  return(common_patterns)
}

#' Cluster Patients Based on Trajectory Patterns
#'
#' @param patient_patterns List of patient pattern analyses
#' @param config Configuration
#' @return Trajectory clustering results
cluster_trajectory_patterns <- function(patient_patterns, config) {

  # Extract features for clustering
  pattern_features <- do.call(rbind, lapply(patient_patterns, function(p) {
    c(
      p$characteristics$mean,
      p$characteristics$sd,
      p$characteristics$avg_rate_of_change,
      as.numeric(factor(p$pattern_type, levels = config$pattern_recognition$pattern_types))
    )
  }))

  # Handle missing values
  pattern_features <- na.omit(pattern_features)

  if (nrow(pattern_features) < 3) {
    return(list(error = "Insufficient data for trajectory clustering"))
  }

  # Scale features
  scaled_features <- scale(pattern_features)

  # Perform clustering
  optimal_k <- find_optimal_clusters_silhouette(scaled_features, 2:8)
  km_result <- kmeans(scaled_features, centers = optimal_k, nstart = 25)

  trajectory_clusters <- list(
    clusters = km_result$cluster,
    centers = km_result$centers,
    optimal_k = optimal_k,
    features = pattern_features
  )

  return(trajectory_clusters)
}

#' Generate Advanced Analytics Report
#'
#' @param analytics_results Results from advanced analytics
#' @param output_dir Output directory
#' @return Report path
generate_advanced_analytics_report <- function(analytics_results, output_dir = "output") {

  if (!dir.exists(output_dir)) {
    dir.create(output_dir, recursive = TRUE)
  }

  report_path <- file.path(output_dir, "advanced_analytics_report.html")

  # Create report content
  report_content <- paste0(
    "<!DOCTYPE html>
    <html>
    <head>
        <title>Advanced Analytics Report</title>
        <style>
            body { font-family: Arial, sans-serif; margin: 40px; }
            h1, h2, h3 { color: #2E86AB; }
            table { border-collapse: collapse; width: 100%; margin: 20px 0; }
            th, td { border: 1px solid #ddd; padding: 8px; text-align: left; }
            th { background-color: #f2f2f2; }
            .summary-box { background-color: #f9f9f9; padding: 15px; border-radius: 5px; margin: 20px 0; }
        </style>
    </head>
    <body>
        <h1>Advanced Analytics Report</h1>
        <p><strong>Generated on:</strong> ", format(Sys.time(), "%Y-%m-%d %H:%M:%S"), "</p>

        <div class='summary-box'>
            <h2>Analysis Summary</h2>
            <p>This report summarizes the advanced analytics performed on the AUS-OA dataset,
            including patient clustering, dimensionality reduction, feature selection, and pattern recognition.</p>
        </div>"
    )

        # Add clustering results if available
        if ("clustering" %in% names(analytics_results)) {
            report_content <- paste0(report_content,
                "<h2>Patient Clustering Results</h2>
                <p><strong>Method:</strong> ", analytics_results$clustering$method, "</p>
                <p><strong>Number of Clusters:</strong> ", analytics_results$clustering$optimal_k, "</p>
                <p><strong>Silhouette Score:</strong> ", round(analytics_results$clustering$validation$silhouette_score, 3), "</p>

                <h3>Cluster Characteristics</h3>
                <table>
                    <tr><th>Cluster</th><th>Size</th><th>Proportion</th></tr>",
                    paste(sapply(names(analytics_results$clustering$characteristics), function(cluster_name) {
                        char <- analytics_results$clustering$characteristics[[cluster_name]]
                        paste0("<tr><td>", cluster_name, "</td><td>", char$size, "</td><td>",
                               round(char$proportion * 100, 1), "%</td></tr>")
                    }), collapse = ""),
                "</table>"
            )
        }

        # Add pattern recognition results if available
        if ("patterns" %in% names(analytics_results)) {
            report_content <- paste0(report_content,
                "<h2>Pattern Recognition Results</h2>
                <h3>Pattern Distribution</h3>
                <table>
                    <tr><th>Pattern Type</th><th>Count</th><th>Proportion</th></tr>",
                    paste(sapply(names(analytics_results$patterns$common_patterns$pattern_distribution), function(pattern) {
                        count <- analytics_results$patterns$common_patterns$pattern_distribution[pattern]
                        total <- sum(analytics_results$patterns$common_patterns$pattern_distribution)
                        paste0("<tr><td>", pattern, "</td><td>", count, "</td><td>",
                               round(count / total * 100, 1), "%</td></tr>")
                    }), collapse = ""),
                "</table>"
            )
        }

        report_content <- paste0(report_content,
        "</body>
    </html>"
  )

  writeLines(report_content, report_path)
  message("Advanced analytics report saved to: ", report_path)

  return(report_path)
}
