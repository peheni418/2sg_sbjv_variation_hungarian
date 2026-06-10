# in: webcorpus 2 freq list
# out: tabular data; outcome var: count of long / short subjunctive 2nd in indef (menjél/menj) and def (adjad/add); predictor var: marking stem vowel (front for megy, back for ad), lemma freq, and a bunch of frequencies for various forms of the stem (see below) that could be analogical bases for the outcome var

# -- head -- #

setwd('~/Github/adjal/')

library(tidyverse)
library(duckdb)
library(hunspell)

# -- fun -- #

# take webcorpus counts, forms matching postag and, if applicable, prefix, return filtered counts
grabForms = function(d, my_xpostag, my_template, my_prefix){
  
  # these tags
  result = d |> 
    filter(xpostag == my_xpostag)
  
  # Only apply template filter if my_template is provided to further filter on tags
  if (!missing(my_template)) {
    result <- result |> 
      filter(str_detect(form, my_template))
  }
  
  # unless motivated, repeated forms matching one xpostag are nonsense (e.g. rakja, rakje for rak 3sg.def). we keep most frequent form.
  result = result |> 
    arrange(-freq) |> 
    group_by(lemma) |> 
    slice(1) |> 
    ungroup()
  
  # rename using prefix so not everything is called the same thing
  result |> 
    select(lemma, lemma_freq, form, freq) |> 
    rename(
      !!paste0(my_prefix, "_form") := form,
      !!paste0(my_prefix, "_freq") := freq
    )
}

# -- read in webcorpus, keep more frequent forms -- #

# we do the first pass using database format, much faster.
# Connect to DuckDB (in-memory)
con = dbConnect(duckdb::duckdb())

# Run the query. hunspell is a pre-existing col which says whether the lemma is in the hunspell dictionary. since these are verbs, a closed class, we can assume that whatever doesn't fit is noise
d = dbGetQuery(con, "
  SELECT *
  FROM read_parquet('~/Github/Webcorpus2FrequencyList/frequencies.parquet')
  WHERE hunspell = true
")

# QUALIFY ROW_NUMBER() OVER (PARTITION BY form ORDER BY lfpm10 DESC) = 1 # no I need these: nyomja, fingja

# Disconnect
dbDisconnect(con, shutdown = TRUE)

# -- drop some stems -- #

# sz stems act weird (eszik, egye, ette). -t stems also act weird (üt, üti, üsse). ik verbs almost never transitive, and dropping them sorts out a lot of parsing issues (like having both böngész/böngészik as lemmas for the same verb "browse")
# eszik iszik tesz vesz lesz hisz visz
# -t
# -ik

# keep verbs, drop ik t sz verbs, drop single-character lemma matches, drop very rare lemmas
d = d |> 
  filter(
    str_detect(xpostag, '^\\[\\/V\\]\\[[^_]'),
    !str_detect(lemma, '(t|ik)$'),
    !lemma %in% c('fér','esz','eszik','isz','iszik','tesz','vesz','lesz','hisz','visz'),
    str_detect(lemma, '[tvh][ei]sz$', negate = T),
    nchar(lemma) > 1,
    lemma_freq > 10
    )

# -- master file -- #

# master: lemma-level info
master = d |> 
  distinct(lemma,corpus_size,lemma_freq,llfpm10,lemma_syl_count)

# -- suffix finder -- #

# outcome variable: longdef rakjad shortdef rakd longindef rakjál shortindef rakj. here we need prefix because same exponent (tag) varies

d_longdef = grabForms(d, my_xpostag = '[/V][Sbjv.Def.2Sg]', my_template = '.*[ae]d$', my_prefix = 'long')
d_shortdef = grabForms(d, my_xpostag = '[/V][Sbjv.Def.2Sg]', my_template = '.*[^ae]d$', my_prefix = 'short')
d_longindef = grabForms(d, my_xpostag = '[/V][Sbjv.NDef.2Sg]', my_template = '.*[áé]l$', my_prefix = 'long')
d_shortindef = grabForms(d, my_xpostag = '[/V][Sbjv.NDef.2Sg]', my_template = '.*[^áé].$', my_prefix = 'short')

# these are def forms
sbjv_def = inner_join(d_shortdef,d_longdef) |> 
  mutate(
    subj_2nd = 'def'
  )

# these are indef forms
sbjv_indef = inner_join(d_shortindef,d_longindef) |> 
  mutate(
    subj_2nd = 'indef'
  )

# inner joins drop verbs with either or. this is an analytical decision.

# we ROW bind this. so each lemma in there twice
sbjv = bind_rows(sbjv_def,sbjv_indef)

# predictors

# we have 3sg.indef because base form.
# we also have suffixes that are theoretically motivated ( = they look the part) analogical bases:
# ja
# jam !jad jak jatok janak
# !jál játok ják
# juk junk jon
# these are these:
my_xpostags = 
c(
'[/V][Prs.Def.3Sg]',
'[/V][Sbjv.Def.3Sg]',
'[/V][Prs.NDef.3Sg]',
'[/V][Sbjv.NDef.3Sg]',
'[/V][Sbjv.Def.1Sg]',
'[/V][Sbjv.NDef.1Sg]',
'[/V][Sbjv.NDef.2Pl]',
'[/V][Sbjv.NDef.3Pl]',
'[/V][Sbjv.Def.2Pl]',
'[/V][Prs.Def.2Pl]',
'[/V][Sbjv.Def.3Pl]',
'[/V][Sbjv.NDef.3Pl]',
'[/V][Prs.Def.3Pl]',
'[/V][Prs.NDef.3Pl]',
'[/V][Sbjv.Def.1Pl]',
'[/V][Prs.Def.1Pl]',
'[/V][Sbjv.NDef.1Pl]',
'[/V][Sbjv.NDef.3Sg]'
)
# for back verbs, some sbjv == prs (most rakja, lécci rakja). not for front verbs. (most lépi, lécci lépje). this is good. we want this.

# tidy up prefixes
my_prefixes = my_xpostags |> 
  str_remove('\\[\\/V\\]') |> 
  str_remove_all('[\\[\\]]') |> 
  str_replace_all('\\.','_')

# do all tags at once for analogical bases
matches = map2(
  my_xpostags,
  my_prefixes,
    ~ grabForms(d, my_xpostag = .x, my_prefix = .y)
    )

# join them up. use full join, because verb x might not have form y in webcorpus, but it's still legit
predictors = matches |> 
  reduce(full_join)

# -- combine -- #

# the wide data is lemma-level info + varying sbjv forms + predictors
dw = master |> 
  inner_join(sbjv) |> 
  left_join(predictors) # we only want predictors where we have the outcome, so inner and left.

# -- filter for weird stuff -- #

# I identified some nonsensical / badly parsed forms / obviously not transitive verbs ("die" lol)
dw = dw |> 
  filter(
    !lemma %in% c('kell','jön','baj','ész','lösz','faj','tól','ed','ma','ó','sz','az','meg','nap','te','szó','fej','fal','hal','íz',''),
    !(subj_2nd == 'def' & lemma %in% c('megy','csökken','meghal')),
    !is.na(Sbjv_NDef_3Sg_form) # these are all ik verbs that ended up here with no ik, like böngész for böngészik
  )

# -- add info -- #

# stem harmony: can't just use last vowel (hívja, na köszi). luckily all verbs have sbjv 3sg indef (rakjon, lépjen, törjön, boom)
# if verb has no long form in df, p long is zero. but lo_long is NA. that's on purpose: we want to keep varying verbs. this is an analytical decision!
dw = dw |> 
  mutate(
    stem_harmony = case_when(
      str_detect(Sbjv_NDef_3Sg_form, 'on$') ~ 'back',
      str_detect(Sbjv_NDef_3Sg_form, '[eö]n$') ~ 'front',
      TRUE ~ NA_character_
    ),
    p_long = ifelse(is.na(long_freq), 0, long_freq / (long_freq + short_freq)),
    lo_long = log(long_freq / short_freq)
  )

# -- long -- #

# we make this long. so each verb once with each analogical source.
dl = dw  |> 
  pivot_longer(
    cols = c(Prs_Def_3Sg_form:Sbjv_NDef_1Pl_freq), # !!
    names_to = c("analogy_label", ".value"),
    names_pattern = "(.+)_(form|freq)$"
  ) |> 
  rename(
    analogy_form = form,
    analogy_freq = freq
  ) |> 
  mutate(
    analogy_freq_filled = ifelse(is.na(analogy_freq),0,analogy_freq) # if we didn't find you, your freq is zero
  )

# -- labels -- #

# log and scale a bunch of stuff
dl = dl |> 
  mutate(
    has_analogy_form = !is.na(analogy_form),
    log_analogy_freq = log(analogy_freq),
    log_analogy_freq_filled = log(analogy_freq_filled),
    z_llfpm10 = scale(llfpm10)[,1]
  ) |> 
  mutate(
    z_log_analogy_freq = scale(log_analogy_freq)[,1],
    z_log_analogy_freq_filled = scale(log_analogy_freq_filled)[,1],
    .by = analogy_label
  ) |> 
  mutate(
    lemma_length = ifelse(lemma_syl_count == 1, 'mono', 'poly'),
    analogy_def = ifelse(str_detect(analogy_label, '_Def'), 'def', 'indef')
  )

# -- nice tags -- #

# I don't know what 3pl sbjv ndef or whatever is. what kind of morphologist am I
# I add the relevant form of one front and one back stem so I don't have to think about it when I look at a figure later
tags = dl |> 
  # filter(!is.na(analogy_form)) |> 
  filter(lemma == 'ad' | lemma == 'ér') |> 
  arrange(-llfpm10) |> 
  distinct(lemma, analogy_label, analogy_form) |>
  pivot_wider(names_from = lemma, values_from = analogy_form) |> 
  mutate(
    analogy_label_tidy = paste0(analogy_label, ' (', ad, ', ', ér, ')') |> str_replace_all('_', ' ')
  ) |> 
  distinct(analogy_label,analogy_label_tidy)

dl = left_join(dl,tags)  

# -- write -- #

dl |> 
  write_tsv('dat/short_long_pairs_long.tsv')
