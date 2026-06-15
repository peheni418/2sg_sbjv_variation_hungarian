# -- head -- #

# all plots for the priming analysis. loads the clean data and the saved fit;
# saves png figures into viz/.

setwd('~/Github/morphological_priming_hungarian/')

library(here)
library(tidyverse)
library(glmmTMB)
library(sjPlot)

set.seed(1337)

# -- read -- #

d    = read_csv(here('dat', 'clean_data.csv'))
fit1 = readRDS(here('fit', 'fit1.rds'))

# -- setup -- #

pair_order = c('back_cell', 'front_cell', 'back_form', 'front_form')
pair_labels = c(
  'back_cell'  = 'várjad/várd',
  'back_form'  = 'várjad/várja',
  'front_cell' = 'kérjed/kérd',
  'front_form' = 'kérjed/kéri'
)

# correct target trials only; same filter as fit.R
d = d |>
  filter(
    stim_type != 'type_distractor',
    !exclude_bad_participant,
    !exclude_slow,
    !(key_resp_5.keys == 'f' & stim_type == 'type_target')
  ) |>
  mutate(
    pair_type = factor(pair_type, levels = pair_order),
    pair = paste(primeHeni, targetHeni, sep = ' → ')
  )

# -- pair averages -- #

# each point = one prime-target pair, averaged over participants
pair_avg = d |>
  filter(!is.na(pair_type)) |>
  summarise(
    mean_rt = mean(key_resp_5.rt, na.rm = TRUE),
    .by = c(pair, pair_type)
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
  annotate('segment', x = 1, xend = 3, y = .925, yend = .925) +
  annotate('segment', x = 1, xend = 1, y = .925, yend = .920) +
  annotate('segment', x = 3, xend = 3, y = .925, yend = .920) +
  annotate('text',    x = 2,           y = .930, label = '**', size = 5) +
  annotate('segment', x = 1, xend = 4, y = .950, yend = .950) +
  annotate('segment', x = 1, xend = 1, y = .950, yend = .945) +
  annotate('segment', x = 4, xend = 4, y = .950, yend = .945) +
  annotate('text',    x = 2.5,         y = .955, label = '*', size = 5)

ggsave(here('viz', 'plot_model_25.png'), p3,
       width = 6, height = 4, dpi = 900)

# model summary, written into google sheet for easy pasting
fit1 |> 
  broom.mixed::tidy(conf.int = T) |> 
  filter(effect == 'fixed') |> 
  select(term,estimate,std.error,conf.low,conf.high,p.value) |> 
  mutate_if(is.double, ~ round(.,3)) |> 
  googlesheets4::write_sheet('https://docs.google.com/spreadsheets/d/1dJdRxbHpLN9lmBCqUPf7oKJR93PoIXeg9PcnwyTnxcY/edit?usp=sharing','Sheet1')
