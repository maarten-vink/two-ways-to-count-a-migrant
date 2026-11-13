# 01_definition_shares.R
# Maarten Vink - 2026-11-04
# How much of the UN DESA international migrant stock is counted as foreign
# citizens rather than as foreign-born? World and continents, 2020 and 2024.
#
# Steps:
#   1. Read Table 1 of the 2020 and 2024 UN DESA files
#   2. Give each row its continent
#   3. Keep countries and classify them by the type of data they report
#   4. Check that the countries add up to the UN DESA totals
#   5. Summarise and write the tables used in the post and in the figures

library(tidyverse)
library(readxl)
library(here)

# Check that here() has found this project's root; stops with a clear
# message if the .Rproj is not open and the working directory is elsewhere
here::i_am("R/01_definition_shares.R")


# Settings ---------------------------------------------------------------

# UN DESA location codes of the six continents
continent_names <- tibble(
  code = c(903L, 935L, 908L, 904L, 905L, 909L),
  continent = c(
    "Africa", "Asia", "Europe", "Latin America and the Caribbean",
    "Northern America", "Oceania"
  )
)

# The five Gulf states where the preprint switches off citizenship
# acquisition: Saudi Arabia, United Arab Emirates, Kuwait, Qatar, Oman
kafala_codes <- c(682, 784, 414, 634, 512)


# 1. Read Table 1 --------------------------------------------------------

# Table 1 has one row per region or country. Its column names are in row 11
# of the sheet. Each year appears three times: first for both sexes, then
# for males, then for females. We need the both-sexes value for the year of
# the revision (2020 in the 2020 file, 2024 in the 2024 file).
read_ims <- function(file, year) {
  path <- here("sources", "external", "undesa_ims", file)

  raw <- read_excel(
    path,
    sheet = "Table 1", skip = 10, .name_repair = "unique_quiet"
  )

  # The first column named after the year belongs to the both-sexes block
  year_columns <- names(raw)[str_starts(names(raw), as.character(year))]
  stock_column <- year_columns[1]

  # Check this: row 7 of the sheet labels the three blocks, so the column
  # must lie between the "both sexes combined" label and the "males" label
  header_rows <- read_excel(
    path,
    sheet = "Table 1", col_names = FALSE, n_max = 11,
    .name_repair = "unique_quiet"
  )
  block_labels <- unlist(header_rows[7, ])
  stock_position <- match(stock_column, names(raw))
  both_position <- which(str_detect(block_labels, "both sexes combined"))
  males_position <- which(str_detect(block_labels, ", males$"))
  stopifnot(
    "stock column is not in the both-sexes block" =
      length(both_position) == 1 && length(males_position) == 1 &&
      stock_position >= both_position && stock_position < males_position
  )

  # The type-of-data column has a different name in the two files
  if ("Type of data" %in% names(raw)) {
    type_column <- "Type of data"
  } else {
    type_column <- "Data type"
  }

  # Keep the columns we need; ".." in the stock column means no data
  raw |>
    transmute(
      name = `Region, development group, country or area`,
      code = as.integer(`Location code`),
      type = .data[[type_column]],
      stock = parse_number(as.character(.data[[stock_column]]), na = c("..", "")),
      revision = year
    )
}

ims_2020 <- read_ims("undesa_pd_2020_ims_stock_by_sex_and_destination.xlsx", 2020)
ims_2024 <- read_ims("undesa_pd_2024_ims_stock_by_sex_and_destination.xlsx", 2024)

ims <- bind_rows(ims_2020, ims_2024)


# 2. Give each row its continent -----------------------------------------

# In Table 1 each continent has a header row, followed by its sub-regions
# and countries. So a country belongs to the last continent row above it:
# mark the continent rows, then fill the name down within each file.
ims <- ims |>
  left_join(continent_names, by = "code") |>
  group_by(revision) |>
  fill(continent, .direction = "down") |>
  ungroup()


# 3. Keep countries and classify them ------------------------------------

# Countries and areas have location codes below 900 (regions have 900 and
# above). Two French territories have no type of data and no stock; they
# are dropped.
countries <- ims |>
  filter(code < 900, !is.na(type))

# UN DESA type-of-data codes: B = data on the foreign-born, C = data on
# foreign citizens, I = imputed (no data), R = refugees added. A country
# reporting both C and B is classed as mixed.
countries <- countries |>
  mutate(
    definition = case_when(
      str_detect(type, "C") & str_detect(type, "B") ~ "Mixed (C and B)",
      str_detect(type, "C") ~ "Citizenship (C)",
      str_detect(type, "B") ~ "Country of birth (B)",
      str_detect(type, "I") ~ "Imputed (I)"
    )
  )

# Stop if a country has a type code we did not expect
stopifnot(
  "unclassified UN DESA type-of-data code" = !anyNA(countries$definition)
)


# 4. Check against the UN DESA totals ------------------------------------

# World total (code 900) and continent totals, as published by UN DESA
world_totals <- ims |>
  filter(code == 900) |>
  select(revision, world_stock = stock)

continent_totals <- ims |>
  filter(code %in% continent_names$code) |>
  select(revision, continent, continent_stock = stock)

# Sum the countries and compare
check_world <- countries |>
  group_by(revision) |>
  summarise(sum_stock = sum(stock, na.rm = TRUE)) |>
  left_join(world_totals, by = "revision") |>
  mutate(gap_pct = 100 * (sum_stock - world_stock) / world_stock)

check_continent <- countries |>
  group_by(revision, continent) |>
  summarise(sum_stock = sum(stock, na.rm = TRUE), .groups = "drop") |>
  left_join(continent_totals, by = c("revision", "continent")) |>
  mutate(gap_pct = 100 * (sum_stock - continent_stock) / continent_stock)

# Stop if any gap is larger than half a percent
stopifnot(
  all(abs(check_world$gap_pct) < 0.5),
  all(abs(check_continent$gap_pct) < 0.5)
)


# 5. Summarise -----------------------------------------------------------

# Number of countries and migrant stock by definition, world
shares_world <- countries |>
  group_by(revision, definition) |>
  summarise(
    n_countries = n(),
    stock = sum(stock, na.rm = TRUE),
    .groups = "drop_last"
  ) |>
  mutate(
    pct_countries = 100 * n_countries / sum(n_countries),
    pct_stock = 100 * stock / sum(stock)
  ) |>
  ungroup()

# The same by continent
shares_continent <- countries |>
  group_by(revision, continent, definition) |>
  summarise(
    n_countries = n(),
    stock = sum(stock, na.rm = TRUE),
    .groups = "drop_last"
  ) |>
  mutate(
    pct_countries = 100 * n_countries / sum(n_countries),
    pct_stock = 100 * stock / sum(stock)
  ) |>
  ungroup()

# Countries that report foreign citizens, or a mix (input for Figure 2)
citizenship_countries <- countries |>
  filter(definition %in% c("Citizenship (C)", "Mixed (C and B)")) |>
  select(revision, continent, name, code, type, definition, stock) |>
  arrange(revision, desc(stock))

# How much of their stock is in the five kafala states
kafala_share <- citizenship_countries |>
  group_by(revision) |>
  summarise(
    stock_c_mixed = sum(stock, na.rm = TRUE),
    stock_kafala = sum(stock[code %in% kafala_codes], na.rm = TRUE)
  ) |>
  left_join(world_totals, by = "revision") |>
  mutate(
    pct_of_c_mixed = 100 * stock_kafala / stock_c_mixed,
    pct_of_world = 100 * stock_kafala / world_stock
  )

# Stock by counting basis, with the kafala states shown separately
# (input for Figure 1)
countries <- countries |>
  mutate(
    basis = case_when(
      definition == "Citizenship (C)" & code %in% kafala_codes ~
        "Citizenship: five kafala states",
      definition == "Citizenship (C)" ~ "Citizenship: other countries",
      definition == "Country of birth (B)" ~ "Country of birth",
      .default = "Mixed or imputed"
    )
  )

# Take the countries twice, once labelled "World" and once with their
# continent, so that one summary gives both the world and the continents
stock_by_basis <- bind_rows(
  countries |> mutate(region = "World"),
  countries |> mutate(region = continent)
) |>
  group_by(revision, region, basis) |>
  summarise(stock = sum(stock, na.rm = TRUE), .groups = "drop")

# Add zero rows for combinations that do not occur (for example kafala
# states in Europe), then compute shares within each region
basis_levels <- c(
  "Country of birth", "Citizenship: other countries",
  "Citizenship: five kafala states", "Mixed or imputed"
)

stock_by_basis <- stock_by_basis |>
  complete(revision, region, basis = basis_levels, fill = list(stock = 0)) |>
  group_by(revision, region) |>
  mutate(
    region_stock = sum(stock),
    pct_stock = 100 * stock / region_stock
  ) |>
  ungroup()


# Write outputs ----------------------------------------------------------

write_csv(stock_by_basis, here("data", "stock_by_basis.csv"))
write_csv(kafala_share, here("data", "kafala_share.csv"))
write_csv(shares_world, here("data", "definition_shares_world.csv"))
write_csv(shares_continent, here("data", "definition_shares_continent.csv"))
write_csv(citizenship_countries, here("data", "citizenship_countries.csv"))

check_totals <- bind_rows(
  check_world |>
    mutate(level = "world", continent = "World"),
  check_continent |>
    rename(world_stock = continent_stock) |>
    mutate(level = "continent")
)
write_csv(check_totals, here("data", "check_totals.csv"))
