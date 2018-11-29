//
//  GraphRouter.swift
//  MapMatching
//
//  Created by devilrabbit on 2018/10/09.
//  Copyright (c) 2018 devilrabbit. All rights reserved.
//

import Foundation

public protocol GraphRouter {
    associatedtype Edge
    associatedtype Point : EdgePoint where Point.TEdge == Edge
    
    func route(source: Point, target: Point, cost: ((Edge) -> Double), bound: ((Edge) -> Double)?, max: Double) -> [Edge]
    func route(source: Point, targets: [Point], cost: ((Edge) -> Double), bound: ((Edge) -> Double)?, max: Double) -> [Point : [Edge]]
    func route(sources: [Point], targets: [Point], cost: ((Edge) -> Double), bound: ((Edge) -> Double)?, max: Double) -> [Point : (Point, [Edge])]
}

public extension GraphRouter {
    
    func route(source: Point, target: Point, cost: ((Edge) -> Double)) -> [Edge] {
        return self.route(source: source, target: target, cost: cost, bound: nil, max: .nan)
    }
    
    func route(source: Point, target: Point, cost: ((Edge) -> Double), bound: ((Edge) -> Double)?) -> [Edge] {
        return self.route(source: source, target: target, cost: cost, bound: bound, max: .nan)
    }
    
    func route(source: Point, target: Point, cost: ((Edge) -> Double), max: Double) -> [Edge] {
        return self.route(source: source, target: target, cost: cost, bound: nil, max: max)
    }
    
    
    func route(source: Point, targets: [Point], cost: ((Edge) -> Double)) -> [Point : [Edge]] {
        return self.route(source: source, targets: targets, cost: cost, bound: nil, max: .nan)
    }
    
    func route(source: Point, targets: [Point], cost: ((Edge) -> Double), bound: ((Edge) -> Double)?) -> [Point : [Edge]] {
        return self.route(source: source, targets: targets, cost: cost, bound: bound, max: .nan)
    }
    
    func route(source: Point, targets: [Point], cost: ((Edge) -> Double), max: Double) -> [Point : [Edge]] {
        return self.route(source: source, targets: targets, cost: cost, bound: nil, max: max)
    }
    
    
    func route(sources: [Point], targets: [Point], cost: ((Edge) -> Double)) -> [Point : (Point, [Edge])] {
        return self.route(sources: sources, targets: targets, cost: cost, bound: nil, max: .nan)
    }
    
    func route(sources: [Point], targets: [Point], cost: ((Edge) -> Double), bound: ((Edge) -> Double)?) -> [Point : (Point, [Edge])] {
        return self.route(sources: sources, targets: targets, cost: cost, bound: bound, max: .nan)
    }
    
    func route(sources: [Point], targets: [Point], cost: ((Edge) -> Double), max: Double) -> [Point : (Point, [Edge])] {
        return self.route(sources: sources, targets: targets, cost: cost, bound: nil, max: max)
    }
}

public class AnyGraphRouter<TEdge, TPoint: EdgePoint> : GraphRouter where TPoint.TEdge == TEdge {
    public typealias Edge = TEdge
    public typealias Point = TPoint
    
    private let _route1: (Point, Point, ((Edge)->Double), ((Edge)->Double)?, Double) -> [TEdge]
    private let _route2: (Point, [Point], ((Edge) -> Double), ((Edge) -> Double)?, Double) -> [Point : [Edge]]
    private let _route3: ([Point], [Point], ((Edge) -> Double), ((Edge) -> Double)?, Double) -> [Point : (Point, [Edge])]
    
    init<R: GraphRouter>(_ inner: R) where R.Point == TPoint, R.Edge == TEdge {
        _route1 = { inner.route(source: $0, target: $1, cost: $2, bound: $3, max: $4) }
        _route2 = { inner.route(source: $0, targets: $1, cost: $2, bound: $3, max: $4) }
        _route3 = { inner.route(sources: $0, targets: $1, cost: $2, bound: $3, max: $4) }
    }
    
    public func route(source: Point, target: Point, cost: ((TEdge) -> Double), bound: ((TEdge) -> Double)?, max: Double) -> [TEdge] {
        return _route1(source, target, cost, bound, max)
    }
    
    public func route(source: Point, targets: [Point], cost: ((TEdge) -> Double), bound: ((TEdge) -> Double)?, max: Double) -> [Point : [TEdge]] {
        return _route2(source, targets, cost, bound, max)
    }
    
    public func route(sources: [Point], targets: [Point], cost: ((TEdge) -> Double), bound: ((TEdge) -> Double)?, max: Double) -> [Point : (Point, [TEdge])] {
        return _route3(sources, targets, cost, bound, max)
    }
}
