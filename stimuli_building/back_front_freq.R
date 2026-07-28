library(here)
library(tidyverse)
library(dplyr)


forms <- read_tsv(here('dat', 'corpus_short_long_pairs_wide.tsv'))
stimuli <- read_csv(here('stimuli_building', 'stimuli_psychopy.csv'))


# 2) make lookup table from forms (keep same col names)
forms_lookup = forms |>
  select(lemma, llfpm10, stem_harmony) |>
  distinct(lemma, .keep_all = TRUE)

# 3) from stimuli primeHeni, cut last 3 chars
#    then join on forms$lemma
out = stimuli |>
  mutate(
    lemma = str_sub(primeHeni, 1, -4)   # remove last 3 characters
  ) |>
  left_join(forms_lookup, by = "lemma") |>
  select(lemma, llfpm10, stem_harmony)

# 4) mean freq
freq_harmony <- out |>
  group_by(stem_harmony) |>
  summarise(mean_llfpm10 = mean(llfpm10, na.rm = TRUE))

print(freq_harmony)
