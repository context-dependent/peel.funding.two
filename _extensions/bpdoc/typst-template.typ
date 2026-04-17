#let pal = (
  blue-full: rgb("#0000FF"),
  blue-zero: rgb("#cff7ff"),
  blue-one: rgb("#87cffa"),
  blue-two: rgb("#0080ff"),
  green: rgb("#00cf96"),
  orange: rgb("#ff4500"),
  grey-light: rgb("#f2f2f2"),
  grey-dark: rgb("#333333"),
  black: rgb("#000000")
)

#let margin-circle = circle.with(height: 13pt, fill: pal.blue-full)

#let section-circles() = {
  let circles = (
    pal.blue-zero, 
    pal.blue-one, 
    pal.blue-two, 
    pal.green, 
    pal.orange, 
    pal.grey-dark
  ).map(it => margin-circle(fill: it))
  
  stack(
    ..circles, 
    dir: ltr,
    spacing: .8em
  )
}

#let bp-flexa(x, size: 11pt, colour: pal.blue-full) = {
  let t = - (size / 25)
  text(
    fill: colour,
    font: "GT Flexa", 
    size: size, 
    tracking: t, 
    weight: "regular",
    x
  )
}

#let bp-heading(x, size: 11pt, colour: pal.blue-full) = {
  let i = .5pt - (size / 10)

  block(
    inset: (left: i),
    bp-flexa(x, size: size, colour: colour)
  )
}

#let insert-pagebreak() = [
  #context[
    #let n_cols = page.columns
    #let width_page = page.width
    #let width_col = width_page/n_cols
    #let x_init = here().position().x
    #let n_current_col = calc.ceil(x_init/width_col)
    #let n_colbreaks_required = n_cols - n_current_col + 1
    #text(1pt, luma(100%))[#n_colbreaks_required]
    #for _ in range(n_colbreaks_required){
        colbreak()
    }
  ]
]

#let section-headings = context {
  return query(heading.where(level: 1))
}

#let section-heading-pages = context { 
  let headings = query(heading.where(level: 1))
  headings.map(x => x.location().position().page)
}

#let has-section-heading() = context {
  let headings = query(heading.where(level: 1))
  let current = counter(page).get()
  let has-section = false

  for h in headings {
    if h.location().page() == current {
      has-section = true
    }
  }
  return has-section
}

#let bp-title-page = (title, fill:  pal.blue-zero) => {
  set page(fill: fill)
  grid(
    rows: (5fr, 8fr), 
    grid.cell(
    bp-heading(bp-flexa(size: 50pt, title)), 
    align: left + horizon
    ), 
    []
  )
}

#let bp-outline = () => {
  set heading(outlined: false)
  page(
    columns: 1,
    grid(
      columns: (1fr, 8fr, 1fr, ), 
      rows: (1fr, ),
      grid.cell([]),
      grid.cell(outline(title: [Table of Contents <toc>], indent: 1em, depth: 2)), 
      grid.cell([]) 
    )
  )
  set heading(outlined: true)
}

#let bp-doc(
  title: none,
  preamble: none,
  date: none, 
  authors: none, 
  bib: none,
  title-page: false, 
  table-of-contents: true,
  columns: 1,
  doc
) = {

  set page(
    paper: "us-letter", 
    columns: columns,
    margin: (x: .5in, y: 1in), 
    header: context {
      let headings = query(heading.where(level: 1, outlined: true))
      let current = counter(page).get().first()
      let has-section = headings.any(x => x.location().page() == current)
      let previous-headings = headings.filter(x => x.location().position().page < current)
      
      set align(right + horizon)

      if (has-section or (previous-headings.len() == 0)) {
        section-circles()
      } else {
        bp-flexa(previous-headings.last().body)
      }
    }, 
    footer: context {
      let current = counter(page).get().first()
      let toc-page = if table-of-contents {
        query(<toc>).first().location().page()
      } else {
        0
      }
      let left-content = grid.cell([])
      let right-content = grid.cell([])
      if current > toc-page {
        left-content = grid.cell(bp-flexa(stack(dir: ltr, spacing: 1em, [#current], title)), align: left + horizon)
        right-content = grid.cell(bp-flexa(stack(dir: ltr, spacing: 1em, date.display(), margin-circle())), align: right + horizon)
      }
      
      if current == 1 {
        left-content = grid.cell(bp-flexa(date.display()), align: left + horizon)
        right-content = grid.cell(bp-heading(bp-flexa([Blueprint], size: 18pt, colour: pal.blue-full)), align: right + horizon)
      } 
      
      grid(
        columns: (2fr, 1fr),
        left-content,
        right-content
      )
    }
  )

  show outline.entry.where(
    level: 1
  ): it => {
    v(12pt, weak: true)
    bp-flexa(size: 12pt, it)
  }

  show outline.entry.where(
    level: 2
  ): it => {
    bp-flexa(size: 12pt, colour: pal.grey-dark, it)
  }

  show heading.where(level: 1): it => context {
    let n-previous = query(heading.where(level: 1, outlined: true).before(it.location())).len()
    if table-of-contents {
      n-previous = n-previous - 1
    }
    if n-previous > 0 {
      insert-pagebreak()
    }
    place(top + left, float: true, {
      v(2em)
      bp-heading(size: 28pt, it.body)
      v(1em)
    })
  }

  show heading.where(level: 2): it => {
    bp-heading(size: 14pt, it.body)
  }

  show heading.where(level: 3): it => {
    bp-heading(size: 11pt, colour: pal.black, it.body)
  }

  show cite: it => {
    text(
      font: "Consolas", 
      size: 10pt, 
      fill: pal.green, 
      weight: 400, 
      it
    )
  }

  show figure.where(kind: table): set figure.caption(position: top)

  show figure.caption: it => {
    bp-flexa(size: 9pt, colour: pal.grey-dark, it)
  }

  show table.cell: it => {
    if it.x == 0 or it.y == 0 {
      bp-flexa(size: 9pt, colour: pal.grey-dark, it)
    } else {
      text(10pt, fill: pal.grey-dark, it)
    }
  }

  set table.hline(
    stroke: (pal.black)
  )

  set table(
    fill: (x, y) => if y > 0 and calc.even(x) { pal.grey-light }
  )

  set math.equation(numbering: "(1)")

  set text(
    font: "Roboto",
    fill: pal.grey-dark,
    size: 10pt, 
    weight: 400
  )

  set list(
    marker: ([
      #v(1pt)
      #circle(width: 5pt, stroke: pal.blue-full)
    ],
    [
      #v(4pt)
      #line(length: 6pt, stroke: pal.blue-full)
    ]),
    indent: .3em)

  set enum(
    full: true,
    indent: .3em,
    numbering: (..nums) =>  {
      let nums = nums.pos()
      let num = nums.last()
      let level = nums.len()

      let format = ("1.", "a.", "i.").at(calc.min(2, level - 1))
      let result = numbering(format, num)
      bp-flexa(result, size: 10pt, colour: pal.blue-full)
    }
  )

  set footnote(numbering: "1 ")

  if title-page and title != none {
    bp-title-page(title)
  }

  if preamble != none{
    set heading(outlined: false)
    page(
      columns: 1, 
      margin: (x: 2in, y: 2in),
      preamble
    )
    set heading(outlined: true)
  }

  if table-of-contents {
    bp-outline()
  }

  doc

}
