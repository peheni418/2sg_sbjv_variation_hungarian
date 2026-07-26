# -- head -- #

# compare three trial-level rt exclusion criteria:
# 1) current: exclude rt > 4 s (build_data.R / exclude_slow)
# 2) raw MAD: exclude rt outside overall median +- 3 MAD
#    (median absolute deviation, stats::mad(); read literally, "mean
#    absolute deviation" would give a different, non-standard quantity,
#    but MAD is the conventional robust threshold that pairs with a
#    median reference point, so it is used here)
# 3) log MAD: same median +- 3 MAD rule, but computed on log(rt) and
#    converted back -- rt is right-skewed, which inflates the raw-scale
#    MAD asymmetrically (Leys et al. 2013 recommend working on a scale
#    where the distribution is roughly symmetric first)

setwd('~/Github/2sg_sbjv_variation_hungarian/')

library(here)
library(tidyverse)
library(glmmTMB)
library(performance)
library(broom.mixed)

set.seed(1337)

# -- read -- #

d = read_csv(here('dat', 'clean_data.csv'))

# -- thresholds -- #

# current: fixed 4 s cutoff, already flagged as exclude_slow in build_data.R
current_cutoff = 4

# alternative: overall (all-trial) median +- 3 MAD
rt_median = median(d$key_resp_5.rt, na.rm = TRUE)
rt_mad    = mad(d$key_resp_5.rt, na.rm = TRUE)
mad_lower = rt_median - 3 * rt_mad
mad_upper = rt_median + 3 * rt_mad

# log MAD: same rule on log(rt), window converted back to the rt scale
log_rt        = log(d$key_resp_5.rt)
log_median    = median(log_rt, na.rm = TRUE)
log_mad       = mad(log_rt, na.rm = TRUE)
mad_log_lower = exp(log_median - 3 * log_mad)
mad_log_upper = exp(log_median + 3 * log_mad)

d = d |>
  mutate(
    exclude_mad     = key_resp_5.rt < mad_lower     | key_resp_5.rt > mad_upper,
    exclude_mad_log = key_resp_5.rt < mad_log_lower  | key_resp_5.rt > mad_log_upper
  )

cat('current cutoff: rt >', current_cutoff, 's\n')
cat('raw MAD window: [', round(mad_lower, 3), ',', round(mad_upper, 3), '] s\n')
cat('log MAD window: [', round(mad_log_lower, 3), ',', round(mad_log_upper, 3), '] s\n')

# -- exclusion overlap -- #

# how many trials each criterion flags, and how much they agree
overlap = d |>
  count(exclude_slow, exclude_mad, exclude_mad_log) |>
  mutate(pct = round(100 * n / sum(n), 1))

overlap |> knitr::kable()

# -- apply exclusions -- #

# same downstream filters as fit.R; only the rt-based flag differs
base_filter = function(data, rt_flag) {
  data |>
    filter(
      stim_type != 'type_distractor',
      !exclude_bad_participant,
      !.data[[rt_flag]],
      !(key_resp_5.keys == 'f' & stim_type == 'type_target')
    ) |>
    mutate(
      rt   = key_resp_5.rt,
      item = primeHeni
    )
}

d_current = base_filter(d, 'exclude_slow')
d_mad     = base_filter(d, 'exclude_mad')
d_mad_log = base_filter(d, 'exclude_mad_log')

cat('current: n trials =', nrow(d_current), ', n participants =', n_distinct(d_current$participant), '\n')
cat('raw MAD: n trials =', nrow(d_mad),     ', n participants =', n_distinct(d_mad$participant),     '\n')
cat('log MAD: n trials =', nrow(d_mad_log), ', n participants =', n_distinct(d_mad_log$participant), '\n')

# -- distribution -- #

p1 = ggplot(d, aes(x = key_resp_5.rt)) +
  geom_histogram(bins = 60, fill = 'lightblue', colour = 'white') +
  geom_vline(xintercept = current_cutoff, linetype = 'dashed') +
  geom_vline(xintercept = mad_upper, linetype = 'dotted') +
  geom_vline(xintercept = mad_log_upper, linetype = 'dotdash') +
  theme_bw() +
  labs(
    x = 'RT (s)',
    y = 'count',
    title = 'RT distribution with all three exclusion cutoffs',
    subtitle = 'dashed = current (4 s), dotted = raw MAD, dot-dash = log MAD'
  )

ggsave(here('viz', 'compare_exclusion_criteria.png'), p1,
       width = 6, height = 4, dpi = 900)

# -- refit main model under each criterion -- #

fit_current = glmmTMB(
  rt ~ pair_type + (1|participant) + (1|item),
  family = Gamma(link = 'log'),
  data = d_current
)

fit_mad = glmmTMB(
  rt ~ pair_type + (1|participant) + (1|item),
  family = Gamma(link = 'log'),
  data = d_mad
)

fit_mad_log = glmmTMB(
  rt ~ pair_type + (1|participant) + (1|item),
  family = Gamma(link = 'log'),
  data = d_mad_log
)

# -- compare -- #

compare_performance(fit_current, fit_mad, fit_mad_log, metrics = 'common')

bind_rows(
  tidy(fit_current, conf.int = TRUE) |> mutate(criterion = 'current'),
  tidy(fit_mad,     conf.int = TRUE) |> mutate(criterion = 'raw_mad'),
  tidy(fit_mad_log, conf.int = TRUE) |> mutate(criterion = 'log_mad')
) |>
  filter(effect == 'fixed') |>
  select(criterion, term, estimate, std.error, conf.low, conf.high, p.value) |>
  knitr::kable(digits = 3)
