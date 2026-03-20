# analysis of group differences in demographic an clinical variables
# Master's Thesis - Tanja Bekritsky

library(readxl)
library(dplyr)
library(FSA)
library(flextable)
library(officer)

cat("================================================================\n")
cat("   DEMOGRAPHIC ANALYSIS ")
cat("================================================================\n\n")

# Set seed ONCE at the beginning (in case simulation is needed)
set.seed(12345)
cat("✓ Random seed set to 12345 (for Fisher simulation if needed)\n\n")

# ============================================================================
# LOAD DATA
# ============================================================================

cat("Step 1: Loading data...\n")
# enter path to Excel with questionnaire scores and data of the subjects
data_all <- read_excel(, sheet = "FS_Questionnaire_final_scores20")
# enter subject IDs
faster_ids <- c()
scott_ids <- c()
tau_ids <- c()

intervention_mapping <- data.frame(
  id = c(faster_ids, scott_ids, tau_ids),
  intervention_group = c(rep("FASTER", length(faster_ids)),
                         rep("SCOTT", length(scott_ids)),
                         rep("TAU", length(tau_ids)))
)

# Filter for BASELINE (PRE) only
data <- data_all %>%
  left_join(intervention_mapping, by = "id") %>%
  filter(!is.na(intervention_group) & session == "PRE")

data$intervention_group <- factor(data$intervention_group, levels = c("FASTER", "SCOTT", "TAU"))

cat("  FASTER:", sum(data$intervention_group == "FASTER"), "\n")
cat("  SCOTT:", sum(data$intervention_group == "SCOTT"), "\n")
cat("  TAU:", sum(data$intervention_group == "TAU"), "\n\n")

# Convert to numeric
numeric_cols <- c("age", "AQ_sum_score", "BDI_sum_score", "SRS_sum_score", 
                  "CFT_20-R", "WURS_K_sum_score", "TAS26_sum_score")
for (col in numeric_cols) {
  if (col %in% names(data) && !is.numeric(data[[col]])) {
    data[[col]] <- as.numeric(as.character(data[[col]]))
  }
}

# Calculate TAS-26 MEAN ITEM SCORE
data$TAS26_mean_item <- data$TAS26_sum_score / 26

cat("✓ Data loaded and prepared\n\n")

# ============================================================================
# ANALYSES
# ============================================================================

cat("Step 2: Running analyses...\n\n")

continuous_vars <- list(
  Age = "age",
  AQ10 = "AQ_sum_score",
  BDI = "BDI_sum_score",
  SRS = "SRS_sum_score",
  `CFT-20` = "CFT_20-R",
  `WURS-K` = "WURS_K_sum_score",
  `TAS-26` = "TAS26_mean_item"
)

categorical_vars <- list(
  Gender = "gender",
  Medication = "Psychopharmaka",
  Comorbidity = "Weitere_Diagnosen"
)

# Kruskal-Wallis for continuous
run_kw <- function(data, var_col, var_label) {
  test_data <- data %>% filter(!is.na(.data[[var_col]]))
  
  desc <- test_data %>%
    group_by(intervention_group) %>%
    summarise(n = n(), mean = mean(.data[[var_col]]), sd = sd(.data[[var_col]]), .groups = "drop")
  
  missing <- data %>%
    group_by(intervention_group) %>%
    summarise(missing = sum(is.na(.data[[var_col]])), .groups = "drop")
  
  kw <- kruskal.test(test_data[[var_col]] ~ test_data$intervention_group)
  
  posthoc_text <- "–"
  if (kw$p.value < 0.05) {
    posthoc <- dunnTest(test_data[[var_col]] ~ test_data$intervention_group, method = "bonferroni")
    means <- test_data %>%
      group_by(intervention_group) %>%
      summarise(m = mean(.data[[var_col]]), .groups = "drop")
    
    sig <- posthoc$res %>% filter(P.adj < 0.05)
    if (nrow(sig) > 0) {
      comparisons <- c()
      for (i in 1:nrow(sig)) {
        grps <- strsplit(sig$Comparison[i], " - ")[[1]]
        m1 <- means$m[means$intervention_group == grps[1]]
        m2 <- means$m[means$intervention_group == grps[2]]
        comparisons <- c(comparisons, if(m1 > m2) paste(grps[1], ">", grps[2]) else paste(grps[2], ">", grps[1]))
      }
      posthoc_text <- paste(comparisons, collapse = " and ")
    }
  }
  
  list(desc = desc, kw = kw, posthoc_text = posthoc_text, missing = missing)
}

kw_results <- lapply(names(continuous_vars), function(v) run_kw(data, continuous_vars[[v]], v))
names(kw_results) <- names(continuous_vars)

# CORRECTED: Fisher's Exact with smart exact/simulation logic
run_fisher <- function(data, var_col, var_label) {
  
  if (var_label == "Gender") {
    # Filter out DIVERSE for the test
    cat("  Testing:", var_label, "(Female/Male only, excluding diverse)...")
    
    test_data <- data %>%
      filter(!is.na(.data[[var_col]])) %>%
      filter(.data[[var_col]] %in% c("WOMAN", "MAN"))
    
    contingency <- table(test_data$intervention_group, test_data[[var_col]])
    
    counts <- test_data %>%
      group_by(intervention_group, .data[[var_col]]) %>%
      summarise(n = n(), .groups = "drop")
    
    totals <- test_data %>%
      group_by(intervention_group) %>%
      summarise(total = n(), .groups = "drop")
    
  } else {
    cat("  Testing:", var_label, "...")
    
    test_data <- data %>% filter(!is.na(.data[[var_col]]))
    
    contingency <- table(test_data$intervention_group, test_data[[var_col]])
    
    counts <- test_data %>%
      group_by(intervention_group, .data[[var_col]]) %>%
      summarise(n = n(), .groups = "drop")
    
    totals <- test_data %>%
      group_by(intervention_group) %>%
      summarise(total = n(), .groups = "drop")
  }
  
  # CORRECTED LOGIC: Try exact first, simulate only if needed
  fisher <- tryCatch({
    # Try exact computation first (no simulation)
    fisher.test(contingency)
  }, error = function(e) {
    # If exact fails (too computationally intensive), use simulation
    cat("\n  → Exact computation failed, using Monte Carlo simulation (B=100,000)...")
    fisher.test(contingency, simulate.p.value = TRUE, B = 100000)
  })
  
  desc <- left_join(counts, totals, by = "intervention_group") %>%
    mutate(percent = (n / total) * 100)
  
  missing <- data %>%
    group_by(intervention_group) %>%
    summarise(missing = sum(is.na(.data[[var_col]])), .groups = "drop")
  
  cat(" Done\n")
  
  # Store whether simulation was used
  used_simulation <- !is.null(fisher$method) && grepl("Monte Carlo", fisher$method)
  
  list(desc = desc, fisher = fisher, missing = missing, simulated = used_simulation)
}

fisher_results <- lapply(names(categorical_vars), function(v) run_fisher(data, categorical_vars[[v]], v))
names(fisher_results) <- names(categorical_vars)

cat("\n✓ All analyses complete\n\n")

# Check if any used simulation
any_simulated <- any(sapply(fisher_results, function(x) x$simulated))
if (any_simulated) {
  cat("ℹ Note: Some Fisher tests used Monte Carlo simulation (100,000 iterations)\n\n")
} else {
  cat("ℹ Note: All Fisher tests used exact computation (no simulation needed)\n\n")
}

# ============================================================================
# FORMAT TABLE
# ============================================================================

cat("Step 3: Formatting table...\n\n")

sig_stars <- function(p) {
  if (is.na(p)) return("")
  if (p < 0.0001) return("***")
  if (p < 0.001) return("***")
  if (p < 0.01) return("**")
  if (p < 0.05) return("*")
  return("")
}

table_data <- data.frame()

# Continuous
for (v in names(continuous_vars)) {
  r <- kw_results[[v]]
  
  faster <- r$desc %>% filter(intervention_group == "FASTER")
  scott <- r$desc %>% filter(intervention_group == "SCOTT")
  tau <- r$desc %>% filter(intervention_group == "TAU")
  
  faster_val <- if(nrow(faster) > 0) sprintf("%.1f ± %.1f", faster$mean, faster$sd) else "–"
  scott_val <- if(nrow(scott) > 0) sprintf("%.1f ± %.1f", scott$mean, scott$sd) else "–"
  tau_val <- if(nrow(tau) > 0) sprintf("%.1f ± %.1f", tau$mean, tau$sd) else "–"
  
  test_stat <- sprintf("H₂ = %.2f%s", r$kw$statistic, sig_stars(r$kw$p.value))
  
  missing_text <- if(sum(r$missing$missing) == 0) "–" else {
    paste(r$missing %>% filter(missing > 0) %>% 
            mutate(t = paste0(intervention_group, " = ", missing)) %>% 
            pull(t), collapse = ", ")
  }
  
  display_name <- if(v == "Age") "Age, Years" else if(v == "TAS-26") "TAS-26ᵃ" else v
  
  table_data <- rbind(table_data, data.frame(
    Measurement = display_name,
    FASTER = faster_val,
    SCOTT = scott_val,
    TAU = tau_val,
    Test_Statistic = test_stat,
    Post_Hoc = r$posthoc_text,
    Data_Missing = missing_text,
    stringsAsFactors = FALSE
  ))
}

# Categorical
for (v in names(categorical_vars)) {
  r <- fisher_results[[v]]
  
  if (v == "Gender") {
    get_gender <- function(desc, grp) {
      female <- desc %>% filter(intervention_group == grp, gender == "WOMAN") %>% pull(n)
      male <- desc %>% filter(intervention_group == grp, gender == "MAN") %>% pull(n)
      sprintf("%d/%d", if(length(female)>0) female else 0, if(length(male)>0) male else 0)
    }
    
    faster_val <- get_gender(r$desc, "FASTER")
    scott_val <- get_gender(r$desc, "SCOTT")
    tau_val <- get_gender(r$desc, "TAU")
    
    display_name <- "Gender, Female/Maleᵇ"
  } else {
    get_yes <- function(desc, grp) {
      var_col_name <- categorical_vars[[v]]
      yes_row <- desc %>% 
        filter(intervention_group == grp, .data[[var_col_name]] %in% c("YES", "yes", 1, "1"))
      if(nrow(yes_row) > 0) sprintf("%d (%.1f)", yes_row$n, yes_row$percent) else "0 (0.0)"
    }
    
    faster_val <- get_yes(r$desc, "FASTER")
    scott_val <- get_yes(r$desc, "SCOTT")
    tau_val <- get_yes(r$desc, "TAU")
    
    display_name <- paste0(v, ", n (%)")
  }
  
  test_stat <- sprintf("p = %s%s", format.pval(r$fisher$p.value, digits = 3, eps = 0.001), 
                       sig_stars(r$fisher$p.value))
  
  missing_text <- if(sum(r$missing$missing) == 0) "–" else {
    paste(r$missing %>% filter(missing > 0) %>% 
            mutate(t = paste0(intervention_group, " = ", missing)) %>% 
            pull(t), collapse = ", ")
  }
  
  table_data <- rbind(table_data, data.frame(
    Measurement = display_name,
    FASTER = faster_val,
    SCOTT = scott_val,
    TAU = tau_val,
    Test_Statistic = test_stat,
    Post_Hoc = "–",
    Data_Missing = missing_text,
    stringsAsFactors = FALSE
  ))
}

# ============================================================================
# CREATE WORD DOCUMENT
# ============================================================================

cat("Step 4: Creating Word document...\n\n")

ft <- flextable(table_data)

ft <- set_header_labels(ft,
  Measurement = "Measurement",
  FASTER = "FASTER\n(n = 13)",
  SCOTT = "SCOTT\n(n = 26)",
  TAU = "TAU\n(n = 6)",
  Test_Statistic = "Test Statistic",
  Post_Hoc = "Post Hoc\nComparison",
  Data_Missing = "Data Missing, n"
)

# APA FORMAT
ft <- border_remove(ft)
ft <- hline_top(ft, border = fp_border(width = 2), part = "header")
ft <- hline_bottom(ft, border = fp_border(width = 2), part = "header")
ft <- hline_bottom(ft, border = fp_border(width = 2), part = "body")

ft <- fontsize(ft, size = 12, part = "all")
ft <- font(ft, fontname = "Times New Roman", part = "all")
ft <- align(ft, align = "center", part = "header")
ft <- align(ft, j = 2:7, align = "center", part = "body")
ft <- align(ft, j = 1, align = "left", part = "body")
ft <- bold(ft, part = "header")
ft <- autofit(ft)

doc <- read_docx()

doc <- body_add_par(doc, "")
doc <- body_add_fpar(doc, fpar(ftext("Table 1", prop = fp_text(bold = TRUE, font.size = 12, font.family = "Times New Roman"))))
doc <- body_add_par(doc, "")

doc <- body_add_fpar(doc, fpar(ftext("Demographic and Clinical Characteristics by Treatment Group", 
                                     prop = fp_text(italic = TRUE, font.size = 12, font.family = "Times New Roman"))))
doc <- body_add_par(doc, "")

doc <- body_add_flextable(doc, ft)
doc <- body_add_par(doc, "")

# Footnotes - CORRECTED to reflect exact/simulation logic
note_text <- if (any_simulated) {
  "Values are presented as n or mean ± SD. Between-group differences for continuous variables were tested using Kruskal-Wallis H tests. For categorical variables, Fisher's Exact Test was used. Fisher's Exact Test p-values were computed exactly where feasible; when exact computation was infeasible, Monte Carlo simulation with 100,000 iterations was used (seed = 12345 for reproducibility)."
} else {
  "Values are presented as n or mean ± SD. Between-group differences for continuous variables were tested using Kruskal-Wallis H tests. For categorical variables, Fisher's Exact Test was used with exact p-value computation."
}

doc <- body_add_par(doc, note_text, style = "Normal")
doc <- body_add_par(doc, "")

doc <- body_add_par(doc, "*Significant at p < .05; **significant at p < .01; ***significant at p < .0001.", 
                    style = "Normal")
doc <- body_add_par(doc, "")

abbrev_text <- "AQ10, Brief Autism Quotient; BDI, Beck Depression Inventory; CFT-20, Culture Fair Intelligence Test; FASTER = [Full intervention name]; SCOTT = [Full intervention name]; SRS, Social Responsiveness Scale; TAU, Treatment as Usual; TAS-26, Toronto Alexithymia Scale-26; WURS-K, Wender Utah Rating Scale-Kurzform. ᵃTAS-26 scores are reported as mean item scores (sum score divided by 26 items). ᵇGender was assessed with three categories (female, male, diverse); two participants in the SCOTT group identified as diverse. For statistical analysis, a comparison between female and male participants across the three treatment groups was conducted using Fisher's Exact Test (diverse participants excluded from the statistical test)."

doc <- body_add_par(doc, abbrev_text, style = "Normal")

# Save
# path to desired output directory
output_dir <- ""
if (!dir.exists(output_dir)) dir.create(output_dir, recursive = TRUE)

output_file <- file.path(output_dir, "Table1_Demographics.docx")
print(doc, target = output_file)

cat("✓ Word document created!\n")
cat("  Location:", output_file, "\n\n")

write.csv(table_data, file.path(output_dir, "table_data_final.csv"), row.names = FALSE)

cat("================================================================\n")
cat("                    COMPLETE!\n")
cat("================================================================\n\n")
cat("FISHER'S EXACT TEST LOGIC:\n")
if (any_simulated) {
  cat("  → Some tests used Monte Carlo (B=100,000, seed=12345)\n")
  cat("  → This is documented in the table footnote\n")
} else {
  cat("  → All tests used exact computation (no simulation needed)\n")
  cat("  → This is the preferred method!\n")
}
cat("\nAll other improvements maintained:\n")
cat("  ✓ Gender: Female/Male only (diverse excluded)\n")
cat("  ✓ TAS-26: Mean item scores\n")
cat("  ✓ Baseline (PRE) data only\n\n")
