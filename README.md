This script filters and samples Hungarian verb lemmas in the 2nd person singular subjunctive form (`2sg.sbjv`) based on three linguistic/statistical criteria:

1. **Lemma log frequency** (`llfpm10`) — how common the lemma is
2. **Definiteness log odds** (`log_odds_3sg_ind`) — the ratio of definite vs. indefinite forms in the 3sg indicative
3. **Long/short subjunctive log odds** (`long_short_sbjv_log_odds`) — the ratio of long vs. short subjunctive forms

The goal is to identify a balanced, well-distributed set of stimuli across **stem harmony** (front vs. back vowel) and **lemma length** (monosyllabic vs. polysyllabic), suitable for use in a priming experiment.

---

### 1. Load Libraries

```r
library(arrow)
library(parquetize)
library(tidyverse)
library(dplyr)
library(stringr)
library(glue)
library(ggplot2)
```


### 2. Pre-filter the Data

```r
second_sg_sbjv <- read_tsv("https://raw.githubusercontent.com/peheni418/morphological_priming_hungarian/main/2sg.sbjv%20-%20forms.tsv") %>%
  filter(llfpm10 > 2) %>%
  filter(!str_detect(subj_2nd, "indef"))
```

- **`read_tsv(...)`** — loads the tab-separated data file from GitHub
- **`filter(llfpm10 > 2)`** — keeps only lemmas with a log frequency above 2, removing very rare words
- **`filter(!str_detect(subj_2nd, "indef"))`** — removes indefinite subjunctive forms, keeping only definite ones

---

### 3. Remove Missing Values

```r
second_sg_sbjv <- second_sg_sbjv %>%
  filter(!is.na(llfpm10) & !is.na(log_odds_3sg_ind) & !is.na(long_short_sbjv_log_odds))
```

Removes any rows where any of the three key variables are missing (`NA`). This ensures the filtering and median calculations below are based on complete data only.

---

### 4. Calculate Medians

```r
median_llfpm10 <- median(second_sg_sbjv$llfpm10, na.rm = TRUE)
median_log_odds_3sg_ind <- median(second_sg_sbjv$log_odds_3sg_ind, na.rm = TRUE)
median_long_short_sbjv_log_odds <- median(second_sg_sbjv$long_short_sbjv_log_odds, na.rm = TRUE)
```

Computes the **median** of each of the three variables. The medians serve as reference points for the filtering step below — items that are too close to or too far from the median on each variable will be excluded.

---

### 5. Threshold-Based Filtering Loop

```r
for (threshold in seq(0.1, 2, 0.1)) {
  second_sg_sbjv_piped <- second_sg_sbjv %>%
    filter(abs(llfpm10 - median_llfpm10) > threshold * 0.2 &
             abs(llfpm10 - median_llfpm10) < threshold * 1.2) %>%
    filter(abs(long_short_sbjv_log_odds - median_long_short_sbjv_log_odds) > threshold * 0.2 &
             abs(long_short_sbjv_log_odds - median_long_short_sbjv_log_odds) < threshold * 8) %>%
    filter(abs(log_odds_3sg_ind - median_log_odds_3sg_ind) < threshold * 1.0)

  cat("Threshold", threshold, "->", nrow(second_sg_sbjv_piped), "rows\n")
}
```

This loop tests **20 different threshold levels** (from 0.1 to 2.0, in steps of 0.1) and reports how many rows survive each threshold setting. For each threshold:

- **`llfpm10`**: keeps lemmas whose frequency deviates from the median by a moderate amount — not too close (avoids items right at the median), not too far (avoids extreme outliers)
- **`long_short_sbjv_log_odds`**: same logic, with a wider upper bound to allow more variation in the long/short ratio
- **`log_odds_3sg_ind`**: keeps only items that are relatively **close** to the median — this controls for definiteness balance

The output lets you inspect how strict or lenient each threshold is before committing to one. After the loop ends, `second_sg_sbjv_piped` holds the result from the **last** threshold (`2.0`).

> **Tip:** If you want to use a specific threshold (e.g., `1.0`), you can run just that iteration of the loop manually and assign the result to `second_sg_sbjv_piped`.

---

### 6. Descriptive Statistics

```r
summary(second_sg_sbjv_piped$llfpm10)
summary(second_sg_sbjv_piped$log_odds_3sg_ind)
summary(second_sg_sbjv_piped$long_short_sbjv_log_odds)
```

Prints basic summary statistics (min, median, mean, max) for the three variables in the filtered dataset. Useful for a quick sanity check.

---

### 7. Distribution Histograms

```r
par(mfrow = c(1, 3))
hist(second_sg_sbjv_piped$llfpm10, main = "llfpm10")
hist(second_sg_sbjv_piped$log_odds_3sg_ind, main = "log_odds_3sg_ind")
hist(second_sg_sbjv_piped$long_short_sbjv_log_odds, main = "long_short_sbjv_log_odds")
par(mfrow = c(1, 1))
```

Plots three histograms side by side (one per variable) for the filtered data. `par(mfrow = c(1, 3))` sets up the 3-panel layout; `par(mfrow = c(1, 1))` resets it afterward.

---

### 8. Violin Plots Split by Stem Harmony

```r
second_sg_sbjv_long <- second_sg_sbjv_piped %>%
  pivot_longer(cols = c(llfpm10, log_odds_3sg_ind, long_short_sbjv_log_odds),
               names_to = "variable",
               values_to = "value")

ggplot(second_sg_sbjv_long, aes(x = stem_harmony, y = value, fill = stem_harmony)) +
  geom_violin() +
  facet_wrap(~variable, scales = "free_y") +
  theme_minimal() +
  labs(title = "Distribution of Variables by Stem Harmony",
       x = "Stem Harmony", y = "Value", fill = "Stem Harmony")
```

- **`pivot_longer()`** reshapes the data from wide to long format so all three variables can be plotted together
- **`geom_violin()`** shows the full distribution shape for each group
- **`facet_wrap(~variable)`** creates a separate panel for each variable
- The plot compares **front** vs. **back** vowel harmony groups across all three variables

---

### 9. Count Items per Category

```r
sum(second_sg_sbjv_piped$lemma_length == "mono")
sum(second_sg_sbjv_piped$lemma_length == "poly")
sum(second_sg_sbjv_piped$stem_harmony == "back")
sum(second_sg_sbjv_piped$stem_harmony == "front")

(second_sg_sbjv_piped %>% count(lemma_length, stem_harmony))
```

Quick counts to check the balance of the filtered set across the two design factors: **lemma length** (mono/poly) and **stem harmony** (back/front). Bad news: only 8 combination of mono-front.

---

### 10. Stratified Sampling: 8 for each bc mono-front combination only had 8 examples, so all others are reduced to 8 from the original 10. This way instead of 40 the total stimuli contains only 32 lemmas.

```r
set.seed(123)
sample1 <- second_sg_sbjv_piped %>%
  group_by(lemma_length, stem_harmony) %>%
  slice_sample(n = 8, replace = FALSE) %>%
  ungroup()

set.seed(456)
sample2 <- second_sg_sbjv_piped %>%
  group_by(lemma_length, stem_harmony) %>%
  slice_sample(n = 8, replace = FALSE) %>%
  ungroup()
```

Creates **two independent random samples** of 8 items per group (4 groups: mono×back, mono×front, poly×back, poly×front = 32 items each), using different random seeds so the samples don't overlap in their selection pattern. `set.seed()` ensures the sampling is reproducible.

---

### 11. Check Sample Distributions

```r
print(sample1 %>% count(lemma_length, stem_harmony))
print(sample2 %>% count(lemma_length, stem_harmony))
```

Verifies that each group has exactly 8 items in both samples. 

The violin plots that follow (for `sample1_plot` and `sample2_plot`) repeat the same visualization logic as Step 8, now applied to each sample individually. This lets you confirm that both samples have similar distributional properties.

---

### 12. Save the Filtered Dataset

```r
write_tsv(second_sg_sbjv_piped, "second_sg_sbjv_piped.tsv")
```

Saves the filtered (pre-sampling) dataset as a TSV file in your **current working directory**. You can set your working directory beforehand using `setwd("your/folder/path")`, or use `here::here()` if you prefer project-relative paths.

---

## Output Files

| File | Description |
|------|-------------|
| `second_sg_sbjv_piped.tsv` | Filtered dataset after threshold-based selection |
| Plots (displayed in RStudio) | Histograms and violin plots for distribution checks |

---

## Variables Used

| Variable | Description |
|----------|-------------|
| `llfpm10` | Log lemma frequency per million (base 10) |
| `log_odds_3sg_ind` | Log odds of definite vs. indefinite form in 3sg indicative |
| `long_short_sbjv_log_odds` | Log odds of long vs. short subjunctive form |
| `stem_harmony` | Vowel harmony class of the stem: `back` or `front` |
| `lemma_length` | Syllable count category: `mono` or `poly` |
| `subj_2nd` | 2nd person subjunctive form label (used for definiteness pre-filtering) |



## PROBLEM: back and front frequencies show different distributions. The viloin plots have different curves comparing back and front lemmas. Back harmony naturally has lower frequency lemmas than front harmony. As copilot said: "This isn't a data quality problem — it's a linguistic pattern in your data."
