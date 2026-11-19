# 05_make_figure1_two_ways.R
# Maarten Vink - 2026-11-19
# Alternative Figure 1: the 2024 international migrant stock by the two
# ways of counting only (country of birth vs citizenship), world and
# continents.
#
# Steps:
#   1. Read the shares written by 01_definition_shares.R
#   2. Group the four UN DESA categories into two ways of counting
#   3. Make the bar labels and put bars and segments in order
#   4. Draw the stacked bars and save the figure

library(tidyverse)
library(here)

# Check that here() has found this project's root; stops with a clear
# message if the .Rproj is not open and the working directory is elsewhere
here::i_am("R/05_make_figure1_two_ways.R")


# Settings ---------------------------------------------------------------

# The two ways of counting, left to right, and their colours
way_levels <- c("Counted by country of birth", "Counted by citizenship")

way_colours <- c(
  "Counted by country of birth" = "#d3d2cd",
  "Counted by citizenship" = "#2a78d6"
)

# Bars, in the order they appear from top to bottom
region_levels <- c(
  "World", "Asia", "Africa", "Europe", "Northern America",
  "Latin America and the Caribbean", "Oceania"
)


# 1. Read the data -------------------------------------------------------

world <- read_csv(here("data", "definition_shares_world.csv"), show_col_types = FALSE) |>
  filter(revision == 2024) |>
  mutate(region = "World")

continents <- read_csv(here("data", "definition_shares_continent.csv"), show_col_types = FALSE) |>
  filter(revision == 2024) |>
  rename(region = continent)

shares <- bind_rows(world, continents)


# 2. Two ways of counting ------------------------------------------------

# Countries reporting both kinds of data (Benin, Guinea) are grouped with
# citizenship; imputed estimates (no data) are grouped with country of
# birth. Together they are 0.2 percent of the world total.
shares <- shares |>
  mutate(
    way = case_when(
      definition %in% c("Citizenship (C)", "Mixed (C and B)") ~ "Counted by citizenship",
      .default = "Counted by country of birth"
    )
  ) |>
  group_by(region, way) |>
  summarise(stock = sum(stock), .groups = "drop") |>
  complete(region, way = way_levels, fill = list(stock = 0)) |>
  group_by(region) |>
  mutate(
    region_stock = sum(stock),
    pct_stock = 100 * stock / region_stock
  ) |>
  ungroup()


# 3. Labels and order ----------------------------------------------------

# Bar label: region name and its total stock, e.g. "Asia" / "92.2 million"
shares <- shares |>
  mutate(label = sprintf("%s\n%.1f million", region, region_stock / 1e6))

# ggplot draws the first level at the bottom and stacks segments from right
# to left, so both orders are reversed
label_order <- shares |>
  distinct(region, label) |>
  arrange(match(region, region_levels)) |>
  pull(label)

shares <- shares |>
  mutate(
    label = factor(label, levels = rev(label_order)),
    way = factor(way, levels = rev(way_levels))
  )

# Percentage inside each segment wide enough to hold it (5 percent or more);
# shares just under 100 are shown as ">99%" so they do not read as 100%;
# dark text on the grey segment, white text on the blue one
shares <- shares |>
  mutate(
    segment_text = case_when(
      pct_stock < 5 ~ "",
      pct_stock > 99 & pct_stock < 99.95 ~ ">99%",
      .default = sprintf("%.0f%%", pct_stock)
    ),
    text_colour = if_else(way == "Counted by citizenship", "white", "grey20")
  )


# 4. Draw and save -------------------------------------------------------

p <- ggplot(shares, aes(x = pct_stock, y = label, fill = way)) +
  geom_col(width = 0.68, colour = "white", linewidth = 0.4) +
  # group = way keeps the labels stacked in the same order as the bars
  geom_text(
    aes(label = segment_text, colour = text_colour, group = way),
    position = position_stack(vjust = 0.5),
    size = 3, fontface = "bold"
  ) +
  scale_colour_identity() +
  scale_fill_manual(values = way_colours, breaks = way_levels, name = NULL) +
  scale_x_continuous(
    breaks = seq(0, 100, 25),
    labels = \(x) paste0(x, "%"),
    expand = expansion(mult = c(0, 0.01))
  ) +
  labs(
    title = "Two ways to count a migrant",
    subtitle = "International migrant stock, mid-2024, by how the destination country counts migrants",
    x = "Share of the region's international migrant stock",
    y = NULL,
    caption = paste0(
      "Source: UN DESA, International Migrant Stock 2024, Table 1 ('type of data'). Country of birth: estimates derived from\n",
      "data on the foreign-born. Citizenship: estimates derived from data on foreign citizens, including Benin and Guinea, which\n",
      "report both; imputed estimates (no data) are grouped with country of birth. Together these are 0.2% of the world total."
    )
  ) +
  theme_minimal(base_size = 10) +
  theme(
    legend.position = "top",
    legend.justification = "left",
    legend.location = "plot",
    legend.margin = margin(0, 0, 0, 0),
    legend.key.size = unit(0.35, "cm"),
    plot.margin = margin(6, 12, 6, 6),
    axis.title.x = element_text(size = 8.5, colour = "grey30", margin = margin(t = 6)),
    panel.grid.major.y = element_blank(),
    panel.grid.minor = element_blank(),
    plot.title.position = "plot",
    plot.caption.position = "plot",
    plot.caption = element_text(hjust = 0, colour = "grey35", size = 7.5),
    axis.text.y = element_text(hjust = 0, colour = "grey15")
  )

ggsave(here("figures", "definition_share_continent_2024_two_ways.pdf"), p,
       width = 18, height = 11, units = "cm")
ggsave(here("figures", "definition_share_continent_2024_two_ways.png"), p,
       width = 18, height = 11, units = "cm", dpi = 300, bg = "white")
