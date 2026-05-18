library(arrow)
library(parquetize)
library(tidyverse)
library(dplyr)
library(stringr)
library(glue)
library(ggplot2)

lemma_list <- read_tsv("C:/Users/Pokk Heni/Documents/Péhádédoktoriphd/2025_26_elso_ev/toldalekos_kisi/masodik_etikus_verzio/kiserlet/second_sg_sbjv_piped.tsv")


## 32 rows
# Set seed for reproducibility
set.seed(123)

##Sampling
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


print(sample1 %>% count(lemma_length, stem_harmony))


## checking distributions with plots


# Create long format for both samples
sample1_plot <- sample1 %>%
  pivot_longer(cols = c(llfpm10, log_odds_3sg_ind, long_short_sbjv_log_odds),
               names_to = "variable",
               values_to = "value")

print(sample1_plot %>% count(lemma_length, stem_harmony))


# Plot Sample 
ggplot(sample1_plot, aes(x = stem_harmony, y = value, fill = stem_harmony)) +
  geom_boxplot() +
  facet_wrap(~variable, scales = "free_y") +
  theme_minimal() +
  labs(title = "Sample 1 - Distribution by Stem Harmony",
       x = "Stem Harmony",
       y = "Value",
       fill = "Stem Harmony")


## creating lemma list
final_lemma_list <- sample1 |> select(lemma)

real_verbs <- read_parquet("C:/Users/Pokk Heni/Downloads/frequencies.parquet") %>%
  filter(freq > 100) %>%
  filter(str_detect(xpostag, "\\[/V\\]")) %>%
  filter(!(lemma %in% c("van", "nincs", "volna", "lesz", "kell", "fog", "sincs", "a", 'á'))) %>% 
  filter(hunspell == "TRUE")



real_verbs_necessary <- real_verbs %>%
  semi_join(final_lemma_list, by = "lemma") %>%
  filter(xpostag %in% c("[/V][Sbjv.Def.2Sg]", "[/V][Prs.Def.3Sg]")) %>%
  group_by(lemma) %>%
  ungroup()


final_lemma_list %>%
  anti_join(real_verbs_necessary, by = "lemma") ## fog lemma is missing from real_verbs_necessary, so it is added manually to the stimuli



real_verbs_necessary <- real_verbs_necessary %>%
  mutate(col_name = case_when(
    xpostag == "[/V][Sbjv.Def.2Sg]" ~ "second_sg_subj",
    xpostag == "[/V][Prs.Def.3Sg]"  ~ "third_sg_def"
  )) %>%
  pivot_wider(
    names_from = col_name,
    values_from = form,
    values_fn = ~paste(., collapse = ", ")
    
  )

stimuli_forms_list <- real_verbs_necessary %>%
  select(lemma, second_sg_subj, third_sg_def) %>%
  arrange(lemma)

# tudja [/V][Prs.Def.3Sg]
# tudjad, tudd [/V][Sbjv.Def.2Sg]


## manually corrected table from stimuli_forms_list

stimuli_priming_2026 <- read_tsv("C:/Users/Pokk Heni/Documents/Péhádédoktoriphd/2025_26_elso_ev/toldalekos_kisi/masodik_etikus_verzio/kiserlet/stimuli.tsv")


##scrambling for foils: first 2 and last 2 chars switch places
stimuli_priming_2026 <- stimuli_priming_2026 %>%
  mutate(scrambled = sapply(long_second_sg_subj, function(x) {
    chars <- strsplit(x, "")[[1]]
    n <- length(chars)
    # swap first 2 and last 2 positions
    chars[c(1, 2, n-1, n)] <- chars[c(n-1, n, 1, 2)]
    paste(chars, collapse = "")
  }))


## reorganizing the columns

stimuli_priming_2026 <- read_csv("C:/Users/Pokk Heni/Documents/Péhádédoktoriphd/2025_26_elso_ev/toldalekos_kisi/masodik_etikus_verzio/kiserlet/psycho/stimuli_priming_2026 - forms+scrambled.csv")


# Rename columns for clarity
colnames(stimuli_priming_2026) <- c("col1", "col2", "col3", "col4")
# col1 = short_second_sg_subj
# col2 = long_second_sg_subj
# col3 = third_sg_def
# col4 = scrambled

# Create the reorganized table
stimuli_psychopy <- data.frame(
  primeHeni = character(),
  targetHeni = character(),
  stim_type = character(),
  stringsAsFactors = FALSE
)

# Loop through each row and create three rows
for (i in 1:nrow(stimuli_priming_2026)) {
  # Row 1: col2 (prime) + col1 (target from col1)
  stimuli_psychopy <- rbind(stimuli_psychopy, data.frame(
    primeHeni = stimuli_priming_2026$col2[i],
    targetHeni = stimuli_priming_2026$col1[i],
    stim_type = "type_target",
    stringsAsFactors = FALSE
  ))
  
  # Row 2: col2 (prime) + col3 (target from col3)
  stimuli_psychopy <- rbind(stimuli_psychopy, data.frame(
    primeHeni = stimuli_priming_2026$col2[i],
    targetHeni = stimuli_priming_2026$col3[i],
    stim_type = "type_target",
    stringsAsFactors = FALSE
  ))
  
  # Row 3: col2 (prime) + col4 (target from col4)
  stimuli_psychopy <- rbind(stimuli_psychopy, data.frame(
    primeHeni = stimuli_priming_2026$col2[i],
    targetHeni = stimuli_priming_2026$col4[i],
    stim_type = "type_distractor",
    stringsAsFactors = FALSE
  ))
}

# Save the CSV
setwd("C:/Users/Pokk Heni/Documents/Péhádédoktoriphd/2025_26_elso_ev/toldalekos_kisi/masodik_etikus_verzio/kiserlet/psycho")
write.csv(stimuli_psychopy, "stimuli_psychopy.csv", row.names = FALSE)
