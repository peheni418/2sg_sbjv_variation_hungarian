# Morphological Priming in Hungarian

This project investigates morphological priming effects in Hungarian: how
different verb forms affect processing speed and accuracy in a lexical decision
task. The experiment lives at
https://gitlab.pavlovia.org/peheni/variation2sg_priming_2026.

There are two parallel analyses: an experimental priming study (`script/`) and
a corpus frequency study (`corpus/`) that tests the same predictions on
corpus counts rather than reaction times.

## Layout

```
.
├── raw_data/           per-participant csvs from psychopy (XXXXXX_priming.csv)
├── dat/                wrangled and intermediate data (experiment + corpus)
├── script/             experimental analysis pipeline
│   ├── build_data.R                raw_data -> dat/clean_data_{unfiltered,filtered}.csv
│   ├── fit.R                       fits the main glmm (full four-level pair_type), saves to fit/
│   ├── viz.R                       loads data + fit, writes plots into viz/
│   ├── hypothesis_testing_exp.R    prereg H0-H3 comparison on the experiment data
│   ├── compare_exclusion_criteria.R  compares the 4s rt cutoff against MAD-based alternatives
│   └── demographic_data.R          age/gender summary from dat/age_gender_priming2026.csv
├── corpus/             corpus-level analyses (parallel structure to script/)
│   ├── build_corpus.R              webcorpus2 freq list -> dat/corpus_short_long_pairs_{wide,long}.tsv
│   ├── hypothesis_testing_corpus.R prereg-style H0-H3 comparison on corpus counts
│   ├── viz_corpus.R                exploratory visualisations
│   ├── fit_corpus.R                earlier/exploratory model fits (lme4)
│   └── explore_corpus.R            ad-hoc exploratory questions (Q1-Q4)
├── fit/                saved model objects (.rds)
├── viz/                figures (png, 900 dpi)
├── stimuli_building/   stimulus construction (separate from analysis)
└── misc/               notes, preregistration pdf, and other supporting text
```

## Experiment pipeline

Run from the project root in order:

1. `script/build_data.R` — reads `raw_data/`, flags completion (144 trials),
   slow trials (rt > 4 s), and bad participants (error rate > .5), assigns
   harmony class and pair type, writes `dat/clean_data_unfiltered.csv` (all
   rows, flags only) and `dat/clean_data_filtered.csv` (exclusions applied).
2. `script/fit.R` — fits the main glmm (`rt ~ pair_type + (1|participant) +
   (1|item)`, Gamma with log link) with the full four-level `pair_type`
   predictor (`back_cell`, `front_cell`, `back_form`, `front_form`) on the
   filtered data, saves it to `fit/fit1.rds`.
3. `script/viz.R` — produces plots into `viz/`: per-pair averages,
   per-participant averages, the model's predicted RT by condition, and the
   emmeans pairwise-contrast plot; also writes `dat/pair_avg.csv`.
4. `script/hypothesis_testing_exp.R` — independent, prereg-driven comparison
   of four hypotheses (H0-H3), each with condition recoded differently, via
   AIC, BIC, and BIC-based Bayes factors.

Supplementary, not part of the main pipeline:

- `script/compare_exclusion_criteria.R` — sensitivity check of the rt
  exclusion cutoff (4 s vs MAD-based alternatives).
- `script/demographic_data.R` — reports participant age/gender summary.

## Corpus pipeline

1. `corpus/build_corpus.R` — reads the webcorpus2 frequency list, writes
   `dat/corpus_short_long_pairs_{wide,long}.tsv` and
   `dat/corpus_dat_summary_with_props.tsv` (the latter block was reverse
   engineered by Claude from the pre-existing file and hand-checked, since
   the original generating code was never committed — see Known issues).
2. `corpus/hypothesis_testing_corpus.R` — the corpus analogue of
   `hypothesis_testing_exp.R`: fits four binomial glmms (`cbind(long_freq,
   short_freq) ~ ...`) encoding the same H0-H3 structure, compares them via
   AIC, BIC, marginal R2, and Bayes factors. Reads
   `dat/corpus_dat_summary_with_props.tsv`.
3. `corpus/viz_corpus.R` — exploratory visualisations of frequency and
   analogical predictors against the long/short subjunctive log-odds.

`corpus/fit_corpus.R` and `corpus/explore_corpus.R` are earlier, exploratory
scripts (multiple ad-hoc `glmer` fits, and four hand-written questions,
respectively) that predate `hypothesis_testing_corpus.R`. Worth confirming
whether to update or retire them.

## Exclusions

Applied uniformly across `build_data.R`, `fit.R`, `viz.R`, and
`hypothesis_testing_exp.R`:

- drop participants who didn't complete all 144 trials,
- drop distractor trials,
- drop participants with error rate > .5,
- drop trials with rt > 4 s,
- drop incorrect ('f') responses on targets.

The corpus pipeline has no trial-level rt exclusions (there are no
reaction times); overdispersion in the aggregated counts is instead handled
with an observation-level random intercept (`(1|obs_id)`).

## Pair Type Coding

The experiment crosses harmony with target shape:

| Pair Type  | Harmony | Target shape | Example         |
|------------|---------|--------------|-----------------|
| back_cell  | back    | d-stem       | várjad → várd   |
| back_form  | back    | regular      | várjad → várja  |
| front_cell | front   | d-stem       | kérjed → kérd   |
| front_form | front   | regular      | kérjed → kéri   |

There used to be a custom `pair_order` variable pinning `pair_type` to
`back_cell, front_cell, back_form, front_form`, applied inconsistently across
scripts, which caused `front_cell` and `back_form` to appear swapped in some
`emmeans` output (position 2/3 differ from R's alphabetical default:
`back_cell, back_form, front_cell, front_form`). This has been removed;
`pair_type` now uses the alphabetical default everywhere. This doesn't
change any fitted values or contrasts — `emmeans` matches by level label,
not position — but `fit.R` still explicitly wraps it in `factor()` before
fitting, because `glmmTMB` otherwise stores a character predictor as-is,
and `sjPlot::plot_model()` then falls back to an unpredictable (non-
alphabetical) axis order rather than the model's actual level order. The
`x` positions of the significance brackets in `viz.R`'s `p3` are hardcoded
to match the resulting alphabetical order.

## Known issues

- `dat/corpus_dat_summary_with_props.tsv`, read by both
  `hypothesis_testing_corpus.R` and `fit_corpus.R`, originally shipped as a
  hand-built file with no generating code in the repo. `build_corpus.R` now
  reconstructs it from `dw`; the reconstruction was reverse engineered by
  Claude and hand-checked against all 2001 rows of the original file
  (exact match). One quirk carried over as-is: `log_odds_3pl_sbjv` puts
  NDef in the numerator, unlike the other three `log_odds_*` columns,
  which put Def in the numerator — looks like an inconsistency in
  whatever produced the original file, worth revisiting.
- `dat/data_filtered.csv` and `dat/raus.csv` aren't read by any current
  script; likely leftovers from an earlier version of the pipeline.

## Notes

- Paths in `script/` use `here::here()` from the project root; some
  `corpus/` scripts use plain relative paths instead (`setwd()` at the top
  covers this in practice, but `here()` would be more robust).
- Seed is `1337` throughout the modelling scripts.
