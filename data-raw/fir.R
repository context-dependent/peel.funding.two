source("data-raw/fir-src.R")

fir_raw <- import_fir_data(2015:2024, fir_meta)

fir_services <- fir_raw$services
fir_statistics <- fir_raw$stats

usethis::use_data(fir_services, overwrite = TRUE)
usethis::use_data(fir_statistics, overwrite = TRUE)

fir_services_ut <- fir_services |>
  aggregate_ut_services()

fir_services_ut |> 
  count(ut_name) |> 
  arrange(desc(n))

fir_statistics_ut <- fir_statistics |> 
  aggregate_ut_stats()

fir_statistics_ut

fir_ut_pc <- fir_services_ut |> 
  dplyr::left_join(fir_statistics_ut, by = c("marsyear", "utid")) |> 
  dplyr::mutate(
    amount_pc = amount / population
  ) |> 
  dplyr::left_join(
    on_cpi, 
    by = c("marsyear")
  ) |> 
  mutate(
    across(
      c(amount, amount_pc), 
      list(`cd23` = ~ .x * cpi_23f)
    )
  )

fir_data <- fir_ut_pc

usethis::use_data(fir_data, overwrite = TRUE)
