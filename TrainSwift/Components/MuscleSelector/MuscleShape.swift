//
//  MuscleShape.swift
//  TrainSwift
//
//  SVG path parser and SwiftUI Shape for rendering muscle paths
//

import SwiftUI

// MARK: - SVG Path Shape

struct SVGPath: Shape {
    let svgPath: String

    func path(in rect: CGRect) -> Path {
        SVGPathParser.parse(svgPath)
    }
}

// MARK: - SVG Path Parser

enum SVGPathParser {
    static func parse(_ pathString: String) -> Path {
        var path = Path()
        let commands = tokenize(pathString)
        var currentPoint = CGPoint.zero
        var startPoint = CGPoint.zero
        var lastControlPoint: CGPoint?
        var lastCommand: Character?
        var isFirstCommand = true

        var i = 0
        while i < commands.count {
            let command = commands[i]
            guard let firstChar = command.first, firstChar.isLetter else {
                i += 1
                continue
            }

            let isRelative = firstChar.isLowercase
            let cmd = firstChar.uppercased().first!

            i += 1
            var numbers: [CGFloat] = []

            // Collect all numbers that follow this command
            while i < commands.count {
                if let num = Double(commands[i]) {
                    numbers.append(CGFloat(num))
                    i += 1
                } else {
                    break
                }
            }

            switch cmd {
            case "M": // Move to
                var j = 0
                while j + 1 < numbers.count {
                    var x = numbers[j]
                    var y = numbers[j + 1]
                    // SVG spec: first coordinate pair of 'm' is absolute from origin
                    // Subsequent pairs are relative to the first point
                    if isRelative && j > 0 {
                        x += currentPoint.x
                        y += currentPoint.y
                    } else if isRelative && !isFirstCommand {
                        x += currentPoint.x
                        y += currentPoint.y
                    }
                    if j == 0 {
                        path.move(to: CGPoint(x: x, y: y))
                        startPoint = CGPoint(x: x, y: y)
                    } else {
                        path.addLine(to: CGPoint(x: x, y: y))
                    }
                    currentPoint = CGPoint(x: x, y: y)
                    isFirstCommand = false
                    j += 2
                }

            case "L": // Line to
                var j = 0
                while j + 1 < numbers.count {
                    var x = numbers[j]
                    var y = numbers[j + 1]
                    if isRelative {
                        x += currentPoint.x
                        y += currentPoint.y
                    }
                    path.addLine(to: CGPoint(x: x, y: y))
                    currentPoint = CGPoint(x: x, y: y)
                    j += 2
                }

            case "H": // Horizontal line to
                for num in numbers {
                    var x = num
                    if isRelative {
                        x += currentPoint.x
                    }
                    path.addLine(to: CGPoint(x: x, y: currentPoint.y))
                    currentPoint.x = x
                }

            case "V": // Vertical line to
                for num in numbers {
                    var y = num
                    if isRelative {
                        y += currentPoint.y
                    }
                    path.addLine(to: CGPoint(x: currentPoint.x, y: y))
                    currentPoint.y = y
                }

            case "C": // Cubic bezier
                var j = 0
                while j + 5 < numbers.count {
                    var x1 = numbers[j]
                    var y1 = numbers[j + 1]
                    var x2 = numbers[j + 2]
                    var y2 = numbers[j + 3]
                    var x = numbers[j + 4]
                    var y = numbers[j + 5]
                    if isRelative {
                        x1 += currentPoint.x
                        y1 += currentPoint.y
                        x2 += currentPoint.x
                        y2 += currentPoint.y
                        x += currentPoint.x
                        y += currentPoint.y
                    }
                    path.addCurve(
                        to: CGPoint(x: x, y: y),
                        control1: CGPoint(x: x1, y: y1),
                        control2: CGPoint(x: x2, y: y2)
                    )
                    lastControlPoint = CGPoint(x: x2, y: y2)
                    currentPoint = CGPoint(x: x, y: y)
                    j += 6
                }

            case "S": // Smooth cubic bezier
                var j = 0
                while j + 3 < numbers.count {
                    var x2 = numbers[j]
                    var y2 = numbers[j + 1]
                    var x = numbers[j + 2]
                    var y = numbers[j + 3]
                    if isRelative {
                        x2 += currentPoint.x
                        y2 += currentPoint.y
                        x += currentPoint.x
                        y += currentPoint.y
                    }
                    // Calculate control point 1 as reflection of last control point
                    let x1: CGFloat
                    let y1: CGFloat
                    if let lastCP = lastControlPoint, lastCommand == "C" || lastCommand == "c" || lastCommand == "S" || lastCommand == "s" {
                        x1 = 2 * currentPoint.x - lastCP.x
                        y1 = 2 * currentPoint.y - lastCP.y
                    } else {
                        x1 = currentPoint.x
                        y1 = currentPoint.y
                    }
                    path.addCurve(
                        to: CGPoint(x: x, y: y),
                        control1: CGPoint(x: x1, y: y1),
                        control2: CGPoint(x: x2, y: y2)
                    )
                    lastControlPoint = CGPoint(x: x2, y: y2)
                    currentPoint = CGPoint(x: x, y: y)
                    j += 4
                }

            case "Q": // Quadratic bezier
                var j = 0
                while j + 3 < numbers.count {
                    var x1 = numbers[j]
                    var y1 = numbers[j + 1]
                    var x = numbers[j + 2]
                    var y = numbers[j + 3]
                    if isRelative {
                        x1 += currentPoint.x
                        y1 += currentPoint.y
                        x += currentPoint.x
                        y += currentPoint.y
                    }
                    path.addQuadCurve(
                        to: CGPoint(x: x, y: y),
                        control: CGPoint(x: x1, y: y1)
                    )
                    lastControlPoint = CGPoint(x: x1, y: y1)
                    currentPoint = CGPoint(x: x, y: y)
                    j += 4
                }

            case "T": // Smooth quadratic bezier
                var j = 0
                while j + 1 < numbers.count {
                    var x = numbers[j]
                    var y = numbers[j + 1]
                    if isRelative {
                        x += currentPoint.x
                        y += currentPoint.y
                    }
                    // Calculate control point as reflection of last control point
                    let controlX: CGFloat
                    let controlY: CGFloat
                    if let lastCP = lastControlPoint, lastCommand == "Q" || lastCommand == "q" || lastCommand == "T" || lastCommand == "t" {
                        controlX = 2 * currentPoint.x - lastCP.x
                        controlY = 2 * currentPoint.y - lastCP.y
                    } else {
                        controlX = currentPoint.x
                        controlY = currentPoint.y
                    }
                    path.addQuadCurve(
                        to: CGPoint(x: x, y: y),
                        control: CGPoint(x: controlX, y: controlY)
                    )
                    lastControlPoint = CGPoint(x: controlX, y: controlY)
                    currentPoint = CGPoint(x: x, y: y)
                    j += 2
                }

            case "A": // Arc
                var j = 0
                while j + 6 < numbers.count {
                    let rx = numbers[j]
                    let ry = numbers[j + 1]
                    let rotation = numbers[j + 2]
                    let largeArc = numbers[j + 3] != 0
                    let sweep = numbers[j + 4] != 0
                    var x = numbers[j + 5]
                    var y = numbers[j + 6]
                    if isRelative {
                        x += currentPoint.x
                        y += currentPoint.y
                    }
                    addArc(
                        to: &path,
                        from: currentPoint,
                        to: CGPoint(x: x, y: y),
                        rx: rx,
                        ry: ry,
                        rotation: rotation,
                        largeArc: largeArc,
                        sweep: sweep
                    )
                    currentPoint = CGPoint(x: x, y: y)
                    j += 7
                }

            case "Z": // Close path
                path.closeSubpath()
                currentPoint = startPoint

            default:
                break
            }

            lastCommand = firstChar
        }

        return path
    }

    private static func tokenize(_ pathString: String) -> [String] {
        var tokens: [String] = []
        var currentToken = ""
        var lastWasDigit = false

        for char in pathString {
            if char.isLetter {
                if !currentToken.isEmpty {
                    tokens.append(currentToken)
                    currentToken = ""
                }
                tokens.append(String(char))
                lastWasDigit = false
            } else if char == "-" || char == "+" {
                // Handle negative numbers and separate positive numbers
                if !currentToken.isEmpty && lastWasDigit {
                    tokens.append(currentToken)
                    currentToken = ""
                }
                currentToken.append(char)
                lastWasDigit = false
            } else if char.isNumber || char == "." {
                // Handle numbers with multiple decimal points (e.g., "1.2.3" -> "1.2", ".3")
                if char == "." && currentToken.contains(".") {
                    tokens.append(currentToken)
                    currentToken = ""
                }
                currentToken.append(char)
                lastWasDigit = true
            } else if char == "," || char.isWhitespace {
                if !currentToken.isEmpty {
                    tokens.append(currentToken)
                    currentToken = ""
                }
                lastWasDigit = false
            }
        }

        if !currentToken.isEmpty {
            tokens.append(currentToken)
        }

        return tokens
    }

    private static func addArc(
        to path: inout Path,
        from start: CGPoint,
        to end: CGPoint,
        rx: CGFloat,
        ry: CGFloat,
        rotation: CGFloat,
        largeArc: Bool,
        sweep: Bool
    ) {
        // Simplified arc implementation - just draw a line for very small arcs
        if rx < 0.01 || ry < 0.01 {
            path.addLine(to: end)
            return
        }

        // Convert endpoint arc to center arc
        let phi = rotation * .pi / 180
        let cosPhi = cos(phi)
        let sinPhi = sin(phi)

        let dx = (start.x - end.x) / 2
        let dy = (start.y - end.y) / 2

        let x1p = cosPhi * dx + sinPhi * dy
        let y1p = -sinPhi * dx + cosPhi * dy

        var rxSq = rx * rx
        var rySq = ry * ry
        let x1pSq = x1p * x1p
        let y1pSq = y1p * y1p

        // Check if radii are large enough
        let lambda = x1pSq / rxSq + y1pSq / rySq
        var rxNew = rx
        var ryNew = ry
        if lambda > 1 {
            let sqrtLambda = sqrt(lambda)
            rxNew = sqrtLambda * rx
            ryNew = sqrtLambda * ry
            rxSq = rxNew * rxNew
            rySq = ryNew * ryNew
        }

        let sq = max(0, (rxSq * rySq - rxSq * y1pSq - rySq * x1pSq) / (rxSq * y1pSq + rySq * x1pSq))
        let sqSign: CGFloat = (largeArc == sweep) ? -1 : 1
        let coef = sqSign * sqrt(sq)

        let cxp = coef * rxNew * y1p / ryNew
        let cyp = -coef * ryNew * x1p / rxNew

        let cx = cosPhi * cxp - sinPhi * cyp + (start.x + end.x) / 2
        let cy = sinPhi * cxp + cosPhi * cyp + (start.y + end.y) / 2

        // Calculate start and end angles
        func angle(ux: CGFloat, uy: CGFloat, vx: CGFloat, vy: CGFloat) -> CGFloat {
            let n = sqrt(ux * ux + uy * uy) * sqrt(vx * vx + vy * vy)
            if n == 0 { return 0 }
            let c = (ux * vx + uy * vy) / n
            let s = ux * vy - uy * vx
            return atan2(s, max(-1, min(1, c)))
        }

        let theta1 = angle(ux: 1, uy: 0, vx: (x1p - cxp) / rxNew, vy: (y1p - cyp) / ryNew)
        var dtheta = angle(
            ux: (x1p - cxp) / rxNew,
            uy: (y1p - cyp) / ryNew,
            vx: (-x1p - cxp) / rxNew,
            vy: (-y1p - cyp) / ryNew
        )

        if !sweep && dtheta > 0 {
            dtheta -= 2 * .pi
        } else if sweep && dtheta < 0 {
            dtheta += 2 * .pi
        }

        // Use ellipse approximation with bezier curves
        let segments = max(1, Int(abs(dtheta) / (.pi / 4)))
        let segmentAngle = dtheta / CGFloat(segments)

        var currentAngle = theta1
        for _ in 0..<segments {
            let nextAngle = currentAngle + segmentAngle
            addArcSegment(
                to: &path,
                cx: cx,
                cy: cy,
                rx: rxNew,
                ry: ryNew,
                phi: phi,
                startAngle: currentAngle,
                endAngle: nextAngle
            )
            currentAngle = nextAngle
        }
    }

    private static func addArcSegment(
        to path: inout Path,
        cx: CGFloat,
        cy: CGFloat,
        rx: CGFloat,
        ry: CGFloat,
        phi: CGFloat,
        startAngle: CGFloat,
        endAngle: CGFloat
    ) {
        let alpha = sin(endAngle - startAngle) * (sqrt(4 + 3 * pow(tan((endAngle - startAngle) / 2), 2)) - 1) / 3

        let cosPhi = cos(phi)
        let sinPhi = sin(phi)

        func point(at angle: CGFloat) -> CGPoint {
            let cosAngle = cos(angle)
            let sinAngle = sin(angle)
            let x = cx + rx * cosAngle * cosPhi - ry * sinAngle * sinPhi
            let y = cy + rx * cosAngle * sinPhi + ry * sinAngle * cosPhi
            return CGPoint(x: x, y: y)
        }

        func derivative(at angle: CGFloat) -> CGPoint {
            let cosAngle = cos(angle)
            let sinAngle = sin(angle)
            let dx = -rx * sinAngle * cosPhi - ry * cosAngle * sinPhi
            let dy = -rx * sinAngle * sinPhi + ry * cosAngle * cosPhi
            return CGPoint(x: dx, y: dy)
        }

        let p1 = point(at: startAngle)
        let p2 = point(at: endAngle)
        let d1 = derivative(at: startAngle)
        let d2 = derivative(at: endAngle)

        let c1 = CGPoint(x: p1.x + alpha * d1.x, y: p1.y + alpha * d1.y)
        let c2 = CGPoint(x: p2.x - alpha * d2.x, y: p2.y - alpha * d2.y)

        path.addCurve(to: p2, control1: c1, control2: c2)
    }
}

// MARK: - Muscle Path View

struct MusclePathView: View {
    let paths: [String]
    let fillColor: Color
    let strokeColor: Color
    let strokeWidth: CGFloat
    let isSelected: Bool
    let onTap: () -> Void

    init(
        paths: [String],
        fillColor: Color = Color.trainMuscleDefault,
        strokeColor: Color = .clear,
        strokeWidth: CGFloat = 0,
        isSelected: Bool = false,
        onTap: @escaping () -> Void = {}
    ) {
        self.paths = paths
        self.fillColor = fillColor
        self.strokeColor = strokeColor
        self.strokeWidth = strokeWidth
        self.isSelected = isSelected
        self.onTap = onTap
    }

    var body: some View {
        ZStack {
            ForEach(paths.indices, id: \.self) { index in
                // Each path is individually tappable with its actual shape as the hit area
                SVGPath(svgPath: paths[index])
                    .fill(isSelected ? Color.trainPrimary : fillColor)
                    .overlay(
                        SVGPath(svgPath: paths[index])
                            .stroke(strokeColor, lineWidth: strokeWidth)
                    )
                    .contentShape(SVGPath(svgPath: paths[index]))
                    .onTapGesture {
                        onTap()
                    }
            }
        }
    }
}
