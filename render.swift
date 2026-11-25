import AppKit
import AVFoundation
import CoreVideo
import CoreGraphics

let W = 1920
let H = 1080
let BASE_W = 1280
let BASE_H = 720
let FPS: Int32 = 24
let TITLE_SECONDS = 5.0
let SCENE_DURATIONS: [Double] = [42.60, 66.52, 47.56, 45.24, 53.16, 46.44]
let SCENE_STARTS = SCENE_DURATIONS.enumerated().map { index, _ in
    SCENE_DURATIONS.prefix(index).reduce(0.0, +)
}
let TOTAL = TITLE_SECONDS + SCENE_DURATIONS.reduce(0.0, +)
let OUT = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "Derivative_Animation.mp4"
let PREVIEW_START = CommandLine.arguments.count > 2 ? (Double(CommandLine.arguments[2]) ?? 0) : 0
let PREVIEW_LENGTH = CommandLine.arguments.count > 3 ? (Double(CommandLine.arguments[3]) ?? TOTAL) : TOTAL

let bg = NSColor(calibratedRed: 0.035, green: 0.055, blue: 0.10, alpha: 1)
let panel = NSColor(calibratedRed: 0.075, green: 0.10, blue: 0.16, alpha: 1)
let white = NSColor(calibratedRed: 0.94, green: 0.96, blue: 1, alpha: 1)
let muted = NSColor(calibratedRed: 0.64, green: 0.70, blue: 0.80, alpha: 1)
let cyan = NSColor(calibratedRed: 0.25, green: 0.83, blue: 0.94, alpha: 1)
let coral = NSColor(calibratedRed: 1, green: 0.44, blue: 0.38, alpha: 1)
let yellow = NSColor(calibratedRed: 1, green: 0.78, blue: 0.31, alpha: 1)
let green = NSColor(calibratedRed: 0.43, green: 0.84, blue: 0.63, alpha: 1)

struct Scene {
    let title: String
    let kicker: String
    let caption: String
    let formula: String
}

let scenes = [
    Scene(title: "A SLOPE AT ONE INSTANT?", kicker: "THE QUESTION", caption: "Average speed is easy. What about one exact moment?", formula: "distance ÷ time"),
    Scene(title: "MEET THE PARABOLA", kicker: "THE FUNCTION", caption: "We will study f of x equals x squared.", formula: "f(x) = x²"),
    Scene(title: "TWO POINTS MAKE A SECANT", kicker: "VISUAL INTUITION", caption: "The secant slope measures change across an interval.", formula: "m = [f(1+h) − f(1)] / h"),
    Scene(title: "WORK THE SECANT SLOPE", kicker: "THE DERIVATION", caption: "Expand, cancel h, then test nearby values.", formula: "m = 2 + h  →  2"),
    Scene(title: "THE TANGENT SLOPE IS 2", kicker: "THE DERIVATIVE", caption: "At x = 1, the instantaneous rate of change is 2.", formula: "f′(1) = 2"),
    Scene(title: "A DERIVATIVE IS A RATE", kicker: "RECAP", caption: "Change over an interval becomes change at an instant.", formula: "f′(x) = limₕ→₀ [f(x+h) − f(x)] / h")
]

func color(_ c: NSColor, _ a: CGFloat = 1) -> CGColor { c.withAlphaComponent(a).cgColor }
func font(_ size: CGFloat, _ weight: NSFont.Weight = .regular) -> NSFont { NSFont.systemFont(ofSize: size, weight: weight) }

func text(_ value: String, _ x: CGFloat, _ y: CGFloat, _ size: CGFloat, _ c: NSColor = white, _ weight: NSFont.Weight = .regular, _ width: CGFloat = 600, _ align: NSTextAlignment = .left) {
    let para = NSMutableParagraphStyle(); para.alignment = align; para.lineBreakMode = .byWordWrapping
    let attrs: [NSAttributedString.Key: Any] = [.font: font(size, weight), .foregroundColor: c, .paragraphStyle: para]
    (value as NSString).draw(in: CGRect(x: x, y: y, width: width, height: size * 2.8), withAttributes: attrs)
}

func rounded(_ ctx: CGContext, _ r: CGRect, _ radius: CGFloat, _ c: NSColor) {
    ctx.setFillColor(color(c)); ctx.addPath(CGPath(roundedRect: r, cornerWidth: radius, cornerHeight: radius, transform: nil)); ctx.fillPath()
}

func line(_ ctx: CGContext, _ a: CGPoint, _ b: CGPoint, _ c: NSColor, _ width: CGFloat = 2, _ dash: [CGFloat] = []) {
    ctx.setStrokeColor(color(c)); ctx.setLineWidth(width); ctx.setLineDash(phase: 0, lengths: dash); ctx.move(to: a); ctx.addLine(to: b); ctx.strokePath(); ctx.setLineDash(phase: 0, lengths: [])
}

func dot(_ ctx: CGContext, _ p: CGPoint, _ radius: CGFloat, _ c: NSColor) {
    ctx.setFillColor(color(c)); ctx.fillEllipse(in: CGRect(x: p.x-radius, y: p.y-radius, width: 2*radius, height: 2*radius))
}

func arrow(_ ctx: CGContext, _ from: CGPoint, _ to: CGPoint, _ c: NSColor, _ width: CGFloat = 2) {
    line(ctx, from, to, c, width)
    let angle = atan2(to.y-from.y, to.x-from.x), size: CGFloat = 11
    for offset in [-0.48, 0.48] {
        let p = CGPoint(x: to.x-size*cos(angle+offset), y: to.y-size*sin(angle+offset))
        line(ctx, to, p, c, width)
    }
}

func drawAtmosphere(_ ctx: CGContext, _ t: Double, _ scene: Int) {
    ctx.saveGState()
    ctx.setFillColor(color(bg)); ctx.fill(CGRect(x:0,y:0,width:BASE_W,height:BASE_H))
    let accents = [cyan, coral, yellow, green, cyan, yellow]
    let accent = accents[max(0, min(5, scene))]
    for band in 0..<4 {
        let cx = CGFloat([190, 560, 930, 1240][band]) + CGFloat(50 * sin(t*0.23 + Double(band)))
        let cy = CGFloat([120, 600, 230, 530][band]) + CGFloat(42 * cos(t*0.18 + Double(band)*1.4))
        ctx.setFillColor(color([cyan, coral, yellow, green][band], 0.035))
        ctx.fillEllipse(in: CGRect(x:cx-260,y:cy-220,width:520,height:440))
    }
    for i in 0..<54 {
        let speed = Double(12 + (i % 7) * 5)
        let x = CGFloat((Double(i * 137) + t * speed).truncatingRemainder(dividingBy:1440)) - 80
        let y = CGFloat(60 + 570 * (0.5 + 0.5*sin(Double(i)*1.71 + t*(0.24 + Double(i%3)*0.08))))
        let radius = CGFloat(1.2 + Double(i%4)*0.5 + 0.7*sin(t*1.8 + Double(i)))
        dot(ctx, CGPoint(x:x,y:y), max(0.8,radius), NSColor(calibratedRed:0.35,green:0.84,blue:0.98,alpha:0.22))
    }
    for ring in 0..<5 {
        let phase = t*0.22 + Double(ring)*1.35
        let cx = CGFloat(170 + ring*235) + CGFloat(42*cos(phase))
        let cy = CGFloat(140 + (ring%2)*410) + CGFloat(24*sin(phase*1.3))
        let radius = CGFloat(16 + (Int(t*7 + Double(ring)*17) % 28))
        ctx.setStrokeColor(color(accent, 0.12)); ctx.setLineWidth(1.1)
        ctx.strokeEllipse(in: CGRect(x:cx-radius,y:cy-radius,width:2*radius,height:2*radius))
        dot(ctx, CGPoint(x:cx+radius*CGFloat(cos(phase*3)),y:cy+radius*CGFloat(sin(phase*3))), 3, accent.withAlphaComponent(0.55))
    }
    ctx.restoreGState()
}

func drawGraph(_ ctx: CGContext, _ time: Double, _ sceneIndex: Int) {
    let entrance = sceneIndex == 1 ? max(0, 1 - time/2.0) : 0
    let r = CGRect(x: 690 + CGFloat(entrance*100), y: 150, width: 520, height: 420)
    let left = r.minX + 58, right = r.maxX - 20, top = r.minY + 32, bottom = r.maxY - 45
    func P(_ x: Double, _ y: Double) -> CGPoint {
        CGPoint(x: left + CGFloat((x + 1.2) / 4.5) * (right-left), y: bottom - CGFloat(y / 8.5) * (bottom-top))
    }
    ctx.saveGState()
    ctx.clip(to: CGRect(x:left, y:top, width:right-left, height:bottom-top))
    var xTickLabels: [(String, CGFloat)] = []
    var yTickLabels: [(String, CGFloat)] = []
    for x in -1...3 {
        let p = P(Double(x), 0); line(ctx, CGPoint(x:p.x,y:top), CGPoint(x:p.x,y:bottom), muted, 0.7)
        xTickLabels.append(("\(x)", p.x))
    }
    for y in 0...8 where y % 2 == 0 {
        let p = P(0, Double(y)); line(ctx, CGPoint(x:left,y:p.y), CGPoint(x:right,y:p.y), muted, 0.7)
        if y > 0 { yTickLabels.append(("\(y)", p.y)) }
    }
    line(ctx, CGPoint(x:left,y:bottom), CGPoint(x:right,y:bottom), white, 1.5)
    line(ctx, CGPoint(x:left,y:P(0,0).y), CGPoint(x:right,y:P(0,0).y), white, 1.5)
    let curve = CGMutablePath()
    let drawAmount = sceneIndex == 1 ? min(1.0, max(0.04, time/22.0)) : 1.0
    let curveEnd = max(8, Int(220 * drawAmount))
    for i in 0...curveEnd {
        let x = -1.15 + 4.35 * Double(i) / Double(curveEnd), p = P(x, x*x)
        if i == 0 { curve.move(to:p) } else { curve.addLine(to:p) }
    }
    ctx.setStrokeColor(color(cyan)); ctx.setLineWidth(4); ctx.addPath(curve); ctx.strokePath()
    text("y = x²", 1032, 180, 20, cyan, .semibold, 130)
    let a = 1.0
    let phase = min(1.0, max(0.0, time / SCENE_DURATIONS[sceneIndex]))
    let local = 1.5 - 1.4 * phase
    let h: Double
    if sceneIndex == 2 { h = 2.25 - 2.15*phase }
    else if sceneIndex == 3 { h = local }
    else if sceneIndex >= 4 { h = 0.10 }
    else { h = 1.6 }
    let A = P(a, a*a), B = P(a+h, (a+h)*(a+h))
    let m = ((a+h)*(a+h) - a*a) / h
    let xLo = -0.2, xHi = 3.15
    let secA = P(xLo, 1 + m*(xLo-1)), secB = P(xHi, 1 + m*(xHi-1))
    if sceneIndex >= 2 {
        arrow(ctx, secA, secB, coral, 2.6)
        dot(ctx, A, 8 + 2*sin(time*5), yellow); dot(ctx, B, 7 + 2*sin(time*5+1), coral)
        text("A (1, 1)", A.x-82, A.y-24, 14, yellow, .medium, 90)
        if sceneIndex <= 3 { text("B", B.x+8, B.y-20, 14, coral, .semibold, 30) }
        if sceneIndex == 2 {
            let foot = P(1+h, 1)
            line(ctx, A, foot, yellow, 1.5, [5,4]); line(ctx, foot, B, yellow, 1.5, [5,4])
            text("Δx = h", foot.x-12, foot.y+8, 13, yellow, .medium, 70)
        }
        if sceneIndex == 3 {
            let d = P(1+h, 0); line(ctx, CGPoint(x:A.x,y:A.y), CGPoint(x:B.x,y:B.y), yellow, 1.4, [4,4])
            text(String(format:"h = %.2f", h), d.x+8, d.y-35, 15, yellow, .medium, 100)
        }
        if sceneIndex >= 4 {
            let T1 = P(xLo, 2*xLo-1), T2 = P(xHi, 2*xHi-1)
            line(ctx, T1, T2, green, 3)
            text("tangent", T2.x-86, T2.y-28, 15, green, .semibold, 90)
            let run = P(2, 1), rise = P(2, 3)
            line(ctx, A, run, yellow, 2); line(ctx, run, rise, yellow, 2)
            text("run 1", A.x+12, A.y+7, 13, yellow, .medium, 65)
            text("rise 2", run.x+8, rise.y+3, 13, yellow, .medium, 65)
        }
    }
    if sceneIndex == 1 {
        let x = -0.85 + 3.5*phase, point = P(x, x*x)
        let pulse = 8 + 3*sin(time*5)
        let tx1 = P(x-0.6, x*x-2*x*0.6), tx2 = P(x+0.6, x*x+2*x*0.6)
        line(ctx, tx1, tx2, green, 2, [7,5]); dot(ctx, point, pulse, yellow)
        text(String(format:"(%.1f, %.2f)", x, x*x), point.x+12, point.y-26, 15, yellow, .semibold, 110)
    }
    ctx.restoreGState()
    for (label, x) in xTickLabels { text(label, x-12, bottom+10, 13, muted, .regular, 30, .center) }
    for (label, y) in yTickLabels { text(label, left-26, y-8, 13, muted, .regular, 22, .right) }
    text("x", right-6, bottom+9, 15, white, .semibold, 20)
    text("y", left-26, top-10, 15, white, .semibold, 20)
}

func drawCar(_ ctx: CGContext, _ t: Double) {
    let roadY: CGFloat = 455
    let progress = min(1, max(0, t / 9.0))
    line(ctx, CGPoint(x:70,y:roadY+55), CGPoint(x:1210,y:roadY+55), muted, 3)
    line(ctx, CGPoint(x:70,y:roadY+63), CGPoint(x:1210,y:roadY+63), muted, 1, [12,10])
    for i in 0..<13 {
        let xMark = CGFloat((Double(i*120) - t*58).truncatingRemainder(dividingBy:1280))
        line(ctx, CGPoint(x:xMark,y:roadY+52), CGPoint(x:xMark+42,y:roadY+52), yellow.withAlphaComponent(0.70), 3)
    }
    for i in 0..<8 {
        let offset = CGFloat((Double(i*170) - t*42).truncatingRemainder(dividingBy:1500))
        let bx = CGFloat(1280) - offset
        let height = CGFloat(28 + (i%4)*13)
        rounded(ctx, CGRect(x:bx,y:roadY-height-18,width:26+CGFloat(i%3)*10,height:height), 5,
                NSColor(calibratedRed:0.17,green:0.30,blue:0.43,alpha:0.42))
        for w in 0..<2 { dot(ctx, CGPoint(x:bx+8+CGFloat(w*12),y:roadY-height-8), 1.4, yellow.withAlphaComponent(0.55)) }
    }
    let x = CGFloat(125 + 850 * progress)
    for i in 0..<4 {
        let tail = CGFloat(15 + i*24)
        line(ctx, CGPoint(x:x-tail,y:roadY+11+CGFloat(i%2)*10), CGPoint(x:x-7,y:roadY+11+CGFloat(i%2)*10), coral.withAlphaComponent(0.78), CGFloat(5-i/2))
    }
    rounded(ctx, CGRect(x:x,y:roadY,width:112,height:47), 15, coral)
    rounded(ctx, CGRect(x:x+20,y:roadY-23,width:65,height:30), 12, cyan)
    for wheelX in [x+25, x+87] {
        let center = CGPoint(x:wheelX,y:roadY+48)
        dot(ctx, center, 12, bg); dot(ctx, center, 4, cyan)
        let angle = t*8
        line(ctx, center, CGPoint(x:center.x+8*cos(angle),y:center.y+8*sin(angle)), white, 1.5)
        line(ctx, center, CGPoint(x:center.x+8*cos(angle+Double.pi/2),y:center.y+8*sin(angle+Double.pi/2)), white, 1.5)
    }
    let seconds = 3 * progress, metres = 60 * progress
    text(String(format:"TIME  %.1f / 3.0 s", seconds), 120, 555, 18, yellow, .semibold, 250)
    text(String(format:"DISTANCE  %.0f / 60 m", metres), 390, 555, 18, cyan, .semibold, 290)
    text("AVERAGE SPEED = 20 m/s", 770, 555, 19, white, .bold, 330)
    let gauge = CGPoint(x:1100,y:500)
    ctx.setStrokeColor(color(cyan,0.55)); ctx.setLineWidth(3)
    ctx.strokeEllipse(in: CGRect(x:gauge.x-48,y:gauge.y-48,width:96,height:96))
    for tick in 0...8 {
        let angle = Double.pi * (1.15 + Double(tick)*0.0875)
        let p1 = CGPoint(x:gauge.x+42*cos(angle),y:gauge.y+42*sin(angle))
        let p2 = CGPoint(x:gauge.x+35*cos(angle),y:gauge.y+35*sin(angle))
        line(ctx,p1,p2,yellow,2)
    }
    let needle = Double.pi * (1.15 + 0.7*progress)
    arrow(ctx,gauge,CGPoint(x:gauge.x+34*cos(needle),y:gauge.y+34*sin(needle)),coral,2.8)
    dot(ctx,gauge,5,white)
    text("20 m/s", 1065, 565, 15, yellow, .bold, 85, .center)
}

func drawOpeningCard(_ ctx: CGContext, _ t: Double) {
    drawAtmosphere(ctx,t,-1)
    text("M3 MATHEMATICS  /  ANIMATION PROJECT", 70, 46, 17, cyan, .semibold, 520)
    text("THE DERIVATIVE", 70, 125, 48, white, .bold, 620)
    text("AT ONE INSTANT", 70, 184, 48, white, .bold, 650)
    text("Concept: instantaneous rate of change", 72, 270, 23, yellow, .semibold, 620)
    text("How does a secant become a tangent?", 72, 310, 21, muted, .regular, 610)
    rounded(ctx, CGRect(x:70,y:390,width:630,height:150), 22, panel)
    text("STUDENT", 96, 414, 13, cyan, .bold, 150)
    text("Surya Pratap Singh Rathore", 96, 438, 21, white, .semibold, 540)
    text("URN  E25B070859", 96, 475, 17, muted, .medium, 260)
    text("BATCH  TURING     ·     LAB  LAMBDA", 96, 505, 16, yellow, .semibold, 560)

    let chart = CGRect(x:770,y:125,width:440,height:405)
    rounded(ctx, chart, 26, panel)
    let left = chart.minX+42, right=chart.maxX-22, top=chart.minY+34, bottom=chart.maxY-38
    func P(_ x: Double, _ y: Double) -> CGPoint {
        CGPoint(x:left+CGFloat((x+1.2)/4.2)*(right-left), y:bottom-CGFloat(y/7.5)*(bottom-top))
    }
    line(ctx, CGPoint(x:left,y:bottom), CGPoint(x:right,y:bottom), muted, 1.2)
    line(ctx, CGPoint(x:left,y:top), CGPoint(x:left,y:bottom), muted, 1.2)
    let reveal = min(1.0, max(0.05, t/2.8))
    let end = max(3, Int(140*reveal)); let curve = CGMutablePath()
    for i in 0...end {
        let x = -1.1+3.8*Double(i)/Double(end), p=P(x,x*x)
        if i==0 { curve.move(to:p) } else { curve.addLine(to:p) }
    }
    ctx.setStrokeColor(color(cyan)); ctx.setLineWidth(4); ctx.addPath(curve); ctx.strokePath()
    let x = 0.2 + min(1,max(0,t/5))*0.9
    let point = P(x,x*x)
    dot(ctx,point,10+3*sin(t*5),yellow)
    text("f(x) = x²", 1010, 160, 18, cyan, .semibold, 150)
    text("f′(1) = 2", 1010, 195, 18, yellow, .semibold, 150)
    text("Opening title · concept · student details", 70, 640, 15, muted, .regular, 650)
    rounded(ctx, CGRect(x:70,y:682,width:1140,height:5), 3, panel)
    rounded(ctx, CGRect(x:70,y:682,width:1140*CGFloat(t/TITLE_SECONDS),height:5), 3, cyan)
}

func render(_ ctx: CGContext, _ t: Double, _ idx: Int, _ local: Double) {
    if t < TITLE_SECONDS { drawOpeningCard(ctx,t); return }
    drawAtmosphere(ctx,t,idx)
    let s = scenes[idx]
    let entrance = min(1, max(0, local/2.2))
    let offset = CGFloat((1-entrance)*70)
    text("MATH IN MOTION    /    CALCULUS", 70, 42, 16, muted, .semibold, 450)
    text(String(format:"SCENE %02d / 06",idx+1), 1030, 42, 16, cyan, .semibold, 180, .right)
    text(s.kicker, 70+offset, 145, 16, yellow, .bold, 540)
    text(s.title, 70+offset, 180, 38, white, .bold, 590)
    text(s.caption, 70+offset, 252, 24, muted, .regular, 555)
    let shown = max(1, Int(Double(s.formula.count)*min(1,max(0,local/3.2))))
    if idx != 3 {
        text(String(s.formula.prefix(shown)), 78, 360, idx == 5 ? 20 : 26, cyan, .semibold, 555)
        line(ctx,CGPoint(x:78,y:401),CGPoint(x:610,y:401),cyan.withAlphaComponent(0.55),2)
        for i in 0..<9 {
            let x = CGFloat(80 + i*61) + CGFloat(12*sin(local*0.8+Double(i)))
            dot(ctx,CGPoint(x:x,y:406),2+CGFloat(i%3),cyan.withAlphaComponent(0.55))
        }
    }
    if idx == 0 { drawCar(ctx,local) } else { drawGraph(ctx,local,idx) }
    if idx == 3 {
        let derivation = [
            "m = [f(1+h) − f(1)] / h",
            "= [(1+h)² − 1] / h",
            "= [1 + 2h + h² − 1] / h",
            "= [2h + h²] / h",
            "= h(2+h) / h = 2+h"
        ]
        let active = min(4, Int(local/4.0))
        for i in 0..<derivation.count where local > Double(i)*1.3 {
            let rowY = CGFloat(328 + i*44)
            let highlight = i == active
            if highlight { rounded(ctx,CGRect(x:70,y:rowY-3,width:545,height:34),8,panel.withAlphaComponent(0.86)) }
            text(derivation[i], 82, rowY, 18, highlight ? yellow : white, .semibold, 520)
            if highlight { dot(ctx,CGPoint(x:600,y:rowY+7),4+2*sin(local*5),cyan) }
        }
        text("Cancel h only because h ≠ 0", 82, 550, 15, muted, .medium, 300)
        let x: CGFloat = 72
        let y: CGFloat = 586
        text("h = 1   →   m = 3", x, y, 15, cyan, .semibold, 170)
        text("h = 0.5   →   m = 2.5", x+180, y, 15, yellow, .semibold, 205)
        text("h = 0.1   →   m = 2.1", x+390, y, 15, coral, .semibold, 220)
        let p = min(1, max(0, local/SCENE_DURATIONS[idx]))
        let markerX = x + 8 + CGFloat(p)*520
        line(ctx,CGPoint(x:x+8,y:y+30),CGPoint(x:x+520,y:y+30),muted.withAlphaComponent(0.45),1.3)
        dot(ctx, CGPoint(x:markerX,y:y+30), 6+2*sin(local*4), yellow)
        text(String(format:"Live secant slope: %.2f", 2 + (1.5-1.4*p)), 72, 625, 16, white, .medium, 410)
    }
    if idx == 4 {
        if local > 5 { text("f′(x) = 2x", 120, 500, 30, green, .bold, 300) }
        if local > 24 {
            arrow(ctx, CGPoint(x:330,y:520), CGPoint(x:374,y:520), yellow, 2)
            let traveler = CGFloat(330 + min(1,max(0,(local-24)/8))*44)
            dot(ctx, CGPoint(x:traveler,y:520), 6+2*sin(local*4), white)
            text("f′(1) = 2", 395, 500, 30, yellow, .bold, 250)
        }
    }
    if idx == 5 {
        text("SECANT", 120, 510, 16, coral, .semibold, 120)
        arrow(ctx, CGPoint(x:205,y:519), CGPoint(x:265,y:519), muted, 2)
        text("LIMIT", 280, 510, 16, yellow, .semibold, 100)
        arrow(ctx, CGPoint(x:355,y:519), CGPoint(x:395,y:519), muted, 2)
        text("TANGENT", 400, 510, 16, green, .semibold, 150)
        let travelerX = CGFloat(205 + (395-205)*min(1,max(0,local/SCENE_DURATIONS[idx])))
        line(ctx, CGPoint(x:205,y:536), CGPoint(x:395,y:536), muted, 1.2, [3,4])
        dot(ctx, CGPoint(x:travelerX,y:536), 7+2*sin(local*5), white)
        text("AVERAGE RATE  →  INSTANTANEOUS RATE", 120, 545, 18, white, .medium, 500)
        let takeaway = ["Secant = average change", "Limit = points meet", "Tangent = instant slope 2"]
        let tx: [CGFloat] = [80, 330, 590]
        for i in 0..<3 where local > 7 + Double(i)*3 {
            dot(ctx,CGPoint(x:tx[i],y:584),5, [coral,yellow,green][i])
            text(takeaway[i],tx[i]+12,576,13,white,.medium,220)
        }
        text("Math source: OpenStax Calculus, Vol. 1, §3.1: Defining the Derivative", 70, 612, 13, muted, .regular, 1100)
        text("Original instrumental · AI helped with script, visuals, code and voice synthesis; student supplied their own voice sample", 70, 634, 13, muted, .regular, 1000)
    }
    let progress = CGFloat(t / TOTAL)
    rounded(ctx, CGRect(x:70,y:682,width:1140,height:5), 3, panel)
    rounded(ctx, CGRect(x:70,y:682,width:1140*progress,height:5), 3, cyan)
    text(String(format:"%d:%02d",Int(t)/60,Int(t)%60), 1115, 648, 16, white, .medium, 90, .right)
}

let url = URL(fileURLWithPath: OUT)
try? FileManager.default.removeItem(at: url)
let writer = try AVAssetWriter(outputURL: url, fileType: .mp4)
let settings: [String: Any] = [AVVideoCodecKey: AVVideoCodecType.h264, AVVideoWidthKey: W, AVVideoHeightKey: H,
    AVVideoCompressionPropertiesKey: [AVVideoAverageBitRateKey: 4_500_000, AVVideoProfileLevelKey: AVVideoProfileLevelH264MainAutoLevel]]
let input = AVAssetWriterInput(mediaType: .video, outputSettings: settings); input.expectsMediaDataInRealTime = false
let attrs: [String: Any] = [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA,
    kCVPixelBufferWidthKey as String: W, kCVPixelBufferHeightKey as String: H,
    kCVPixelBufferCGImageCompatibilityKey as String: true, kCVPixelBufferCGBitmapContextCompatibilityKey as String: true]
let adaptor = AVAssetWriterInputPixelBufferAdaptor(assetWriterInput: input, sourcePixelBufferAttributes: attrs)
guard writer.canAdd(input) else { fatalError("Cannot add video input") }; writer.add(input)
writer.startWriting(); writer.startSession(atSourceTime: .zero)
let totalFrames = Int(PREVIEW_LENGTH * Double(FPS))
let startFrame = Int(PREVIEW_START * Double(FPS))
for frame in startFrame..<(startFrame + totalFrames) {
    while !input.isReadyForMoreMediaData { Thread.sleep(forTimeInterval: 0.002) }
    var pb: CVPixelBuffer?
    let allocation = CVPixelBufferCreate(kCFAllocatorDefault, W, H, kCVPixelFormatType_32BGRA,
                                         attrs as CFDictionary, &pb)
    guard allocation == kCVReturnSuccess, let buffer = pb else { fatalError("Could not allocate video frame") }
    CVPixelBufferLockBaseAddress(buffer, [])
    let ctx = CGContext(data: CVPixelBufferGetBaseAddress(buffer), width: W, height: H, bitsPerComponent: 8,
        bytesPerRow: CVPixelBufferGetBytesPerRow(buffer), space: CGColorSpaceCreateDeviceRGB(),
        bitmapInfo: CGImageAlphaInfo.premultipliedFirst.rawValue | CGBitmapInfo.byteOrder32Little.rawValue)!
    ctx.translateBy(x: 0, y: CGFloat(H)); ctx.scaleBy(x: 1.5, y: -1.5)
    NSGraphicsContext.saveGraphicsState(); NSGraphicsContext.current = NSGraphicsContext(cgContext: ctx, flipped: true)
    let time = Double(frame) / Double(FPS)
    let sceneTime = max(0, time - TITLE_SECONDS)
    var idx = 0
    while idx < 5 && sceneTime >= SCENE_STARTS[idx + 1] { idx += 1 }
    let local = sceneTime - SCENE_STARTS[idx]
    render(ctx, time, idx, local)
    NSGraphicsContext.restoreGraphicsState(); CVPixelBufferUnlockBaseAddress(buffer, [])
    let pts = CMTime(value: Int64(frame - startFrame), timescale: FPS)
    if !adaptor.append(buffer, withPresentationTime: pts) { fatalError("Frame append failed: \(String(describing: writer.error))") }
}
input.markAsFinished()
let sem = DispatchSemaphore(value: 0)
writer.finishWriting { sem.signal() }; sem.wait()
if writer.status != .completed { fatalError("Video export failed: \(writer.error?.localizedDescription ?? "unknown")") }
print(String(format: "Created %@ · %.0f seconds · silent MP4", url.path, PREVIEW_LENGTH))
