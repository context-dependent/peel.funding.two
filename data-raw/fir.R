on_cpi <- 
  readr::read_csv(
    "data-raw/misc/on-cpi.csv", 
    col_types = readr::cols(
      VALUE = readr::col_double(), 
      REF_DATE = readr::col_integer()
    ), 
    col_select = c(REF_DATE, VALUE), 
    show_col_types = FALSE
  ) |> 
  dplyr::transmute(
    marsyear = REF_DATE, 
    cpi_23f = 1 / (VALUE / dplyr::last(VALUE))
  )

usethis::use_data(on_cpi, internal = TRUE, overwrite = TRUE)

fir_meta <- list(
  cost_classification = 
    tibble::tribble(
      ~slc_schedule, ~slc_column, ~cost_type,  ~cost_payer, 
      "40X",         c("01", "02", "03", "04", "05", "06", "12", "13"),     "operating", "total", 
      "12X",         "03",     "operating", "other_municipalities",
      "12X",         "04",     "operating", "users",
      "12X",         "01",     "operating", "ontario", 
      "12X",         "02",     "operating", "canada",
      "51A",         "03",     "capital",   "total", 
      "51C",         "02",     "capital",   "total", 
      "51C",         "03",     "capital",   "total", 
      "12X",         "05",     "capital",   "ontario", 
      "12X",         "06",     "capital",   "canada",
      "12X",         "07",     "capital",   "other_municipalities",
    ) |> 
    tidyr::unnest(slc_column), 
  service_classification = 
    tibble::tribble(
      ~service,                ~service_type, ~slc_line, 
      "Protection",            "Core",         c("L0499"), 
      "Transportation",        "Core",         c("L0611", "L0612", "L0613", "L0614", "L0621", "L0622", "L0640", "L0650", "L0660", "L0698"), 
      "Environmental",         "Core",         c("L0899"),
      "Planning",              "Core",         c("L1899"),
      "Administration",        "Core",         c("L0299", "L1910"),
      "Transit",               "Social",       c("L0631", "L0632"), 
      "Public Health",         "Social",       c("L1010", "L1098"),
      "Hospitals",             "Social",       c("L1020"), 
      "Ambulance",             "Social",       c("L1030", "L1035"), 
      "Cemetaries",            "Social",       c("L1040"), 
      "General Assistance",    "Social",       c("L1210", "L1298"), 
      "Senior Support",        "Social",       c("L1220"), 
      "Childcare",             "Social",       c("L1230"),
      "Social Housing",        "Social",       c("L1499"),
      "Parks and Recreation",  "Social",       c("L1610", "L1620", "L1631", "L1634"),
      "Culture",               "Social",       c("L1640", "L1645", "L1650", "L1698"),
    ) |> 
    dplyr::mutate(
      slc_schedule = purrr::map(service, ~ c("40X", "12X", "51A", "51C"))
    ) |> 
    tidyr::unnest(slc_schedule) |> 
    tidyr::unnest(slc_line), 
  quantities = 
    tibble::tribble(
        ~slc_schedule, ~slc_row,    ~variable,       ~slc_column, ~slc_line,
                "02X",       "C01", "households",           "01",   "L0040", 
                "02X",       "C01", "population",           "01",   "L0041", 
                "02X",       "C01",      "youth",           "01",   "L0042",
                "80A",       "C01",  "fte_total",           "01",   "L0399",
                "80A",       "C01",  "pts_total",  c("02", "03"),   "L0399", 
                "80A",       "C01",  "fte_social",          "01",   c(
                  "L0220", "L0320", # Transit
                  "L0227", "L0327", "L0228", "L0328", "L0229", "L0329", # Ambulance
                  "L0230", "L0330", # Health
                  "L0235", "L0335", # Senior Support
                  "L0240", "L0340", # Other Social Services
                  "L0245", "L0345", # Parks and Recreation
                  "L0250", "L0350"  # Libraries
                ),
                "80A",       "C01",  "pts_social", c("02", "03"),   c(
                  "L0220", "L0320", # Transit
                  "L0227", "L0327", "L0228", "L0328", "L0229", "L0329", # Ambulance
                  "L0230", "L0330", # Health
                  "L0235", "L0335", # Senior Support
                  "L0240", "L0340", # Other Social Services
                  "L0245", "L0345", # Parks and Recreation
                  "L0250", "L0350"  # Libraries
                ),
                "74A",      "C01", "debt_burden",          "01", "L9910"
      ) |> 
      tidyr::unnest(slc_column) |> 
      tidyr::unnest(slc_line)
)

usethis::use_data(fir_meta, internal = TRUE, overwrite = TRUE)

import_fir_data <- function(years, fir_meta) {
  d <- 
    purrr::map_dfr(
      years, 
      ~readr::read_csv(
        glue::glue(
          "data-raw/fir/fir_data_{.x}.csv",
        ),
        col_types = readr::cols(MUNID = readr::col_integer()), 
        show_col_types = FALSE
      )
    ) |> 
    janitor::clean_names() |> 
    decompose_slc_code()

  list(
    services = d |> extract_fir_services(fir_meta),
    stats = d |> extract_fir_statistics(fir_meta)
  )
}

extract_fir_services <- function(fir_data, fir_meta) {

  fir_data |> 
    dplyr::left_join(fir_meta$cost_classification, by = c("slc_schedule", "slc_column")) |> 
    dplyr::left_join(fir_meta$service_classification, by = c("slc_line", "slc_schedule")) |>  
    drop_unused_items() |> 
    dplyr::mutate(
      amount = dplyr::case_when(
        slc_schedule == "51C" & slc_column == "03" ~ -1 * amount, 
        TRUE ~ amount
      )
    ) |> 
    dplyr::group_by(
      marsyear, 
      munid, 
      ut_number,
      municipality_desc,
      tier_code,
      service,
      service_type,
      cost_type,
      cost_payer
    ) |> 
    dplyr::summarize(amount = sum(amount), .groups = "drop") |> 
    pivot_payers()
}

extract_fir_services <- function(fir_data, fir_meta) {

  fir_data |> 
    dplyr::left_join(fir_meta$cost_classification, by = c("slc_schedule", "slc_column")) |> 
    dplyr::left_join(fir_meta$service_classification, by = c("slc_line", "slc_schedule")) |>  
    drop_unused_items() |> 
    dplyr::mutate(
      amount = dplyr::case_when(
        slc_schedule == "51C" & slc_column == "03" ~ -1 * amount, 
        TRUE ~ amount
      )
    ) |> 
    dplyr::group_by(marsyear, munid, ut_number, municipality_desc, tier_code, service, service_type, cost_type, cost_payer) |> 
    dplyr::summarize(amount = sum(amount), .groups = "drop") |> 
    pivot_payers()

}

extract_fir_statistics <- function(fir_data, fir_meta) {  
  fir_data |> 
    dplyr::left_join(fir_meta$quantities, by = c("slc_schedule", "slc_column", "slc_row", "slc_line")) |>
    dplyr::filter(!is.na(variable)) |> 
    dplyr::group_by(marsyear, munid, ut_number, municipality_desc, tier_code, variable) |>
    dplyr::summarize(amount = sum(amount), .groups = "drop")  |> 
    tidyr::pivot_wider(names_from = variable, values_from = amount, values_fill = 0)
}

decompose_slc_code <- function(fir_data) {
  fir_data |> 
    tidyr::separate(
      slc, into = c("x0", "slc_schedule", "slc_line", "slc_row", "slc_column"),
      sep = "\\.", remove = FALSE
    ) |> 
    dplyr::select(-x0)
}

drop_unused_items <- function(fir_data) {
  fir_data |> 
    dplyr::filter(!is.na(service), !is.na(cost_type))
}

pivot_payers <- function(fir_data) {
  fir_data |> 
    tidyr::pivot_wider(
      names_from = cost_payer, values_from = amount, values_fill = 0
    ) |> 
    dplyr::mutate(
      municipal_taxpayers = total - ontario - canada - other_municipalities - users, 
      municipal_taxpayers_plus_users = total - ontario - canada - other_municipalities
    ) |> 
    tidyr::pivot_longer(
      cols = c(ontario, canada, other_municipalities, users, municipal_taxpayers, municipal_taxpayers_plus_users), 
      names_to = "cost_payer", values_to = "amount"
    ) |>
    dplyr::ungroup()
}


fir_data <- import_fir_data(2015:2023, fir_meta)
fir_services <- fir_data$services
fir_statistics <- fir_data$stats

usethis::use_data(fir_services, overwrite = TRUE)
usethis::use_data(fir_statistics, overwrite = TRUE)
