# -- head -- #

# wrangle raw psychopy csvs into a tidy clean_data.csv with exclusion flags,
# harmony class, and pair type.

setwd('~/Github/2sg_sbjv_variation_hungarian/')

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


# -- completion -- #

# completed participant: exactly 144 trials
d = d |>
  mutate(
    n_trials = n(),
    complete = n_trials == 144,
    .by = participant
  ) |>
  select(-n_trials)

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


# -- completion time -- #

# completion time per participant:
# from first instructions.started to last end_2.stopped
completion_time = list.files(
  here('raw_data'),
  pattern = '^[0-9]{6}_priming\\.csv$',
  full.names = TRUE
) |>
  map_df(\(x) {
    tmp = read.csv(x)
    tibble(
      participant = str_extract(basename(x), '^[0-9]{6}'),
      completion_time_sec =
        max(tmp$end_2.stopped, na.rm = TRUE) -
        min(tmp$instructions.started, na.rm = TRUE)
    )
  })

# attach participant-level completion time to all rows
d = d |>
  left_join(completion_time, by = 'participant')

# print median completion time (seconds) to console
cat('Median completion time (sec):', median(completion_time$completion_time_sec, na.rm = TRUE), '\n')

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

# -- add cols -- #


# keep correct ('j') target trials from good participants, fast trials only
d2 = d |>
  # 1) keep only completed participants
  filter(complete) |>
  # 2) apply trial/quality filters within completed participants
  filter(
    stim_type != 'type_distractor',
    !exclude_bad_participant,
    !exclude_slow,
    !(key_resp_5.keys == 'f' & stim_type == 'type_target')
  ) |>
  mutate(
    rt   = key_resp_5.rt,
    item = primeHeni,
    pair_type = factor(pair_type, levels = pair_order)
  )

# -- write -- #

write_csv(d, here('dat', 'clean_data_unfiltered.csv'))
write_csv(d2, here('dat', 'clean_data_filtered.csv'))
