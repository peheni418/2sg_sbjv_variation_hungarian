# -- head -- #

# definte four hypotheses for the corpus that look like our exp prereg hypotheses
# compare them by fitting one glmm per hypothesis
# and comparing them via AIC, BIC, RMSE, and BIC-based Bayes factors.
# https://aspredicted.org/92c82r.pdf

setwd('~/Github/2sg_sbjv_variation_hungarian/')

library(here)
library(tidyverse)
library(glmmTMB)
library(performance)
library(sjPlot)
library(DHARMa)

set.seed(1337)

# -- read -- #

d = read_tsv(here('dat', 'corpus_dat_summary_with_props.tsv'))

# -- scale -- #

d = d |> 
  mutate(
    llfpm10_scaled = as.double(scale(llfpm10)),
    log_odds_3sg_ind_scaled = as.double(scale(log_odds_3sg_ind))
  ) |> 
  filter(!is.na(log_odds_3sg_ind_scaled))

# -- fits -- #

# frequency effects only
m0 = glmmTMB(cbind(long_freq,short_freq) ~ 1 + lemma_length + llfpm10_scaled + subj_2nd + (1|obs_id) + (1|lemma), data = d, family = binomial)

# phonological similarity
m1 = glmmTMB(cbind(long_freq,short_freq) ~ 1 + stem_harmony * subj_2nd + lemma_length + llfpm10_scaled + (1|obs_id) + (1|lemma), data = d, family = binomial)

# paradigm patterns
m2 = glmmTMB(cbind(long_freq,short_freq) ~ log_odds_3sg_ind_scaled * subj_2nd + lemma_length + llfpm10_scaled + (1|obs_id) + (1|lemma), data = d, family = binomial)

# both
m3 = glmmTMB(cbind(long_freq,short_freq) ~ stem_harmony * subj_2nd + log_odds_3sg_ind_scaled * subj_2nd + lemma_length + llfpm10_scaled + (1|obs_id) + (1|lemma), data = d, family = binomial)

# -- eval -- #

check_residuals(m0);check_collinearity(m0);check_overdispersion(m0)
simulateResiduals(m0) |> testResiduals()
check_residuals(m1);check_collinearity(m1);check_overdispersion(m1)
simulateResiduals(m1) |> testResiduals()
check_residuals(m2);check_collinearity(m2);check_overdispersion(m2)
simulateResiduals(m2) |> testResiduals()
check_residuals(m3);check_collinearity(m3);check_overdispersion(m3)
simulateResiduals(m3) |> testResiduals()

# -- compare -- #

t1 = compare_performance(m0,m1,m2,m3, metrics = 'common') |>
  select(Name,AIC,BIC,R2_marginal) |> 
  tibble()
bf2_0 = test_bf(m0,m2)
bf2_1 = test_bf(m1,m2)
bf2_3 = test_bf(m3,m2)

# -- comparison -- #

bfs       = tibble(log_BF = as.double(c(log(bf2_0$BF[2]), log(bf2_1$BF[2]), NA, log(bf2_3$BF[2]))))
bf_names  = tibble(BF_comparison = c('H2 vs H0', 'H2 vs H1', '', 'H2 vs H3'))
t1b = bind_cols(t1, bf_names, bfs)

# -- best model -- #

t2 = m2 |> 
  broom.mixed::tidy(conf.int = T) |> 
  filter(effect == 'fixed') |> 
  select(term,estimate,std.error,conf.low,conf.high)

# -- write -- #

t1b |> 
  mutate_if(is.double, ~ round(.,3)) |> 
  googlesheets4::write_sheet('https://docs.google.com/spreadsheets/d/1dJdRxbHpLN9lmBCqUPf7oKJR93PoIXeg9PcnwyTnxcY/edit?usp=sharing','corpus_selection')

t2 |> 
  mutate_if(is.double, ~ round(.,3)) |> 
  googlesheets4::write_sheet('https://docs.google.com/spreadsheets/d/1dJdRxbHpLN9lmBCqUPf7oKJR93PoIXeg9PcnwyTnxcY/edit?usp=sharing','corpus_best_model')
