library(tidyverse)
library(sf)
source("data-raw/t3010-src.R")

t3010 <- import_t3010_years(2019:2023) |> 
  filter(province == "ON") |> 
  geocode_charities() |> 
  rename(
    mapbox_address_input = `mapbox_address...4`,
    mapbox_address_output = `mapbox_address...24`
  ) |> 
  link_onbound() |> 
  propagate_municipality() |> 
  restore_t3010_details()

t3010 |> 
  filter(is.na(munid))

usethis::use_data(t3010, overwrite = TRUE)

t3010 |> 
  filter(
    category %in% c(
      "Community Resource", 
      "Organizations Relieving Poverty"
    )
  ) |> 
  summarize(
    revenue_government = sum(revenue_government, na.rm = TRUE), 
    .by = c(munid, municipality_onbound, data_year, category)
  ) |> 
  arrange(desc(revenue_government)) |> 
  pivot_wider(
    names_from = category, 
    values_from = revenue_government
  ) |> 
  View()


t3010 |> 
  filter(
    category %in% c(
      "Community Resource", 
      "Organizations Relieving Poverty"
    )
  ) |> 
  summarize(
    revenue_government = sum(revenue_government, na.rm = TRUE), 
    .by = c(charity_id, legal_name, munid, municipality_onbound, category)
  ) |> 
  arrange(desc(revenue_government)) |> 
  slice(1:3, .by = municipality_onbound) |> 
  View()

t3010_consolidated <- t3010 |> 
  group_by(
    charity_id, 
    legal_name, 
    account_name, 
    super_category, 
    category, 
    sub_category, 
    category_code, 
    sub_category_code,
    munid, 
    data_year,
  ) |> 
  summarize(
    across(
      matches("^revenue_"), 
      sum, 
      na.rm = TRUE
    ),
    .groups = "drop_last"
  )



t3010_consolidated |>
  mutate(
    across(
      matches("^revenue_"), 
      ~(.x - lag(.x)) / lag(.x)
    )
  ) |> 
  filter(!is.na(revenue_total), revenue_government <= 1) |> 
  ggplot(aes(data_year, revenue_government)) + 
  geom_path(aes(group = munid), alpha = .3) + 
  facet_grid(super_category ~ .)


multi_returns <- 
  t3010 |> 
    group_by(charity_id, data_year) |> 
    filter(n() > 1)

multi_returns |> 
  arrange(fiscal_end) |>
  mutate(
    nth_return = row_number(),
    marginal_revenue_reported = revenue_total - lag(revenue_total, default = 0)) |>
  filter(revenue_total < 1e9) |>  
  ggplot(aes(nth_return, revenue_total)) + 
  geom_point(shape = 23) + 
  geom_path(aes(group = charity_id), alpha = .3)
