# -- head -- #

setwd('~/Github/2sg_sbjv_variation_hungarian/')

library(tidyverse)
library(ggthemes)
library(patchwork)

# -- read -- #

d = read_tsv('dat/dat_summary_with_props.tsv')

# -- viz -- #

# d |> 
#   ggplot(aes(llfpm10,long_short_sbjv_log_odds)) +
#   geom_point(alpha = .5) +
#   geom_smooth() +
#   theme_few() +
#   facet_wrap( ~ lemma_length)
# 
# d |> 
#   ggplot(aes(llfpm10,long_short_sbjv_log_odds, colour = lemma_length)) +
#   geom_smooth() +
#   theme_few() +
#   scale_colour_colourblind() +
#   geom_rug()
# 
# d |> 
#   ggplot(aes(llfpm10,long_short_sbjv_log_odds)) +
#   # scale_fill_viridis_c(name = "count", option = 'H') +
#   # geom_hex(bins = 50) +
#   geom_density_2d_filled(alpha = .5) +
#   geom_smooth(colour = 'lightgrey', fill = 'black') +
#   theme_few() +
#   facet_wrap( ~ lemma_length) +
#   guides(fill = 'none')
# 
d |>
  ggplot(aes(llfpm10, long_short_sbjv_log_odds)) +
  scale_fill_viridis_c(name = "count", option = 'H') +
  geom_hex(bins = 50) +
  geom_smooth(colour = 'red', fill = 'red', method = 'lm') +
  theme_few() +
  facet_wrap(~ lemma_length, labeller = labeller(lemma_length = c("mono" = "monosyllabic\nstems", "poly" = "polysyllabic\nstems"))) +
  guides(fill = 'none') +
  labs(x = "log lemma frequency", y = "log(long sbjv/short sbjv)")

ggsave('viz/paper_corpus_1.png', dpi = 900, width = 8, height = 4)

d |>
  ggplot(aes(llfpm10, long_short_sbjv_log_odds)) +
  scale_fill_viridis_c(name = "count", option = 'H') +
  geom_hex(bins = 50) +
  geom_smooth(colour = 'red', fill = 'red', method = 'lm') +
  theme_few() +
  facet_wrap(~ stem_harmony, labeller = labeller(stem_harmony = c("back" = "back-vowel\nstems", "front" = "front-vowel\nstems"))) +
  guides(fill = 'none') +
  labs(x = "log lemma frequency", y = "log(long sbjv/short sbjv)")

ggsave('viz/paper_corpus_2.png', dpi = 900, width = 8, height = 4)

d |>
  ggplot(aes(log_odds_3sg_ind, long_short_sbjv_log_odds)) +
  scale_fill_viridis_c(name = "count", option = 'H') +
  geom_hex(bins = 50) +
  geom_smooth(colour = 'red', fill = 'red', method = 'lm') +
  theme_few() +
  facet_wrap(~ subj_2nd, labeller = labeller(subj_2nd = c("def" = "definite\ns2sg.sbjv", "indef" = "indefinite\n2sg.sbjv"))) +
  guides(fill = 'none') +
  labs(x = "log(3sg.def/3sg.indef)", y = "log(long sbjv/short sbjv)")

ggsave('viz/paper_corpus_3.png', dpi = 900, width = 8, height = 4)
