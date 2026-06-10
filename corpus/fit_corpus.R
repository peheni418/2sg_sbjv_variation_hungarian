# -- head -- #

setwd('~/Github/PokkRebrusRacz2027varjal/')

library(tidyverse)
library(lme4)
library(emmeans)
library(performance)
library(sjPlot)
library(broom.mixed)
library(knitr)

# -- read -- #

d = read_tsv('dat/dat_summary_with_props.tsv')

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
fit1 = glmer(cbind(long_freq,short_freq) ~ 1 + lemma_length + llfpm10_scaled + subj_2nd + (1|obs_id) + (1|lemma), data = d, family = binomial)

# stem vowel
fit2 = glmer(cbind(long_freq,short_freq) ~ 1 + stem_harmony + lemma_length + llfpm10_scaled + subj_2nd + (1|obs_id) + (1|lemma), data = d, family = binomial)
fit2b = glmer(cbind(long_freq,short_freq) ~ 1 + stem_harmony * subj_2nd + lemma_length + llfpm10_scaled + (1|obs_id) + (1|lemma), data = d, family = binomial)

# def prop
fit3 = glmer(cbind(long_freq,short_freq) ~ log_odds_3sg_ind_scaled + subj_2nd + lemma_length + llfpm10_scaled + (1|obs_id) + (1|lemma), data = d, family = binomial, control = glmerControl(optimizer="bobyqa"))
fit3b = glmer(cbind(long_freq,short_freq) ~ log_odds_3sg_ind_scaled * subj_2nd + lemma_length + llfpm10_scaled + (1|obs_id) + (1|lemma), data = d, family = binomial, control = glmerControl(optimizer="bobyqa"))
fit3c = glmer(cbind(long_freq,short_freq) ~ log_odds_3sg_ind_scaled * subj_2nd + stem_harmony + lemma_length + llfpm10_scaled + (1|obs_id) + (1|lemma), data = d, family = binomial, control = glmerControl(optimizer="bobyqa"))

# stem vowel + def prop
fit4 = glmer(cbind(long_freq,short_freq) ~ log_odds_3sg_ind_scaled * subj_2nd + log_odds_3sg_ind_scaled * stem_harmony + lemma_length + llfpm10_scaled + (1|obs_id) + (1|lemma), data = d, family = binomial, control = glmerControl(optimizer="bobyqa"))

fit5 = glmer(cbind(long_freq,short_freq) ~ log_odds_3sg_ind_scaled * subj_2nd + subj_2nd * log_odds_3sg_ind_scaled * stem_harmony + lemma_length + llfpm10_scaled + (1|obs_id) + (1|lemma), data = d, family = binomial, control = glmerControl(optimizer="bobyqa"))

fit6 = glmer(cbind(long_freq,short_freq) ~ log_odds_3sg_ind_scaled * subj_2nd * stem_harmony + log_odds_3sg_ind_scaled + lemma_length + llfpm10_scaled + (1|obs_id) + (1|lemma), data = d, family = binomial, control = glmerControl(optimizer="bobyqa"))

# -- eval -- #

check_residuals(fit1);check_collinearity(fit1);check_overdispersion(fit1);tidy(fit1, conf.int = T)
check_residuals(fit2);check_collinearity(fit2);check_overdispersion(fit2);tidy(fit2, conf.int = T)
check_residuals(fit2b);check_collinearity(fit2b);check_overdispersion(fit2b);tidy(fit2b, conf.int = T)
check_residuals(fit3);check_collinearity(fit3);check_overdispersion(fit3);tidy(fit3b, conf.int = T)
check_residuals(fit3b);check_collinearity(fit3b);check_overdispersion(fit3b);tidy(fit3b, conf.int = T)
check_residuals(fit3c);check_collinearity(fit3c);check_overdispersion(fit3c);tidy(fit3c, conf.int = T)
check_residuals(fit4);check_collinearity(fit4);check_overdispersion(fit4);tidy(fit4, conf.int = T)
check_residuals(fit5);check_collinearity(fit5);check_overdispersion(fit5);tidy(fit5, conf.int = T) # eh
check_residuals(fit6);check_collinearity(fit6);check_overdispersion(fit6);tidy(fit6, conf.int = T) # eh

compare_performance(fit1,fit2,fit2b,fit3,fit3b,fit3c,fit4,fit5,fit6, metrics = 'common') |> 
  arrange(AIC,BIC)

test_performance(fit3,fit3b)
test_performance(fit3c,fit3b)
test_performance(fit3c,fit3)
test_bf(fit3b,fit3)

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
  scale_x_continuous(sec.axis = sec_axis(trans = ~ plogis(.), breaks = c(.01,0.1,.5), name = '% várjad/várjál\np(long)'), limits = c(-9,1), name = 'várd/várj > várjad/várjál\nlog(p(long 2sg sbjv)/p(short 2sg sbjv))', breaks = c(-7,-5,-3,-1,0,1))

ggsave('viz/adjal_manyek_0.png', dpi = 900, width = 4, height = 4)

tidy(fit3b,conf.int = T) |> 
  filter(effect == 'fixed') |> 
  select(term,estimate,conf.low,conf.high) |> 
  mutate_if(is.double, ~ round(.,2)) |> 
  googlesheets4::write_sheet('https://docs.google.com/spreadsheets/d/1brgf4DytlncX4YoUvk3Ldla1EY3cWiMvUZPL05DfvsA/edit?usp=sharing', 'corpus_fixef')

plot_model(fit3b, 'est', transform = NULL) + 
  theme_minimal() + 
  scale_colour_viridis_d(option = 'D') +
  geom_hline(yintercept = 0, alpha = .5)

plot_model(fit3b, 'pred', terms = c('llfpm10_scaled','lemma_length')) + 
  theme_minimal() + 
  scale_colour_grey() +
  scale_fill_grey() +
  xlab('stem frequency\nlog(lemma freq / million), scaled') +
  ylab('% várjad/várjál\np(long 2sg sbjv)') +
  labs(colour = 'stem length') +
  ggtitle('')

ggsave('viz/adjal_manyek_1.png', dpi = 900, width = 5, height = 4)

# plot_model(fit3c, 'pred', terms = c('stem_harmony','subj_2nd')) + 
#   theme_minimal() + 
#   scale_colour_grey() +
#   scale_fill_grey() +
#   xlab('log(p(3sg def)/p(3sg indef)), scaled') +
#   ylab('% várjál\np(long 2sg sbjv)') +
#   labs(colour = '2sg sbjv') +
#   ggtitle('')
# 
# ggsave('viz/adjal_manyek_2.png', dpi = 900, width = 4, height = 3)

plot_model(fit3b, 'pred', terms = c('log_odds_3sg_ind_scaled','subj_2nd','stem_harmony')) + 
  theme_minimal() + 
  scale_colour_grey(name = 'def/indef', labels = c("várjad/várd", "várjál/várj")) +
  scale_fill_grey() +
  xlab('vár > várja\nlog(p(3sg def)/p(3sg indef)), scaled') +
  ylab('% várjad/várjál\np(long 2sg sbjv)') +
  ggtitle('') +
  facet_wrap(~facet, labeller = labeller(facet = c("back" = "vár", "front" = "kér")))

ggsave('viz/adjal_manyek_3.png', dpi = 900, width = 6, height = 4)

