
library(arrow)
library(parquetize)
library(tidyverse)
library(dplyr)
library(stringr)

install.packages("glue")
library(glue)

# --  Getting the most frequent verbs, excluding auxiliaries and hunspell FALSE -- #

real_verbs <- read_parquet("C:/Users/Pokk Heni/Downloads/frequencies.parquet") %>%
  filter(freq > 100) %>%
  filter(str_detect(xpostag, "\\[/V\\]")) %>%
  filter(!(lemma %in% c("van", "nincs", "volna", "lesz", "kell", "fog", "sincs", "a", 'á'))) %>% 
  filter(hunspell == "TRUE")


# --  imperative long/short pairs  -- #

imperative <- real_verbs %>%
  filter(str_detect(xpostag, "\\[Sbjv\\.(Def|NDef)\\.2Sg\\]")) %>%  # Both Def and NDef
  group_by(lemma, xpostag) %>%
  filter(n_distinct(form) > 1) %>%  # Multiple forms per xpostag
  ungroup() %>%
  arrange(lemma, xpostag, form)

n_distinct(imperative$lemma) #240


# --  epethesis -- #

epenthesis <- read_tsv("C:/Users/Pokk Heni/Downloads/epenthesis_pairs_webcorpus2.tsv")



# --  epenthesis$base and real_verb$lemma matching and getting a table of only varying ep verbs  -- #

ep_real <- real_verbs %>%
  semi_join(
    epenthesis,
    by = c("lemma" = "base")
  ) %>% 
  arrange(lemma)

# -- getting all person/number forms of indicative, present tense -- #

ep_real <- ep_real %>% 
  filter(str_detect(xpostag, "^\\[/V\\]\\[Prs\\.NDef\\.(1Sg|2Sg|3Sg|1Pl|2Pl|3Pl)\\]$")) %>% 
  arrange(lemma, xpostag)
  



# -- keeping all xpostags that have two forms corresponding to them, and excluding one to one forms and tags -- # 

ep_real <- ep_real %>%
  group_by(lemma, xpostag) %>%
  filter(n_distinct(form) > 1) %>%
  ungroup() %>%
  arrange(lemma, xpostag, form)

# -- excluding 1sg forms, alszom/alszok -- #

ep_real <- ep_real %>%
  filter(!str_detect(xpostag, "\\[/V\\]\\[Prs\\.NDef\\.1Sg\\]"))

n_distinct(ep_real$lemma) #35
