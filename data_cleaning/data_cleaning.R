library(tidyverse)

# Read and combine all CSV files from data folder
data <- list.files("C:/Users/Pokk Heni/Documents/Péhádédoktoriphd/2025_26_elso_ev/toldalekos_kisi/masodik_etikus_verzio/elemzes/data", pattern = "\\.csv$", full.names = TRUE) %>%
  map_df(~read.csv(.x) %>% 
           mutate(participant = as.character(participant))) %>%
  select(participant, key_resp_5.keys, key_resp_5.rt, primeHeni, targetHeni, stim_type)


# Remove rows with NA
data <- data %>%
  filter(!is.na(key_resp_5.keys) & !is.na(key_resp_5.rt) & !is.na(stim_type))

# Remove rows where key_resp_5.rt is above 4
data <- data %>%
  filter(key_resp_5.rt <= 4)

# Find participants to exclude based on error rates
bad_participants <- data %>%
  mutate(error = case_when(
    stim_type == "type_target" & key_resp_5.keys == "f" ~ 1,
    stim_type == "type_distractor" & key_resp_5.keys == "j" ~ 1,
    TRUE ~ 0
  )) %>%
  group_by(participant) %>%
  summarise(error_rate = mean(error), .groups = "drop") %>%
  filter(error_rate > 0.5) %>%
  pull(participant)

# Remove bad participants
data <- data %>%
  filter(!(participant %in% bad_participants))


# Determine harmony class based on target verb ending
data <- data %>%
  mutate(
    harmony_class = case_when(
      str_ends(targetHeni, "i") ~ "front",
      TRUE ~ "back"
    )
  )

# Get all unique primeHeni values from front harmony rows
front_primes <- data %>%
  filter(harmony_class == "front") %>%
  pull(primeHeni) %>%
  unique()

# Update harmony_class to front for all rows with these primes
data <- data %>%
  mutate(
    harmony_class = case_when(
      primeHeni %in% front_primes ~ "front",
      TRUE ~ harmony_class
    )
  )

# Create pair_type column based on harmony_class and target ending
# Only for type_target rows
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




# Calculate average reaction time per word per pair_type
data_summary <- data %>%
  filter(!is.na(pair_type)) %>%
  group_by(pair_type, targetHeni) %>%
  summarise(mean_rt = mean(key_resp_5.rt), .groups = "drop")

# Define the order you want
pair_order <- c("back_cell", "front_cell", "back_form", "front_form")

# Convert pair_type to a factor with the specified order
data_summary$pair_type <- factor(data_summary$pair_type, levels = pair_order)

# Create labels mapping
pair_labels <- c(
  "back_cell" = "várjad/várd",
  "back_form" = "várjad/várja",
  "front_cell" = "kérjed/kérd",
  "front_form" = "kérjed/kéri"
)

# Create violin plot with renamed x-axis
ggplot(data_summary, aes(x = pair_type, y = mean_rt)) +
  geom_violin(fill = "lightblue", alpha = 0.7) +
  geom_boxplot(width = 0.2, fill = "white") +
  geom_jitter(width = 0.15, alpha = 0.5) +
  scale_x_discrete(labels = pair_labels) +
  labs(
    x = "Pair Type",
    y = "Mean Reaction Time (s)",
    title = "Average Rection Times per Category"
  ) +
  theme_minimal()



## Participant plot 

participant_summary <- data %>%
  filter(!is.na(pair_type)) %>%
  group_by(participant, pair_type) %>%
  summarise(mean_rt = mean(key_resp_5.rt), .groups = "drop")



ggplot(participant_summary, aes(x = pair_type, y = mean_rt)) +
  geom_violin(fill = "lightblue", alpha = 0.7) +
  geom_jitter(width = 0.2, alpha = 0.5, size = 3) +
  geom_boxplot(width = 0.2, fill = "white", alpha = 0.7) +
  scale_x_discrete(labels = pair_labels) +
  labs(
    x = "Pair Type",
    y = "Mean Reaction Time (s)",
    title = "Overall Average Reaction Times per Participant by Pair Type"
  ) +
  theme_minimal()

