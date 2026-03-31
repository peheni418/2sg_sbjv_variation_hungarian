install.packages("parquetize")
install.packages("arrow")
install.packages("stringr")
library(arrow)
library(parquetize)
library(tidyverse)
library(dplyr)
library(stringr)




word_freq <- read_parquet("C:/Users/Pokk Heni/Downloads/frequencies.parquet")

most_freq <- filter(word_freq, freq > 10000 )

verbs <- most_freq %>%
  filter(str_detect(xpostag, "\\[/V\\]"))

real_verbs <- verbs %>%
  filter(!(lemma %in% c("van", "nincs", "volna", "lesz", "kell", "fog")))




# filter here, filter there 

prs_verbs <- real_verbs %>% 
  filter(str_detect(xpostag, "Prs"))

pst_verbs <- real_verbs %>% 
  filter(str_detect(xpostag, "Pst"))

prs_ndef_verbs <- prs_verbs %>% 
  filter(str_detect(xpostag, "NDef"))

prs_def_verbs <- prs_verbs %>% 
  filter(str_detect(xpostag, "Def") & !str_detect(xpostag, "NDef"))

pst_ndef_verbs <- pst_verbs %>% 
  filter(str_detect(xpostag, "NDef"))

pst_def_verbs <- pst_verbs %>% 
  filter(str_detect(xpostag, "Def") & !str_detect(xpostag, "NDef"))





# def/indef pairs

real_verbs <- real_verbs %>%
  mutate(xpostag_base = str_remove(xpostag, "Def|NDef"))


def_indef_pairs <- verbs %>%
  group_by(lemma, xpostag_base) %>%
  filter(n_distinct(str_extract(xpostag, "Def|NDef")) == 2) %>%
  ungroup() %>%
  arrange(lemma, xpostag_base, str_extract(xpostag, "Def|NDef"))


n_distinct(def_indef_pairs$lemma)




# filtering for variation for fun

variation <- real_verbs %>%
  group_by(lemma, xpostag) %>%
  filter(n_distinct(form) > 1) %>%
  ungroup() %>%
  arrange(lemma, xpostag, form)


# filtering for stem alternations based on cv skeleton, skeleton column


# Function to convert a word to CV skeleton
to_cv_skeleton <- function(word) {
  # Convert to lowercase
  word <- tolower(word)
  
  # Define vowels
  vowels <- "[aáeéiíoóöőuúüű]"
  
  # Replace vowels with 'V' and consonants with 'C'
  skeleton <- str_replace_all(word, vowels, "V")
  skeleton <- str_replace_all(skeleton, "[^V]", "C")
  
  return(skeleton)
}


real_verbs <- real_verbs %>%
  mutate(
    lemma_cv = to_cv_skeleton(lemma),
    form_cv = to_cv_skeleton(form)
  )


# Filter for stem alternants:
# Lemma has simple CV (no CC cluster) but forms have CC clusters
stem_alternants <- real_verbs %>%
  group_by(lemma) %>%
  filter(
    !str_detect(lemma_cv, "CC"),  # Lemma has no CC cluster
    any(str_detect(form_cv, "CC"))  # But some forms do have CC
  ) %>%
  ungroup()

stem_alternants_var <- variation %>%
  group_by(lemma) %>%
  filter(
    !str_detect(lemma_cv, "CC"),  # Lemma has no CC cluster
    any(str_detect(form_cv, "CC"))  # But some forms do have CC
  ) %>%
  ungroup()










