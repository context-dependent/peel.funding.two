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

t3010 <- 2019:2023 |> 
  purrr::map_dfr(import_t3010_year)

t3010 |> 
  dplyr::count(data_year)
