library(arrow)      # Tools for parquet/arrow formats (not directly used below, but often useful in this project)
library(tidyverse)  # Core data science collection: readr, tidyr, dplyr, ggplot2, etc.
library(dplyr)      # Data manipulation verbs (filter, mutate, summarise, ...)
library(stringr)    # String pattern matching (str_detect)
library(glue)       # String interpolation (not directly used below)
library(ggplot2)    # Plotting
library(here)       # Project-relative file paths (safer than setwd)

## ----------------------------- ##
## 1) Read and pre-filter input ##
## ----------------------------- ##

# Read the raw lemma-level table from the project folder.
# `here("stimuli_building", "2sg.sbjv - forms.tsv")` builds a path relative to project root,
# so this script can run on different machines without hard-coded absolute paths.
second_sg_sbjv <- read_tsv(here("stimuli_building", "2sg.sbjv - forms.tsv")) %>%
  
  # Keep only lemmas with log lemma frequency above 2.
  # This removes very rare lemmas and keeps items more likely to be known.
  filter(llfpm10 > 2) %>% 
  
  # Remove rows marked as indefinite 2sg subjunctive in `subj_2nd`.
  # The goal is to keep the subset relevant for your definite-form stimulus design.
  filter(!str_detect(subj_2nd, "indef"))


## ------------------------------------------------------- ##
## 2) Keep complete rows for the 3 key control variables ##
## ------------------------------------------------------- ##

# Remove rows with missing values in any variable used in the balancing filters.
# This is important because median calculations and distance-based filters need numeric values.
second_sg_sbjv <- second_sg_sbjv %>%
  filter(!is.na(llfpm10) & !is.na(log_odds_3sg_ind) & !is.na(long_short_sbjv_log_odds))


## ---------------------------------------- ##
## 3) Compute medians used as anchor points ##
## ---------------------------------------- ##

# Median of lemma frequency (llfpm10):
median_llfpm10 <- median(second_sg_sbjv$llfpm10, na.rm = TRUE)

# Median of 3sg definite-vs-indefinite log-odds:
median_log_odds_3sg_ind <- median(second_sg_sbjv$log_odds_3sg_ind, na.rm = TRUE)

# Median of long-vs-short subjunctive log-odds:
median_long_short_sbjv_log_odds <- median(second_sg_sbjv$long_short_sbjv_log_odds, na.rm = TRUE)


## ------------------------------------------------------------ ##
## 4) Explore threshold values and inspect surviving row count ##
## ------------------------------------------------------------ ##

# This loop tries multiple threshold values (0.1, 0.2, ..., 2.0).
# For each threshold, it applies the three distance-based filters and prints remaining row count.
# Purpose: find a threshold that leaves ~90 rows.
for (threshold in seq(0.1, 2, 0.1)) {
  second_sg_sbjv_piped <- second_sg_sbjv %>%
    
    # FREQUENCY FILTER:
    # Keep rows at a moderate distance from median llfpm10:
    #   - greater than threshold*0.2 (exclude too-close-to-median values)
    #   - less than threshold*1.2 (exclude far outliers)
    filter(abs(llfpm10 - median_llfpm10) > threshold * 0.2 & 
             abs(llfpm10 - median_llfpm10) < threshold * 1.2) %>%
    
    # LONG/SHORT LOG-ODDS FILTER:
    # Similar logic, but with a wider upper bound (threshold*8),
    # allowing a broader spread while still excluding near-median and extreme tails.
    filter(abs(long_short_sbjv_log_odds - median_long_short_sbjv_log_odds) > threshold * 0.2 & 
             abs(long_short_sbjv_log_odds - median_long_short_sbjv_log_odds) < threshold * 8) %>%
    
    # 3SG DEF/INDEF LOG-ODDS FILTER:
    # Keep rows close to median (no lower bound), i.e. avoid large imbalance in this measure.
    filter(abs(log_odds_3sg_ind - median_log_odds_3sg_ind) < threshold * 1.0)
  
  # Print how many rows remain at this threshold.
  cat("Threshold", threshold, "->", nrow(second_sg_sbjv_piped), "rows\n")
}


## ---------------------------------------------------------- ##
## 5) Quick numeric summaries of the final filtered dataset ##
## ---------------------------------------------------------- ##

# Summary stats after filtering:
# min, 1st quartile, median, mean, 3rd quartile, max.
summary(second_sg_sbjv_piped$llfpm10)
summary(second_sg_sbjv_piped$log_odds_3sg_ind)
summary(second_sg_sbjv_piped$long_short_sbjv_log_odds)  


## ------------------------------------------------------- ##
## 6) Histograms for the three key filtering dimensions   ##
## ------------------------------------------------------- ##

# Show three histograms side-by-side for the final filtered set.
# Useful to inspect distribution shape and detect remaining skew/outliers.
par(mfrow = c(1, 3))
hist(second_sg_sbjv_piped$llfpm10, main = "llfpm10")
hist(second_sg_sbjv_piped$log_odds_3sg_ind, main = "log_odds_3sg_ind")
hist(second_sg_sbjv_piped$long_short_sbjv_log_odds, main = "long_short_sbjv_log_odds")
par(mfrow = c(1, 1))  # reset plotting layout


## ---------------------------------------------------------- ##
## 7) Compare variable distributions by stem harmony (plot) ##
## ---------------------------------------------------------- ##

# Reshape from wide to long so one ggplot can facet over all three numeric variables.
second_sg_sbjv_long <- second_sg_sbjv_piped %>%
  pivot_longer(cols = c(llfpm10, log_odds_3sg_ind, long_short_sbjv_log_odds),
               names_to = "variable",
               values_to = "value")

# Violin plots by stem_harmony (front/back), faceted by variable.
# This helps check whether front vs. back stems have similar/acceptable distributions
# for each controlled dimension.
ggplot(second_sg_sbjv_long, aes(x = stem_harmony, y = value, fill = stem_harmony)) +
  geom_violin() +
  facet_wrap(~variable, scales = "free_y") +
  theme_minimal() +
  labs(title = "Distribution of Variables by Stem Harmony",
       x = "Stem Harmony",
       y = "Value",
       fill = "Stem Harmony")


## ------------------------------------------------------ ##
## 8) Check availability for later stratified sampling   ##
## ------------------------------------------------------ ##

# These checks answer: do we have enough rows in broad categories before final item selection?
sum(second_sg_sbjv_piped$lemma_length == "mono")
sum(second_sg_sbjv_piped$lemma_length == "poly")
sum(second_sg_sbjv_piped$stem_harmony == "back")
sum(second_sg_sbjv_piped$stem_harmony == "front")


## ------------------------- ##
## 9) Save filtered output  ##
## ------------------------- ##

# Write the filtered table to disk for use in downstream scripts.
write_tsv(second_sg_sbjv_piped, "second_sg_sbjv_piped.tsv")