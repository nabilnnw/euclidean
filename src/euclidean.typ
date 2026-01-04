#import "@preview/cetz:0.4.2"


// Shorthand for ease of use
#let (draw, vec) = (cetz.draw, cetz.vector)


// Convert coordinates (Polar/Named) to Cartesian (x, y)
#let parse(c) = {
  // 1. Return immediately if not an array (e.g., a named point string "A")
  if type(c) != array { return c }

  // 2. Identify Polar coordinates: (angle, radius)
  if c.len() == 2 and type(c.at(0)) == angle {
    let (a, r) = c
    // 3. Convert to Cartesian using x = r*cos(a), y = r*sin(a)
    return (r * calc.cos(a), r * calc.sin(a))
  }

  return c
}


// Point / vector elementary operation
#let add(a, b) = vec.add(parse(a), parse(b))
#let sub(a, b) = vec.sub(parse(a), parse(b))
#let mul(v, s) = vec.scale(parse(v), s)
#let div(v, s) = vec.scale(parse(v), 1/s)


// Calculate the scalar distance between two points
#let dist(A, B) = {
  // 1. Convert inputs to Cartesian coordinates
  let p1 = parse(A)
  let p2 = parse(B)
  
  // 2. Subtract points to get the displacement vector
  let d = sub(p2, p1)
  
  // 3. Return the Euclidean length (norm) of the vector
  return vec.len(d)
}


// Draw dot for points
#let dot(pt, radius: 0.05, fill: black, stroke: none, ..args) = {
  // 1. Check if pt is a single coordinate (Cartesian, Polar, or Named)
  let is_single = type(pt) == str or (
    type(pt) == array and pt.len() >= 2 and type(pt.at(0)) in (int, float, length, angle)
  )

  // 2. Normalize input into an array of points for the loop
  let points = if is_single { (pt,) } else { pt }

  for p in points {
    draw.circle(
      p,
      radius: radius,
      fill: fill,
      stroke: stroke,
      ..args
    )
  }
}


// Label points
#let label(pt, texts, angle: -90deg, dist: 0.3, anchor: "center", boxed: false, ..args) = {
  // 1. Normalize inputs: allow single values or arrays for points and text
  let is_single_pt = type(pt) == str or (
    type(pt) == array and pt.len() >= 2 and type(pt.at(0)) in (int, float, length, angle)
  )
  let is_single_txt = type(texts) in (str, content)
  
  let points = if is_single_pt { (pt,) } else { pt }
  let labels = if is_single_txt { (texts,) } else { texts }

  for (i, p) in points.enumerate() {
    // 2. Pick corresponding label; fallback to the last one if points > labels
    let txt = labels.at(i, default: labels.last())
    
    // 3. Calculate offset position using polar vector math
    let pos = add(p, (angle, dist))
    
    draw.content(
      pos,
      txt,
      anchor: anchor,
      fill: if boxed { white } else { none },
      padding: 0,
      frame: if boxed { "rect" } else { none },
      stroke: none,
      ..args
    )
  }
}


// Draw segment
#let segment(p1, p2, extend: 0, ..args) = {
  let A = parse(p1)
  let B = parse(p2)
  
  // 1. Handle extension values: allow uniform (scaler) or per-end (array)
  let (e1, e2) = if type(extend) == array { extend } else { (extend, extend) }
  
  // 2. Fast path for standard segments
  if e1 == 0 and e2 == 0 {
    draw.line(A, B, ..args)
  } else {
    let d = sub(B, A)
    let len = vec.len(d)
    
    // 3. Prevent division by zero for coincident points
    if len == 0 {
      draw.line(A, B, ..args)
    } else {
      // 4. Calculate unit direction and shift start/end points outward
      let unit = div(d, len)
      let start = sub(A, mul(unit, e1))
      let end = add(B, mul(unit, e2))
      
      draw.line(start, end, ..args)
    }
  }
}


// Line-Line Intersection (Returns a single point or none)
#let iLL(A, B, C, D) = {
  // 1. Normalize inputs
  let (x1, y1) = parse(A)
  let (x2, y2) = parse(B)
  let (x3, y3) = parse(C)
  let (x4, y4) = parse(D)
  
  // 2. Calculate the denominator
  let den = (x1 - x2) * (y3 - y4) - (y1 - y2) * (x3 - x4)
  
  // 3. Parallel check (using a small epsilon for float precision)
  if calc.abs(den) < 1e-9 { return none } 
  
  // 4. Determinant formula
  let d12 = x1*y2 - y1*x2
  let d34 = x3*y4 - y3*x4
  
  let px = (d12 * (x3 - x4) - (x1 - x2) * d34) / den
  let py = (d12 * (y3 - y4) - (y1 - y2) * d34) / den
  
  return (px, py)
}


// Line-Circle Intersection (Returns an array of 0, 1, or 2 points)
#let iLC(A, B, O, r) = {
  // 1. Normalize inputs
  let O_pt = parse(O)
  let A_pt = sub(A, O_pt) // Shift origin to circle center
  let B_pt = sub(B, O_pt)
  
  let (x1, y1) = A_pt
  let (x2, y2) = B_pt
  
  let dx = x2 - x1
  let dy = y2 - y1
  let dr2 = calc.pow(dx, 2) + calc.pow(dy, 2)
  let D = x1 * y2 - x2 * y1
  
  // 2. Discriminant
  let disc = calc.pow(r, 2) * dr2 - calc.pow(D, 2)
  
  // 3. Floating point safety check
  if disc < -1e-9 { return () }
  // Treat tiny negatives or tiny positives as tangent (1 point)
  let is_tangent = calc.abs(disc) < 1e-9
  let sqrt_disc = if is_tangent { 0 } else { calc.sqrt(disc) }
  
  // 4. Sign of dy (standard geometric convention)
  let sgn_dy = if dy < 0 { -1 } else { 1 }
  
  let x_part1 = D * dy
  let x_part2 = sgn_dy * dx * sqrt_disc
  let y_part1 = -D * dx
  let y_part2 = calc.abs(dy) * sqrt_disc
  
  let p1 = add(O_pt, ((x_part1 + x_part2)/dr2, (y_part1 + y_part2)/dr2))
  let p2 = add(O_pt, ((x_part1 - x_part2)/dr2, (y_part1 - y_part2)/dr2))
  
  if is_tangent { (p1,) } else { (p1, p2) }
}


// Circle-Circle Intersection (Returns an array of 0, 1, or 2 points)
#let iCC(O1, r1, O2, r2) = {
  // 1. Normalize inputs
  let p1 = parse(O1)
  let p2 = parse(O2)
  
  let d_vec = sub(p2, p1)
  let d = vec.len(d_vec)
  
  // 2. Check for no intersection or coincident centers
  if d > r1 + r2 or d < calc.abs(r1 - r2) or d < 1e-9 { return () }
  
  // 3. Distance from p1 to the point where the line joining intersections crosses p1-p2
  let a = (calc.pow(r1, 2) - calc.pow(r2, 2) + calc.pow(d, 2)) / (2 * d)
  
  // 4. Height from that line to the intersection points
  let h_sq = calc.pow(r1, 2) - calc.pow(a, 2)
  let is_tangent = calc.abs(h_sq) < 1e-9
  let h = if is_tangent { 0 } else { calc.sqrt(calc.max(0, h_sq)) }
  
  // 5. Find the base point on the line O1-O2
  let p_base = add(p1, mul(d_vec, a / d))
  
  // 6. Offset by h in the perpendicular direction
  // Perpendicular vector to (dx, dy) is (-dy, dx)
  let (dx, dy) = d_vec
  
  let i1 = (
    p_base.at(0) + h * dy / d,
    p_base.at(1) - h * dx / d
  )
  let i2 = (
    p_base.at(0) - h * dy / d,
    p_base.at(1) + h * dx / d
  )
  
  if is_tangent { (i1,) } else { (i1, i2) }
}