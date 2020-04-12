import UIKit
import PlaygroundSupport

// Basic search
func closestPoints(path: [CGPoint], stations: [CGPoint], distance: CGFloat) -> Set<CGPoint> {
    var res = Set<CGPoint>()

    for i in 0..<path.count-1 {
        for s in stations {
            if pointIntervalDistance(interval: (a: path[i], b: path[i+1]), point: s) <= distance {
                res.insert(s)
            }
        }
    }

    return res
}

// Improved search, which  doesn't measure distance to points that are too far
func closestPointsBetter(path: [CGPoint], stations: [CGPoint], distance: CGFloat) -> Set<CGPoint> {
    var res = Set<CGPoint>()
    var sordetStations = stations
    sordetStations.sort { p1, p2 in
        return p1.x < p2.x
    }

    for i in 0..<path.count-1 {
        let start = path[i]
        let end = path[i+1]
        let xPreselected = pointsBoundByX(sordetStations, lower: min(start.x, end.x)-distance, upper: max(start.x, end.x)+distance)
        for s in xPreselected {
            if pointIntervalDistance(interval: (a: start, b: end), point: s) <= distance {
                res.insert(s)
            }
        }
    }
    return res
}

func sqr(_ x: CGFloat) -> CGFloat {
    return x * x
}

func distance(p1: CGPoint, p2: CGPoint) -> CGFloat {
    return sqrt(sqr(p1.x-p2.x) + sqr(p1.y-p2.y))
}

func pointIntervalDistance(interval: (a: CGPoint, b: CGPoint), point: CGPoint) -> CGFloat {
    let dx = interval.b.x - interval.a.x
    let dy = interval.b.y - interval.a.y
    let l2 = sqr(dx) + sqr(dy)

    if l2 == 0.0 {
        return distance(p1: interval.a, p2: point)
    }

    var t = ((point.x - interval.a.x) * dx + (point.y - interval.a.y) * dy) / l2
    t = max(0.0, min(1.0, t))

    let p = CGPoint(x: interval.a.x + t * dx, y: interval.a.y + t * dy)
    return distance(p1: point, p2: p)
}

extension CGPoint: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(x)
        hasher.combine(y)
    }
}

// Binary search of the index of the point
// with x coordinate closest to a bound from left or right
func xBoundIndex(_ arr: [CGPoint], bound: CGFloat, upper: Bool) -> Int {
    var l = 0
    var u = arr.count-1
    var c = l + (u-l) / 2
    while (u - l) > 1 {
        if arr[c].x > bound {
            u = c
        }
        else {
            l = c
        }
        c = l + (u-l) / 2
    }

    return upper ? u : l
}

// Returns subarray of sorted points with x coordinate within given bounds
func pointsBoundByX(_ points: [CGPoint], lower: CGFloat, upper: CGFloat) -> ArraySlice<CGPoint> {
    let lowerIndex = xBoundIndex(points, bound: lower, upper: false)
    let upperIndex = xBoundIndex(points, bound: upper, upper: true)
    return points[lowerIndex...upperIndex]
}

// Test view, displays path, stations with stations within distance selected
class PathView: UIView {
    var path = [CGPoint]()
    var stations = [CGPoint]()
    var nearest = Set<CGPoint>()
    var nearestOpt = Set<CGPoint>()

    override func draw(_ rect: CGRect) {
        guard let context = UIGraphicsGetCurrentContext() else {
          return
        }
        context.setFillColor(UIColor.white.cgColor)
        context.fill(bounds)

        context.setLineWidth(1.0)

        for s in stations {
            let r = CGRect(x: s.x - 2.0, y: s.y-2.0, width: 4.0, height: 4.0)
            context.addEllipse(in: r)
            let contains = nearest.contains(s)
            let containsOpt = nearestOpt.contains(s)

            switch (contains, containsOpt) {
            case (false, false):
                context.setFillColor(UIColor.black.cgColor)
                context.setStrokeColor(UIColor.black.cgColor)
                context.drawPath(using: .stroke)
            case (false, true):
                context.setFillColor(UIColor.green.cgColor)
                context.setStrokeColor(UIColor.green.cgColor)
                context.drawPath(using: .fillStroke)
            case (true, false):
                context.setFillColor(UIColor.blue.cgColor)
                context.setStrokeColor(UIColor.blue.cgColor)
                context.drawPath(using: .fillStroke)
            case (true, true):
                context.setFillColor(UIColor.black.cgColor)
                context.setStrokeColor(UIColor.black.cgColor)
                context.drawPath(using: .fillStroke)
            }
        }

        context.setStrokeColor(UIColor.blue.cgColor)
        context.beginPath()
        context.addLines(between: path)
        context.strokePath()
    }
}

let stationsCount = 500
let pathPointCount = 40

class MyViewController : UIViewController {
    override func loadView() {
        let view = UIView()
        view.backgroundColor = .white

        let v = PathView()
        v.frame = CGRect(x: 0.0, y: 0.0, width: 300.0, height: 600.0)
        let stations = (0..<stationsCount).map { _ in return CGPoint(x: CGFloat.random(in: 10.0 ..< 290.0), y: CGFloat.random(in: 10.0 ..< 590.0))}
        v.stations = stations

        let pathX = (0..<pathPointCount).map { _ in return CGFloat.random(in: 10.0 ..< 290.0)}.sorted()
        let pathY = (0..<pathPointCount).map { _ in return CGFloat.random(in: 10.0 ..< 590.0)}.sorted()
        let path = zip(pathX, pathY).map { CGPoint(x: $0.0, y: $0.1)}
        v.path = path
        let n = closestPoints(path: path, stations: stations, distance: 20.0)
        let n_opt = closestPointsBetter(path: path, stations: stations, distance: 20.0)
        print("same result from both methods: \(n == n_opt)")
        v.nearest = n
        v.nearestOpt = n_opt
        view.addSubview(v)
        v.setNeedsDisplay()
        self.view = view
    }
}

PlaygroundPage.current.liveView = MyViewController()
