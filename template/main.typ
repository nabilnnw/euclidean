#import "@local/mathjestic-fancy:0.1.0": *
#import "@local/euclidean:0.1.0": *

#show: mathjestic.with(
  // draft: true,
  color: "emerald",
  social: ( // Can only show the first 4 at the moment
    whatsapp: "6282337293909",
    instagram: "mathjestic.id",
    // youtube: "mathjestic",
    // github: "nabilnnw",
  ),
  // outline: true,
  lastupdate: true,
  website: "mathjestic.id",
  // titlepage: "1",
  // printsol: true,
  // pslink: true,
  title: "Euclidean",
  author: "Nabil Nabawi Wibisono",
  // abstract: "The easier you try to make your life, the harder it is going to be. You avoid hardships, risks, and constant improvement without realizing that when you try to stay the same, you don't stay the same. You slowly drown in problems until it is ten times harder to get out."
)

Still purely cartesian coordinate.

= Point

#cetz.canvas({
  import cetz.draw: *

  // Origin
  let O = (0, 0)

  // Define point by cartesian coordinate
  let A = (1, 2)

  // Define point by polar coordinate
  let B = (90deg, 2) // Degree
  let C = ((calc.pi / 4) * 1rad, 2) // Radian

  // Create point relative to other point
  let D = add(A, (3, 2))
  // let D = (rel: (3, 0), to: A) // Base

  let E = add((1, 2), (3, 0))

  let F = add(A, B)
  let G = add(F, E)

  // content((0, -1), [#repr(F)])

  dot((O, A, B, C, D, E, F, G))

  label(O, $O$, dist: 0, boxed: true)
  label(
    (A, B, C, D, E, F, G),
    ($A$, $B$, $C$, $D$, $E$, $F$, $G$),
    // anchor: "north"
  )
  // label(A, $A$, angle: 0deg, dist: 0.3)
})


= Segment