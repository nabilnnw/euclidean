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

= Point

#cetz.canvas({
  import cetz.draw: *

  // Define Point
  let A = (0, 0)

  // Draw Point
  circle(A, radius: 0.05, fill: black, name: "A")

  // Label Point
  set-style(content: (frame: "rect", stroke: none, fill: white, padding: 0.02))

  // First method to give label
  content((name: "A", anchor: 0deg), anchor: "west", [$A$])

  // Second method to give label (can offset)
  content((rel: (0pt, -5pt), to: "A.center"), anchor: "north", [$B$])

  // Second method with polar offset
  content((rel: (30deg, 1), to: "A.center"), anchor: "north", [$C$])
})

= Segment

#cetz.canvas({
  import cetz.draw: *

  // Define Point
  let A = (0, 0)
  let B = (3, 4)
  let C = (5, 0)
  let D = (2, 1)
  let E = (4, 3)

  // Draw Point
  dot((A, B, C, D, E))

  // Draw Segment
  segment(A, B, extend: (1, 2))
  segment(C, D)

  intersections("i", {
    xline(A, B)
    xline(C, D)
  })

  let P = "i.0"

  dot(P)
  segment(P, E)
})


// 1. Setup the Geometry (Math Phase)
#let A = (0, 0)
#let B = (4, 0)
#let C = (2, 3)
#let E = (0, 3)
#let O = (2, 1.5) // Center of a circle
#let r = 2.0

// 2. Calculate Intersections (Pure Variables!)
#let I = iLL(A, C, B, E)
#let pts = iLC(A, B, O, r) // Returns an array of points
#let P1 = pts.at(0)
#let P2 = pts.at(1)

#let P = vec.lerp(A, B, 1/20)

// 3. Draw it (Drawing Phase)
#cetz.canvas({
  dot((A, B, C, I, E, P1, P2, P))
  segment(A, C)
  segment(B, E)
  segment(A, B)
  
  // THIS WORKS NOW! Because I is a real array.
  segment(I, B, extend: (0.5, 0.5), stroke: blue)
  
  cetz.draw.circle(O, radius: r, stroke: gray)
})


#cetz.canvas({
  import cetz.draw: *
  // Create short math aliases ONLY inside this canvas
  let (add, sub, mul, div) = (vec.add, vec.sub, vec.scale, (v, s) => vec.scale(v, 1/s))
  
  let A = (1, 2)
  let B = (3, 4)
  
  // It's not A + B, but it's very close and stays local:
  let C = add(A, B)      // (4, 6)
  let M = div(add(A, B), 2) // Midpoint
  let V = mul(sub(B, A), 2) // Vector from A to B, doubled
  
  dot((A, B, C, M, V))
  line(A, B, C, close: true)
})



