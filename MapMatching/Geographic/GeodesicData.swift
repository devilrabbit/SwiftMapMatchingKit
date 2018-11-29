//
//  GeodesicData.swift
//  MapMatching
//
//  Created by devilrabbit on 2018/10/17.
//  Copyright (c) 2018 devilrabbit. All rights reserved.
//

import Foundation

/**
 * The results of geodesic calculations.
 *
 * This is used to return the results for a geodesic between point 1
 * (<i>lat1</i>, <i>lon1</i>) and point 2 (<i>lat2</i>, <i>lon2</i>).  Fields
 * that have not been set will be filled with Double.NaN.  The returned
 * GeodesicData objects always include the parameters provided to {@link
 * Geodesic#Direct(double, double, double, double) Geodesic.Direct} and {@link
 * Geodesic#Inverse(double, double, double, double) Geodesic.Inverse} and it
 * always includes the field <i>a12</i>.
 **********************************************************************/
public final class GeodesicData {
    
    /// latitude of point 1 (degrees).
    public var lat1: Double
    
    /// longitude of point 1 (degrees).
    public var lon1: Double
    
    /// azimuth at point 1 (degrees).
    public var azi1: Double
    
    /// latitude of point 2 (degrees).
    public var lat2: Double
    
    /// longitude of point 2 (degrees).
    public var lon2: Double
    
    /// azimuth at point 2 (degrees).
    public var azi2: Double
    
    /// distance between point 1 and point 2 (meters).
    public var s12: Double
    
    /// arc length on the auxiliary sphere between point 1 and point 2 (degrees).
    public var a12: Double
    
    /// reduced length of geodesic (meters).
    public var m12: Double
    
    /// geodesic scale of point 2 relative to point 1 (dimensionless).
    public var M12: Double
    
    /// geodesic scale of point 1 relative to point 2 (dimensionless).
    public var M21: Double
    
    /// Area under the geodesic (meters<sup>2</sup>).
    public var S12: Double
    
    public init() {
        self.lat1 = .nan
        self.lon1 = .nan
        self.azi1 = .nan
        self.lat2 = .nan
        self.lon2 = .nan
        self.azi2 = .nan
        self.s12 = .nan
        self.a12 = .nan
        self.m12 = .nan
        self.M12 = .nan
        self.M21 = .nan
        self.S12 = .nan
    }
}
