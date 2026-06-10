# Morphological Priming in Hungarian

This project investigates morphological priming effects in Hungarian: how
different verb forms affect processing speed and accuracy in a lexical decision
task. The experiment lives at
https://gitlab.pavlovia.org/peheni/variation2sg_priming_2026.

## Layout

```
.
├── raw_data/           per-participant csvs from psychopy (XXXXXX_priming.csv)
├── dat/                wrangled and intermediate data
│   ├── clean_data.csv      output of script/build_data.R
│   ├── data_filtered.csv   the subset used for modelling
│   └── pair_avg.csv        per-pair averages used in plots
├── script/             analysis pipeline
│   ├── build_data.R        raw_data -> dat/clean_data.csv
│   ├── fit.R               fits the main glmm, saves to fit/
│   ├── viz.R               loads data + fit, writes plots into viz/
│   └── hypothesis_testing.R    prereg H0-H3 comparison
├── fit/                saved model objects (.rds)
├── viz/                figures (png, 900 dpi)
└── stimuli_building/   stimulus construction (separate from analysis)
```

## Pipeline

Run from the project root in order:

1. `script/build_data.R` — reads `raw_data/`, applies exclusion flags
   (slow trials, high-error participants), assigns harmony class and pair type,
   writes `dat/clean_data.csv`.
2. `script/fit.R` — fits the main glmm (`rt ~ pair_type + (1|participant) +
   (1|item)`, gamma with log link) on the filtered data and saves it to
   `fit/fit1.rds`.
3. `script/viz.R` — produces three plots into `viz/`: per-pair averages,
   per-participant averages, and the model's predicted RT by condition.
4. `script/hypothesis_testing.R` — independent, prereg-driven comparison
   of four hypotheses (H0-H3) via AIC, BIC, and BIC-based Bayes factors.

## Exclusions

Applied uniformly across `fit.R`, `viz.R`, and `hypothesis_testing.R`:

- drop distractor trials,
- drop participants with error rate > .5,
- drop trials with rt > 4 s,
- drop incorrect ('f') responses on targets.

## Pair Type Coding

The experiment crosses harmony with target shape:

| Pair Type  | Harmony | Target shape | Example         |
|------------|---------|--------------|-----------------|
| back_cell  | back    | d-stem       | várjad → várd   |
| back_form  | back    | regular      | várjad → várja  |
| front_cell | front   | d-stem       | kérjed → kérd   |
| front_form | front   | regular      | kérjed → kéri   |

## Notes

- Paths use `here::here()` from the project root.
- Seed is `1337` throughout.

## Corpus

The corpus folder has the scripts to build the 2sg.sbjv dataset from the webcorpus frequency list; fit model on data; build visualisation. Data live in dat.
