# 02_make_figure.R
# Maarten Vink - 2026-11-04
# Figure 1: the 2024 international migrant stock by counting basis
# (foreign-born vs foreign citizens), world and continents.
#
# Steps:
#   1. Read the shares written by 01_definition_shares.R
#   2. Make the bar labels and put bars and segments in order
#   3. Draw the stacked bars and save the figure

library(tidyverse)
library(here)

# Check that here() has found this project's root; stops with a clear
# message if the .Rproj is not open and the working directory is elsewhere
here::i_am("R/02_make_figure.R")


# Settings ---------------------------------------------------------------

# Segments, in the order they appear from left to right, and their colours
basis_levels <- c(
  "Country of birth", "Citizenship: other countries",
  "Citizenship: five kafala states", "Mixed or imputed"
)

basis_colours <- c(
  "Country of birth" = "#d3d2cd",
  "Citizenship: other countries" = "#2a78d6",
  "Citizenship: five kafala states" = "#eb6834",
  "Mixed or imputed" = "#ecebe7"
)

# Bars, in the order they appear from top to bottom
region_levels <- c(
  "World", "Asia", "Africa", "Europe", "Northern America",
  "Latin America and the Caribbean", "Oceania"
)


# 1. Read the data -------------------------------------------------------

stock <- read_csv(here("data", "stock_by_basis.csv"), show_col_types = FALSE) |>
  filter(revision == 2024)


# 2. Labels and order ----------------------------------------------------

# Bar label: region name and its total stock, e.g. "Asia" / "92.2 million"
stock <- stock |>
  mutate(label = sprintf("%s\n%.1f million", region, region_stock / 1e6))

# Put the bar labels in the order of region_levels. ggplot draws the first
# level at the bottom, so the order is reversed; the same goes for the
# segments, which ggplot stacks from right to left.
label_order <- stock |>
  distinct(region, label) |>
  arrange(match(region, region_levels)) |>
  pull(label)

stock <- stock |>
  mutate(
    label = factor(label, levels = rev(label_order)),
    basis = factor(basis, levels = rev(basis_levels))
  )

# Percentage shown inside the citizenship segments, only where the
# segment is wide enough (4 percent or more); empty text elsewhere
stock <- stock |>
  mutate(
    segment_text = if_else(
      str_starts(basis, "Citizenship") & pct_stock >= 4,
      sprintf("%.0f%%", pct_stock),
      ""
    )
  )


# 3. Draw and save -------------------------------------------------------

p <- ggplot(stock, aes(x = pct_stock, y = label, fill = basis)) +
  geom_col(width = 0.68, colour = "white", linewidth = 0.4) +
  geom_text(
    aes(label = segment_text),
    position = position_stack(vjust = 0.5),
    colour = "white", size = 3, fontface = "bold"
  ) +
  scale_fill_manual(
    values = basis_colours,
    breaks = basis_levels,
    name = NULL
  ) +
  scale_x_continuous(
    breaks = seq(0, 100, 25),
    labels = \(x) paste0(x, "%"),
    expand = expansion(mult = c(0, 0.01))
  ) +
  labs(
    title = "About one in five international migrants is counted as a foreign citizen",
    subtitle = "International migrant stock, mid-2024, by the type of data each destination country reports",
    x = "Share of the region's international migrant stock",
    y = NULL,
    caption = paste0(
      "Source: UN DESA, International Migrant Stock 2024, Table 1 ('type of data'). ",
      "Country of birth: estimates derived from data on the foreign-born.\n",
      "Citizenship: estimates derived from data on foreign citizens. ",
      "Five kafala states: Saudi Arabia, United Arab Emirates, Kuwait, Qatar, Oman."
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
  ) +
  guides(fill = guide_legend(nrow = 2, byrow = TRUE))

ggsave(here("figures", "definition_share_continent_2024.pdf"), p,
       width = 18, height = 11, units = "cm")
ggsave(here("figures", "definition_share_continent_2024.png"), p,
       width = 18, height = 11, units = "cm", dpi = 300, bg = "white")
