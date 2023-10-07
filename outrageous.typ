#let presets = (
  // outrageous preset for a Table of Contents
  outrageous-toc: (
    font-weight: ("bold", auto),
    font-style: (auto,),
    vspace: (12pt, none),
    font: ("Noto Sans", auto),
    fill: (none, repeat[~~.]),
    fill-right-pad: .4cm,
    fill-align: true,
    body-transform: none,
    page-transform: none,
  ),
  // outrageous preset for List of Figures/Tables/Listings
  outrageous-figures: (
    font-weight: (auto,),
    font-style: (auto,),
    vspace: (none,),
    font: (auto,),
    fill: (repeat[~~.],),
    fill-right-pad: .4cm,
    fill-align: true,
    body-transform: (lvl, body) => {
      // exclude the supplement, and group by chapter (if per-chapter numbering is used)
      let (supplement, _, number, separator, ..text) = body.children
      let v = if number.text.ends-with("1") and not number.text.starts-with("1") { v(10pt) }
      box[#v#number. #text.join()]
    },
    page-transform: none,
  ),
  // preset without any style changes
  typst: (
    font-weight: (auto,),
    font-style: (auto,),
    vspace: (none,),
    font: (auto,),
    fill: (auto,),
    fill-right-pad: none,
    fill-align: false,
    body-transform: none,
    page-transform: none,
  ),
)

#let show-entry(
  entry,
  font-weight: presets.outrageous-toc.font-weight,
  font-style: presets.outrageous-toc.font-style,
  vspace: presets.outrageous-toc.vspace,
  font: presets.outrageous-toc.font,
  fill: presets.outrageous-toc.fill,
  fill-right-pad: presets.outrageous-toc.fill-right-pad,
  fill-align: presets.outrageous-toc.fill-align,
  body-transform: presets.outrageous-toc.body-transform,
  page-transform: presets.outrageous-toc.page-transform,
  label: <outrageous-modified-entry>,
  state-key: "outline-page-number-max-width",
) = {
  fill-right-pad = if fill-right-pad == none { 0pt } else { fill-right-pad }
  let max-width = state(state-key, 0pt)
  if entry.at("label", default: none) == label {
    entry // prevent infinite recursion
  } else {
    let font-weight = font-weight.at(calc.min(font-weight.len(), entry.level) - 1)
    let font-style = font-style.at(calc.min(font-style.len(), entry.level) - 1)
    let vspace = vspace.at(calc.min(vspace.len(), entry.level) - 1)
    let font = font.at(calc.min(font.len(), entry.level) - 1)
    let fill = fill.at(calc.min(fill.len(), entry.level) - 1)

    set text(font: font) if font not in (auto, none)
    set text(weight: font-weight) if font-weight not in (auto, none)
    set text(style: font-style) if font-style not in (auto, none)
    if vspace != none { v(vspace, weak: true) }

    style(styles => {
      let this-width = measure(entry.page, styles).width
      if fill != none {
        max-width.update(max => calc.max(this-width, max))
      }

      let fields = entry.fields()
      if body-transform != none {
        let new-body = body-transform(entry.level, entry.body)
        fields.body = if new-body == none { entry.body } else { new-body }
      }
      if page-transform != none {
        let new-page = page-transform(entry.level, entry.page)
        fields.page = if new-page == none { entry.page } else { new-page }
      }

      if fill in (none, auto) or not fill-align {
        if fill != auto {
          fields.fill = if fill == none { none } else {
            box(width: 100% - fill-right-pad, fill)
          }
        }
        [#outline.entry(..fields.values()) #label]
      } else {
        locate(loc => {
          let fields = fields
          let max-width = max-width.final(loc)
          fields.fill = box(width: 100% - (max-width - this-width) - fill-right-pad, fill)
          [#outline.entry(..fields.values()) #label]
        })
      }
    })
  }
}
