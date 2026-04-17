real_dollars <- function(x, x_year, to_year = 2023) {
  deflator <- on_cpi |> 
    dplyr::mutate(
      fct = (1 / (cpi_02 / cpi_02[marsyear == to_year])) |> 
        purrr::set_names(marsyear) 
    ) |> 
    dplyr::pull(fct)

  unname(x * deflator[as.character(x_year)])
}


write_tbl_wb <- function(tbls, path) {
  wb <- openxlsx::createWorkbook()

  purrr::iwalk(
    tbls,
    \(.tbl, .sheet) {
      openxlsx::addWorksheet(wb, .sheet)
      openxlsx::writeData(wb, .sheet, .tbl)
    }
  )

  openxlsx::saveWorkbook(wb, path, overwrite = TRUE)
}