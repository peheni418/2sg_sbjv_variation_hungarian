# -- head -- #

# all plots for the priming analysis. loads the clean data and the saved fit;
# saves png figures into viz/.

setwd('~/Github/2sg_sbjv_variation_hungarian/')

library(here)
library(tidyverse)
library(glmmTMB)
library(sjPlot)

set.seed(1337)

# -- read -- #

d    = read_csv(here('dat', 'clean_data_filtered.csv'))
fit1 = readRDS(here('fit', 'fit1.rds'))

# -- setup -- #

pair_labels = c(
  'back_cell'  = 'back, same-cell',
  'back_form'  = 'back, cross-cell',
  'front_cell' = 'front, same-cell',
  'front_form' = 'front, cross-cell'
)

# -- pair averages -- #

# each point = one prime-target pair, averaged over participants
pair_avg = d |>
  filter(!is.na(pair_type)) |>
  summarise(
    mean_rt = mean(key_resp_5.rt, na.rm = TRUE),
    .by = c(pair_type,item)
  )

write_csv(pair_avg, here('dat', 'pair_avg.csv'))

p1 = ggplot(pair_avg, aes(x = pair_type, y = mean_rt)) +
  geom_violin(fill = 'lightblue', alpha = .7) +
  geom_boxplot(width = .2, fill = 'white') +
  geom_jitter(width = .15, alpha = .5) +
  scale_x_discrete(labels = pair_labels) +
  theme_bw() +
  labs(
    x = 'pair type',
    y = 'mean RT (s)',
    title = 'average RT per prime-target pair'
  )

ggsave(here('viz', 'across_pairtypes25.png'), p1,
       width = 6, height = 4, dpi = 900)
ggsave(here('viz', 'across_pairtypes25.pdf'), p1,
       width = 6, height = 4)


# -- participant averages -- #

# each point = one participant, averaged over their trials in that pair type
participant_avg = d |>
  filter(!is.na(pair_type)) |>
  summarise(
    mean_rt = mean(key_resp_5.rt, na.rm = TRUE),
    .by = c(participant, pair_type)
  )

p2 = ggplot(participant_avg, aes(x = pair_type, y = mean_rt)) +
  geom_violin(fill = 'lightblue', alpha = .7) +
  geom_boxplot(width = .2, fill = 'white') +
  geom_jitter(width = .15, alpha = .5) +
  scale_x_discrete(labels = pair_labels) +
  theme_bw() +
  labs(
    x = 'pair type',
    y = 'mean RT (s)',
    title = 'average RT per participant by pair type'
  )

ggsave(here('viz', 'across_participants25.png'), p2,
       width = 6, height = 4, dpi = 900)

# -- model predictions -- #

# predicted RT per condition with the contrast brackets from analysis_script
p3 = plot_model(fit1, type = 'pred', terms = 'pair_type') +
  theme_bw() +
  scale_x_discrete(labels = pair_labels) +
  labs(
    title = 'predicted RT by condition',
    x = 'condition',
    y = 'RT (s)'
  ) +
  # brackets assume alphabetical pair_type order: back_cell, back_form, front_cell, front_form
  annotate('segment', x = 1, xend = 2, y = .925, yend = .925) +
  annotate('segment', x = 1, xend = 1, y = .925, yend = .920) +
  annotate('segment', x = 2, xend = 2, y = .925, yend = .920) +
  annotate('text',    x = 1.5,         y = .930, label = '**', size = 5) +
  annotate('segment', x = 1, xend = 4, y = .950, yend = .950) +
  annotate('segment', x = 1, xend = 1, y = .950, yend = .945) +
  annotate('segment', x = 4, xend = 4, y = .950, yend = .945) +
  annotate('text',    x = 2.5,         y = .955, label = '*', size = 5)

ggsave(here('viz', 'plot_model_25.png'), p3,
       width = 6, height = 4, dpi = 900)

# emmeans

emm1 = emmeans::emmeans(fit1, ~ pair_type)

contrasts1 = emm1 |>
  emmeans::contrast(method = 'pairwise') |>
  summary(infer = TRUE, type = 'response') |>
  as.data.frame() |>
  as_tibble()

contrasts1
  
p4 = emm1 |> 
  plot(comparisons = TRUE) +
  geom_vline(xintercept = 0, linetype = "dashed") +  # only if on response scale
  theme_bw() +
  scale_y_discrete(name = 'pair type')

ggsave(here('viz', 'plot_model_contrasts_25.png'), p4,
       width = 6, height = 4, dpi = 900)

