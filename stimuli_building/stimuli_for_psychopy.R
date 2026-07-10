library(arrow)       # Support for Arrow data formats (kept for project consistency)
library(tidyverse)   # Core tools for reading, reshaping, and manipulating data
library(dplyr)       # Data wrangling verbs used throughout
library(stringr)     # String pattern matching for xpostag filtering
library(glue)        # String interpolation (not directly used below)
library(ggplot2)     # Plotting distributions
library(here)        # Project-relative paths (portable across machines)
library(parquetize)  # Parquet helpers used with frequency data workflow

## ---------------------------------------------------- ##
## 1) Load pre-filtered lemma candidates for sampling  ##
## ---------------------------------------------------- ##

# Read the lemma pool produced by earlier filtering steps.
# This file should already reflect the corpus-based constraints.
lemma_list <- read_tsv(here("stimuli_building", "second_sg_sbjv_piped.tsv"))


## ---------------------------------------------- ##
## 2) Make random sampling reproducible           ##
## ---------------------------------------------- ##

# Set random seed so the same lemmas are sampled each time this script is run.
# This makes results stable and easy to reproduce in future reruns.
set.seed(123)

## ----------------------------------------------------------- ##
## 3) Draw the final lemma sample by design cell              ##
## ----------------------------------------------------------- ##

# Build a 48-lemma sample with fixed cell sizes:
# - monosyllabic: 8 back + 8 front
# - polysyllabic: 16 back + 16 front
# This is done by sampling inside each (lemma_length × stem_harmony) group.
sample1 <- bind_rows(
  lemma_list %>%
    filter(lemma_length == "mono") %>%
    group_by(lemma_length, stem_harmony) %>%
    slice_sample(n = 8, replace = FALSE) %>%
    ungroup(),
  
  lemma_list %>%
    filter(lemma_length == "poly") %>%
    group_by(lemma_length, stem_harmony) %>%
    slice_sample(n = 16, replace = FALSE) %>%
    ungroup()
)

# Quick sanity check: verify actual per-cell row counts.
print(sample1 %>% count(lemma_length, stem_harmony))


## ------------------------------------------------ ##
## 4) Inspect distribution of key control variables ##
## ------------------------------------------------ ##

# Reshape to long format so three numeric variables can be plotted in one faceted figure.
sample1_plot <- sample1 %>%
  pivot_longer(
    cols = c(llfpm10, log_odds_3sg_ind, long_short_sbjv_log_odds),
    names_to = "variable",
    values_to = "value"
  )

# Additional count check (same grouping after reshaping).
print(sample1_plot %>% count(lemma_length, stem_harmony))

# Plot boxplots by stem harmony for each variable.
# This helps confirm that front/back stems look distributionally reasonable.
ggplot(sample1_plot, aes(x = stem_harmony, y = value, fill = stem_harmony)) +
  geom_boxplot() +
  facet_wrap(~variable, scales = "free_y") +
  theme_minimal() +
  labs(
    title = "Sample 1 - Distribution by Stem Harmony",
    x = "Stem Harmony",
    y = "Value",
    fill = "Stem Harmony"
  )


## ------------------------------------------ ##
## 5) Keep only sampled lemma names          ##
## ------------------------------------------ ##

# Create a lemma-only table used to pull relevant inflected forms later.
final_lemma_list <- sample1 |> select(lemma)


## ---------------------------------------------------------- ##
## 6) Load frequency table and keep valid verb wordforms     ##
## ---------------------------------------------------------- ##

# Read full frequency table and keep high-frequency, spellchecked verbs.
# Also exclude auxiliaries/function items and a few manual exclusions.
real_verbs <- read_parquet(here("stimuli_building", "frequencies.parquet")) %>%
  filter(freq > 100) %>%
  filter(str_detect(xpostag, "\\[/V\\]")) %>%
  filter(!(lemma %in% c("van", "nincs", "volna", "lesz", "kell", "fog", "sincs", "a", "á"))) %>% 
  filter(hunspell == "TRUE")


## ------------------------------------------------------------ ##
## 7) Keep only needed paradigm cells for sampled lemmas       ##
## ------------------------------------------------------------ ##

# Restrict to sampled lemmas and keep only two forms needed for stimuli:
# - 2sg subjunctive definite
# - 3sg indicative definite
real_verbs_necessary <- real_verbs %>%
  semi_join(final_lemma_list, by = "lemma") %>%
  filter(xpostag %in% c("[/V][Sbjv.Def.2Sg]", "[/V][Prs.Def.3Sg]")) %>%
  group_by(lemma) %>%
  ungroup()

# Show sampled lemmas missing from retrieved forms.
# "fog" is absent here and was added manually later.
final_lemma_list %>%
  anti_join(real_verbs_necessary, by = "lemma")


## ------------------------------------------------------ ##
## 8) Reshape forms: one row per lemma, two form columns ##
## ------------------------------------------------------ ##

# Convert tag labels to cleaner column names, then pivot wide:
# lemma | second_sg_subj | third_sg_def
# If multiple forms exist in a cell, collapse with ", ".
real_verbs_necessary <- real_verbs_necessary %>%
  mutate(col_name = case_when(
    xpostag == "[/V][Sbjv.Def.2Sg]" ~ "second_sg_subj",
    xpostag == "[/V][Prs.Def.3Sg]"  ~ "third_sg_def"
  )) %>%
  pivot_wider(
    names_from = col_name,
    values_from = form,
    values_fn = ~ paste(., collapse = ", ")
  )

# Final lemma-form table for manual review/correction workflow.
stimuli_forms_list <- real_verbs_necessary %>%
  select(lemma, second_sg_subj, third_sg_def) %>%
  arrange(lemma)


## ---------------------------------------------------------------- ##
## 9) Load manually corrected wordform table for final build        ##
## ---------------------------------------------------------------- ##

# This file is a manually edited version that includes fixes:
# - missing inflected forms added
# - prefixed verbs replaced by similar-frequency non-prefixed verbs
stimuli_priming_2026 <- read_csv(here("stimuli_building", "stimuli_wordforms.csv"))


## ------------------------------------------------------------ ##
## 10) Create scrambled foil by swapping edge character pairs  ##
## ------------------------------------------------------------ ##

# For each long 2sg subj form:
# - split into characters
# - swap first 2 with last 2 characters
# - rejoin
# Result is stored as `scrambled`, used as distractor target type.
stimuli_priming_2026 <- stimuli_priming_2026 %>%
  mutate(scrambled = sapply(long_second_sg_subj, function(x) {
    chars <- strsplit(x, "")[[1]]
    n <- length(chars)
    chars[c(1, 2, n - 1, n)] <- chars[c(n - 1, n, 1, 2)]
    paste(chars, collapse = "")
  }))


## ------------------------------------------------------ ##
## 11) Standardize column names for easy downstream use  ##
## ------------------------------------------------------ ##

# Rename to generic temporary names used below in the loop.
# Mapping:
# col1 = short_second_sg_subj
# col2 = long_second_sg_subj
# col3 = third_sg_def
# col4 = scrambled
colnames(stimuli_priming_2026) <- c("col1", "col2", "col3", "col4")


## ---------------------------------------------------------- ##
## 12) Build PsychoPy stimulus table (prime-target format)   ##
## ---------------------------------------------------------- ##

# Pre-create empty output table.
# Each input row becomes 3 output rows:
#   A) prime=long, target=short,      type_target
#   B) prime=long, target=3sg_def,    type_target
#   C) prime=long, target=scrambled,  type_distractor
stimuli_psychopy <- data.frame(
  primeHeni = character(),
  targetHeni = character(),
  stim_type = character(),
  stringsAsFactors = FALSE
)

# Expand row-by-row into the three planned pair types.
for (i in 1:nrow(stimuli_priming_2026)) {
  stimuli_psychopy <- rbind(stimuli_psychopy, data.frame(
    primeHeni = stimuli_priming_2026$col2[i],
    targetHeni = stimuli_priming_2026$col1[i],
    stim_type = "type_target",
    stringsAsFactors = FALSE
  ))
  
  stimuli_psychopy <- rbind(stimuli_psychopy, data.frame(
    primeHeni = stimuli_priming_2026$col2[i],
    targetHeni = stimuli_priming_2026$col3[i],
    stim_type = "type_target",
    stringsAsFactors = FALSE
  ))
  
  stimuli_psychopy <- rbind(stimuli_psychopy, data.frame(
    primeHeni = stimuli_priming_2026$col2[i],
    targetHeni = stimuli_priming_2026$col4[i],
    stim_type = "type_distractor",
    stringsAsFactors = FALSE
  ))
}


## ------------------------------ ##
## 13) Save final PsychoPy table ##
## ------------------------------ ##

# Write final prime-target list for experiment runtime.
write.csv(stimuli_psychopy, "stimuli_psychopy.csv", row.names = FALSE)