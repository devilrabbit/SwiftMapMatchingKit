//
//  Rect2D.swift
//  MapMatching
//
//  Created by devilrabbit on 2018/11/23.
//  Copyright (c) 2018 devilrabbit. All rights reserved.
//

import Foundation

public protocol Rect2D {
    
    var isEmpty: Bool { get }
    var min: Coordinate2D { get }
    var center: Coordinate2D { get }
    var max: Coordinate2D { get }
    
    func contains(_ c: Coordinate2D) -> Bool
    func intersects(_ r: Rect2D) -> Bool
}

public class Rectangle2D: Rect2D {
    
    public var min: Coordinate2D
    public var max: Coordinate2D

    public convenience init() {
        self.init(min: Vector2D(x: .nan, y: .nan), max: Vector2D(x: .nan, y: .nan))
    }
    
    public init(min: Coordinate2D, max: Coordinate2D) {
        self.min = min
        self.max = max
    }
    
    public init(minX: Double, minY: Double, maxX: Double, maxY: Double) {
        self.min = Vector2D(x: minX, y: minY)
        self.max = Vector2D(x: maxX, y: maxY)
    }
    
    public var isEmpty: Bool {
        return min.x.isNaN || min.y.isNaN || max.x.isNaN || max.y.isNaN
    }
    
    public var center: Coordinate2D {
        return Vector2D(x: (min.x + max.x) / 2, y: (min.y + max.y) / 2)
    }
    
    public func contains(_ c: Coordinate2D) -> Bool {
        return min.x <= c.x && c.x <= max.x && min.y <= c.y && c.y <= max.y
    }
    
    public func intersects(_ r: Rect2D) -> Bool {
        return self.min.x <= r.max.x && self.max.x >= r.min.x
            && self.min.y <= r.max.y && self.max.y >= r.min.y
    }
    
}
