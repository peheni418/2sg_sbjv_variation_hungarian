library(ggplot2)
library(tidyverse)
library(here)


# ----- Set path to data file -----
data <- read_csv(here("data_cleaning/clean_data"))

# ----- Make sure pair_type is ordered -----
pair_order <- c("back_cell", "front_cell", "back_form", "front_form")
pair_labels <- c(
  "back_cell" = "várjad/várd",
  "back_form" = "várjad/várja",
  "front_cell" = "kérjed/kérd",
  "front_form" = "kérjed/kéri"
)

data$pair_type <- factor(data$pair_type, levels = pair_order)

# ============================================================================
# PLOT 1: Each POINT is a single pair's average across all participants
# e.g., átlag RT all participants gave to "engedjed,edgedjen"
# ============================================================================

# Combine prime/target for each trial (for unique pairs)
data <- data %>%
  mutate(pair = paste(primeHeni, targetHeni, sep = " → "))

pair_avg <- data %>%
  filter(!is.na(pair_type)) %>%
  group_by(pair, pair_type) %>%
  summarise(mean_rt = mean(key_resp_5.rt, na.rm = TRUE), .groups = "drop")

ggplot(pair_avg, aes(x = pair_type, y = mean_rt)) +
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

# ============================================================================
# PLOT 2: Each POINT is a single participant's average for that pair type
# e.g., átlag RT for participant 013564 to 'back_cell'
# ============================================================================

participant_avg <- data %>%
  filter(!is.na(pair_type)) %>%
  group_by(participant, pair_type) %>%
  summarise(mean_rt = mean(key_resp_5.rt, na.rm = TRUE), .groups = "drop")

participant_avg$pair_type <- factor(participant_avg$pair_type, levels = pair_order)

ggplot(participant_avg, aes(x = pair_type, y = mean_rt)) +
  geom_violin(fill = "lightblue", alpha = 0.7) +
  geom_boxplot(width = 0.2, fill = "white") +
  geom_jitter(width = 0.15, alpha = 0.5) +
  scale_x_discrete(labels = pair_labels) +
  labs(
    x = "Pair Type",
    y = "Mean Reaction Time (s)",
    title = "Avg RT per Participant by Pair Type"
  ) +
  theme_minimal() +
  theme(legend.position = "none", axis.text.x = element_text(angle = 45, hjust = 1))

