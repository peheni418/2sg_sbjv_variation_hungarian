# -- head -- #

# wrangle raw psychopy csvs into a tidy clean_data.csv with exclusion flags,
# harmony class, and pair type.

setwd('~/Github/2sg_sbjv_variation_hungarian/')

library(here)
library(tidyverse)

set.seed(1337)

# ids were anonymised (script/anonymise_ids.R, one-off, gitignored): raw_data
# filenames and the internal `participant` column both use participant1..N
# now, in place of the original neptun codes / psychopy-assigned ids.

# -- read -- #

# one csv per participant; the filename is participantN_priming.csv.
# abandoned sessions can be so short that psychopy never got to writing some
# columns at all (e.g. key_resp_5.keys), or wrote one that's entirely blank,
# which read.csv() then infers as logical instead of character -- either way
# bind_rows() across files fails on the schema mismatch unless every file is
# normalised to the same five columns, with the same types, before binding
needed_chr = c('key_resp_5.keys', 'primeH', 'targetH', 'stim_type')

# participant3, participant22, participant41, participant42: pilot/test runs
# by the research team (originally named 0420, 420, lanyok, proba in
# raw_data, before ids were anonymised), not study participants. the old
# filenames didn't match the strict 6-digit pattern this glob used to use, so
# they were never read in; excluded explicitly now so that generalising the
# pattern for the new participantN names doesn't silently pull them in and
# change clean_data_unfiltered.csv's reported totals
test_session_ids = c('participant3', 'participant22', 'participant41', 'participant42')

d = list.files(
    here('raw_data'),
    pattern = '^participant[0-9]+_priming\\.csv$',
    full.names = TRUE
  ) |>
  discard(\(x) str_extract(basename(x), '^participant[0-9]+') %in% test_session_ids) |>
  map_df(\(x) {
    raw = read.csv(x)
    for (col in c(needed_chr, 'key_resp_5.rt')) {
      if (!col %in% names(raw)) raw[[col]] = NA
    }
    raw |>
      mutate(
        participant = str_extract(basename(x), '^participant[0-9]+'),
        across(all_of(needed_chr), as.character),
        key_resp_5.rt = as.numeric(key_resp_5.rt)
      ) |>
      select(participant, all_of(needed_chr), key_resp_5.rt)
  })

d = d |>
  select(participant, key_resp_5.keys, key_resp_5.rt, primeH, targetH, stim_type) |>
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
  pattern = '^participant[0-9]+_priming\\.csv$',
  full.names = TRUE
) |>
  discard(\(x) str_extract(basename(x), '^participant[0-9]+') %in% test_session_ids) |>
  map_df(\(x) {
    tmp = read.csv(x)
    tibble(
      participant = str_extract(basename(x), '^participant[0-9]+'),
      completion_time_sec =
        max(tmp$end_2.stopped, na.rm = TRUE) -
        min(tmp$instructions.started, na.rm = TRUE)
    )
  })

# attach participant-level completion time to all rows
d = d |>
  left_join(completion_time, by = 'participant')

# print median completion time (seconds) to console. restricted to finite
# values: a session that never reached the end screen has end_2.stopped
# entirely NA, so max(..., na.rm = TRUE) returns -Inf -- not a real
# completion time, and broadening the file glob above (for the id
# anonymisation) now pulls a few such abandoned sessions into this list
# that weren't matched before
finite_times = completion_time$completion_time_sec[is.finite(completion_time$completion_time_sec)]
cat('Median completion time (sec):', median(finite_times, na.rm = TRUE), '\n')

# -- harmony class -- #

# front if target ends in 'i', else back
d = d |>
  mutate(harmony_class = if_else(str_ends(targetH, 'i'), 'front', 'back'))

# carry the class to primes that appear paired with a front target
front_primes = d |>
  filter(harmony_class == 'front') |>
  pull(primeH) |>
  unique()

d = d |>
  mutate(harmony_class = if_else(primeH %in% front_primes, 'front', harmony_class))

# -- pair type -- #

# cross harmony (front/back) with target shape (cell = ends in 'd', else form)
d = d |>
  mutate(
    pair_type = case_when(
      stim_type == 'type_distractor'                          ~ NA_character_,
      harmony_class == 'front' &  str_ends(targetH, 'd')   ~ 'front_cell',
      harmony_class == 'front' & !str_ends(targetH, 'd')   ~ 'front_form',
      harmony_class == 'back'  &  str_ends(targetH, 'd')   ~ 'back_cell',
      harmony_class == 'back'  & !str_ends(targetH, 'd')   ~ 'back_form'
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
    item = primeH
  )

# -- write -- #

write_csv(d, here('dat', 'clean_data_unfiltered.csv'))
write_csv(d2, here('dat', 'clean_data_filtered.csv'))
