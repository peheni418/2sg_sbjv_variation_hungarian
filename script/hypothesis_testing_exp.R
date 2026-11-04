# -- head -- #

# compare the four prereg hypotheses (H0-H3) by fitting one glmm per hypothesis
# and comparing them via AIC, BIC, RMSE, and BIC-based Bayes factors.
# https://aspredicted.org/92c82r.pdf

setwd('~/Github/2sg_sbjv_variation_hungarian/')

library(here)
library(tidyverse)
library(glmmTMB)
library(performance)
library(sjPlot)
library(DHARMa)
library(emmeans)
library(patchwork)

set.seed(1337)

# -- read -- #

d = read_csv(here('dat', 'clean_data_filtered.csv'))

# -- setup -- #

# correct target trials only; same filter as fit.R / viz.R
d = d |>
  mutate(
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

# overdispersion detected: ratio ~1.39, p < .001, in all four models
# (this comment previously said "ok" -- it wasn't; matches the paper's text)
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
compare_performance(h0, h1, h2, h3, metrics = 'common')

test_performance(h0, h1) # H1 better than null
test_bf(h0, h1)          # H1 ~32x better than H0
test_bf(h2, h1)          # H1 ~12x better than H2
test_bf(h3, h1)          # H1 ~34x  better than H3

# -- table -- #

# tidy summary table for the paper
t1 = compare_performance(h0, h1, h2, h3, metrics = 'common') |>
  tibble()

bf2 = test_bf(h0, h1)
bf3 = test_bf(h2, h1)
bf4 = test_bf(h3, h1)

bfs       = tibble(log_BF = as.double(c(log(bf2$BF[2]), '', log(bf3$BF[2]), log(bf4$BF[2]))))
bf_names  = tibble(BF_comparison = c('H1 vs H0', '', 'H1 vs H2', 'H1 vs H3'))
t1b = bind_cols(t1, bf_names, bfs)

# t1b |>
#   select(Name, AIC, BIC, R2_marginal, BF_comparison, log_BF) |>
#   mutate_if(is.double, ~ round(., 3)) |> 
#   googlesheets4::write_sheet('https://docs.google.com/spreadsheets/d/1dJdRxbHpLN9lmBCqUPf7oKJR93PoIXeg9PcnwyTnxcY/edit?usp=sharing','exp_selection')

# h1 |> 
#   broom.mixed::tidy(conf.int = T) |> 
#   filter(effect == 'fixed') |> 
#   select(term,estimate,std.error,conf.low,conf.high) |> 
#   mutate_if(is.double, ~ round(.,3)) |> 
#   googlesheets4::write_sheet('https://docs.google.com/spreadsheets/d/1dJdRxbHpLN9lmBCqUPf7oKJR93PoIXeg9PcnwyTnxcY/edit?usp=sharing','exp_best_model')

emmeans(h1, 'condition_h1')

# -- emmeans plot for the best model (H1) -- #

# `comparison` isn't an emmeans() argument (it's `comparisons`, and it belongs to
# plot.emmGrid, not emmeans() itself) -- that's why the earlier attempt had no
# effect. The right way to get comparison arrows: build the emmGrid first, then
# call plot(..., comparisons = TRUE, plotit = FALSE) to pull out the arrow
# endpoints (lcmpl/rcmpl) as data, which we then plot ourselves in house style.
# A comparison arrow is NOT a second CI: it's calibrated so that two groups'
# arrows overlap iff their difference is non-significant at `alpha` (default
# .05, Tukey-adjusted) -- so it's a more honest significance cue than eyeballing
# whether two plain 95% CIs overlap, which is what the first version of this
# plot did and which is why the two intervals looked like they overlapped
# despite a p = 2.47e-5 difference.
emm1_grid = emmeans(h1, 'condition_h1', type = 'response')

emm1 = plot(emm1_grid, comparisons = TRUE, horizontal = FALSE, plotit = FALSE) |>
  as.data.frame() |>
  mutate(
    condition_h1 = factor(recode(condition_h1, cell = 'same-cell', form = 'cross-cell'),
                           levels = c('same-cell', 'cross-cell')),
    x_num = as.numeric(condition_h1),
    emmean_ms = the.emmean * 1000,
    LCL_ms = asymp.LCL * 1000,
    UCL_ms = asymp.UCL * 1000,
    lcmpl_ms = lcmpl * 1000,  # left comparison-arrow endpoint (NA unless this group is the higher one)
    rcmpl_ms = rcmpl * 1000   # right/upper comparison-arrow endpoint (NA unless this group is the lower one)
  )

p_exp = ggplot(emm1, aes(x = condition_h1)) +
  geom_linerange(aes(ymin = LCL_ms, ymax = UCL_ms), colour = 'grey70', linewidth = 1) +
  geom_point(aes(y = emmean_ms), size = 2.5) +
  # one arrow per group: whichever of lcmpl/rcmpl is non-NA for that row
  geom_segment(
    aes(x = x_num + .12, xend = x_num + .12, y = emmean_ms, yend = rcmpl_ms),
    na.rm = TRUE, arrow = arrow(length = unit(.12, 'cm')), linewidth = .6
  ) +
  geom_segment(
    aes(x = x_num + .12, xend = x_num + .12, y = emmean_ms, yend = lcmpl_ms),
    na.rm = TRUE, arrow = arrow(length = unit(.12, 'cm')), linewidth = .6
  ) +
  theme_bw() +
  labs(x = 'target relation to prime', y = 'predicted RT (ms)')

ggsave(here('viz', 'exp_h1_emmeans.png'), p_exp, dpi = 900, width = 3.8, height = 3.8)
ggsave('~/Documents/latex/sbjv/figures/exp_est.pdf', p_exp, width = 3.8, height = 3.8)

# -- raw-data plot, all four conditions, with the H1 contrast marked -- #

# the predicted-means plot above shows a credible difference (p = 2.47e-5,
# estimate 0.075, 95% CI [0.040, 0.110]), but its two intervals visibly
# overlap -- that's an artefact of comparing marginal CIs naively rather than
# the model's within-participant/within-item contrast. this plot shows the
# actual trial-level RTs instead, so the reader can see how much the raw
# distributions overlap even though the aggregate difference is real.

pair_labels = c(
  'back_cell'  = 'várjad/várd',
  'front_cell' = 'kérjed/kérd',
  'back_form'  = 'várjad/várja',
  'front_form' = 'kérjed/kéri'
)

# display is capped at 2200ms (49 of 2275 points, 2.2%, fall above this and
# are not shown); the model and all reported statistics use the full data.
#
# the annotation lives in its own strip, patchworked on top of the main panel,
# rather than sharing the main panel's coordinate space. earlier versions tried
# to fit the bracket inside the main panel (by expanding ylim with headroom, or
# by disabling clipping) -- both made it look like the panel extends past where
# the real data stop, i.e. like there are no observations up near the display
# cap, which is the opposite of what's true: the main panel below is left
# exactly as the data actually look, ylim hard-capped at 2200 with no added
# headroom, and the bracket is composited in a separate, unrelated y-range above it
d_plot = d |>
  filter(!is.na(pair_type)) |>
  mutate(
    pair_type = factor(pair_type, levels = c('back_cell','front_cell','back_form','front_form')),
    rt_ms = rt * 1000
  )

p_main = ggplot(d_plot, aes(x = pair_type, y = rt_ms)) +
  geom_violin(fill = 'grey90', colour = 'grey50') +
  geom_boxplot(width = .15, outlier.shape = NA, fill = 'white') +
  geom_jitter(width = .08, alpha = .15, size = .8) +
  scale_x_discrete(labels = pair_labels) +
  coord_cartesian(ylim = c(0, 2200)) +
  theme_bw() +
  labs(x = 'condition (prime > target)', y = 'RT (ms)')

# bracket spans the two H1 groups: {back_cell,front_cell} vs {back_form,front_form}
# *** reflects the H1 contrast p-value (2.47e-5); this is the only contrast
# the paper actually tests and reports -- not a post-hoc comparison across
# all six raw condition pairs. same x categories as p_main, so patchwork aligns
# the bracket's x positions with the violins below it
p_strip = ggplot(d_plot, aes(x = pair_type)) +
  annotate('segment', x = 1.5, xend = 1.5, y = 1, yend = .55) +
  annotate('segment', x = 3.5, xend = 3.5, y = 1, yend = .55) +
  annotate('segment', x = 1.5, xend = 3.5, y = 1, yend = 1) +
  annotate('text', x = 2.5, y = 1.3, label = 'same-cell vs. cross-cell: ***') +
  scale_x_discrete(labels = pair_labels) +
  coord_cartesian(ylim = c(0, 1.6)) +
  theme_void()

p_raw = p_strip / p_main + plot_layout(heights = c(1, 6))

ggsave(here('viz', 'exp_raw.png'), p_raw, dpi = 900, width = 6, height = 4.8)
ggsave('~/Documents/latex/sbjv/figures/exp_raw.pdf', p_raw, width = 6, height = 4.8)
