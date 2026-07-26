# in: sbjv pairs with analogical source frequencies and whatnot, made by script/build_corpus
# out: rezult

######################################################
# Q1: Given rakja-rakjad and lépi<->lépje, do we have stem vowel x def/indef interaction?
######################################################
######################################################
# Q2: Frequency effect?
######################################################
######################################################
# Q3: Analogical effect?
######################################################
######################################################
# Q4: Paradigm-specific frequency effect?
######################################################

# -- head -- #

setwd('~/Github/2sg_sbjv_variation_hungarian/')

library(tidyverse)
library(lme4)
library(broom.mixed)
library(performance)
library(emmeans)
library(sjPlot)
library(patchwork)

# -- fun -- #

# fit model predicting freq res from analogical source freq
fitModel = function(dat){  
  fit = lm(resid ~ z_log_analogy_freq, data = dat)
  
return(fit)
}

# bonferroni-corrected tidy function
tidy2 = function(x){tidy(x, conf.int = T, conf.level = 0.999)} # adjusting for multiple comparisons. actual is p = 0.05/a whopping 56 comparisons (14 forms * 2 * 2) which is .00089, this is .001

# plot analogy strengths
analogyPlot = function(dat){
  
  dat |> 
    ggplot(aes(estimate,analogy_label_tidy, colour = int)) +
    geom_vline(xintercept = 0, lty = 3) +
    geom_point(position = position_dodge(.6)) +
    geom_linerange(aes(xmin = conf.low, xmax = conf.high, colour = int), position = position_dodge(.6)) +
    theme_bw() +
    xlab('estimate, 95 CI (adjusted)') +
    theme(axis.title.y = element_blank(), legend.position = 'top') +
    scale_colour_viridis_d(option = 'D')
}

# -- read -- #

dl = read_tsv('dat/corpus_short_long_pairs_long.tsv')

# -- simple summary, def/indef freq -- #

# data w/o analogical source forms
d_simple = dl |> 
  distinct(long_freq,short_freq,lemma,llfpm10,stem_harmony,subj_2nd,lemma_syl_count) |> 
  mutate(
    z_llfpm10 = scales::rescale(llfpm10),
    lemma_syl_count_fct = ifelse(lemma_syl_count < 5, lemma_syl_count, '5+') |> as.factor() |> 
      ordered(),
    obs_id = 1:n()
         ) # obs id for OLRE (observation-level random effect)

# -- fit on simple summary -- #

# main model, underspecified for everything except random effects and lemma freq on purpose
fit_simple0 = glmer(cbind(long_freq,short_freq) ~ z_llfpm10 + lemma_syl_count_fct + (1|obs_id) + (1|lemma), data = d_simple, family = binomial, control = glmerControl(optimizer="bobyqa"))
# potential other lemma-level effects
fit_simple1 = glmer(cbind(long_freq,short_freq) ~ z_llfpm10 + lemma_syl_count_fct + stem_harmony + subj_2nd + (1|obs_id) + (1|lemma), data = d_simple, family = binomial, control = glmerControl(optimizer="bobyqa"))
fit_simple2 = glmer(cbind(long_freq,short_freq) ~ z_llfpm10 + lemma_syl_count_fct + stem_harmony * subj_2nd + (1|obs_id) + (1|lemma), data = d_simple, family = binomial, control = glmerControl(optimizer="bobyqa"))

test_performance(fit_simple0,fit_simple1)
test_performance(fit_simple1,fit_simple2)
summary(fit_simple1)
summary(fit_simple2)

compare_performance(fit_simple0,fit_simple1,fit_simple2) |> 
  as_tibble() |> 
  add_column(model = c(as.character(formula(fit_simple0))[3],as.character(formula(fit_simple1))[3],as.character(formula(fit_simple2))[3])) |> 
  mutate(model = model |> 
  str_remove(' \\+ \\(1 \\| obs_id\\) \\+ \\(1 \\| lemma\\)')
  ) |> 
  select(model,AIC,BIC,RMSE)

######################################################
# Q1: Given rakja-rakjad and lépi<->lépje, do we have stem vowel x def/indef interaction?
# A: Nope
######################################################

# -- residualise -- #

p1 = plot_model(fit_simple0, 'pred', terms = 'z_llfpm10') +
  theme_bw() +
  xlab('log(lemma freq / 10^7)') +
  ylab('p(long sbjv)') +
  ggtitle('predicted probabilities')

p2 = plot_model(fit_simple0, 'pred', terms = 'lemma_syl_count_fct') +
  theme_bw() +
  xlab('lemma syllable count') +
  ylab('p(long sbjv)') +
  ggtitle('predicted probabilities')

d_simple$resid = resid(fit_simple0)

p3 = d_simple |> 
  ggplot(aes(resid)) +
  geom_histogram() +
  theme_bw() +
  xlab('residual') +
  ggtitle('residuals')

p1 + p2 + p3 + plot_annotation(title = 'p(long sbjv) ~ log lemma freq')
ggsave('viz/main_model.png', dpi = 900, width = 9, height = 3.5)

######################################################
# Q2: Frequency effect?
# A: Absolutely. More frequent form: short sbjv more likely. Makes sense.
######################################################

# I take the residuals and fit models predicting those.
# "For variation left by frequency effect, how much is explained by frequency of analogial source"
# Do this for def/indef x front/back stem
# Individual models because rampant collinearity. This is not very nice but there's a wrapup model at the end. Taken together, it sort of checks out.

# -- fit individual models -- #

# add resid from fit_simple
dl2 = d_simple |> 
  select(lemma,subj_2nd,stem_harmony,resid) |> 
  right_join(dl)

# nest per analogical source
dn = dl2 |> 
  nest(.by = c(analogy_label,analogy_label_tidy,stem_harmony,subj_2nd))

# fit resid mod
dr = dn |> 
  mutate(
    data_dropped = map(data, ~ filter(., !is.na(analogy_form))),
    resid_fit = map(data_dropped, fitModel),
    sum = map(resid_fit, tidy2)
  )

# -- vis -- #

# A: frequency of source forms
analogy_sums = dl |> 
  summarise(sum = sum(analogy_freq, na.rm = T), .by = c(analogy_label_tidy,corpus_size)) |> 
  mutate(d_for_def = str_detect(analogy_label_tidy, ' Def ')) |> 
  arrange(d_for_def,-sum)

analogy_label_tidy_levels = analogy_sums |> 
  pull(analogy_label_tidy)

p2 = analogy_sums |> 
  mutate(
    afp10m = sum / corpus_size * 10^7,
    lafp10m = log(afp10m),
    analogy_label_tidy = factor(analogy_label_tidy, levels = analogy_label_tidy_levels) |> fct_rev()
  ) |> 
  ggplot(aes(lafp10m, analogy_label_tidy)) +
  geom_segment(aes(x = -Inf, xend = lafp10m, y = analogy_label_tidy, yend = analogy_label_tidy)) +
  geom_point() +
  theme_bw() +
  xlab('log(form freq / 10^7)') +
  theme(axis.title.y = element_blank(), axis.text.y = element_blank(), axis.ticks.y = element_blank())

# B: effect of source forms.
p1 = dr |> 
  mutate(
    analogy_label_tidy = factor(analogy_label_tidy, levels = analogy_label_tidy_levels) |> fct_rev(),
    int = interaction(stem_harmony, subj_2nd, sep = ', ')
  ) |> 
  select(analogy_label_tidy,int,sum) |> 
  unnest(sum) |> 
  filter(term == 'z_log_analogy_freq') |> 
  analogyPlot()

p1 + p2 + plot_layout(widths = c(3,1))

ggsave('viz/residual_fits.png', dpi = 900, width = 8, height = 8)

# Stage 1 residual: positive means this verb uses more long forms than expected for its frequency. Negative means fewer long forms than expected.
# Stage 2 estimate: the coefficient tells you which direction a specific form's frequency pushes that residual.

######################################################
# Q3: Analogical effect?
# A: Not quite.
# If def source form frequent, def shorter
# If indef source form frequent, indef shorter
# Overall frequency effect: more x forms, stronger effect
######################################################
