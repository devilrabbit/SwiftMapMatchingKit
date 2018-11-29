//
//  Coordinate2D.swift
//  MapMatching
//
//  Created by devilrabbit on 2018/10/15.
//  Copyright (c) 2018 devilrabbit. All rights reserved.
//

import CoreLocation
import simd

public protocol Vec2D {
    var x: Double { get }
    var y: Double { get }
    
    func distance(_ other: Vec2D) -> Double
}

public typealias Coordinate2D = Vec2D

extension CLLocationCoordinate2D: Coordinate2D {
    
    public var x: Double {
        return self.longitude
    }
    
    public var y: Double {
        return self.latitude
    }
    
    public func distance(_ other: Coordinate2D) -> Double {
        let dx = self.x - other.x
        let dy = self.y - other.y
        return sqrt(dx * dx + dy * dy)
    }
}

typealias Vector2D = vector_double2

extension Vector2D: Coordinate2D {
    
    public func distance(_ other: Coordinate2D) -> Double {
        let dx = self.x - other.x
        let dy = self.y - other.y
        return sqrt(dx * dx + dy * dy)
    }
}
