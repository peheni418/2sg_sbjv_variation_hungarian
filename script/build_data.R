# -- head -- #

# wrangle raw psychopy csvs into a tidy clean_data.csv with exclusion flags,
# harmony class, and pair type.

setwd('~/Github/morphological_priming_hungarian/')

library(here)
library(tidyverse)

set.seed(1337)

# NB: one participant submitted their neptun code (UMIZ4M) as the id.
# rename it to a 6-digit number in raw_data/ before running.

# -- read -- #

# one csv per participant; the filename starts with a 6-digit id
d = list.files(
    here('raw_data'),
    pattern = '^[0-9]{6}_priming\\.csv$',
    full.names = TRUE
  ) |>
  map_df(\(x) {
    read.csv(x) |>
      mutate(participant = str_extract(basename(x), '^[0-9]{6}'))
  })

d = d |>
  select(participant, key_resp_5.keys, key_resp_5.rt, primeHeni, targetHeni, stim_type) |>
  drop_na()

# -- exclusions -- #

# slow trials: rt > 4 s
d = d |>
  mutate(exclude_slow = key_resp_5.rt > 4)

# bad participants: error rate > .5
# (error = 'f' on a target or 'j' on a distractor)
d = d |>
  mutate(
    error = case_when(
      stim_type == 'type_target'     & key_resp_5.keys == 'f' ~ 1,
      stim_type == 'type_distractor' & key_resp_5.keys == 'j' ~ 1,
      TRUE ~ 0
    )
  ) |>
  mutate(
    error_rate = mean(error),
    exclude_bad_participant = error_rate > .5,
    .by = participant
  ) |>
  select(-error)

# -- harmony class -- #

# front if target ends in 'i', else back
d = d |>
  mutate(harmony_class = if_else(str_ends(targetHeni, 'i'), 'front', 'back'))

# carry the class to primes that appear paired with a front target
front_primes = d |>
  filter(harmony_class == 'front') |>
  pull(primeHeni) |>
  unique()

d = d |>
  mutate(harmony_class = if_else(primeHeni %in% front_primes, 'front', harmony_class))

# -- pair type -- #

# cross harmony (front/back) with target shape (cell = ends in 'd', else form)
d = d |>
  mutate(
    pair_type = case_when(
      stim_type == 'type_distractor'                          ~ NA_character_,
      harmony_class == 'front' &  str_ends(targetHeni, 'd')   ~ 'front_cell',
      harmony_class == 'front' & !str_ends(targetHeni, 'd')   ~ 'front_form',
      harmony_class == 'back'  &  str_ends(targetHeni, 'd')   ~ 'back_cell',
      harmony_class == 'back'  & !str_ends(targetHeni, 'd')   ~ 'back_form'
    )
  )

# -- write -- #

write_csv(d, here('dat', 'clean_data.csv'))
