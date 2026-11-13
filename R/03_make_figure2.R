# 03_make_figure2.R
# Maarten Vink - 2026-11-04
# Figure 2: the 15 largest destinations that count migrants as foreign
# citizens, mid-2024, with the five kafala states highlighted.
#
# Steps:
#   1. Read the country list written by 01_definition_shares.R
#   2. Keep the 15 largest and prepare names, groups and order
#   3. Draw the ranked bars and save the figure

library(tidyverse)
library(here)

# Check that here() has found this project's root; stops with a clear
# message if the .Rproj is not open and the working directory is elsewhere
here::i_am("R/03_make_figure2.R")


# Settings ---------------------------------------------------------------

# Saudi Arabia, United Arab Emirates, Kuwait, Qatar, Oman
kafala_codes <- c(682, 784, 414, 634, 512)

group_colours <- c(
  "Five kafala states" = "#eb6834",
  "Other countries" = "#2a78d6"
)


# 1. Read the data -------------------------------------------------------

# 2024 countries that report foreign citizens (mixed cases left out)
countries <- read_csv(here("data", "citizenship_countries.csv"), show_col_types = FALSE) |>
  filter(revision == 2024, definition == "Citizenship (C)")


# 2. Top 15, names, groups and order -------------------------------------

top <- countries |>
  slice_max(stock, n = 15)

top <- top |>
  mutate(
    # Drop UN DESA's footnote asterisk and shorten Iran's name
    name = str_remove(name, "\\*$"),
    name = str_replace(name, "Iran \\(Islamic Republic of\\)", "Iran"),
    # Kafala states or other countries
    group = if_else(code %in% kafala_codes, "Five kafala states", "Other countries"),
    group = factor(group, levels = names(group_colours)),
    # Largest at the top
    name = fct_reorder(name, stock),
    # Stock in millions
    stock_m = stock / 1e6
  )


# 3. Draw and save -------------------------------------------------------

p <- ggplot(top, aes(x = stock_m, y = name, fill = group)) +
  geom_col(width = 0.7) +
  geom_text(
    aes(label = sprintf("%.1f", stock_m)),
    hjust = -0.2, size = 2.8, colour = "grey25"
  ) +
  scale_fill_manual(values = group_colours, name = NULL) +
  scale_x_continuous(
    breaks = seq(0, 14, 2),
    expand = expansion(mult = c(0, 0.08))
  ) +
  labs(
    title = "The largest destinations that count migrants as foreign citizens",
    subtitle = "International migrant stock, mid-2024: the 15 largest of 46 countries or areas reporting foreign citizens",
    x = "International migrant stock (millions)",
    y = NULL,
    caption = paste0(
      "Source: UN DESA, International Migrant Stock 2024, Table 1. Countries or areas whose estimates are derived\n",
      "from data on foreign citizens (type of data C). Five kafala states: Saudi Arabia, United Arab Emirates, Kuwait,\n",
      "Qatar, Oman. Country names as in UN DESA, shortened for Iran."
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
    panel.grid.major.y = element_blank(),
    panel.grid.minor = element_blank(),
    plot.title.position = "plot",
    plot.caption.position = "plot",
    plot.caption = element_text(hjust = 0, colour = "grey35", size = 7.5),
    axis.title.x = element_text(size = 8.5, colour = "grey30", margin = margin(t = 6)),
    axis.text.y = element_text(colour = "grey15")
  )

ggsave(here("figures", "citizenship_destinations_top15_2024.pdf"), p,
       width = 18, height = 12, units = "cm")
ggsave(here("figures", "citizenship_destinations_top15_2024.png"), p,
       width = 18, height = 12, units = "cm", dpi = 300, bg = "white")
