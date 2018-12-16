//
//  Route.swift
//  MapMatching
//
//  Created by devilrabbit on 2018/10/12.
//  Copyright (c) 2018 devilrabbit. All rights reserved.
//

public final class Route: Path, Equatable {

    private static let EmptyEdges = [Road]()

    public var startPoint: RoadPoint
    public var endPoint: RoadPoint
    
    private var _edges: [Road]
    public var edges: [Road] {
        return Route.getEdges(startPoint, endPoint, _edges)
    }
    
    public private(set) var length: Double
    
    public init(startPoint: RoadPoint, endPoint: RoadPoint, edges: [Road]) {
        self.startPoint = startPoint
        self.endPoint = endPoint
        self._edges = edges
        self.length = Route.computeLength(startPoint, endPoint, edges)
    }
    
    public func cost(_ costFunc: ((Road)->(Double))) -> Double {
        var value = (1.0 - startPoint.fraction) * costFunc(startPoint.edge)
        for e in _edges {
            value += costFunc(e)
        }
        value -= (1.0 - endPoint.fraction) * costFunc(endPoint.edge)
        return value
    }
    
    public func toGeometry() -> Polyline2D {
        let coords = edges.map { $0.geometry }.flatMap{ $0.coordinates }
        let geom = LineString(geometry: coords)
        return geom
    }
    
    public static func == (lhs: Route, rhs: Route) -> Bool {
        if lhs === rhs { return true }
        if lhs.startPoint != rhs.startPoint { return false }
        if lhs.endPoint != rhs.endPoint { return false }
        return lhs.edges == rhs.edges
    }
    
    private static func computeLength(_ startPoint: RoadPoint, _ endPoint: RoadPoint, _ edges: [Road]) -> Double {
        let edges_ = getEdges(startPoint, endPoint, edges)
        let totalLength = edges_.map { $0.length }.reduce(0, +)
        let length = totalLength - (startPoint.fraction * startPoint.edge.length) - ((1.0 - endPoint.fraction) * endPoint.edge.length)
        return length
    }
    
    private static func getEdges(_ startPoint: RoadPoint, _ endPoint: RoadPoint, _ edges: [Road]) -> [Road] {
        var results = [Road]()
        results.append(startPoint.edge)
        for edge in edges {
            results.append(edge)
        }
        results.append(endPoint.edge)
        return results
    }
}
