#' Ontario Financial Information Returns (FIR) 2015-2023
#' @rdname fir_data
#' @description 
#'  The `fir_services` dataset represents the costs of services 
#'  provided by Ontario municipalities, as reported in the FIR. 
#'  It classifies those services by their service category, 
#'  cost type (operating or capital), and payer.
#'  Services are identified by their 'functional classification', 
#'  per the FIR manual.
#'  Some functional classification codes represent combinations of others. 
#'  The dataset's functional classifications are filtered such that totals 
#'  across services are not contaminated by double-counting. 
#' @name fir_services
#' @format A tibble with 305,108 rows and 10 columns: 
#' \describe{
#'  \item{marsyear}{The year of the FIR data}
#'  \item{munid}{The municipality ID}
#'  \item{ut_number}{The upper-tier municipality number (equivalent to munid for single-tier municipalities)}
#'  \item{municipality_desc}{The legal name of the municipality}
#'  \item{tier_code}{The tier code of the municipality (UT, LT, or ST)}
#'  \item{service}{The service, as classified by the FIR manual}
#'  \item{service_type}{The type of service (Core or Social) as classified by the project team}
#'  \item{cost_type}{The type of cost (Operating or Capital)}
#'  \item{cost_payer}{The payer of the cost (Ontario, Canada, Other Municipalities, Users)}
#'  \item{total}{The total amount of the cost of a service to a given payer in a given year and municipality}
#' }
"fir_services"

#' @rdname fir_data
#' @name fir_statistics
#' @format A tibble with key statistics from the FIR data
"fir_statistics"

#' Ontario Charity Revenue Data 2019-2023 (T3010)
#' @rdname t3010
#' @name t3010
#' @format A tibble with 145,645 rows and 23 columns
"t3010"

#' Ontario CPI 2015-2023
#' @description CPI data for All Items in Ontario, 2015-2023, per Statistics Canada
#' @rdname on_cpi
#' @name on_cpi
#' @format A tibble with 9 rows and 2 columns
"on_cpi"