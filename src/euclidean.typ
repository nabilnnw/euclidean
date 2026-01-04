#import "@preview/cetz:0.4.2"


// ==================================================
// Define and Create
// ==================================================


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


// Midpoint
#let midpoint(A, B) = {
  // 1. Parse inputs to ensure they are Cartesian coordinates
  let p1 = parse(A)
  let p2 = parse(B)
  
  // 2. Average the coordinates: (A + B) / 2
  return div(add(p1, p2), 2)
}


// Centroid
#let centroid(A, B, C) = {
  // 1. Parse inputs to ensure they are Cartesian coordinates
  let p1 = parse(A)
  let p2 = parse(B)
  let p3 = parse(C)
  
  // 2. The Centroid is the average: (A + B + C) / 3
  return div(add(add(p1, p2), p3), 3)
}


// Find point P on AB such that PA/PB = r
#let point-ratio(A, B, r) = {
  let p1 = parse(A)
  let p2 = parse(B)
  
  // To make PA/PB = r:
  // P = (1 * A + r * B) / (1 + r)
  let weight_a = 1 / (1 + r)
  let weight_b = r / (1 + r)
  
  return add(mul(p1, weight_a), mul(p2, weight_b))
}


// Returns a point P on the line AB at a specific distance from A (or B)
// d: the absolute distance from the anchor point
// from_b: if true, distance is measured from B towards A. If false, from A towards B.
#let point-on-line(A, B, d, from_b: false) = {
  let p_a = parse(A)
  let p_b = parse(B)
  let full_dist = dist(p_a, p_b)

  // 1. Safety: if A and B are the same point
  if full_dist < 1e-9 { return p_a }

  // 2. Determine direction and anchor
  // We calculate the unit vector of the segment
  let v_unit = div(sub(p_b, p_a), full_dist)

  if from_b {
    // Start at B and move distance 'd' in the direction of A
    // The vector from B to A is the negative of v_unit
    return sub(p_b, mul(v_unit, d))
  } else {
    // Start at A and move distance 'd' in the direction of B
    return add(p_a, mul(v_unit, d))
  }
}


// Incenter
#let incenter(A, B, C) = {
  let p1 = parse(A)
  let p2 = parse(B)
  let p3 = parse(C)
  
  // 1. Calculate side lengths
  let a = dist(p2, p3) // side BC
  let b = dist(p1, p3) // side AC
  let c = dist(p1, p2) // side AB
  
  let total_perimeter = a + b + c
  
  // 2. Weighted average of vertices
  let p_weighted = add(
    add(mul(p1, a), mul(p2, b)), 
    mul(p3, c)
  )
  
  return div(p_weighted, total_perimeter)
}


// Inradius
#let inradius(A, B, C) = {
  let p1 = parse(A)
  let p2 = parse(B)
  let p3 = parse(C)
  
  // 1. Calculate side lengths
  let a = dist(p2, p3)
  let b = dist(p1, p3)
  let c = dist(p1, p2)
  
  // 2. Semi-perimeter (s)
  let s = (a + b + c) / 2
  
  // 3. Area (K) using Heron's Formula
  let area = calc.sqrt(s * (s - a) * (s - b) * (s - c))
  
  // 4. Radius r = Area / Semi-perimeter
  return area / s
}


// Angle bisector of angle ABC (returns 1 point)
#let angle-bisector(A, B, C, length: 1) = {
  let pA = parse(A)
  let pB = parse(B)
  let pC = parse(C)

  let v_ba = sub(pA, pB)
  let v_bc = sub(pC, pB)
  
  let d_ba = dist(pB, pA)
  let d_bc = dist(pB, pC)

  // Safety: If points are on B, default to unit vectors to avoid div-by-zero
  let u_ba = if d_ba < 1e-9 { (1, 0) } else { div(v_ba, d_ba) }
  let u_bc = if d_bc < 1e-9 { (1, 0) } else { div(v_bc, d_bc) }

  let v_bisect = add(u_ba, u_bc)
  let d_bisect = vec.len(v_bisect)

  if d_bisect < 1e-9 {
    // 180-degree case: B is between A and C
    let perp = (-u_ba.at(1), u_ba.at(0))
    return add(pB, mul(perp, length))
  } else {
    // Normal case
    return add(pB, mul(div(v_bisect, d_bisect), length))
  }
}


// Line-Line Intersection (Returns a single point or none)
#let inter-LL(A, B, C, D) = {
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


// Helper to handle (Center, Radius) or (Center, PointOnCircle)
// For tangent functions
#let _get-radius(O, arg) = {
  if type(arg) == float or type(arg) == int {
    return float(arg)
  }
  return dist(O, arg)
}


// Line-Circle Intersection (Returns an array of 0, 1, or 2 points)
// R can be a numeric radius or a point on the circumference
#let inter-LC(A, B, O, R) = {
  // 1. Normalize inputs and handle radius extraction
  let p_o = parse(O)
  let r = _get-radius(p_o, R)
  let p_a = sub(parse(A), p_o) // Shift origin to circle center
  let p_b = sub(parse(B), p_o)
  
  let (x1, y1) = p_a
  let (x2, y2) = p_b
  
  let dx = x2 - x1
  let dy = y2 - y1
  let dr2 = calc.pow(dx, 2) + calc.pow(dy, 2)
  let det = x1 * y2 - x2 * y1 // Determinant
  
  // 2. Discriminant calculation
  let disc = calc.pow(r, 2) * dr2 - calc.pow(det, 2)
  
  // 3. Floating point safety check
  if disc < -1e-9 { return () }
  
  // Treat tiny negatives or tiny positives as tangent (1 point)
  let is_tangent = calc.abs(disc) < 1e-9
  let sqrt_disc = if is_tangent { 0 } else { calc.sqrt(disc) }
  
  // 4. Sign of dy (standard geometric convention for intersection order)
  let sgn_dy = if dy < 0 { -1 } else { 1 }
  
  let x_part1 = det * dy
  let x_part2 = sgn_dy * dx * sqrt_disc
  let y_part1 = -det * dx
  let y_part2 = calc.abs(dy) * sqrt_disc
  
  let p1 = add(p_o, ((x_part1 + x_part2)/dr2, (y_part1 + y_part2)/dr2))
  let p2 = add(p_o, ((x_part1 - x_part2)/dr2, (y_part1 - y_part2)/dr2))
  
  if is_tangent { (p1,) } else { (p1, p2) }
}


// Circle-Circle Intersection (Returns an array of 0, 1, or 2 points)
// R1 and R2 can be numeric radii or points on the respective circumferences
#let inter-CC(O1, R1, O2, R2) = {
  // 1. Normalize inputs and handle radius extraction
  let p1 = parse(O1)
  let p2 = parse(O2)
  let r1 = _get-radius(p1, R1)
  let r2 = _get-radius(p2, R2)
  
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
  // Perpendicular vector to (dx, dy) is (dy, -dx)
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


// Projection of point P onto line segment AB (Foot of the altitude)
#let projection(P, A, B) = {
  // 1. Normalize all inputs to 2D Cartesian
  let p = parse(P)
  let a = parse(A)
  let b = parse(B)
  
  // 2. Create vectors for the line (ab) and the point (ap)
  let ab = sub(b, a)
  let ap = sub(p, a)
  
  // 3. Use the scalar projection formula: (ap · ab) / |ab|²
  // How far along the line AB the projection sits
  let ab_len_sq = calc.pow(vec.len(ab), 2)
  
  if ab_len_sq < 1e-9 { return a } // Safety for zero-length lines
  
  let t = vec.dot(ap, ab) / ab_len_sq
  
  // 4. Result = A + t * (B - A)
  return add(a, mul(ab, t))
}


// Orthocenter
#let orthocenter(A, B, C) = {
  // 1. Find the foot of the altitude from A to line BC
  let Ha = projection(A, B, C)
  
  // 2. Find the foot of the altitude from B to line AC
  let Hb = projection(B, A, C)
  
  // 3. The Orthocenter is the intersection of altitudes AH_a and BH_b
  return inter-LL(A, Ha, B, Hb)
}


// Perpendicular Bisector of AB (return 2 points defining the line)
#let perp-bisector(A, B, length: 1) = {
  let p1 = parse(A)
  let p2 = parse(B)
  
  // 1. Find the midpoint
  let mid = div(add(p1, p2), 2)
  
  // 2. Get the vector AB and its perpendicular (-dy, dx)
  let v = sub(p2, p1)
  let perp = (-v.at(1), v.at(0))
  
  // 3. Normalize the perpendicular vector
  let d = vec.len(perp)
  if d < 1e-9 { return (mid, mid) }
  let unit_perp = div(perp, d)
  
  // 4. Return two points extending from the midpoint
  let start = add(mid, mul(unit_perp, length))
  let end = sub(mid, mul(unit_perp, length))
  
  return (start, end)
}


// Circumcenter
#let circumcenter(A, B, C) = {
  // 1. Get two points on the bisector of AB
  let (p1, p2) = perp-bisector(A, B)
  // 2. Get two points on the bisector of BC
  let (p3, p4) = perp-bisector(B, C)
  
  // 3. The intersection is the circumcenter
  return inter-LL(p1, p2, p3, p4)
}


// Circumradius
#let circumradius(A, B, C) = {
  // 1. Find the circumcenter first
  let O = circumcenter(A, B, C)
  
  // 2. The radius is the distance from the center to any vertex
  return dist(O, A)
}


// Returns point P such that PA is perpendicular to BC and dist(P, A) = length
#let perp-through(A, B, C, length: 1) = {
  let pA = parse(A)
  let pB = parse(B)
  let pC = parse(C)

  // 1. Get the direction vector of the base line BC
  let v = sub(pC, pB)
  let d = dist(pB, pC)

  // 2. Safety: handle zero-length base line
  if d < 1e-9 { return add(pA, (0, length)) }

  // 3. Rotate the vector 90° CCW: (dx, dy) -> (-dy, dx)
  let perp = (-(v.at(1)), v.at(0))
  
  // 4. Normalize and scale to the target length in one step
  return add(pA, mul(perp, length / d))
}

// Returns point P such that PA is parallel to BC and dist(P, A) = length
#let parallel-through(A, B, C, length: 1) = {
  let pA = parse(A)
  let pB = parse(B)
  let pC = parse(C)

  // 1. Get the direction vector of the base line BC
  let v = sub(pC, pB)
  let d = dist(pB, pC)

  // 2. Safety: handle zero-length base line
  if d < 1e-9 { return add(pA, (length, 0)) }

  // 3. Normalize and scale the direction vector BC to the target length
  return add(pA, mul(v, length / d))
}


// Returns (T1, T2) representing the two tangent points from P to circle(O, R)
// R can be a numeric radius or a point on the circumference
#let tangent-points(P, O, R) = {
  let p_p = parse(P)
  let p_o = parse(O)
  let r = _get-radius(p_o, R)
  
  // 1. Calculate distance from the external point to the center
  let d = dist(p_p, p_o)
  
  // 2. Safety: If P is inside the circle, no tangents can be drawn
  if d < r - 1e-9 { return none }
  
  // 3. Special Case: If P is exactly on the circle, return P twice
  if calc.abs(d - r) < 1e-9 { return (p_p, p_p) }
  
  // 4. Calculate distance from P to the tangent points using Pythagoras
  // The radius is perpendicular to the tangent line at the point of contact
  let l = calc.sqrt(calc.pow(d, 2) - calc.pow(r, 2))
  
  // 5. The tangent points are the intersection of:
  //    Circle A: center O, radius r
  //    Circle B: center P, radius l
  return inter-CC(p_o, r, p_p, l)
}


// Returns ((A1, B1), (A2, B2)) for external tangents between circles
// A1, A2 are on Circle 1; B1, B2 are on Circle 2
#let external-tangents(O1, R1, O2, R2) = {
  let p1 = parse(O1)
  let p2 = parse(O2)
  let r1 = _get-radius(p1, R1)
  let r2 = _get-radius(p2, R2)
  let d = dist(p1, p2)
  
  // 1. Safety: check if one circle is inside the other
  if d <= calc.abs(r1 - r2) or d < 1e-9 { return none }
  
  // 2. Case: Equal radii (tangents are parallel to the center line)
  if calc.abs(r1 - r2) < 1e-9 {
    let p_unit = div(sub(p2, p1), d)
    let n = (-(p_unit.at(1)), p_unit.at(0)) // Perpendicular unit vector
    
    return (
      (add(p1, mul(n, r1)), add(p2, mul(n, r1))),
      (sub(p1, mul(n, r1)), sub(p2, mul(n, r1)))
    )
  }
  
  // 3. Case: Different radii. Find external center of homothety H
  // H = (r1*P2 - r2*P1) / (r1 - r2)
  let h = div(sub(mul(p2, r1), mul(p1, r2)), r1 - r2)
  
  // 4. Find tangent points from H to both circles
  let (A1, A2) = tangent-points(h, p1, r1)
  let (B1, B2) = tangent-points(h, p2, r2)
  
  return ((A1, B1), (A2, B2))
}

// Returns ((A1, B1), (A2, B2)) for internal tangents between circles
// A1, A2 are on Circle 1; B1, B2 are on Circle 2
#let internal-tangents(O1, R1, O2, R2) = {
  let p1 = parse(O1)
  let p2 = parse(O2)
  let r1 = _get-radius(p1, R1)
  let r2 = _get-radius(p2, R2)
  let d = dist(p1, p2)
  
  // 1. Safety: internal tangents only exist if circles do not overlap
  if d < (r1 + r2) { return none }
  
  // 2. Find internal center of homothety H (lies between the circles)
  // H = (r2*P1 + r1*P2) / (r1 + r2)
  let h = div(add(mul(p1, r2), mul(p2, r1)), r1 + r2)
  
  // 3. Find tangent points from H to both circles
  let (A1, A2) = tangent-points(h, p1, r1)
  let (B1, B2) = tangent-points(h, p2, r2)
  
  // 4. For internal tangents, the image is inverted through H.
  // A1 pairs with B2 and A2 pairs with B1 to form the "X" shape.
  return ((A1, B2), (A2, B1))
}


// Returns a point on a circle at a given angle
// R: numeric radius or a point on the circumference
// rel: if true and R is a point, angle is relative to the direction OR
#let point-on-circle(O, R, angle, rel: false) = {
  let p_o = parse(O)
  let r = _get-radius(p_o, R)
  
  // 1. Determine the starting (base) angle
  let base_angle = 0deg
  if rel and type(R) != float and type(R) != int {
    let p_r = parse(R)
    let v = sub(p_r, p_o)
    // calc.atan2(y, x) returns the angle of the vector
    base_angle = calc.atan2(v.at(0), v.at(1))
  }

  // 2. Calculate final angle in radians
  let total_angle = base_angle + angle * 1deg

  // 3. Calculate the offset from center O
  let offset = (
    r * calc.cos(total_angle),
    r * calc.sin(total_angle)
  )

  return add(p_o, offset)
}


// ==================================================
// Draw
// ==================================================


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


// ==================================================
// Mark
// ==================================================


// Draws a square "hook" at vertex B to indicate a 90-degree angle.
// A and C are points on the legs, B is the vertex.
#let mark-right-angle(A, B, C, size: 0.2, z-level: -2, 
  stroke: (thickness: 0.5pt, paint: fuchsia), 
  fill: fuchsia.lighten(80%), ..style) = {
  
  let p_a = parse(A)
  let p_b = parse(B)
  let p_c = parse(C)

  // Unit vectors to ensure the mark remains a perfect square
  let v_ba = div(sub(p_a, p_b), dist(p_a, p_b))
  let v_bc = div(sub(p_c, p_b), dist(p_c, p_b))
  
  let p1 = add(p_b, mul(v_ba, size))         
  let p3 = add(p_b, mul(v_bc, size))         
  let p2 = add(p1, mul(v_bc, size))          

  draw.on-layer(z-level, {
    // Fill the square (p1-p2-p3-B)
    if fill != none {
      draw.line(p1, p2, p3, p_b, close: true, stroke: none, fill: fill)
    }

    // Draw the "hook" (p1-p2-p3) using the default stroke
    draw.line(p1, p2, p3, stroke: stroke, ..style)
  })
}


// Draws one or more circular arcs centered at vertex B to mark an angle.
// Supports inner/reflex angles, multiple arc counts, and fills.
#let mark-angle(A, B, C, radius: 0.3, count: 1, spacing: 0.05, reflex: false, z-level: -2, 
  stroke: (thickness: 0.5pt, paint: red),
  fill: red.lighten(80%), ..style) = {
  
  let p_a = parse(A)
  let p_b = parse(B)
  let p_c = parse(C)

  let v_ba = sub(p_a, p_b)
  let v_bc = sub(p_c, p_b)
  
  let ang_a = calc.atan2(v_ba.at(0), v_ba.at(1))
  let ang_c = calc.atan2(v_bc.at(0), v_bc.at(1))

  let diff = ang_a - ang_c
  if diff > 180deg { diff -= 360deg }
  if diff < -180deg { diff += 360deg }
  
  if reflex {
    if diff > 0deg { diff -= 360deg }
    else { diff += 360deg }
  }
  
  let final_stop = ang_c + diff

  draw.on-layer(z-level, {
    let fill_radius = radius + (count - 1) * spacing

    // Use "PIE" mode for the wedge fill
    if fill != none {
      draw.arc(p_b, start: ang_c, stop: final_stop, radius: fill_radius, 
               anchor: "origin", mode: "PIE", stroke: none, fill: fill)
    }
    
    // Draw the arcs
    for i in range(count) {
      let r = radius + (i * spacing)
      draw.arc(p_b, start: ang_c, stop: final_stop, radius: r, anchor: "origin", stroke: stroke, ..style)
    }
  })
}


// Draws tick marks on segment AB to show they are congruent.
// Ticks are centered on the midpoint of the segment.
#let mark-segment(A, B, count: 1, size: 0.13, spacing: 0.05, z-level: 9, 
  stroke: (thickness: 0.5pt), ..style) = {
  let p_a = parse(A)
  let p_b = parse(B)
  
  // 1. Find the midpoint of the segment
  let mid = point-ratio(p_a, p_b, 1) 
  
  draw.on-layer(z-level, {
    for i in range(count) {
      // Offset the ticks so the group is centered on the midpoint
      let offset_val = (i - (count - 1) / 2) * spacing
      let tick_center = point-on-line(p_a, p_b, dist(p_a, mid) + offset_val)
      
      // Calculate perpendicular endpoints for the tick
      let p1 = perp-through(tick_center, p_a, p_b, length: size / 2)
      let p2 = perp-through(tick_center, p_b, p_a, length: size / 2)
      
      draw.line(p1, p2, stroke: stroke, ..style)
    }
  })
}


// Draws arrow (chevron) marks on segment AB to show they are parallel.
// Arrows point from A towards B.
#let mark-parallel(A, B, count: 1, size: 0.1, spacing: 0.12, z-level: 9, 
  stroke: (thickness: 0.5pt), ..style) = {
  let p_a = parse(A)
  let p_b = parse(B)
  
  // 1. Get direction and perpendicular vectors
  let v = sub(p_b, p_a)
  let d = dist(p_a, p_b)
  let unit = div(v, d)
  let perp = (-unit.at(1), unit.at(0))
  
  draw.on-layer(z-level, {
    for i in range(count) {
      // Center the group of arrows on the midpoint
      let offset_val = (i - (count - 1) / 2) * spacing
      let tip = point-on-line(p_a, p_b, d/2 + offset_val)
      
      // Calculate "wings" of the chevron relative to the line direction
      let wing_back = mul(unit, size)
      let wing_out = mul(perp, size * 0.8) 
      
      let p1 = add(sub(tip, wing_back), wing_out)
      let p2 = add(sub(tip, wing_back), mul(wing_out, -1))
      
      // Draw chevron path (wing1 -> tip -> wing2)
      draw.line(p1, tip, p2, stroke: stroke, ..style)
    }
  })
}


// ==================================================
// Label
// ==================================================


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
