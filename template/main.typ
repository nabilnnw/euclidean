#import "@local/mathjestic-fancy:0.1.0": *
#import "@local/euclidean:0.1.0": *

#show: mathjestic.with(
  color: "emerald",
  title: "Euclidean",
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

#cetz.canvas({
  import cetz.draw: *

  let O = (0, 0)
  let A = (1, 2)
  let B = (3, 3)
  let C = (4, 0)
  let D = (30deg, 1)
  let F = (8, 1)

  circle(C, radius: 3, stroke: blue)
  circle(F, radius: dist(F, C), stroke: green)

  segment(O, A, extend: (1, 2))
  segment(A, B, C, close: true) // Can still do this

  let E = iLL(O, D, A, C)

  let P = iLC(O, D, C, 3)
  let P2 = P.at(0)
  let P1 = P.at(1)

  let Q = iCC(C, 3, F, dist(F, C))
  let Q1 = Q.at(0)
  let Q2 = Q.at(1)

  dot((O, A, B, C, D, E, P1, P2, F, Q1, Q2))
  label((O, A, B, C, D, E, P1, P2, F, Q1, Q2), ($O$, $A$, $B$, $C$, $D$, $E$, $P_1$, $P_2$, $F$, $Q_1$, $Q_2$))
})