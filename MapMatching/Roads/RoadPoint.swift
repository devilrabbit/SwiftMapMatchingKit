//
//  RoadPoint.swift
//  MapMatching
//
//  Created by devilrabbit on 2018/10/12.
//  Copyright (c) 2018 devilrabbit. All rights reserved.
//

import Foundation

public class RoadPoint: EdgePoint {
    public typealias TEdge = Road
    
    public private(set) var edge: Road
    public private(set) var fraction: Double
    public private(set) var coordinate: Coordinate2D
    public private(set) var azimuth: Double
    
    public init(road: Road, fraction: Double, azimuth: Double, spatial: SpatialOperator) {
        self.edge = road
        self.fraction = fraction
        self.azimuth = azimuth
        self.coordinate = spatial.interpolate(edge.geometry, fraction)
    }
    
    public init(road: Road, fraction: Double, coordinate: Coordinate2D, spatial: SpatialOperator) {
        self.edge = road
        self.fraction = fraction
        self.coordinate = coordinate
        self.azimuth = spatial.azimuth(road.geometry, fraction)
    }
    
    public convenience init(road: Road, fraction: Double, azimuth: Double) {
        self.init(road: road, fraction: fraction, azimuth: azimuth, spatial: GeographySpatialOperator.shared)
    }
    
    public init(road: Road, fraction: Double, spatial: SpatialOperator) {
        self.edge = road
        self.fraction = fraction
        self.azimuth = spatial.azimuth(road.geometry, fraction)
        self.coordinate = spatial.interpolate(edge.geometry, fraction)
    }
    
    public convenience init(road: Road, fraction: Double) {
        self.init(road: road, fraction: fraction, spatial: GeographySpatialOperator.shared)
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(edge)
        hasher.combine(fraction)
    }
    
    public static func == (lhs: RoadPoint, rhs: RoadPoint) -> Bool {
        return lhs.edge == rhs.edge && abs(lhs.fraction - rhs.fraction) < 10E-6
    }
}
