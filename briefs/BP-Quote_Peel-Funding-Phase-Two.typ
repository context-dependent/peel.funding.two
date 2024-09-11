#import "@local/bp-doc:0.1.0": bp-doc, pal, bp-flexa
#import "@preview/oxifmt:0.2.1": strfmt

#show: bp-doc.with(
  title: [
    Quotation for Services 
    Peel Funding Analysis Phase Two
  ], 
  preamble: none,  
  date: datetime.today(),
  authors: [Thomas McManus], 
  bib: none, 
  title-page: true, 
  table-of-contents: false
)

= Overview

#v(1em)

#figure(
  table(
    columns: 2, 
    align: (right + horizon, left + horizon), 
    stroke: none, 
    table.header(
      [Matter], [Fact]
    ), 
    table.hline(), 
    [Client], [Metamorphosis Network], 
    [Proponent], [Blueprint-ADE], 
    [Timeline], [August - September 2024], 
    [Final Deliverables], [Phase Two Final Report], 
    [Budget], [\$22,625 + HST]
  ), 
  caption: [Project Summary]
) <t-overview>

#v(1em)

#columns(2)[

== Background 

In the spring of 2024, Blueprint-ADE was engaged by the Metamorphosis Network to analyze and report on the provincial funding of social services in the municipalities within the Region of Peel. 
Completed in May, the final report for Phase One of the project provided a comprehensive overview of the funding landscape, comparing funding allocations across Ontario municipalities and quantifying the funding gap in Peel. 

== Purpose

Phase One succeeded in highlighting the funding gap experienced in the Region of Peel and sparking valuable discussions about its implications. 
The core goal of Phase Two is to build from this foundation of awareness and understanding toward more specific and actionable insights. 
The final report for Phase Two will expand on the analysis and findings of Phase One, examining the funding gaps by service area. 
It will be designed and executed with its ultimate publication in mind, ensuring that the report is accessible, informative, polished and rigorously researched. 

== Scope of Work

As the essential purpose of Phase Two builds on work completed in Phase One, so too does the scope of work. 
Where possible, data, code, and methods developed in Phase One will be reused and extended.
Where feedback provided subsequent to the publication of the Phase One report suggests opportunities for improvement, these will be incorporated into the Phase Two analysis. 

=== Key Activities

- Develop a useful categorization of service areas
- Update and extend research datasets developed in Phase One
- Quantify and analyze funding gaps by service area
- Validate preliminary findings and refine analysis methodology with key stakeholders (Metamorphosis Network, Region of Peel, domain experts)
- Draft, finalize, and publish the Phase Two report
- Support knowledge mobilization and dissemination activities undertaken by the Metamorphosis Network

=== Deliverables

As indicated in @t-overview, the final deliverable for Phase Two is the Phase Two Final Report (working title). 
However, arriving at that final deliverable will involve the production of several interim deliverables, including the following:

- Report outline and analysis plan
- Summary of preliminary findings
- First draft report for client team review
- Second draft report for external review
- Final report for publication
- Knowledge mobilization support (e.g., launch events, presentations)

]

= Workplan and Budget

#let workplan-data = (
  deliverables: (
    (
      label: [Outline and Analysis Plan], 
      timing: [Early August], 
      activities: (
        (label: [Build service area categorization], days: (pa: 1, a: 0)), 
        (label: [Map additional data sources], days: (pa: 1, a: 0)),
        (label: [Draft outline], days: (pa: .5, a: 0)),
        (label: [Finalize outline], days: (pa: .25, a: 0))
      )
    ), (
      label: [Summary of Preliminary Findings],
      timing: [Mid-August],
      activities: (
        (label: [Develop and document research datasets], days: (pa: 1, a: 0)),
        (label: [Conduct exploratory analysis], days: (pa: 1, a: 0)),
        (label: [Summarize preliminary findings], days: (pa: 1, a: 0)),
        (label: [Review and refine with client team], days: (pa: .5, a: 0))
      )
    ), (
      label: [Draft Report],
      timing: [Late August],
      activities: (
        (label: [Conduct final analysis], days: (pa: 2, a: 0)),
        (label: [Develop internal draft], days: (pa: 1, a: 0)),
        (label: [Review and refine with client team], days: (pa: .5, a: 0)),
        (label: [Develop external draft], days: (pa: 2, a: 1)),
        (label: [Review and refine with external stakeholders], days: (pa: .5,a: .5))
      )
    ), (
      label: [Final Report],
      timing: [Mid-September],
      activities: (
        (label: [Finalize report], days: (pa: 1.5, a: 1)),
        (label: [Support knowledge mobilization], days: (pa: .5, a: 0))
      )
    )
  ), 
  rate-card: (
    pa: 1500, 
    a: 500
  ), 
  notes: (
    [PA: Principal Associate (90% Thomas McManus, 10% Spencer Gordon)], 
    [A: Associate (TBD)]
  )
)

#let render-deliverable = (d) => {
  (
    table.cell([#d.label], rowspan: d.activities.len()),
    table.cell([#d.timing], rowspan: d.activities.len()),
    ..d.activities.map(a => (
      table.cell([#a.label]), 
      ..a.days.keys().map(
        (k) => 
          table.cell([#strfmt("{:.2}", float(a.days.at(k)))])
      ), 
      [#h(1em) \$], [#strfmt("{:.2}", float(a.cost))]
    ))
  ).flatten()
}

#let render-workplan = (d) => {
  let n-roles = d.rate-card.len()
  let n-cols = 5 + n-roles
  let d-costed = d.deliverables.map(
    x => {
      let res = x
      res.activities = x.activities.map(
        a => {
          let res = a
          res.cost = 0
          for (k, v) in a.days {
            res.cost = res.cost + v * d.rate-card.at(k)
          }
          res
        }
      )
      res
    })

  let subtotal = d-costed.fold(0, (a, b) => 
    a + b.activities.fold(0, (c, d) => c + d.cost))
  let hst = subtotal * 0.13
  let total = subtotal + hst

  figure(
    table(
      columns: n-cols,
      align: (x, _) => 
        if x < 3 { left + horizon } else { right + horizon },
      fill: none, 
      stroke: (_, y) => (
        y: if y > 1 { .5pt + pal.blue-full } else { 1pt + pal.blue-full }, 
        x: none
      ),
      table.header(
        table.cell([Deliverable], rowspan: 2),
        table.cell([Timing], rowspan: 2),
        table.cell([Activities], rowspan: 2),
        table.cell([Days], colspan: n-roles),
        table.cell([Cost], rowspan: 2, colspan: 2),
        ..d.rate-card.keys().map((role) => table.cell([#upper(role)]))
      ), 
      ..d-costed.map(x => render-deliverable(x)).flatten(),
      table.cell([Subtotal], colspan: n-cols - 2), [#h(1em) \$], [#strfmt("{:.2}", float(subtotal))], 
      table.cell([HST], colspan: n-cols - 2), [#h(1em) \$], [#hst],
      table.cell([Total], colspan: n-cols - 2), [#h(1em) \$], [#total],
      ..d.notes.map(x => 
        table.cell(
          text(x, font: "Roboto", size: 8pt, fill: pal.grey-dark), 
          colspan: n-cols, 
          align: right + horizon, 
          stroke: none,
          fill: pal.grey-light
        )
      ), 
      table.hline() 
    ), 
    caption: [Workplan and Budget]
  )
}

#render-workplan(workplan-data) <t-workplan>


