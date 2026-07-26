# -- head -- #

# fit the main glmm: rt ~ pair_type with crossed random effects for
# participant and prime. saves the fit to fit/.

setwd('~/Github/2sg_sbjv_variation_hungarian/')

library(here)
library(tidyverse)
library(glmmTMB)
library(performance)
library(broom.mixed)

set.seed(1337)

# -- read -- #

d = read_csv(here('dat', 'clean_data_filtered.csv'))

# -- setup -- #

pair_order = c('back_cell', 'front_cell', 'back_form', 'front_form')

# keep correct ('j') target trials from good participants, fast trials only
d = d |>
  mutate(
    pair_type = factor(pair_type, levels = pair_order)
  )

# -- fit -- #

# rt is positive and right-skewed: gamma with log link
fit1 = glmmTMB(
  rt ~ pair_type + (1|participant) + (1|item),
  family = Gamma(link = 'log'),
  data = d
)

# -- diagnostics -- #

check_overdispersion(fit1)
check_collinearity(fit1)
check_autocorrelation(fit1)

# -- report -- #

tidy(fit1, conf.int = TRUE)
summary(fit1)

# -- save -- #

saveRDS(fit1, here('fit', 'fit1.rds'))
