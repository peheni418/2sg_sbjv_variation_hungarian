# Morphological Priming in Hungarian

This project investigates morphological priming effects in Hungarian, examining how different verb forms affect processing speed and accuracy in a lexical decision task.

## Project Structure

```
morphological_priming_hungarian/
├── raw_data/                    # All participant results from the experiment
├── data_cleaning/               # Data cleaning process and output
│   ├── data_cleaning.R          # Script to process raw data
│   └── clean_data               # Cleaned dataset (output)
├── analysis_script.R            # Statistical analysis and visualizations
└── README.md                    # This file
```

## Raw Data

The `raw_data/` folder contains individual CSV files from each participant. These files are generated from the PsychoPy experiment and follow the naming convention: `XXXXXX_priming.csv` where `XXXXXX` is the participant ID.

Raw data includes:
- Participant responses (key presses)
- Reaction times
- Prime verb forms
- Target verb forms
- Stimulus types (target or distractor)

The complete experiment structure and additional documentation can be found in the GitLab repository: https://gitlab.pavlovia.org/peheni/variation2sg_priming_2026

## Data Cleaning Process

The `data_cleaning/data_cleaning.R` script processes raw participant data and produces a single cleaned dataset. 

### Cleaning Steps

1. **Load and Combine Files**: Reads all participant CSV files from the `raw_data/` folder and combines them into one dataset, extracting participant IDs from filenames

2. **Select Relevant Columns**: Keeps only:
   - `participant` — participant ID
   - `key_resp_5.keys` — key pressed (f or j)
   - `key_resp_5.rt` — reaction time in seconds
   - `primeHeni` — prime verb form
   - `targetHeni` — target verb form
   - `stim_type` — stimulus type

3. **Remove Missing Data**: Filters out rows with missing values in key columns

4. **Remove Outliers**: Excludes reaction times above 4 seconds

5. **Exclude Participants with High Error Rates**: Removes participants with error rates above 50% (identifying participants who:
   - Pressed "f" for targets and "j" for distractors correctly)

6. **Determine Harmony Class**: Creates a `harmony_class` column based on verb ending:
   - Front vowel harmony: target verb ends with "i"
   - Back vowel harmony: all other cases
   - Extends harmony class to primes based on the targets they appear with

7. **Create Pair Types**: Categorizes each target into one of four pair types:
   - `back_cell` — back harmony target ending with "d"
   - `back_form` — back harmony target not ending with "d"
   - `front_cell` — front harmony target ending with "d"
   - `front_form` — front harmony target not ending with "d"

8. **Summary Statistics**: Calculates mean reaction times per pair type and target

### Output

The cleaned dataset is saved as `data_cleaning/clean_data` and contains:
- All participant data combined
- Only valid responses with reaction times ≤ 4 seconds
- Harmony and pair type classifications
- Ready for statistical analysis

## Analysis Script

The `analysis_script.R` script loads the cleaned data and produces visualizations and summary statistics.

### Analysis Steps

1. **Load Clean Data**: Reads the cleaned dataset from `data_cleaning/clean_data`

2. **Order Categories**: Ensures pair types are ordered consistently for visualization:
   - back_cell → "várjad/várd"
   - front_cell → "kérjed/kérd"
   - back_form → "várjad/várja"
   - front_form → "kérjed/kéri"

3. **Plot 1: Pair Averages**: Each point represents one unique prime-target pair's average reaction time across all participants
   - Shows overall pattern of reaction times across pair types
   - Violin plot with boxplot overlay and individual data points

4. **Plot 2: Participant Averages**: Each point represents one participant's average reaction time for a pair type
   - Shows variation between participants
   - Same visualization structure for consistency

### Output

Two visualizations showing:
- Distribution of reaction times by pair type
- Balance and consistency across conditions
- Individual participant variation

## Pair Type Coding

The experiment uses four main conditions defined by two dimensions:

| Pair Type | Harmony | Ending | Example |
|-----------|---------|--------|---------|
| back_cell | Back | d-stem | várjad → várd |
| back_form | Back | regular | várjad → várja |
| front_cell | Front | d-stem | kérjed → kérd |
| front_form | Front | regular | kérjed → kéri |

## Running the Analysis

1. Ensure all participant CSV files are in the `raw_data/` folder
2. Run `data_cleaning/data_cleaning.R` to generate `clean_data`
3. Run `analysis_script.R` to generate visualizations and summaries

## Notes

- The project uses the `here` package for file paths, which automatically detects the project root directory
- All reaction time data is trimmed at 4 seconds to remove extreme outliers
- Participants with error rates exceeding 50% are excluded from analysis
- Pair type classification is based on target verb characteristics, applied to all trials in each pair regardless of stimulus type
