// Some definitions presupposed by pandoc's typst output.
#let blockquote(body) = [
  #set text( size: 0.92em )
  #block(inset: (left: 1.5em, top: 0.2em, bottom: 0.2em))[#body]
]

#let horizontalrule = [
  #line(start: (25%,0%), end: (75%,0%))
]

#let endnote(num, contents) = [
  #stack(dir: ltr, spacing: 3pt, super[#num], contents)
]

#show terms: it => {
  it.children
    .map(child => [
      #strong[#child.term]
      #block(inset: (left: 1.5em, top: -0.4em))[#child.description]
      ])
    .join()
}

// Some quarto-specific definitions.

#show raw.where(block: true): set block(
    fill: luma(230),
    width: 100%,
    inset: 8pt,
    radius: 2pt
  )

#let block_with_new_content(old_block, new_content) = {
  let d = (:)
  let fields = old_block.fields()
  fields.remove("body")
  if fields.at("below", default: none) != none {
    // TODO: this is a hack because below is a "synthesized element"
    // according to the experts in the typst discord...
    fields.below = fields.below.amount
  }
  return block.with(..fields)(new_content)
}

#let empty(v) = {
  if type(v) == "string" {
    // two dollar signs here because we're technically inside
    // a Pandoc template :grimace:
    v.matches(regex("^\\s*$")).at(0, default: none) != none
  } else if type(v) == "content" {
    if v.at("text", default: none) != none {
      return empty(v.text)
    }
    for child in v.at("children", default: ()) {
      if not empty(child) {
        return false
      }
    }
    return true
  }

}

// Subfloats
// This is a technique that we adapted from https://github.com/tingerrr/subpar/
#let quartosubfloatcounter = counter("quartosubfloatcounter")

#let quarto_super(
  kind: str,
  caption: none,
  label: none,
  supplement: str,
  position: none,
  subrefnumbering: "1a",
  subcapnumbering: "(a)",
  body,
) = {
  context {
    let figcounter = counter(figure.where(kind: kind))
    let n-super = figcounter.get().first() + 1
    set figure.caption(position: position)
    [#figure(
      kind: kind,
      supplement: supplement,
      caption: caption,
      {
        show figure.where(kind: kind): set figure(numbering: _ => numbering(subrefnumbering, n-super, quartosubfloatcounter.get().first() + 1))
        show figure.where(kind: kind): set figure.caption(position: position)

        show figure: it => {
          let num = numbering(subcapnumbering, n-super, quartosubfloatcounter.get().first() + 1)
          show figure.caption: it => {
            num.slice(2) // I don't understand why the numbering contains output that it really shouldn't, but this fixes it shrug?
            [ ]
            it.body
          }

          quartosubfloatcounter.step()
          it
          counter(figure.where(kind: it.kind)).update(n => n - 1)
        }

        quartosubfloatcounter.update(0)
        body
      }
    )#label]
  }
}

// callout rendering
// this is a figure show rule because callouts are crossreferenceable
#show figure: it => {
  if type(it.kind) != "string" {
    return it
  }
  let kind_match = it.kind.matches(regex("^quarto-callout-(.*)")).at(0, default: none)
  if kind_match == none {
    return it
  }
  let kind = kind_match.captures.at(0, default: "other")
  kind = upper(kind.first()) + kind.slice(1)
  // now we pull apart the callout and reassemble it with the crossref name and counter

  // when we cleanup pandoc's emitted code to avoid spaces this will have to change
  let old_callout = it.body.children.at(1).body.children.at(1)
  let old_title_block = old_callout.body.children.at(0)
  let old_title = old_title_block.body.body.children.at(2)

  // TODO use custom separator if available
  let new_title = if empty(old_title) {
    [#kind #it.counter.display()]
  } else {
    [#kind #it.counter.display(): #old_title]
  }

  let new_title_block = block_with_new_content(
    old_title_block, 
    block_with_new_content(
      old_title_block.body, 
      old_title_block.body.body.children.at(0) +
      old_title_block.body.body.children.at(1) +
      new_title))

  block_with_new_content(old_callout,
    block(below: 0pt, new_title_block) +
    old_callout.body.children.at(1))
}

// 2023-10-09: #fa-icon("fa-info") is not working, so we'll eval "#fa-info()" instead
#let callout(body: [], title: "Callout", background_color: rgb("#dddddd"), icon: none, icon_color: black) = {
  block(
    breakable: false, 
    fill: background_color, 
    stroke: (paint: icon_color, thickness: 0.5pt, cap: "round"), 
    width: 100%, 
    radius: 2pt,
    block(
      inset: 1pt,
      width: 100%, 
      below: 0pt, 
      block(
        fill: background_color, 
        width: 100%, 
        inset: 8pt)[#text(icon_color, weight: 900)[#icon] #title]) +
      if(body != []){
        block(
          inset: 1pt, 
          width: 100%, 
          block(fill: white, width: 100%, inset: 8pt, body))
      }
    )
}

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
    place(top + left, float: true, scope: "parent", {
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
    bp-flexa(size: 9pt, colour: pal.blue-full, it)
  }

  show table.cell: it => {
    if it.x == 0 or it.y == 0 {
      bp-flexa(size: 9pt, colour: pal.blue-full, it)
    } else {
      text(10pt, fill: pal.blue-full, it)
    }
  }

  set table.hline(
    stroke: (pal.blue-full)
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


// Typst custom formats typically consist of a 'typst-template.typ' (which is
// the source code for a typst template) and a 'typst-show.typ' which calls the
// template's function (forwarding Pandoc metadata values as required)
//
// This is an example 'typst-show.typ' file (based on the default template  
// that ships with Quarto). It calls the typst function named 'article' which 
// is defined in the 'typst-template.typ' file. 
//
// If you are creating or packaging a custom typst template you will likely
// want to replace this file and 'typst-template.typ' entirely. You can find
// documentation on creating typst templates here and some examples here:
//   - https://typst.app/docs/tutorial/making-a-template/
//   - https://github.com/typst/templates

#show: bp-doc.with(
  title: [Blueprint Styles in Typst], 
      preamble: [This is a custom Quarto template that uses Typst to generate Blueprint-style reports from Quarto documents.

],
        date: toml.decode("date = 2021-09-01").date,
        authors: (
       (
        name: [Thomas McManus],
      ) 
    ),
    title-page: true,
  table-of-contents: true, 
  columns: 2,
      bib: bibliography("refs.bib"),
  )

= Introduction
<introduction>
This is a custom Quarto template that uses Typst to generate Blueprint-style reports from Quarto documents.

== Paragraph
<paragraph>
#lorem(100)
== Code Block
<code-block>
@fig-bpdoc-example compares engine displacement to highway mileage. In it, we observe a clear negative relationship between them. Cars with larger engines tend to have lower highway mileage.

```r
library(ggplot2)
mpg |> 
  ggplot(aes(x = displ, y = hwy)) + 
  geom_point()
```

#figure([
#box(image("template_files/figure-typst/fig-bpdoc-example-1.svg"))
], caption: figure.caption(
position: bottom, 
[
A plot comparing engine displacement to highway mileage.
]), 
kind: "quarto-float-fig", 
supplement: "Figure", 
)
<fig-bpdoc-example>


== Bulleted List
<bulleted-list>
- One thing
- Another thing
  - A sub-thing
  - Another sub-thing
- A third thing

== Numbered List
<numbered-list>
+ First thing
+ Second thing
+ Third thing

= More Information
<more-information>
You can learn more about creating custom Typst templates here:

#link("https://quarto.org/docs/prerelease/1.4/typst.html#custom-formats")

#bibliography("refs.bib")

