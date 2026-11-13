# -- head -- #

setwd('~/Github/2sg_sbjv_variation_hungarian/')

library(tidyverse)
library(glmmTMB)
library(emmeans)
library(performance)
library(sjPlot)
library(broom.mixed)
library(knitr)
library(ggeffects)
library(patchwork)
library(marginaleffects)

# -- read -- #

d = read_tsv('dat/corpus_dat_summary_with_props.tsv')

# -- filter -- #

d = d |> 
  select(long_short_sbjv_log_odds,long_freq,short_freq,lemma_length,llfpm10,subj_2nd,stem_harmony,log_odds_3sg_ind,obs_id,lemma) |> 
  na.omit()

# 1907 obs

# -- info -- #

d |> 
  distinct(lemma)

ex_lemma = d |> 
  distinct(lemma) |> 
  sample_n(5) |> 
  pull(lemma)

d |> 
  filter(lemma %in% ex_lemma) |> 
  arrange(lemma) |> 
  select(lemma,llfpm10,lemma_length,long_freq,short_freq,subj_2nd,long_short_sbjv_log_odds) |> 
  knitr::kable(digits = 2)
  
# -- scale -- #

d = d |> 
  mutate(
    llfpm10_scaled = as.double(scale(llfpm10)),
    log_odds_3sg_ind_scaled = as.double(scale(log_odds_3sg_ind))
  ) 

# -- fits -- #

# frequency effects only
fit1 = glmmTMB(cbind(long_freq,short_freq) ~ 1 + lemma_length + llfpm10_scaled + subj_2nd + (1|obs_id) + (1|lemma), data = d, family = binomial)

# stem vowel
fit2 = glmmTMB(cbind(long_freq,short_freq) ~ 1 + stem_harmony + lemma_length + llfpm10_scaled + subj_2nd + (1|obs_id) + (1|lemma), data = d, family = binomial)
fit2b = glmmTMB(cbind(long_freq,short_freq) ~ 1 + stem_harmony * subj_2nd + lemma_length + llfpm10_scaled + (1|obs_id) + (1|lemma), data = d, family = binomial)

# def prop
fit3 = glmmTMB(cbind(long_freq,short_freq) ~ log_odds_3sg_ind_scaled + subj_2nd + lemma_length + llfpm10_scaled + (1|obs_id) + (1|lemma), data = d, family = binomial)
fit3b = glmmTMB(cbind(long_freq,short_freq) ~ log_odds_3sg_ind_scaled * subj_2nd + lemma_length + llfpm10_scaled + (1|obs_id) + (1|lemma), data = d, family = binomial)
fit3c = glmmTMB(cbind(long_freq,short_freq) ~ log_odds_3sg_ind_scaled * subj_2nd + stem_harmony + lemma_length + llfpm10_scaled + (1|obs_id) + (1|lemma), data = d, family = binomial)

# stem vowel + def prop
fit4 = glmmTMB(cbind(long_freq,short_freq) ~ log_odds_3sg_ind_scaled * subj_2nd + log_odds_3sg_ind_scaled * stem_harmony + lemma_length + llfpm10_scaled + (1|obs_id) + (1|lemma), data = d, family = binomial)

# both cell interactions, no three-way term -- this is M3 as described in the paper
# (cell x harmony and cell x definiteness preference), distinct from fit4 above,
# which instead crosses harmony with definiteness preference
fit4b = glmmTMB(cbind(long_freq,short_freq) ~ log_odds_3sg_ind_scaled * subj_2nd + stem_harmony * subj_2nd + lemma_length + llfpm10_scaled + (1|obs_id) + (1|lemma), data = d, family = binomial)

fit5 = glmmTMB(cbind(long_freq,short_freq) ~ log_odds_3sg_ind_scaled * subj_2nd + subj_2nd * log_odds_3sg_ind_scaled * stem_harmony + lemma_length + llfpm10_scaled + (1|obs_id) + (1|lemma), data = d, family = binomial)

fit6 = glmmTMB(cbind(long_freq,short_freq) ~ log_odds_3sg_ind_scaled * subj_2nd * stem_harmony + log_odds_3sg_ind_scaled + lemma_length + llfpm10_scaled + (1|obs_id) + (1|lemma), data = d, family = binomial)

# -- eval -- #

check_residuals(fit1);check_collinearity(fit1);check_overdispersion(fit1);tidy(fit1, conf.int = T)
# non-uniform residuals p < .001
# no vif over 2
# no dispersion
check_residuals(fit2);check_collinearity(fit2);check_overdispersion(fit2);tidy(fit2, conf.int = T)
# non-uniform residuals p < .001
# no vif over 2
# no dispersion
check_residuals(fit2b);check_collinearity(fit2b);check_overdispersion(fit2b);tidy(fit2b, conf.int = T)
# non-uniform residuals p < .001
# no vif over 2
# no dispersion
check_residuals(fit3);check_collinearity(fit3);check_overdispersion(fit3);tidy(fit3b, conf.int = T)
# non-uniform residuals p < .001
# no vif over 2
# no dispersion
check_residuals(fit3b);check_collinearity(fit3b);check_overdispersion(fit3b);tidy(fit3b, conf.int = T)
# non-uniform residuals p < .001
# no vif over 5.5 (!)
# no dispersion
check_residuals(fit3c);check_collinearity(fit3c);check_overdispersion(fit3c);tidy(fit3c, conf.int = T)
# non-uniform residuals p < .001
# no vif over 5.5 (!)
# no dispersion
check_residuals(fit4);check_collinearity(fit4);check_overdispersion(fit4);tidy(fit4, conf.int = T)
# non-uniform residuals p < .001
# no vif over 6.5 (!!)
# no dispersion
check_residuals(fit4b);check_collinearity(fit4b);check_overdispersion(fit4b);tidy(fit4b, conf.int = T)
# non-uniform residuals p < .001
# no vif over 5.5 (!)
# no dispersion
check_residuals(fit5);check_collinearity(fit5);check_overdispersion(fit5);tidy(fit5, conf.int = T) # # non-uniform residuals p < .001
# vif 9
# no dispersion
check_residuals(fit6);check_collinearity(fit6);check_overdispersion(fit6);tidy(fit6, conf.int = T) # # non-uniform residuals p < .001
# vif 9
# no dispersion
compare_performance(fit1,fit2,fit2b,fit3,fit3b,fit3c,fit4,fit4b,fit5,fit6, metrics = 'common') |>
  arrange(AIC,BIC)
# 3b,3c,4,...
test_likelihoodratio(fit3,fit3b) # 3b
test_likelihoodratio(fit3c,fit3b) # ns
test_likelihoodratio(fit3c,fit3) # 3
test_bf(fit3b,fit3)

# -- M0-M3 model comparison table for the paper -- #
# M0 = fit1 (baseline), M1 = fit2b (cell x harmony), M2 = fit3b (cell x def pref,
# the best model), M3 = fit4b (both interactions, no three-way term)
m_labels = c(fit1 = 'M0', fit2b = 'M1', fit3b = 'M2', fit4b = 'M3')

model_comparison = compare_performance(fit1, fit2b, fit3b, fit4b, metrics = 'common') |>
  as_tibble() |>
  mutate(
    model_label = m_labels[Name],
    log_bf_vs_m2 = (BIC - BIC[model_label == 'M2']) / 2
  ) |>
  select(model_label, AIC, BIC, R2_marginal, log_bf_vs_m2) |>
  arrange(AIC)

model_comparison |>
  mutate_if(is.double, ~ round(., 3)) |>
  write_tsv('corpus/corpus_model_comparison.tsv')

model_comparison

# -- results -- #

d |> 
  mutate(
    lo_long = log(long_freq/short_freq)
  ) |> 
  ggplot(aes(lo_long)) +
  geom_vline(xintercept = 0, alpha = .5, lty = 3) +
  geom_vline(xintercept = qlogis(.01), alpha = .5, lty = 4) +
  theme_bw() +
  geom_histogram() +
  facet_wrap( ~ subj_2nd) +
  scale_x_continuous(sec.axis = sec_axis(trans = ~ plogis(.), breaks = c(.01,0.1,.5), name = '% long 2sg sbjv\np(long)'), limits = c(-9,1), name = 'short > long\nlog(p(long 2sg sbjv)/p(short 2sg sbjv))', breaks = c(-7,-5,-3,-1,0,1))

ggsave('viz/adjal_manyek_0.png', dpi = 900, width = 4, height = 4)

tidy(fit3b,conf.int = T) |>
  filter(effect == 'fixed') |>
  select(term,estimate,conf.low,conf.high) |>
  mutate_if(is.double, ~ round(.,2)) |>
  write_tsv('corpus/fit3bcorpus_est.tsv')

plot_model(fit3b, 'est', transform = NULL) + 
  theme_minimal() + 
  scale_colour_viridis_d(option = 'D') +
  geom_hline(yintercept = 0, alpha = .5)

plot_model(fit3b, 'pred', terms = c('llfpm10_scaled','lemma_length')) + 
  theme_minimal() + 
  scale_colour_grey() +
  scale_fill_grey() +
  xlab('stem frequency\nlog(lemma freq / million), scaled') +
  ylab('% long 2sg sbjv\np(long)') +
  labs(colour = 'stem length') +
  ggtitle('')

ggsave('viz/adjal_manyek_1.png', dpi = 900, width = 5, height = 4)

# plot_model(fit3c, 'pred', terms = c('stem_harmony','subj_2nd')) +
#   theme_minimal() +
#   scale_colour_grey() +
#   scale_fill_grey() +
#   xlab('log(p(3sg def)/p(3sg indef)), scaled') +
#   ylab('% long 2sg sbjv\np(long)') +
#   labs(colour = '2sg sbjv') +
#   ggtitle('')
#
# ggsave('viz/adjal_manyek_2.png', dpi = 900, width = 4, height = 3)

# plot_model(fit3b, 'pred', terms = c('log_odds_3sg_ind_scaled','subj_2nd','stem_harmony')) +
#   theme_minimal() +
#   scale_colour_grey(name = 'def/indef', labels = c("same-cell", "cross-cell")) +
#   scale_fill_grey() +
#   xlab('definiteness preference, scaled\nlog(p(3sg def)/p(3sg indef))') +
#   ylab('% long 2sg sbjv\np(long)') +
#   ggtitle('') +
#   facet_wrap(~facet, labeller = labeller(facet = c("back" = "back", "front" = "front")))
#
# ggsave('viz/adjal_manyek_3.png', dpi = 900, width = 6, height = 4)

# -- ggeffects tableau of significant fit3b effects -- #

# every fixed term in fit3b has a CI excluding 0 (see corpus/fit3bcorpus_est.tsv):
# log_odds_3sg_ind_scaled, subj_2nd, lemma_length, llfpm10_scaled, and their interaction.
# the interaction panel covers both the log_odds_3sg_ind_scaled and subj_2nd main effects.

# population-average (counterfactual) predictions via marginaleffects: for each
# focal value, every row in the data is predicted once per non-focal level actually
# observed, then averaged -- so e.g. lemma_length is weighted by its real mono/poly
# mix (302 vs 1605 rows), not an arbitrary reference level or an equal-weighted split.
# an explicit, moderate grid is used for the continuous terms instead of '[all]':
# '[all]' asks for a prediction at every one of ~1,400 unique observed values, and
# each of those re-runs the counterfactual average over all 1907 rows -- that
# combination hangs for minutes, where a 25-30 point grid takes a few seconds
# and looks just as smooth
eff_interaction = predict_response(fit3b, terms = c('log_odds_3sg_ind_scaled [-3.5:3.5 by=0.25]','subj_2nd'), margin = 'empirical')
eff_length = predict_response(fit3b, terms = 'lemma_length', margin = 'empirical')
eff_freq = predict_response(fit3b, terms = 'llfpm10_scaled [-2.7:3 by=0.25]', margin = 'empirical')

# shared y range for the bottom row, fixed to 0 and the stem-length panel's
# upper CI, so neither panel's smooth gets cut off
y_range = c(0, max(eff_length$conf.high))

p_interaction = plot(eff_interaction, show_data = FALSE) +
  theme_bw() +
  scale_colour_grey(start = .1, end = .6, labels = c('definite', 'indefinite')) +
  scale_fill_grey(start = .1, end = .6, guide = 'none') +
  labs(
    x = 'definiteness preference, scaled\nlog(p(3sg def)/p(3sg indef))',
    y = 'p(long 2sg sbjv)',
    colour = '2sg sbjv',
    title = 'definiteness × 2sg sbjv'
  ) +
  coord_cartesian(ylim = y_range) +
  theme(legend.position = 'bottom')

p_length = plot(eff_length, show_data = FALSE) +
  theme_bw() +
  labs(x = 'stem length', y = 'p(long 2sg sbjv)', title = 'stem length') +
  coord_cartesian(ylim = y_range)

p_freq = plot(eff_freq, show_data = FALSE) +
  theme_bw() +
  labs(
    x = 'stem frequency\nlog(lemma freq / million), scaled',
    y = 'p(long 2sg sbjv)',
    title = 'stem frequency'
  )

bottom_row = (p_interaction | p_length) +
  plot_layout(axes = 'collect', guides = 'collect') &
  theme(legend.position = 'bottom')

p_freq / bottom_row

ggsave('viz/fit3b_effects_tableau.png', dpi = 900, width = 7, height = 6.2)
ggsave('~/Documents/latex/sbjv/figures/corpus_est.pdf', width = 7, height = 6.2)
