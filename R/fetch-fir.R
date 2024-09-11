#' Fetch FIR data for a given year
#' @param year The year for which to fetch FIR data
#' @return A data frame with FIR data for the given year
#' @importFrom httr2 request req_perform req_progress
#' @importFrom glue glue
#' @importFrom readr read_csv
#' @export
fetch_fir <- function(year, dest = NULL) {
  req <- 
    request(glue(
      "https://efis.fma.csc.gov.on.ca/", 
      "fir/MultiYearReport/fir_data_{year}.zip"
    )) |> 
    req_progress()

  z <- tempfile(fileext = ".zip")

  if (is.null(dest)) {
    d <- tempdir()
  } else {
    d <- dest
  }

  resp <- req_perform(req, path = z)
  if (resp$status != 200) {
    stop(glue("Failed to fetch FIR data for {year}"))
  }

  unzip(z, exdir = d)
  res <- read_csv(file.path(d, glue::glue("fir_data_{year}.csv")))
  is.null(dest) && unlink(d)
  unlink(z)

  res
}


