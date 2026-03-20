# ASSUMPTIONS TESTING SCRIPT
# Master's Thesis - Tanja Bekritsky
# Testing statistical assumptions for BASELINE demographic comparisons; "PRE" ONLY!
# Groups: FASTER (n=13), SCOTT (n=26), TAU (n=6)

# METHODOLOGICAL NOTES:
# 1. Levene's test uses center = median (more robust for unbalanced/non-normal data)
# 2. All tests conducted on BASELINE (PRE) data only
# 3. For reproducibility: If simulation-based p-values are used (e.g., Fisher's Exact
#    with simulate.p.value = TRUE), set.seed() should be specified and the number
#    of iterations (B) should be reported

library(readxl)
library(dplyr)
library(ggplot2)
library(car)      # for Levene's test
library(tidyr)
library(gridExtra)

cat("================================================================\n")
cat("    ASSUMPTIONS TESTING ")
cat("================================================================\n\n")

# ============================================================================
# LOAD DATA AND FILTER FOR BASELINE
# ============================================================================

# Load ALL data
# enter path to Excel with questionnaire scores and data of the subjects
data_all <- read_excel("", sheet = "FS_Questionnaire_final_scores20")

cat("✓ Data loaded successfully\n")
cat("  Total observations in file:", nrow(data_all), "\n")

# Check session distribution
cat("\nSession distribution in file:\n")
print(table(data_all$session, useNA = "ifany"))

# Group assignments
# enter subject IDs
faster_ids <- c("")

scott_ids <- c("")

tau_ids <- c("")

intervention_mapping <- data.frame(
  id = c(faster_ids, scott_ids, tau_ids),
  intervention_group = c(rep("FASTER", length(faster_ids)),
                         rep("SCOTT", length(scott_ids)),
                         rep("TAU", length(tau_ids)))
)

# Filter for our IDs AND for PRE session only!
data <- data_all %>%
  left_join(intervention_mapping, by = "id") %>%
  filter(!is.na(intervention_group)) %>%
  filter(session == "PRE")

data$intervention_group <- factor(data$intervention_group, levels = c("FASTER", "SCOTT", "TAU"))

cat("\n✓ FILTERED FOR BASELINE (PRE) ONLY\n")
cat("  FASTER:", sum(data$intervention_group == "FASTER"), "\n")
cat("  SCOTT:", sum(data$intervention_group == "SCOTT"), "\n")
cat("  TAU:", sum(data$intervention_group == "TAU"), "\n")
cat("  TOTAL:", nrow(data), "\n\n")

# Verification: Should be 13 + 26 + 6 = 45
if (nrow(data) != 45) {
  warning("⚠ WARNING: Expected 45 baseline observations but got ", nrow(data))
}

# ============================================================================
# CONVERT DATA TYPES
# ============================================================================

cat("Converting data types...\n")

numeric_cols <- c("age", "AQ_sum_score", "BDI_sum_score", "SRS_sum_score", 
                  "CFT_20-R", "WURS_K_sum_score", "TAS26_sum_score")

for (col in numeric_cols) {
  if (col %in% names(data)) {
    if (!is.numeric(data[[col]])) {
      data[[col]] <- as.numeric(as.character(data[[col]]))
    }
  }
}

cat("✓ Data types converted\n\n")

# Define variables
continuous_vars <- list(
  AGE = "age",
  AQ10 = "AQ_sum_score",
  BDI = "BDI_sum_score",
  SRS = "SRS_sum_score",
  CFT20 = "CFT_20-R",
  WURS_K = "WURS_K_sum_score",
  TAS26 = "TAS26_sum_score"
)

categorical_vars <- list(
  GENDER = "gender",
  MEDICATION = "Psychopharmaka",
  COMORBIDITY = "Weitere_Diagnosen"
)

# ============================================================================
# 1. NORMALITY TESTS (Shapiro-Wilk)
# ============================================================================

cat("================================================================\n")
cat("1. NORMALITY TESTS (Shapiro-Wilk)\n")
cat("================================================================\n\n")

normality_results <- data.frame()

for (var_name in names(continuous_vars)) {
  var_col <- continuous_vars[[var_name]]
  
  cat("Testing:", var_name, "\n")
  
  for (grp in c("FASTER", "SCOTT", "TAU")) {
    subset_data <- data %>%
      filter(intervention_group == grp, !is.na(.data[[var_col]]))
    
    if (nrow(subset_data) >= 3) {
      shapiro_test <- shapiro.test(subset_data[[var_col]])
      
      is_normal <- ifelse(shapiro_test$p.value > 0.05, "YES ✓", "NO ✗")
      
      normality_results <- rbind(normality_results, data.frame(
        Variable = var_name,
        Group = grp,
        n = nrow(subset_data),
        W = shapiro_test$statistic,
        p_value = shapiro_test$p.value,
        Normal = is_normal,
        stringsAsFactors = FALSE
      ))
      
      cat(sprintf("  %s (n=%d): W = %.3f, p = %.3f %s\n", 
                  grp, nrow(subset_data), shapiro_test$statistic, 
                  shapiro_test$p.value, is_normal))
    }
  }
  cat("\n")
}

# Save
# path to desired output directory
output_dir <- ""
if (!dir.exists(output_dir)) dir.create(output_dir, recursive = TRUE)

write.csv(normality_results, file.path(output_dir, "1_normality_tests.csv"), row.names = FALSE)

cat("✓ Normality results saved\n\n")

# ============================================================================
# 2. LEVENE'S TEST (Variance Homogeneity)
# ============================================================================

cat("================================================================\n")
cat("2. LEVENE'S TEST (Variance Homogeneity)\n")
cat("================================================================\n\n")

levene_results <- data.frame()

for (var_name in names(continuous_vars)) {
  var_col <- continuous_vars[[var_name]]
  
  test_data <- data %>%
    filter(!is.na(.data[[var_col]]), !is.na(intervention_group))
  
  if (nrow(test_data) > 0) {
    # Use median-based Levene test (more robust for unbalanced/non-normal data)
    levene_test <- leveneTest(test_data[[var_col]] ~ test_data$intervention_group, 
                              center = median)
    
    f_stat <- levene_test$`F value`[1]
    df1 <- levene_test$Df[1]
    df2 <- levene_test$Df[2]
    p_val <- levene_test$`Pr(>F)`[1]
    
    is_homogeneous <- ifelse(p_val > 0.05, "YES ✓", "NO ✗")
    
    levene_results <- rbind(levene_results, data.frame(
      Variable = var_name,
      F_statistic = f_stat,
      df1 = df1,
      df2 = df2,
      p_value = p_val,
      Homogeneous = is_homogeneous,
      stringsAsFactors = FALSE
    ))
    
    cat(sprintf("%s: F(%d,%d) = %.3f, p = %.3f %s\n", 
                var_name, df1, df2, f_stat, p_val, is_homogeneous))
  }
}

write.csv(levene_results, file.path(output_dir, "2_levene_tests.csv"), row.names = FALSE)

cat("\n✓ Levene's test results saved\n\n")

# ============================================================================
# 3. OUTLIER DETECTION (IQR Method)
# ============================================================================

cat("================================================================\n")
cat("3. OUTLIER DETECTION (IQR Method)\n")
cat("================================================================\n\n")

outlier_results <- data.frame()

for (var_name in names(continuous_vars)) {
  var_col <- continuous_vars[[var_name]]
  
  cat("Checking outliers for:", var_name, "\n")
  
  found_any <- FALSE
  
  for (grp in c("FASTER", "SCOTT", "TAU")) {
    subset_data <- data %>%
      filter(intervention_group == grp, !is.na(.data[[var_col]]))
    
    if (nrow(subset_data) >= 4) {
      Q1 <- quantile(subset_data[[var_col]], 0.25)
      Q3 <- quantile(subset_data[[var_col]], 0.75)
      IQR_val <- Q3 - Q1
      
      lower_bound <- Q1 - 1.5 * IQR_val
      upper_bound <- Q3 + 1.5 * IQR_val
      
      outliers <- subset_data %>%
        filter(.data[[var_col]] < lower_bound | .data[[var_col]] > upper_bound)
      
      if (nrow(outliers) > 0) {
        outlier_ids <- paste(outliers$id, collapse = ", ")
        outlier_vals <- paste(round(outliers[[var_col]], 1), collapse = ", ")
        
        outlier_results <- rbind(outlier_results, data.frame(
          Variable = var_name,
          Group = grp,
          n_outliers = nrow(outliers),
          outlier_ids = outlier_ids,
          outlier_values = outlier_vals,
          stringsAsFactors = FALSE
        ))
        
        cat(sprintf("  %s: %d outlier(s) - IDs: %s\n", grp, nrow(outliers), outlier_ids))
        found_any <- TRUE
      }
    }
  }
  
  if (!found_any) {
    outlier_results <- rbind(outlier_results, data.frame(
      Variable = var_name,
      Group = "None",
      n_outliers = 0,
      outlier_ids = "No outliers detected",
      outlier_values = "–",
      stringsAsFactors = FALSE
    ))
    cat("  No outliers detected\n")
  }
  
  cat("\n")
}

write.csv(outlier_results, file.path(output_dir, "3_outlier_detection.csv"), row.names = FALSE)

cat("✓ Outlier detection results saved\n\n")

# ============================================================================
# 4. CHI-SQUARE ASSUMPTIONS (Categorical Variables)
# ============================================================================

cat("================================================================\n")
cat("4. CHI-SQUARE ASSUMPTIONS (Categorical Variables)\n")
cat("================================================================\n\n")

chisq_results <- data.frame()

for (var_name in names(categorical_vars)) {
  var_col <- categorical_vars[[var_name]]
  
  cat("Checking:", var_name, "\n")
  
  # CRITICAL: For Gender, exclude DIVERSE to match final analysis
  if (var_name == "GENDER") {
    test_data <- data %>%
      filter(!is.na(.data[[var_col]]), 
             .data[[var_col]] %in% c("WOMAN", "MAN"))  # Exclude DIVERSE!
    
    contingency <- table(test_data$intervention_group, test_data[[var_col]])
    cat("  → Excluding 'diverse' category (tested only Female vs. Male)\n")
  } else {
    contingency <- table(data$intervention_group, data[[var_col]])
  }
  
  # Calculate expected frequencies
  row_totals <- rowSums(contingency)
  col_totals <- colSums(contingency)
  total <- sum(contingency)
  
  expected <- outer(row_totals, col_totals) / total
  
  min_expected <- min(expected)
  all_above_5 <- all(expected >= 5)
  
  recommendation <- ifelse(all_above_5, 
                          "Chi-square Test", 
                          "Fisher's Exact Test")
  
  chisq_results <- rbind(chisq_results, data.frame(
    Variable = var_name,
    Min_Expected = min_expected,
    All_Above_5 = all_above_5,
    Recommendation = recommendation,
    stringsAsFactors = FALSE
  ))
  
  cat(sprintf("  Minimum expected frequency: %.2f\n", min_expected))
  cat(sprintf("  All cells ≥ 5? %s\n", ifelse(all_above_5, "YES", "NO")))
  cat(sprintf("  Recommendation: %s\n\n", recommendation))
}

write.csv(chisq_results, file.path(output_dir, "4_chisquare_assumptions.csv"), row.names = FALSE)

cat("✓ Chi-square assumptions saved\n\n")

# ============================================================================
# 5. FINAL TEST RECOMMENDATIONS
# ============================================================================

cat("================================================================\n")
cat("5. FINAL TEST RECOMMENDATIONS\n")
cat("================================================================\n\n")

recommendations <- data.frame()

for (var_name in names(continuous_vars)) {
  norm_summary <- normality_results %>%
    filter(Variable == var_name) %>%
    summarise(n_normal = sum(grepl("YES", Normal)), 
              n_total = n())
  
  lev_result <- levene_results %>% filter(Variable == var_name)
  
  is_all_normal <- (norm_summary$n_normal == norm_summary$n_total)
  is_homogeneous <- ifelse(nrow(lev_result) > 0, 
                           grepl("YES", lev_result$Homogeneous), 
                           FALSE)
  
  if (is_all_normal && is_homogeneous) {
    test <- "ANOVA"
    posthoc <- "Tukey HSD"
    reason <- "Normal distribution + equal variances"
  } else if (is_all_normal && !is_homogeneous) {
    test <- "Welch's ANOVA"
    posthoc <- "Games-Howell"
    reason <- "Normal distribution but UNequal variances"
  } else {
    test <- "Kruskal-Wallis"
    posthoc <- "Dunn's Test"
    reason <- "Non-normal distribution"
  }
  
  recommendations <- rbind(recommendations, data.frame(
    Variable = var_name,
    Test = test,
    PostHoc = posthoc,
    Reason = reason,
    stringsAsFactors = FALSE
  ))
  
  cat(sprintf("%s: %s (%s)\n", var_name, test, reason))
}

for (var_name in names(categorical_vars)) {
  # Get actual recommendation from chi-square assumptions testing
  chisq_result <- chisq_results %>% filter(Variable == var_name)
  
  if (nrow(chisq_result) > 0) {
    test <- chisq_result$Recommendation
    reason <- if (chisq_result$All_Above_5) {
      sprintf("Expected frequencies ≥ 5 (min = %.2f)", chisq_result$Min_Expected)
    } else {
      sprintf("Expected frequencies < 5 (min = %.2f)", chisq_result$Min_Expected)
    }
  } else {
    # Fallback if somehow missing
    test <- "Fisher's Exact"
    reason <- "Expected frequencies not calculated"
  }
  
  recommendations <- rbind(recommendations, data.frame(
    Variable = var_name,
    Test = test,
    PostHoc = "–",
    Reason = reason,
    stringsAsFactors = FALSE
  ))
  
  cat(sprintf("%s: %s (%s)\n", var_name, test, reason))
}

write.csv(recommendations, file.path(output_dir, "5_FINAL_TEST_RECOMMENDATIONS_CORRECTED.csv"), row.names = FALSE)

cat("\n✓ Final recommendations saved\n\n")

# ============================================================================
# SUMMARY
# ============================================================================

cat("================================================================\n")
cat("                    SUMMARY\n")
cat("================================================================\n\n")

cat("✓ ALL ASSUMPTIONS TESTED ON BASELINE (PRE) DATA ONLY\n")
cat("✓ Correct sample sizes: FASTER=13, SCOTT=26, TAU=6\n")
cat("✓ All results saved to:", output_dir, "\n\n")

cat("Files created:\n")
cat("  1. 1_normality_tests.csv\n")
cat("  2. 2_levene_tests.csv\n")
cat("  3. 3_outlier_detection.csv\n")
cat("  4. 4_chisquare_assumptions.csv\n")
cat("  5. 5_FINAL_TEST_RECOMMENDATIONS.csv\n\n")

cat("================================================================\n\n")
