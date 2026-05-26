library(ggplot2)
library(tidyverse)
library(here)
library(lme4)


# ----- Set path to data file -----
data <- read_csv(here("clean_data.csv"))

# ----- Make sure pair_type is ordered -----
pair_order <- c("back_cell", "front_cell", "back_form", "front_form")
pair_labels <- c(
  "back_cell" = "várjad/várd",
  "back_form" = "várjad/várja",
  "front_cell" = "kérjed/kérd",
  "front_form" = "kérjed/kéri"
)

data$pair_type <- factor(data$pair_type, levels = pair_order)

data_filtered <- data_filtered <- data %>%
  filter(
    stim_type != "type_distractor",                              # Exclude type_distractor rows
    exclude_bad_participant != "TRUE",                              # Exclude bad participants
    exclude_slow != "TRUE",                                         # Exclude slow trials
    !(key_resp_5.keys == "j" & stim_type == "type_distractor"),  # Exclude j + type_distractor rows
    !(key_resp_5.keys == "f" & stim_type == "type_target")       # Exclude f + type_target rows
  ) |> 
  mutate(
    pair_type = factor(pair_type, levels = pair_order)
  )



# ============================================================================
# PLOT 1: Each POINT is a single pair's average across all participants
# e.g., átlag RT all participants gave to "engedjed,edgedjen"
# ============================================================================

# Combine prime/target for each trial (for unique pairs)
data_filtered <- data_filtered %>%
  mutate(pair = paste(primeHeni, targetHeni, sep = " → "))

pair_avg <- data_filtered %>%
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

participant_avg <- data_filtered %>%
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


## =============


# Fit the GLMM
model <- glmer(
  key_resp_5.rt ~ pair_type + (1|participant) + (1|primeHeni),
  family = Gamma(link = 'log'),
  data = data_filtered
)

# View results
summary(model)
<<<<<<< HEAD:analysis_script.R

sjPlot::plot_model(model, 'pred')

sjPlot::plot_model(model, 'pred') +
  theme_bw() + # nice background
  labs(
    title = 'predicted values of rt x condition',
    x = 'condition',
    y = 'rt'
  ) + # nice labs
  # horizontal line
  annotate("segment",
           x = 1, xend = 3,          # back_cell=1, back_form=3 (position on x axis)
           y = 0.85, yend = 0.85) +
  # left tick
  annotate("segment", x = 1, xend = 1, y = 0.85, yend = 0.845) +
  # right tick
  annotate("segment", x = 3, xend = 3, y = 0.85, yend = 0.845) +
  # stars
  annotate("text", x = 2, y = 0.855, label = "**", size = 5)


=======
sjPlot::plot_model(model, 'pred')
broom.mixed::tidy(model)
>>>>>>> 01a728efabab64f075dbc38b7cb86bb384bfe3c7:script/analysis_script.R
