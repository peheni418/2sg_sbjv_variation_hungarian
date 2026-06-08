library(here)
library(tidyverse)

##ATTENTION: THERE IS ONE PARTICIPANTS WHO GAVE IS NEPTUN CODE AS PARTICIPANT ID: UMIZ4M. AS A FIRST STEP IT IS NEEDED TO BE RENAMED. I USUSALLY DO UMIZ4M --> 123456. 

# =================== DATA LOADING ===================
# Read all CSVs, each participant's file is named with 6 digits then '_priming.csv'
data <- list.files(
  here("raw_data"),
  pattern = "^[0-9]{6}_priming\\.csv$",
  full.names = TRUE
) %>%
  map_df(~{
    df <- read.csv(.x)
    # Extract participant ID from filename
    df$participant <- stringr::str_extract(basename(.x), "^[0-9]{6}")
    df
  })

# Only keep needed columns
data <- data %>%
  select(participant, key_resp_5.keys, key_resp_5.rt, primeHeni, targetHeni, stim_type)

data <- data %>% drop_na()

# =================== FLAG EXCLUSIONS: slow RTs ===================
# Add a column to flag slow response (>4 sec)
data <- data %>%
  mutate(
    exclude_slow = if_else(!is.na(key_resp_5.rt) & key_resp_5.rt > 4, "T", "F")
  )

# =================== FLAG EXCLUSIONS: bad participants ===================
# Calculate participant error rate
# Error = incorrect response (pressing 'f' on target or 'j' on distractor)
participant_error_rate <- data %>%
  filter(!is.na(key_resp_5.keys) & !is.na(stim_type)) %>%
  mutate(
    error = case_when(
      stim_type == "type_target" & key_resp_5.keys == "f" ~ 1,
      stim_type == "type_distractor" & key_resp_5.keys == "j" ~ 1,
      TRUE ~ 0
    )
  ) %>%
  group_by(participant) %>%
  summarise(error_rate = mean(error), .groups = "drop")

# Mark participants with error_rate > 0.5 as "bad"
# Join back to original data to flag each participant
data <- data %>%
  left_join(participant_error_rate %>%
              mutate(exclude_bad_participant = if_else(error_rate > 0.5, "T", "F")),
            by = "participant")
# For participants not in the error rate table, mark as not excluded (safer default)
data$exclude_bad_participant[is.na(data$exclude_bad_participant)] <- "F"

# =================== VOWEL HARMONY SCORING ===================
# Mark harmony class based on targetHeni
data <- data %>%
  mutate(
    harmony_class = case_when(
      str_ends(targetHeni, "i") ~ "front",
      TRUE ~ "back"
    )
  )

# All unique primes in front harmony
front_primes <- data %>%
  filter(harmony_class == "front") %>%
  pull(primeHeni) %>%
  unique()

# Primes in front group get marked as front harmony
data <- data %>%
  mutate(
    harmony_class = case_when(
      primeHeni %in% front_primes ~ "front",
      TRUE ~ harmony_class
    )
  )



# =================== PAIR TYPE ===================
# Same cell or form similarity coding


data <- data %>%
  mutate(
    pair_type = case_when(
      stim_type == "type_distractor" ~ NA_character_,
      harmony_class == "front" & str_ends(targetHeni, "d") ~ "front_cell",
      harmony_class == "front" & !str_ends(targetHeni, "d") ~ "front_form",
      harmony_class == "back" & str_ends(targetHeni, "d") ~ "back_cell",
      harmony_class == "back" & !str_ends(targetHeni, "d") ~ "back_form"
    )
  )


# =================== SAVE MUTATED DATA ===================
# Write out all data with exclusion columns
write.csv(data, "clean_data.csv", row.names = FALSE)

