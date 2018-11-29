//
//  RouteMark.swift
//  MapMatching
//
//  Created by devilrabbit on 2018/10/09.
//  Copyright (c) 2018 devilrabbit. All rights reserved.
//

import Foundation

struct RouteMark<TEdge : GraphEdge>: Comparable, Hashable {
    
    public var markedEdge: TEdge?
    public var predecessorEdge: TEdge?
    public var cost: Double
    public var boundingCost: Double
    
    public static var empty: RouteMark<TEdge> {
        return RouteMark<TEdge>(markedEdge: nil, predecessorEdge: nil, cost: .nan, boundingCost: .nan)
    }
    
    public var isEmpty: Bool {
        return cost.isNaN
    }
    
    /// Constructor of an entry.
    /// - parameter markedEdge: {@link AbstractEdge} defining the route mark.
    /// - parameter predecessorEdge: Predecessor {@link AbstractEdge}.
    /// - parameter cost: Cost value to this route mark.
    /// - parameter boundingCost: Bounding cost value to this route mark.
    public init(markedEdge: TEdge?, predecessorEdge: TEdge?, cost: Double, boundingCost: Double) {
        self.markedEdge = markedEdge
        self.predecessorEdge = predecessorEdge
        self.cost = cost
        self.boundingCost = boundingCost
    }
    
    static func < (lhs: RouteMark<TEdge>, rhs: RouteMark<TEdge>) -> Bool {
        if lhs.isEmpty {
            return false
        }
        if rhs.isEmpty  {
            return true
        }
        return lhs.cost < rhs.cost
    }
    
    static func ==(lhs: RouteMark<TEdge>, rhs: RouteMark<TEdge>) -> Bool {
        if lhs.isEmpty || rhs.isEmpty {
            return false
        }
        return lhs.cost == rhs.cost
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(markedEdge)
        if let edge = predecessorEdge {
            hasher.combine(edge)
        }
        hasher.combine(cost)
    }
    
}
