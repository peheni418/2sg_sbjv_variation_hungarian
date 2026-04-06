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
