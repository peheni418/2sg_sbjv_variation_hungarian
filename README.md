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
├── raw_data/           per-participant csvs from psychopy (participantN_priming.csv)
├── dat/                wrangled and intermediate data (experiment + corpus)
├── script/             experimental analysis pipeline
│   ├── anonymise_ids.R             one-off, gitignored -- see "Participant ids" below
│   ├── build_data.R                raw_data -> dat/clean_data_{unfiltered,filtered}.csv
│   ├── fit.R                       fits the main glmm (full four-level pair_type), saves to fit/
│   ├── viz.R                       loads data + fit, writes plots into viz/
│   ├── hypothesis_testing_exp.R    prereg H0-H3 comparison on the experiment data
│   ├── compare_exclusion_criteria.R  compares the 4s rt cutoff against MAD-based alternatives
│   └── demographic_data.R          age/gender summary from dat/age_gender_priming2026.csv
├── corpus/             corpus-level analyses (parallel structure to script/)
│   ├── build_corpus.R              webcorpus2 freq list -> dat/corpus_short_long_pairs_{wide,long}.tsv
│   ├── hypothesis_testing_corpus.R prereg-style H0-H3 comparison on corpus counts
│   ├── fit_corpus.R                earlier/exploratory model fits (glmmTMB, same as above)
│   └── explore_corpus.R            ad-hoc exploratory questions (Q1-Q4)
├── fit/                saved model objects (.rds)
├── viz/                figures (png, 900 dpi)
├── stimuli_building/   stimulus construction (separate from analysis)
└── LICENSE             MIT
```

## Participant ids

Raw and processed files use `participant1`..`participantN` throughout, not the
original psychopy-assigned ids or (in one case) a Neptun code a participant
typed into the id field by mistake. The mapping from old to new ids lived only
in `script/anonymise_ids.R`'s output (`id_mapping.csv`), gitignored and never
committed, since it's the one place old and new ids are linked. Re-running
`anonymise_ids.R` is a one-off operation and not expected to happen again;
`build_data.R` explicitly excludes four known pilot/test sessions by their new
ids (see the comment above `test_session_ids` in that script) so that the
broader `participant[0-9]+` filename pattern doesn't silently pull them back
into the analysis.

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

`corpus/fit_corpus.R` is a later, more thorough model-comparison pass on the
same file (model selection by AIC/BIC/LRT/Bayes factor, plus the population-
averaged effects figure for the paper); `corpus/explore_corpus.R` is an
earlier, ad-hoc pass (four hand-written questions, Q1-Q4) that predates both.
All three use `glmmTMB`, not `lme4`/`glmer`.

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

## Data dictionary: `dat/corpus_dat_summary_with_props.tsv`

One row per lemma x paradigm cell (definite/indefinite); 2,001 rows, read by
`hypothesis_testing_corpus.R` and `fit_corpus.R`. All four `log_odds_*`
columns use add-one (Laplace) smoothing, `log((x + 1) / (y + 1))`, to avoid
`log(0)` on zero-count cells.

| Column | Type | Description |
|---|---|---|
| `lemma` | chr | the verb lemma (e.g. `vár`, `kér`) |
| `subj_2nd` | chr | paradigm cell for this row: `def` or `indef` |
| `long_freq` | int | corpus count of the long 2sg.sbjv variant for this lemma x cell (e.g. `várjad`, `várjál`) |
| `short_freq` | int | corpus count of the short 2sg.sbjv variant (e.g. `várd`, `várj`) |
| `long_short_sbjv_log_odds` | dbl | `log((long_freq + 1) / (short_freq + 1))` -- the outcome variable; long-form preference for this lemma x cell |
| `stem_harmony` | chr | `back` or `front`, read off the 3sg.sbjv.indef form (e.g. `rakjon` = back, `lépjen` = front) |
| `lemma_length` | chr | `mono` or `poly`, from the lemma's syllable count (1 vs. more) |
| `llfpm10` | dbl | log10 lemma frequency per 10 million words (whole-corpus, not cell-specific) |
| `log_odds_3sg_ind` | dbl | lemma's definiteness preference: `log((Prs.Def.3Sg freq + 1) / (Prs.NDef.3Sg freq + 1))`, e.g. `várja` vs. `vár`. This is the subparadigm-frequency predictor used in the best model (M2/`fit3b`) |
| `log_odds_3sg_sbjv` | dbl | same construction for the 3sg subjunctive: `log((Sbjv.Def.3Sg freq + 1) / (Sbjv.NDef.3Sg freq + 1))`, e.g. `várja` (sbjv, homographous with the indicative for back stems) vs. `várjon` |
| `log_odds_3pl_ind` | dbl | same for the 3pl indicative: `log((Prs.Def.3Pl freq + 1) / (Prs.NDef.3Pl freq + 1))`, e.g. `várják` vs. `várnak` |
| `log_odds_3pl_sbjv` | dbl | same for the 3pl subjunctive, **but with NDef in the numerator**, unlike the other three columns: `log((Sbjv.NDef.3Pl freq + 1) / (Sbjv.Def.3Pl freq + 1))`, e.g. `várjanak` vs. `várják`. Kept as-is to match the pre-existing file; see Known issues |
| `obs_id` | int | row number; used as the observation-level random intercept group (`(1\|obs_id)`) to absorb overdispersion in the binomial models |

`dat/corpus_short_long_pairs_wide.tsv` and `_long.tsv` carry much more detail
(all 18 analogical-base frequencies `build_corpus.R` extracts, not just the
four used above) and are not described column-by-column here; see
`build_corpus.R`'s `my_xpostags`/`grabForms()` for what each one is.

## Data dictionary: `dat/clean_data_filtered.csv`

One row per critical (non-distractor) trial that survived all exclusions;
2,275 rows, 25 participants. `dat/clean_data_unfiltered.csv` has the same
columns minus `rt` and `item` (added only once the exclusion filters are
applied) and includes all trials, flags included, before any exclusion.

| Column | Type | Description |
|---|---|---|
| `participant` | chr | anonymised id (see "Participant ids" above); only the subset with raw_data files appears here, not the full `participant1`..`participant69` range (the demographic file's ids run higher, to accommodate Neptun codes with no raw_data counterpart) |
| `key_resp_5.keys` | chr | raw key press on the critical trial: `j` (real/familiar word) or `f` (not) |
| `key_resp_5.rt` | dbl | raw response time in seconds, from psychopy |
| `primeH` | chr | the prime word form shown |
| `targetH` | chr | the target word form shown |
| `stim_type` | chr | `type_target` (critical trial) or `type_distractor`; only `type_target` rows reach `clean_data_filtered.csv` |
| `complete` | lgl | did this participant finish all 144 trials |
| `exclude_slow` | lgl | `key_resp_5.rt > 4` (seconds) |
| `error_rate` | dbl | participant-level proportion of incorrect responses, computed across *all* trial types (target + distractor combined), not distractor trials alone as the preregistration specifies -- see paper-side note in `sbjv_paper.tex` |
| `exclude_bad_participant` | lgl | `error_rate > .5` |
| `completion_time_sec` | dbl | session duration, `max(end_2.stopped) - min(instructions.started)`, in seconds. Restricted to finite values as of this version: a session that never reached the end screen has `end_2.stopped` entirely missing, so the unguarded calculation returns `-Inf` -- true of 13 of the 38 raw sessions, and the reason the previously-reported median completion time (11.7 min) differs from the corrected one (12.1 min); see Known issues |
| `harmony_class` | chr | `back`/`front`, read off the target form (and carried to primes sharing a front target) |
| `pair_type` | chr | `back_cell`/`back_form`/`front_cell`/`front_form` for target trials, `NA` for distractors -- see "Pair Type Coding" above |
| `rt` | dbl | `= key_resp_5.rt`; `clean_data_filtered.csv` only |
| `item` | chr | `= primeH`; `clean_data_filtered.csv` only, used as the item-level random intercept group |

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
- `script/compare_exclusion_criteria.R` reads `dat/clean_data.csv`, which no
  current script writes (only `clean_data_{unfiltered,filtered}.csv` exist).
  Predates a rename somewhere upstream; not fixed, since it's not part of
  the main pipeline and it's unclear which of the two it should point to.
- The median completion time reported in the paper (11.7 min) was computed
  without guarding against `-Inf` (see the `completion_time_sec` entry
  above): 13 of the 38 raw sessions never reached the end screen, and their
  `-Inf` "duration" pulled the unguarded median down to something that
  happened to look plausible. `build_data.R` now excludes non-finite values
  before taking the median, giving 12.1 min instead. This doesn't affect any
  modelled result, only that one descriptive sentence in the paper's
  Procedure section, which hasn't been updated yet.

## Notes

- Paths in `script/` use `here::here()` from the project root; some
  `corpus/` scripts use plain relative paths instead (`setwd()` at the top
  covers this in practice, but `here()` would be more robust).
- Seed is `1337` throughout the modelling scripts.

## License

MIT; see `LICENSE`.
