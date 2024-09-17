#' Fetch the current common clustering of t3010 and fir codes
#' @export
fetch_clustering <- memoise::memoise(function() {
  googlesheets4::gs4_auth()
  googlesheets4::gs4_find("t3010-fir-clusters") |> 
    googlesheets4::read_sheet(sheet = 1)
})
