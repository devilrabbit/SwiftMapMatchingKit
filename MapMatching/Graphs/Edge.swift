//
//  Edge.swift
//  MapMatching
//
//  Created by devilrabbit on 2018/10/09.
//  Copyright (c) 2018 devilrabbit. All rights reserved.
//

//
//  Edge.swift
//  Graph
//
//  Created by Andrew McKnight on 5/8/16.
//
import Foundation

public protocol Edge: Hashable, CustomStringConvertible {
    associatedtype TVertex: Hashable
    var source: TVertex { get }
    var target: TVertex { get }
    var weight: Double? { get }
}

extension Edge {
    
    public var description: String {
        guard let weight = weight else {
            return "\(source) -> \(target)"
        }
        return "\(source) -(\(weight))-> \(target)"
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(source)
        hasher.combine(target)
        hasher.combine(weight)
    }
    
    public static func == (lhs: Self, rhs: Self) -> Bool {
        guard lhs.source == rhs.source else { return false }
        guard lhs.target == rhs.target else { return false }
        guard lhs.weight == rhs.weight else { return false }
        return true
    }
}
