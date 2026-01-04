#import "@preview/cetz:0.4.2"

#let (draw, vec) = (cetz.draw, cetz.vector)


#let dot(pt, radius: 0.05, fill: black, stroke: none, name: none) = {
  // Check if pt is a single point (array) or a string (anchor name)
  let is_single = if type(pt) == str {
    true
  } else if type(pt) == array and pt.len() > 0 {
    // Check if it's a coordinate (number, number)
    type(pt.at(0)) in (int, float, length)
  } else {
    false
  }

  let points = if is_single { (pt,) } else { pt }

  for p in points {
    draw.circle(p, radius: radius, fill: fill, stroke: stroke, name: name)
  }
}


#let segment(p1, p2, extend: (0, 0), ..args) = {
  // If either point is a string, we can't calculate 'unit_d' easily 
  // because we don't know the coordinates yet.
  if type(p1) == str or type(p2) == str {
    draw.line(p1, p2, ..args) // Fallback to standard line
  } else {
    // ... your existing normalization logic for numeric coordinates ...
    let d = vec.sub(p2, p1)
    let len = vec.len(d)
    let unit_d = if len != 0 { vec.scale(d, 1/len) } else { (0, 0) }
    let (e1, e2) = if type(extend) != array { (extend, extend) } else { extend }
    draw.line(vec.add(p1, vec.scale(unit_d, -e1)), vec.add(p2, vec.scale(unit_d, e2)), ..args)
  }
}


#let xline(p1, p2, scale: 100, ..args) = {
  // 1. Get direction and length
  let d = vec.sub(p2, p1)
  let len = vec.len(d)
  
  // 2. Normalize (Unit Vector)
  let unit_d = if len != 0 { vec.scale(d, 1/len) } else { (0, 0) }
  
  // 3. Extend from p1 and p2 by 'scale' units
  // We go "backwards" from p1 and "forwards" from p2
  let far_p1 = vec.add(p1, vec.scale(unit_d, -scale))
  let far_p2 = vec.add(p2, vec.scale(unit_d, scale))

  draw.hide(
    draw.line(far_p1, far_p2, ..args)
  )
}


// Line-Line Intersection (Returns a single point or none)
#let iLL(A, B, C, D) = {
  let (x1, y1) = A
  let (x2, y2) = B
  let (x3, y3) = C
  let (x4, y4) = D
  
  let den = (x1 - x2) * (y3 - y4) - (y1 - y2) * (x3 - x4)
  if calc.abs(den) < 1e-9 { return none } 
  
  // The determinants
  let d12 = x1*y2 - y1*x2
  let d34 = x3*y4 - y3*x4
  
  let px = (d12 * (x3 - x4) - (x1 - x2) * d34) / den
  let py = (d12 * (y3 - y4) - (y1 - y2) * d34) / den
  
  (px, py)
}


// Line-Circle Intersection (Returns an array of 0, 1, or 2 points)
#let iLC(A, B, O, r) = {
  let (x1, y1) = vec.sub(A, O)
  let (x2, y2) = vec.sub(B, O)
  let dx = x2 - x1
  let dy = y2 - y1
  let dr2 = calc.pow(dx, 2) + calc.pow(dy, 2)
  let D = x1 * y2 - x2 * y1
  let disc = calc.pow(r, 2) * dr2 - calc.pow(D, 2)
  
  if disc < 0 { return () }
  
  let sgn_dy = if dy < 0 { -1 } else { 1 }
  let x_part1 = D * dy
  let x_part2 = sgn_dy * dx * calc.sqrt(disc)
  let y_part1 = -D * dx
  let y_part2 = calc.abs(dy) * calc.sqrt(disc)
  
  let p1 = vec.add(O, ((x_part1 + x_part2)/dr2, (y_part1 + y_part2)/dr2))
  let p2 = vec.add(O, ((x_part1 - x_part2)/dr2, (y_part1 - y_part2)/dr2))
  
  if disc == 0 { (p1,) } else { (p1, p2) }
}


#let iCC(O1, r1, O2, r2) = {
  let d = vec.len(vec.sub(O2, O1))
  
  // No intersection or one circle inside another
  if d > r1 + r2 or d < calc.abs(r1 - r2) or d == 0 { return () }
  
  let a = (calc.pow(r1, 2) - calc.pow(r2, 2) + calc.pow(d, 2)) / (2 * d)
  let h = calc.sqrt(calc.max(0, calc.pow(r1, 2) - calc.pow(a, 2)))
  
  // Find point P2 which is the point on the line O1-O2
  let p2 = vec.add(O1, vec.scale(vec.sub(O2, O1), a / d))
  
  // The two intersection points
  let x3 = p2.at(0) + h * (O2.at(1) - O1.at(1)) / d
  let y3 = p2.at(1) - h * (O2.at(0) - O1.at(0)) / d
  
  let x4 = p2.at(0) - h * (O2.at(1) - O1.at(1)) / d
  let y4 = p2.at(1) + h * (O2.at(0) - O1.at(0)) / d
  
  if h == 0 { ((x3, y3),) } else { ((x3, y3), (x4, y4)) }
}