# -- head -- #

# compare the four prereg hypotheses (H0-H3) by fitting one glmm per hypothesis
# and comparing them via AIC, BIC, RMSE, and BIC-based Bayes factors.
# https://aspredicted.org/92c82r.pdf

setwd('~/Github/morphological_priming_hungarian/')

library(here)
library(tidyverse)
library(glmmTMB)
library(performance)
library(sjPlot)
library(DHARMa)

set.seed(1337)

# -- read -- #

d = read_csv(here('dat', 'clean_data.csv'))

# -- setup -- #

# correct target trials only; same filter as fit.R / viz.R
d = d |>
  filter(
    stim_type != 'type_distractor',
    !exclude_bad_participant,
    !exclude_slow,
    !(key_resp_5.keys == 'f' & stim_type == 'type_target')
  ) |>
  mutate(
    item = primeHeni,
    rt = key_resp_5.rt,
    condition = pair_type |>
      fct_relevel('back_cell', 'front_cell', 'back_form', 'front_form')
  )

# -- prereg conditions -- #

# A - back  same-cell:   prime várjad → target várd
# B - back  form-similar: prime várjad → target várja
# C - front same-cell:   prime kérjed → target kérd
# D - front form-similar: prime kérjed → target kéri
#
# H0: A = B = C = D
# H1 (morphological blocking):     A,C > B,D
# H2 (phonological facilitation):  B < A,C,D
# H3 (both effects):               A,C > D; B < D

d = d |>
  mutate(
    # H1: same-cell vs form-similar
    condition_h1 = fct_collapse(condition,
      'cell' = c('back_cell', 'front_cell'),
      'form' = c('back_form', 'front_form')
    ),
    # H2: back_form vs everything else
    condition_h2 = fct_collapse(condition,
      'other'     = c('back_cell', 'front_cell', 'front_form'),
      'back_form' = 'back_form'
    ),
    # H3: cell vs back_form vs front_form
    condition_h3 = fct_collapse(condition,
      'cell'       = c('back_cell', 'front_cell'),
      'back_form'  = 'back_form',
      'front_form' = 'front_form'
    )
  )

# -- fits -- #

# one fit per hypothesis; H0 is intercept-only (no contrast)
h0 = glmmTMB(rt ~ 1            + (1|participant) + (1|item), data = d, family = Gamma(link = 'log'))
h1 = glmmTMB(rt ~ condition_h1 + (1|participant) + (1|item), data = d, family = Gamma(link = 'log'))
h2 = glmmTMB(rt ~ condition_h2 + (1|participant) + (1|item), data = d, family = Gamma(link = 'log'))
h3 = glmmTMB(rt ~ condition_h3 + (1|participant) + (1|item), data = d, family = Gamma(link = 'log'))

# -- diagnostics -- #

# overdispersion ok
check_overdispersion(h1)
check_overdispersion(h2)
check_overdispersion(h3)
# autocorrelation ok
check_autocorrelation(h1)
check_autocorrelation(h2)
check_autocorrelation(h3)
# residuals look fine
check_residuals(h1)
check_residuals(h2)
check_residuals(h3)
simulateResiduals(h1, plot = TRUE)
simulateResiduals(h2, plot = TRUE)
simulateResiduals(h3, plot = TRUE)

# -- model selection -- #

# H1 wins on AIC and BIC
plot(compare_performance(h0, h1, h2, h3, metrics = 'common'))

test_performance(h0, h1) # H1 better than null
test_bf(h0, h1)          # H1 ~2.7x better than H0
test_bf(h2, h1)          # H1 ~6.4x better than H2
test_bf(h3, h1)          # H1 ~40x  better than H3

# -- table -- #

# tidy summary table for the paper
t1 = compare_performance(h0, h1, h2, h3, metrics = 'common') |>
  tibble()

bf2 = test_bf(h0, h1)
bf3 = test_bf(h2, h1)
bf4 = test_bf(h3, h1)

bfs       = tibble(BF = as.double(c(bf2$BF[2], '', bf3$BF[2], bf4$BF[2])))
bf_names  = tibble(BF_comparison = c('H1 vs H0', '', 'H1 vs H2', 'H1 vs H3'))
t1 = bind_cols(t1, bf_names, bfs)

t1 |>
  select(Name, AIC, BIC, RMSE, BF_comparison, BF) |>
  knitr::kable(digits = 2)
