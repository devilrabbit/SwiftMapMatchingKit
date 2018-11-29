//
//  SpatialOperator.swift
//  MapMatching
//
//  Created by devilrabbit on 2018/10/10.
//  Copyright (c) 2018 devilrabbit. All rights reserved.
//

import CoreLocation

public protocol SpatialOperator {
    
    /// Gets the distance between two <see cref="Geometries.Coordinate2D"/> <i>a</i> and <i>b</i>.
    /// - parameter a: First point.
    /// - parameter b: Second point.
    /// - returns: Distance between points in meters.
    func distance(_ a: Coordinate2D, _ b: Coordinate2D) -> Double
    
    func length(of line: Polyline2D) -> Double
    
    /// Gets interception point of a LineString intercepted by Point c.
    /// This is analog to <see cref="Intercept(Coordinate2D, Coordinate2D, Coordinate2D)"/>.
    /// The fraction <i>f</i> refers to the full length of the LineString.
    /// - parameter p: Line to be intercepted.
    /// - parameter c: Point that intercepts straight line a to b.
    /// - returns: Interception point described as the linearly interpolated fraction f in the interval [0,1] of the line
    func intercept(_ p: Polyline2D, _ c: Coordinate2D) -> Double
    func intercept(_ a: Coordinate2D, _ b: Coordinate2D, _ p: Coordinate2D) -> Double
    
    func interpolate(_ a: Coordinate2D, _ b: Coordinate2D, _ f: Double) -> Coordinate2D
    func interpolate(_ path: Polyline2D, _ f: Double) -> Coordinate2D
    func interpolate(_ path: Polyline2D, _ l: Double, _ f: Double) -> Coordinate2D
    
    func azimuth(_ a: Coordinate2D, _ b: Coordinate2D, _ f: Double) -> Double
    func azimuth(_ path: Polyline2D, _ f: Double) -> Double
    func azimuth(_ path: Polyline2D, _ l: Double, _ f: Double) -> Double
    
    func envelope(_ c: Coordinate2D, _ radius: Double) -> Rect2D
    func envelope(_ line: Polyline2D) -> Rect2D
}
