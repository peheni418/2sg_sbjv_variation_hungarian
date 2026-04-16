library(arrow)
library(parquetize)
library(tidyverse)
library(dplyr)
library(stringr)
library(glue)
library(ggplot2)

# Load data directly from GitHub repository
data_url <- "https://raw.githubusercontent.com/peheni418/morphological_priming_hungarian/main/2sg.sbjv%20-%20forms.tsv"

second_sg_sbjv <- read_tsv(data_url) %>%
  filter(llfpm10 > 2) %>% 
  filter(!str_detect(subj_2nd, "indef"))



## filtering for llfpm10, def/indef and long/short

# First, remove NAs from the three columns
# Clean data with NAs removed
second_sg_sbjv <- second_sg_sbjv %>%
  filter(!is.na(llfpm10) & !is.na(log_odds_3sg_ind) & !is.na(long_short_sbjv_log_odds))

# Calculate medians
median_llfpm10 <- median(second_sg_sbjv$llfpm10, na.rm = TRUE)
median_log_odds_3sg_ind <- median(second_sg_sbjv$log_odds_3sg_ind, na.rm = TRUE)
median_long_short_sbjv_log_odds <- median(second_sg_sbjv$long_short_sbjv_log_odds, na.rm = TRUE)


for (threshold in seq(0.1, 2, 0.1)) {
  second_sg_sbjv_piped <- second_sg_sbjv %>%
    filter(abs(llfpm10 - median_llfpm10) > threshold * 0.2 & 
             abs(llfpm10 - median_llfpm10) < threshold * 1.2) %>%
    filter(abs(long_short_sbjv_log_odds - median_long_short_sbjv_log_odds) > threshold * 0.2 & 
             abs(long_short_sbjv_log_odds - median_long_short_sbjv_log_odds) < threshold * 8) %>%
    filter(abs(log_odds_3sg_ind - median_log_odds_3sg_ind) < threshold * 1.0)
  
  cat("Threshold", threshold, "->", nrow(second_sg_sbjv_piped), "rows\n")
}

#checking for everything

#numbers

summary(second_sg_sbjv_piped$llfpm10)
summary(second_sg_sbjv_piped$log_odds_3sg_ind)
summary(second_sg_sbjv_piped$long_short_sbjv_log_odds)  

#plots
par(mfrow = c(1, 3))
hist(second_sg_sbjv_piped$llfpm10, main = "llfpm10")
hist(second_sg_sbjv_piped$log_odds_3sg_ind, main = "log_odds_3sg_ind")
hist(second_sg_sbjv_piped$long_short_sbjv_log_odds, main = "long_short_sbjv_log_odds")
par(mfrow = c(1, 1))


## all 3 aspects split by back and front


# Create a long format for easier plotting
second_sg_sbjv_long <- second_sg_sbjv_piped %>%
  pivot_longer(cols = c(llfpm10, log_odds_3sg_ind, long_short_sbjv_log_odds),
               names_to = "variable",
               values_to = "value")

# Create violin plots split by stem_harmony
ggplot(second_sg_sbjv_long, aes(x = stem_harmony, y = value, fill = stem_harmony)) +
  geom_violin() +
  facet_wrap(~variable, scales = "free_y") +
  theme_minimal() +
  labs(title = "Distribution of Variables by Stem Harmony",
       x = "Stem Harmony",
       y = "Value",
       fill = "Stem Harmony")


sum(second_sg_sbjv_piped$lemma_length == "mono")
sum(second_sg_sbjv_piped$lemma_length == "poly")
sum(second_sg_sbjv_piped$stem_harmony == "back")
sum(second_sg_sbjv_piped$stem_harmony == "front")

## 36 rows
# Set seed for reproducibility
set.seed(123)

# Sample 1
sample1 <- second_sg_sbjv_piped %>%
  group_by(lemma_length, stem_harmony) %>%
  slice_sample(n = 8, replace = FALSE) %>%
  ungroup()


# Set different seed for Sample 2
set.seed(456)

sample2 <- second_sg_sbjv_piped %>%
  group_by(lemma_length, stem_harmony) %>%
  slice_sample(n = 8, replace = FALSE) %>%
  ungroup()


print(sample1 %>% count(lemma_length, stem_harmony))
print(sample2 %>% count(lemma_length, stem_harmony))

## checking distributions with plots


# Create long format for both samples
sample1_plot <- sample1 %>%
  pivot_longer(cols = c(llfpm10, log_odds_3sg_ind, long_short_sbjv_log_odds),
               names_to = "variable",
               values_to = "value")

sample2_plot <- sample2 %>%
  pivot_longer(cols = c(llfpm10, log_odds_3sg_ind, long_short_sbjv_log_odds),
               names_to = "variable",
               values_to = "value")

print(sample1_plot %>% count(lemma_length, stem_harmony))
print(sample2_plot %>% count(lemma_length, stem_harmony))


# Plot Sample 1
ggplot(sample1_plot, aes(x = stem_harmony, y = value, fill = stem_harmony)) +
  geom_violin() +
  facet_wrap(~variable, scales = "free_y") +
  theme_minimal() +
  labs(title = "Sample 1 - Distribution by Stem Harmony",
       x = "Stem Harmony",
       y = "Value",
       fill = "Stem Harmony")

# Plot Sample 2
ggplot(sample2_plot, aes(x = stem_harmony, y = value, fill = stem_harmony)) +
  geom_violin() +
  facet_wrap(~variable, scales = "free_y") +
  theme_minimal() +
  labs(title = "Sample 2 - Distribution by Stem Harmony",
       x = "Stem Harmony",
       y = "Value",
       fill = "Stem Harmony")


# Save output to current working directory
# Use setwd("your/folder/path") beforehand if needed, or replace with a full path
write_tsv(second_sg_sbjv_piped, "second_sg_sbjv_piped.tsv")
