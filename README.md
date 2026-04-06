subj_variation_stimuli.R azt mutatja, hogy jutottam el a stim_wordform_list-hez és a stim_lemma_metadatahoz. nem raktam fel hozzá a fájlokat, mert csak mutiba van az, ahogy
1. a webkorpusz freq listából kiveszek minden 100nál gyakoribb igét
2. abból kiveszem a felszólító alakpárokat (ez még az előtt volt, hogy elküldted volna a tiedet, és pont jó kiegészítője a tiednek, mert ebben benne vannak az actual wordformok)
3. betöltöm a te listádat
4. megbeszéltük, hogy az indeffel nem foglalkozunk, szal azokat kivettem
5. csinálok egy listát azokból a lemmákból, amik vannak nálam meg nálad
6. a tiedből csak azokat tartom meg, amik megvannak nekem is. hogy ne maradjon nálad olyan, amihez az imperative_def (enyém) táblázatban nincs wordform
7. három szempontból homogenizálom a listát: lemmagyakoriság, stem/def gyakoriság aránya, rövid/hosszú alalkok gyakoriságának aránya. mekgerestem a mediánt, és az ahhoz közelieket tartottam meg. így lett 50 valami igénk, amivel azért lőttem felé direkt, mert mi van, ha ki kell dobni 1-2 igét valamiért, és hogy mindenképpen legyen 50-50% back/front
8. igazgatom a címkéket, hogy ugyanaz legyen a két táblázatban, kirakok ezt-azt
9. write_tsv JUHUUUUU


ami lett ezekből: 1. lemmák listája minden adattal, amit a lemmáról tudni kell, szóalakok listája, amiben szintán vannak adatok róluk.
ha leokézod, akkor elkészítem azt a táblázatot, amit a psychopyba rakok be, csak lemmák és szóalakok. JA! meg ugye ekll majd még scrambelelni a foilokhoz, és lesznek kontroll sorok is abban a végleges táblázatban. de csak ha a tényleges stimulit jóváhagyod!

## File descriptions

### `stim_wordform_list.tsv`
**Level of analysis: individual word forms (surface forms)**

This file contains one row per wordform — each actual inflected form of a verb. It has ~104 rows (2 forms × 52 lemmas: a short and a long definite subjunctive 2sg form, e.g., `nézd` / `nézzed`).

| Column | Description |
|---|---|
| `form` | The actual wordform (e.g., `nézd`, `nézzed`) |
| `lemma` | The base lemma it belongs to |
| `xpostag` | Morphological tag (all are `[/V][Sbjv.Def.2Sg]`) |
| `freq` | Corpus frequency of that specific wordform |
| `corpus_size` | Total corpus size |
| `lemma_freq` | Frequency of the lemma |
| `lfpm10` / `llfpm10` | (Log) frequency per million for the form / lemma |
| `form_length`, `form_syl_count` | Length and syllable count of the wordform |
| `lemma_length`, `lemma_syl_count` | Length and syllable count of the lemma |
| `hunspell` | Whether the form is recognized by Hunspell |

---

### `stim_lemma_metadata.tsv`
**Level of analysis: lemmas (one row per lemma)**

This file contains one row per lemma — 52 rows total. It stores higher-level linguistic metadata about each lemma, including paradigm-level statistics.

| Column | Description |
|---|---|
| `lemma` | The base form |
| `long_freq` / `short_freq` | Frequencies of the long and short subjunctive variants |
| `long_short_sbjv_log_odds` | Log odds ratio of long vs. short form usage |
| `stem_harmony` | Vowel harmony class (`back`/`front`) |
| `subj_2nd` | Definiteness class (`Def`) |
| `lemma_length` | Monosyllabic or polysyllabic |
| `llfpm10` | Log lemma frequency per million |
| `log_odds_3pl_ind/sbjv`, `log_odds_3sg_ind/sbjv` | Log odds for other paradigm cells (3sg/3pl, indicative/subjunctive) |
| `obs_id` | An observation ID (linking to another dataset) |

---

### Summary

| | `stim_wordform_list` | `stim_lemma_metadata` |
|---|---|---|
| **Granularity** | One row per wordform | One row per lemma |
| **Focus** | Surface form properties (length, freq, syllables) | Lemma-level &amp; paradigm-level properties |
| **# rows** | ~104 (2 forms × 52 lemmas) | 52 (one per lemma) |
| **Use** | Describing the actual stimuli | Describing the lemmas behind the stimuli |
