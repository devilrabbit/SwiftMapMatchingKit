//
//  AbstractGraphEdge.swift
//  MapMatching
//
//  Created by devilrabbit on 2018/10/09.
//  Copyright (c) 2018 devilrabbit. All rights reserved.
//

import Foundation

public protocol GraphEdge: class, Edge {
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
    }
    
    public static func == (lhs: Self, rhs: Self) -> Bool {
        if lhs === rhs { return true }
        return lhs.id == rhs.id
    }
}
