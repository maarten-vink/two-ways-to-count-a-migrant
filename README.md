---
editor_options: 
  markdown: 
    wrap: 72
---

# Two ways to count a migrant - data and code for the Substack post

Companion repository for **"Two ways to count a migrant: And why this
matters for migration models"** by Maarten Vink
([maartenpvink.substack.com](https://maartenpvink.substack.com)).

The repository contains the material required to reproduce Figures 1 and
2 in the post, and the numbers quoted in the text about how the UN DESA
international migrant stock is counted. Figure 3 in the post is taken
from the preprint it discusses (see "Related work" below) and is not
reproduced here.

## What is here

```         
replication/
|-- README.md
|-- two-ways-to-count-a-migrant.Rproj
|-- R/
|   |-- 01_definition_shares.R   # reads UN DESA files, writes data/*.csv
|   |-- 02_make_figure.R         # Figure 1: stock by counting basis, by continent
|   `-- 03_make_figure2.R        # Figure 2: 15 largest citizenship-counting destinations
|-- sources/external/undesa_ims/
|   |-- undesa_pd_2020_ims_stock_by_sex_and_destination.xlsx
|   `-- undesa_pd_2024_ims_stock_by_sex_and_destination.xlsx
|-- data/
|   |-- definition_shares_world.csv       # countries and stock by counting basis, world
|   |-- definition_shares_continent.csv   # the same, by continent
|   |-- stock_by_basis.csv                # input for Figure 1
|   |-- citizenship_countries.csv         # all citizenship-counting destinations (input for Figure 2)
|   |-- kafala_share.csv                  # share of the five kafala states
|   `-- check_totals.csv                  # country sums reconciled against UN DESA totals
`-- figures/
    |-- definition_share_continent_2024.png / .pdf   # Figure 1
    `-- citizenship_destinations_top15_2024.png / .pdf  # Figure 2
```

## Reproducing the figures

Open `two-ways-to-count-a-migrant.Rproj` in RStudio and run the scripts
in `R/` in order, or from the command line:

``` sh
for s in R/*.R; do Rscript "$s"; done
```

`01_definition_shares.R` regenerates every CSV in `data/` from the two
UN DESA files; `02` and `03` regenerate the figures in `figures/`. No
internet connection is needed. The first script stops with an error if
the country-level stocks do not add up to UN DESA's own world and
continent totals (the result of that check is written to
`data/check_totals.csv`).

Tested with R 4.5.2. Packages: `tidyverse` (2.0.0; uses dplyr, tidyr,
readr, stringr, purrr, forcats, ggplot2), `readxl` (1.4.5), `here`
(1.0.2).

## Where the data come from

### UN DESA International Migrant Stock, 2024 and 2020 revisions

United Nations Department of Economic and Social Affairs, Population
Division (2024). *International Migrant Stock 2024*
(POP/DB/MIG/Stock/Rev.2024), and (2020) *International Migrant Stock
2020* (POP/DB/MIG/Stock/Rev.2020). Downloaded on 4 November 2026 from
the [UN DESA International Migrant Stock
page](https://www.un.org/development/desa/pd/content/international-migrant-stock),
files "by sex and destination".

The scripts use Table 1 (international migrant stock at mid-year, both
sexes, by country or area of destination) and its "type of data" column.
UN DESA's legend for that column (sheet "Migrant notes"):

-   **B**: estimates derived from data on the foreign-born population;
-   **C**: estimates derived from data on foreign citizens;
-   **R**: refugees (as reported by UNHCR or UNRWA) added to the
    estimates;
-   **I**: no data; estimates imputed.

### How the scripts classify countries

-   "Citizenship (C)": type code contains C but not B.
-   "Country of birth (B)": type code contains B but not C.
-   "Mixed (C and B)": type code contains both (Benin and Guinea in
    2024).
-   "Imputed (I)": no data.

Only countries and areas are counted (location codes below 900);
regional aggregates are excluded. Continents are assigned from the order
of rows in Table 1, where each country follows its continent's header
row. The "five kafala states" are Saudi Arabia, the United Arab
Emirates, Kuwait, Qatar and Oman, the five destinations for which the
preprint below switches off citizenship acquisition.

Units are countries or areas as defined by UN DESA (233 in the 2024
revision), including territories, so counts differ from the 192
countries modelled in the preprint. Some type codes change between the
2020 and 2024 revisions; the two years should not be read as a trend.

## Related work

The post discusses the following preprint, which used the UN DESA 2020
revision and the GLOBALCIT Citizenship Law Dataset. Its model code is
not part of this repository.

-   Schirojan, D. E., Petrova, K., Vink, M. and Zantout, K. (2026).
    *Accounting for migrant definitions improves global migration
    modeling.* SocArXiv.
    [doi:10.31235/osf.io/dy4nt_v1](https://doi.org/10.31235/osf.io/dy4nt_v1)

## Citation

Please cite the post and the upstream source:

-   Vink, M. (2026). *Two ways to count a migrant: And why this matters
    for migration models.* Substack post, November 2026.
    [maartenpvink.substack.com](https://maartenpvink.substack.com).
-   United Nations Department of Economic and Social Affairs, Population
    Division (2024). *International Migrant Stock 2024.*

## Licence

The R code in `R/` is released under the MIT licence. The derived data
in `data/` and the figures in `figures/` are released under [CC BY
4.0](https://creativecommons.org/licenses/by/4.0/).

The two UN DESA files in `sources/external/undesa_ims/` are
redistributed unchanged under their original licence, [CC BY 3.0
IGO](https://creativecommons.org/licenses/by/3.0/igo/) (Copyright 2020
and 2024, United Nations). This repository is not affiliated with or
endorsed by the United Nations.

## Note on tools

The R code for extracting, cleaning and visualising the data in this
repository was developed with the assistance of a large language model
(Anthropic's Claude), used as a coding and data-wrangling assistant. All
source data, code, and figures were reviewed and verified by the author,
who is solely responsible for the analysis, interpretation, and any
errors.
