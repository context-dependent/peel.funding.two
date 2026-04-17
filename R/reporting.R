#' @import ggplot2
slope_chart <- function(
  d, 
  yvar, 
  ylab,
  xvar = marsyear, 
  xlab = "Fiscal Year Ending",
  yavg = NULL, 
  yfmt = identity, 
  idvar = ut_name,
  font_size = 8,
  highlight_ut = c("York R"),
  highlight_colour = "blue"
) {


  dplt <- d |> 
    dplyr::filter({{ xvar }} < Inf) |> 
    dplyr::filter({{ xvar }} %in% range({{ xvar }}), .by = c({{ idvar }}))

  plt <- dplt |> 
    ggplot(aes({{ xvar }}, {{ yvar }})) 
    
  if(rlang::quo_is_null(rlang::enquo(yavg))) {
    dplt <- dplt
  } else {
    davg <- d |> 
      dplyr::filter({{ xvar }} < Inf) |> 
      dplyr::filter({{ xvar }} %in% range({{ xvar }})) |>
      dplyr::distinct({{ xvar }}, {{ yavg }})

    plt <- plt + 
      geom_line(
        aes(y = {{ yavg }}), 
        linewidth = 1, 
        linetype = "dotted",
        data = davg
      ) + 
      geom_point(
        aes(y = {{ yavg }}),
        shape = 22, 
        size = 3,
        fill = "white", 
        data = davg
      )
  }

  plt <- plt + 
    geom_line(
      aes(
        group = {{ idvar }},
      ), alpha = .4, linewidth = 1
    ) + 
    ggrepel::geom_text_repel(
      aes(label = ut_name), 
      direction = "y", 
      size = font_size / ggplot2::.pt,
      nudge_x = .3,
      hjust = "left",
      segment.linetype = "dotted",
      data = \(.d) {
        .d |> 
          dplyr::filter({{ xvar }} == max({{ xvar }}), .by= c({{ idvar }}))
      }
    ) +
    geom_point(
      shape = 21, 
      size = 3,
      fill = "white"
    )

  plt <- plt + 
    geom_line(
      aes(
        group = {{ idvar }},
      ), 
      colour = highlight_colour,
      linewidth = 1,
      data = \(.d) {
        .d |> 
          dplyr::filter({{ idvar }} %in% highlight_ut)
      }
    ) + 
    geom_point(
      shape = 21, 
      size = 3,
      stroke = 1,
      colour = highlight_colour,
      fill = "white",
      data = \(.d) {
        .d |> 
          dplyr::filter({{ idvar }} %in% highlight_ut)
      }
    )

  plt + 
    scale_y_continuous(
      labels = yfmt
    ) + 
    scale_x_continuous(
      breaks = unique(dplt |> dplyr::pull({{ xvar }})),
      expand = expansion(mult = c(.05, .25))
    ) + 
    bptheme::theme_blueprint(
      plot_background_color = "white",
      base_size = font_size,
      subtitle_size = font_size,
      subtitle_family = "Arial", 
      subtitle_color = "black",
      grid = ""
    ) + 
    labs(
      y = NULL, 
      x = xlab, 
      subtitle = ylab
    ) + 
    theme(
      plot.caption = element_text(size = font_size - 2, hjust = 0, lineheight = 1.1)
    )
}

fill_pop <- function(t3010_ut) {
  mf <- t3010_ut |> 
    dplyr::distinct(data_year, munid, population) |> 
    tsibble::as_tsibble(
      key = c(munid), 
      index = data_year
    )

  m <- mf |> 
    dplyr::filter(!is.na(population)) |> 
    fabletools::model(
      fable::TSLM(log(population) ~ trend())
    )

  fitted <- m |> 
    fabletools::interpolate(new_data = mf) |> 
    tibble::as_tibble()

  t3010_ut |> 
    select(-population) |> 
    dplyr::left_join(
      fitted,
      by = c("data_year", "munid")
    )
}

tabulate_gap <- function(d, y = amount, t = marsyear) {
  d |> dplyr::mutate(
    total_real = real_dollars({{ y }}, {{ t }}, 2023)
  ) |> 
  dplyr::summarize(
    total_real_muni = sum(total_real, na.rm = TRUE),
    .by = c({{ t }}, utid, ut_name, population)
  ) |> 
  dplyr::mutate(
    pc_real_muni = total_real_muni / population
  ) |>
  dplyr::mutate(
    pc_real_prov  = weighted.mean(
      pc_real_muni, population, na.rm = TRUE
    ),
    pc_real_gap = pc_real_muni - pc_real_prov,
    total_real_gap = pc_real_gap * population, 
    pop_muni = population,
    pop_prov = sum(population, na.rm = TRUE),
    .by = c(marsyear)
  ) |> 
  dplyr::select(
    marsyear, 
    matches("^pc_real"),
    pop_muni,
    matches("^total_real"),
    pop_prov,
    dplyr::everything()
  ) %>%
  dplyr::bind_rows(
    summarize(., 
      marsyear = Inf,
      across(
        c(matches("^(pc|total).*prov$")),
        ~ weighted.mean(.x, pop_prov, na.rm = TRUE)
      ), 
      across(
        c(matches("^(pc|total).*muni$")),
        ~ weighted.mean(.x, pop_muni, na.rm = TRUE)
      ),
      pop_muni = mean(pop_muni),
      .by = c(utid, ut_name)
    ) |> 
    mutate(
      pc_real_gap = pc_real_muni - pc_real_prov,
      total_real_gap = pc_real_gap * pop_muni
    )
  ) |> 
  dplyr::mutate(
    data_year = marsyear, 
    data_range = glue::glue("({min(data_year)}-{max(data_year[data_year < Inf])})"),
    headline_gap_pc = pc_real_gap,
    headline_gap_total = total_real_gap
  )
}

render_gap_tbl <- function(
  tbl, 
  .ut_name = "York R",
  .ut_label = "York",
  ylab = "Provincial Support per Capita"
) {
  tbl |> dplyr::filter(ut_name == .ut_name) |> 
    gt::gt() |> 
    gt::cols_label(
      marsyear = "Year",
      pc_real_prov = "Ontario",
      pc_real_muni = .ut_label,
      pc_real_gap = "Gap",
      pop_muni = glue::glue("{.ut_label} Population"),
      total_real_gap = "Total Gap"
    ) |> 
    gt::cols_hide(-c(
      marsyear,
      matches("^pc_real"),
      total_real_gap,
      pop_muni
    )) |>
    gt::text_replace(
      locations = gt::cells_body(columns = c(marsyear)), 
      pattern = "Inf",
      replacement = "Avg (2015-2024)"
    ) |> 
    gt::fmt_number(
      columns = c(
        matches("^pop")
      ),
      decimals = 0
    ) |> 
    gt::fmt_currency(
      columns = c(
        matches("^(total|pc)_real")
      ), 
      decimals = 0
    ) |> 
    gt::tab_spanner(
      label = ylab,
      columns = c(
        pc_real_prov,
        pc_real_muni,
        pc_real_gap
      )
    ) |> 
    gt::tab_footnote(
      footnote = "Average calculated across available UT / ST municipalities with populations over 300,000",
      locations = gt::cells_column_labels(columns = c(pc_real_prov))
    ) |> 
    gt::tab_footnote(
      footnote = "Total gap is the product of per-capita gap and municipal population", 
      locations = gt::cells_column_labels(columns = c(total_real_gap))
    ) |> 
    gt::tab_source_note(
      "All dollar amounts are expressed in 2023 dollars, adjusted for inflation using the Ontario Consumer Price Index (Annual Average)"
    ) |> 
    gt_global()
}

gt_global <- function(g) {
  g |> 
    gt::tab_options(
      table.font.size = "8pt"
    ) |> 
    gt::tab_style(
      style = gt::cell_text(
        align = "left"
      ), 
      locations = gt::cells_footnotes()
    ) |> 
    gt::tab_style(
      style = gt::cell_borders(
        sides = "bottom", 
        color = "black", 
        weight = gt::px(1)
      ),
      locations = list(
        gt::cells_column_spanners(),
        gt::cells_column_labels()
      )
    )
}
