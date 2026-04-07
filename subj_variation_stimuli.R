library(arrow)
library(parquetize)
library(tidyverse)
library(dplyr)
library(stringr)
library(glue)


# --  Getting the most frequent verbs, excluding auxiliaries and hunspell FALSE -- #

real_verbs <- read_parquet("C:/Users/Pokk Heni/Downloads/frequencies.parquet") %>%
  filter(freq > 100) %>%
  filter(str_detect(xpostag, "\\[/V\\]")) %>%
  filter(!(lemma %in% c("van", "nincs", "volna", "lesz", "kell", "fog", "sincs", "a", 'á'))) %>% 
  filter(hunspell == "TRUE")


# --  imperative long/short pairs  -- #

imperative <- real_verbs %>%
  filter(str_detect(xpostag, "\\[Sbjv\\.(Def|NDef)\\.2Sg\\]")) %>%  # Both Def and NDef
  group_by(lemma, xpostag) %>%
  filter(n_distinct(form) > 1) %>%  # Multiple forms per xpostag
  ungroup() %>%
  arrange(lemma, xpostag, form)

n_distinct(imperative$lemma) #240

# -- Petya 2sg.sbjv -- #

second_sg_sbjv <- read_tsv("C:/Users/Pokk Heni/Downloads/2sg.sbjv - forms.tsv")


# -- definite form keep, indef exclude

imperative_def <- imperative %>% 
  filter(!str_detect(xpostag, "NDef"))



# Find lemmas that exist in both tables
common_lemmas <- intersect(imperative_def$lemma, second_sg_sbjv$lemma)


n_distinct(imperative_def$lemma) # 112
n_distinct(second_sg_sbjv$lemma) # 1486
n_common <- length(common_lemmas) #70


petya_es_en_lemma <- tibble(lemma = common_lemmas) %>%
  arrange(lemma)


write_tsv(imperative, "imperative.tsv")
getwd()
setwd("C:/Users/Pokk Heni/Documents/Péhádédoktoriphd/2025_26_elso_ev/toldalekos_kisi/masodik_etikus_verzio/kiserlet")

write_tsv(imperative_def, "imperative_def.tsv")

write_tsv(second_sg_sbjv, "second_sg_sbjv.tsv")

# -- keeping only common lemmas in petya table

stimuli_lemma <- second_sg_sbjv %>%
  semi_join(
    tibble(lemma = common_lemmas),
    by = "lemma"
  )

stimuli_lemma <- stimuli_lemma %>%
  filter(!str_detect(lemma, "^kérd$")) #mert volt benne egy árva kérd



# -- creating pipe for llfpm10>stem/def>long/short


median_llfpm10 <- median(stimuli_lemma$llfpm10, na.rm = TRUE)
median_log_odds_3sg_ind <- median(stimuli_lemma$log_odds_3sg_ind, na.rm = TRUE)
median_long_short_sbjv_log_odds <- median(stimuli_lemma$long_short_sbjv_log_odds, na.rm = TRUE)

for (threshold in seq(0.1, 2, 0.1)) {
  stimuli_lemma_filtered <- stimuli_lemma %>%
    filter(abs(llfpm10 - median_llfpm10) > threshold * 0.2 & 
             abs(llfpm10 - median_llfpm10) < threshold * 1.2) %>%
    filter(abs(long_short_sbjv_log_odds - median_long_short_sbjv_log_odds) > threshold * 0.2 & 
             abs(long_short_sbjv_log_odds - median_long_short_sbjv_log_odds) < threshold * 8) %>%
    filter(abs(log_odds_3sg_ind - median_log_odds_3sg_ind) < threshold * 2)
  
  cat("Threshold", threshold, "->", nrow(stimuli_lemma_filtered), "rows\n")
}





# --ja amúgy az indef nem is kell:

stim_lemma_metadata <- stimuli_lemma_filtered %>%
  filter(subj_2nd != "indef")

stim_wordform_list_all <- imperative_def


# -- keeping all forms in stim_wordform_list that are in _stim_lemma_metadata

stim_wordform_list <- stim_wordform_list_all %>%
  semi_join(stim_lemma_metadata, by = "lemma")


# -- spotted a single lemma "ér", getting rid of it

stim_wordform_list <- stim_wordform_list %>%
  filter(lemma != "ér")

stim_lemma_metadata <- stim_lemma_metadata %>%
  filter(lemma != "ér")

stim_wordform_list <- stim_wordform_list %>%
  filter(form != "keressd")




# -- ggplot for back/front

ggplot(stim_lemma_metadata, aes(x = stem_harmony, y = long_short_sbjv_log_odds)) +
  geom_violin() +
  geom_boxplot(width = 0.2) +
  labs(
    x = "stem_harmony",
    y = "long_short_sbjv_log_odds"
  ) +
  theme_grey()



setwd("C:/Users/Pokk Heni/Documents/Péhádédoktoriphd/2025_26_elso_ev/toldalekos_kisi/masodik_etikus_verzio/kiserlet/")
write_tsv(stim_wordform_list, "stim_wordform_list.tsv")
write_tsv(stim_lemma_metadata, "stim_lemma_metadata.tsv")
