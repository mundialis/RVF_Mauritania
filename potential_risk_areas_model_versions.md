|Model version | Used data version | Training presence samples | Training all samples (background and presence) | Description | Notes |
| - | - | - | - | - | - |
| 01 | 01 | 152 | 752 | single model with all disease data combined | variable contribution: ca. 70 % impact of current precipitation |
| 02 | 01 | dependent on month | dependent on month | monthly models (for each month with at least one single positive sample) | for monthly models very different results when applying model + within variable contribution; mostly precipitation driving factor of model |
| 03 | 02 | 53 | 187| monthly model, only for October 2020 | variable contribution: roughly 40 % for 2 month prior and 40 % for 1 month prior precipitation |
| 04 | 02 | 152 | 752 | single model with all disease data combined | variable contribution: ca. 80 % impact of current precipitation|
| 05 | 02 | 132| 437 | single model with 09/10 2020 and 09/10 2022 data combined (the four month with the most positive disease data) | variable contribution: 30 % lst night, 30 % current month precipitation <br/> application results has a lot of round/circle structures with strong borders of change in risk (coming from precipitation) |
| 06 | 02 | 282 | 820| as mv04, but keep duplicates during training| less strong impact of current precipitation on model (ca. 45 %), followed by precipitation 1 month prior (20 %) and 2 month prior (14 %) <br/> keeping duplicates during training results in less strong changes in risk (in some month e.g. 05-2020, 06-2020, ... ) compared to mv04 |
| 07 | 02 | 232 | 487| as mv05, but keep duplicates during training | precipitation 2 month prior strongest impact on model (ca. 50 %) <br/> similar geometric patterns (coming from precipitation) as in mv05|
