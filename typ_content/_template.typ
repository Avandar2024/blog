// Components shared by Typst posts.

// Render folded web content as an expanded callout in Typst documents. The
// metadata labels are invisible in Typst, but Pandoc preserves them so the
// conversion script can restore the Zola `fold` shortcode.
#let fold(title, body) = [
  #metadata(none)#label("fold-start:" + title)
  #block(
    width: 100%,
    breakable: true,
    fill: luma(96%),
    stroke: 0.6pt + luma(72%),
    radius: 4pt,
    inset: (x: 10pt, y: 8pt),
  )[
    #text(weight: "semibold")[#title]
    #v(5pt)
    #body
  ]
  #metadata(none)#label("fold-end:" + title)
]
