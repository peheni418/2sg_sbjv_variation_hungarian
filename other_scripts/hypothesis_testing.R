# ============================================================
# Comparing the hypotheses in the preregistration
# ============================================================

# -- packages -- #

library(tidyverse)
library(glmmTMB)      # frequentist GLMMs
library(performance)  # model comparison (compare_performance)
library(sjPlot)       # quick model visualisation (plot_model)
library(DHARMa)       # residual diagnostics for GLMMs

# -- read -- #

d = read_csv('~/Github/morphological_priming_hungarian/clean_data.csv')

# -- setup -- #

# Keep only correct responses (key 'j') to target stimuli. stimuli already filtered for bad apples in clean_data.R
d = d |> 
  filter(
    stim_type != "type_distractor",                              # Exclude type_distractor rows
    exclude_bad_participant != "TRUE",                              # Exclude bad participants
    exclude_slow != "TRUE",                                         # Exclude slow trials
    !(key_resp_5.keys == "j" & stim_type == "type_distractor"),  # Exclude j + type_distractor rows
    !(key_resp_5.keys == "f" & stim_type == "type_target")       # Exclude f + type_target rows
  ) |> 
  mutate(
    item = primeHeni,
    rt = key_resp_5.rt,
    condition = pair_type |> 
      fct_relevel('back_cell', 'front_cell', 'back_form', 'front_form')
  )

# -- prereg -- #

# https://aspredicted.org/92c82r.pdf

# A - back, same-cell: prime = 2sg subjunctive long, back harmony verb (várjad), target = 2sg subjunctive short, back harmony verb (várd)
# B - back, form-similar: prime = 2sg subjunctive long, back harmony verb (várjad), target = 3sg indicative, back harmony verb (várja)
# C - front, same-cell: prime = 2sg subjunctive long, front harmony verb (kérjed) target = 2sg subjunctive short, front harmony verb (kérd)
# D - front, form-similar: prime = 2sg subjunctive long, front harmony verb (kérjed), target = 3sg indicative, front harmony verb (kéri), 

# H0: RT for A = B = C = D
# H1 (morphological blocking): RT for A,C > B,D
# H2 (phonological facilitation): B < A,C,D
# H3 (both effects): A,C > D; B < D

d = d |> 
  mutate(
    # form > cell
    condition_h1 = fct_collapse(condition,
                                "cell" = c("back_cell", "front_cell"),
                                "form" = c("back_form", "front_form")
    ),
    # back_form > other
    condition_h2 = fct_collapse(condition,
                                "other" = c("back_cell", "front_cell", "front_form"),
                                "back_form"  = "back_form"
    ),
    # both
    condition_h3 = fct_collapse(condition,
                                "cell" = c("back_cell", "front_cell"),
                                "back_form"  = "back_form",
                                "front_form" = "front_form"
    )
  )

# the three hypotheses are expressed by the three factors
levels(d$condition_h1)
levels(d$condition_h2)
levels(d$condition_h3)

# -- fits -- #

# we fit four models. one only estimates an intercept (this is the null hypothesis, everything is the same)

# h0
h0   = glmmTMB(rt ~ 1 + (1|participant) + (1|item), data = d, family = Gamma(link = "log"))
# h1
h1   = glmmTMB(rt ~ condition_h1 + (1|participant) + (1|item), data = d, family = Gamma(link = "log"))
# h2
h2   = glmmTMB(rt ~ condition_h2 + (1|participant) + (1|item), data = d, family = Gamma(link = "log"))
# h3
h3   = glmmTMB(rt ~ condition_h3 + (1|participant) + (1|item), data = d, family = Gamma(link = "log"))

# -- model health -- #

# overdispersion ok
check_overdispersion(h1)
check_overdispersion(h2)
check_overdispersion(h3)
# autocor ok
check_autocorrelation(h1)
check_autocorrelation(h2)
check_autocorrelation(h3)
# we haven't enough contrasts to even worry about collinearity
# autocorrelation worrying:
check_residuals(h1)
check_residuals(h2)
check_residuals(h3)
# let's look at it
simulateResiduals(h1,   plot = TRUE)
simulateResiduals(h2,   plot = TRUE)
simulateResiduals(h3,   plot = TRUE)
# this is fine

# -- model selection -- #

plot(compare_performance(h0,h1,h2,h3, metrics = 'common'))
# h1 wins on aic, bic
test_performance(h0,h1) # h1 better than null
test_bf(h0,h1) # h1 2.7x better than h0 based on bayes factors
test_bf(h2,h1) # h1 6.4x better than h2 based on bayes factors
test_bf(h3,h1) # h1 40x better than h3

# -- outputs -- #

# nice table for paper
t1 = compare_performance(h0,h1,h2,h3, metrics = 'common') |> 
  tibble()
bf2 = test_bf(h0,h1) # h1 2.7x better than h0 based on bayes factors
bf3 = test_bf(h2,h1) # h1 6.4x better than h2 based on bayes factors
bf4 = test_bf(h3,h1) # h1 40x better than h3
BFs = tibble(BF = as.double(c(bf2$BF[2],'',bf3$BF[2],bf4$BF[2])))
BF_names = tibble(BF_comparison = c('H1 vs H0','','H1 vs H2','H1 vs H3'))
t1 = bind_cols(t1,BF_names,BFs)

t1 |> 
  select(Name,AIC,BIC,RMSE,BF_comparison,BF) |> 
  knitr::kable(digits = 2)
