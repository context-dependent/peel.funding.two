library(tidyverse)
library(httr2)

import_t3010_year <- function(year) {
  dir_path <- file.path("data-raw/t3010", year)
  cat <- import_categories(dir_path)
  ident <- import_ident(dir_path)
  sec_d <- import_sec_d(dir_path)

  ident |> 
    dplyr::mutate(data_year = year) |> 
    dplyr::left_join(
      cat, 
      by = c("category_code", "sub_category_code")
    ) |> 
    dplyr::left_join(
      sec_d, 
      by = "charity_id"
    )
}

import_categories <- function(dir_path) {
  readr::read_csv(
    file.path(dir_path, "# Category_Sub-Category.csv"), 
    locale = readr::locale(encoding = "latin1"),
    show_col_types = FALSE
  ) |> 
    janitor::clean_names() |> 
    dplyr::transmute(
      category_code,
      category = category_english_desc, 
      sub_category_code, 
      sub_category = sub_category_english_desc,
      super_category = charity_type_english_desc
    )
}


import_ident <- function(dir_path) {
  readr::read_csv(
    file.path(dir_path, "Ident.csv"), 
    locale = readr::locale(encoding = "latin1"),
    show_col_types = FALSE
  ) |> 
    janitor::clean_names() |> 
    dplyr::transmute(
      charity_id = bn_registration_number,
      category_code, 
      sub_category_code, 
      legal_name, 
      account_name, 
      mailing_address, 
      city, 
      province,
      postal_code, 
      country
    )
}

import_sec_d <- function(dir_path) {
  readr::read_csv(
    file.path(dir_path, "Financial Section D & Schedule 6.csv"),
    locale = readr::locale(encoding = "latin1"), 
    show_col_types = FALSE
  ) |> 
    janitor::clean_names() |> 
    dplyr::transmute(
      charity_id = bn_registration_number, 
      fiscal_end = lubridate::as_date(
        lubridate::ymd_hms(fiscal_period_end)
      ),
      section_used = financial_indicator_d_or_6, 
      revenue_total =  x4700,
      revenue_federal = x4540, 
      revenue_provincial = x4550, 
      revenue_municipal = x4560,
      revenue_government = x4570,
    ) |> 
    dplyr::filter(!is.na(revenue_total)) |> 
    dplyr::mutate(
      dplyr::across(
        matches("^revenue_"), 
        function(x) {
          x |> 
            stringr::str_remove(r"(\$)") |> 
            readr::parse_number()
        }
      ), 
      dplyr::across(
        matches("^revenue_"), 
        function(x) {
          dplyr::case_when(
            is.na(x) ~ 0, 
            TRUE ~ x
          )
        }
      ), 
      revenue_government = dplyr::case_when(
        section_used == "6" ~ revenue_provincial + revenue_municipal + revenue_federal,
        TRUE ~ revenue_government
      )
    )
}

generate_mb_payload <- function(d) {
  d |> 
    dplyr::transmute(
      address_line1 = mailing_address, 
      place, 
      region = "ON", 
      postcode = postal_code, 
      country = "CA"
    ) |> 
    as.data.frame() |> 
    as.list() |> 
    purrr::transpose() |> 
    purrr::map(
      function(x) {
        x$limit <- 1L
        x[["types"]] <- c("address", "postcode", "place")
        x
      }
    ) 
}


mb_batch_request <- function(mb_batch, mb_token) {
  request("https://api.mapbox.com/search/geocode/v6/batch") |> 
    req_url_query(access_token = mb_token) |> 
    req_body_json(mb_batch) |> 
    req_error(is_error = function(x) FALSE) |> 
    req_perform() 
}

mb_batch_result_to_coords <- function(result_batch) {
  x <- result_batch |> resp_body_json() 

  purrr::map_dfr(x$batch, 
    function(item) {
      if (length(item$features) > 0) {
        return(
          item$features |> 
            map_dfr(
              function(feature) {
                tibble::tibble(
                  type = feature$properties$feature_type, 
                  name = feature$properties$name,
                  match_code_confidence = feature$properties$match_code$confidence,
                  country_code = feature$properties$context$country$country_code,
                  region_code = feature$properties$context$region$region_code,
                  place =  feature$properties$context$place$name, 
                  postcode = feature$properties$context$postcode$name, 
                  longitude = feature$properties$coordinates$longitude, 
                  latitude = feature$properties$coordinates$latitude, 
                  raw = list(item)
                )
              }
            ) |> 
            dplyr::filter(country_code == "CA", region_code == "ON")
        )
      } 
    }
  )
}

mb_token <- keyring::key_get("mapbox-token")

t3010 <- 2019:2023 |> 
  purrr::map_dfr(import_t3010_year) |> 
  filter(province == "ON")


gc_sample <- t3010 |> 
  filter(province == "ON") |> 
  mutate(place = city) |> 
  group_by(city, legal_name) |>
  slice(1) |> 
  group_by(city) |>  
  group_nest() |>
  mutate(
    batch_size = purrr::map_int(data, ~min(nrow(.x), 10)), 
    data = purrr::map2(data, batch_size, ~sample_n(.x, .y))
  ) |> 
  mutate(
    payload = purrr::map(data, generate_mb_payload), 
  )

gc_sample_query <- gc_sample |> 
  mutate(
    result = purrr::map(payload, ~mb_batch_request(.x, mb_token))
  )

points <- gc_sample_query |> 
  mutate(
    shp = result |> 
      map(mb_batch_result_to_coords)
  ) |> 
  select(city, shp) |> 
  unnest(shp) 

library(sf)
library(onbound)

sf_use_s2(FALSE)

on_municipal_boundaries_wet

city_centroids <- points |> 
  st_as_sf(
    coords = c("longitude", "latitude"), 
    crs = 4326
  ) |> 
  group_by(city) |> 
  summarize() |> 
  st_centroid() |> 
  st_transform(st_crs(on_municipal_boundaries_wet))

city_centroids |> 
  readr::write_rds("data-raw/cra-city-centroids.rds")
city_centroids <- readr::read_rds("data-raw/cra-city-centroids.rds")


munid_index <- on_municipal_boundaries_wet |> 
  filter(tier_code %in% c("UT", "ST")) |> 
  st_make_valid() |> 
  st_join(city_centroids) |> 
  filter(!is.na(city)) |> 
  group_by(city) |> 
  slice(1) |> 
  st_set_geometry(NULL) |> 
  select(city, tier_code, munid)


t3010 <- t3010 |> 
  left_join(
    munid_index, 
    by = "city"
  )

usethis::use_data(t3010, overwrite = TRUE)

t3010

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
