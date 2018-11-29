//
//  AbstractGraphEdge.swift
//  MapMatching
//
//  Created by devilrabbit on 2018/10/09.
//  Copyright (c) 2018 devilrabbit. All rights reserved.
//

import Foundation

public protocol GraphEdge: Edge {
    associatedtype TEdge: GraphEdge
    
    var id: Int64 { get }
    var neighbor: TEdge? { get set }
    var successor: TEdge? { get set }
    var successors: [TEdge] { get }
}

extension GraphEdge {
    
    public var successors: [TEdge] {
        var array = [TEdge]()
        let s = self.successor
        var i = s
        while let e = i {
            array.append(e)
            if let n = e.neighbor as? TEdge, n != s {
                i = n
            } else {
                i = nil
            }
        }
        return array
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(source)
        hasher.combine(target)
        hasher.combine(weight)
    }
    
    public static func == (lhs: Self, rhs: Self) -> Bool {
        guard lhs.id == rhs.id else { return false }
        guard lhs.source == rhs.source else { return false }
        guard lhs.target == rhs.target else { return false }
        guard lhs.weight == rhs.weight else { return false }
        return true
    }
}
