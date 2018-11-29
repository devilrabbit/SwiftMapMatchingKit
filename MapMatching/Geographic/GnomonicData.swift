//
//  GnomonicData.swift
//  MapMatching
//
//  Created by devilrabbit on 2018/10/18.
//  Copyright (c) 2018 devilrabbit. All rights reserved.
//

import Foundation

/**
 * The results of gnomonic projection.
 * <p>
 * This is used to return the results for a gnomonic projection of a point
 * (<i>lat</i>, <i>lon</i>) given a center point of projection (<i>lat0</i>,
 * <i>lon0</i>). The returned GnomonicData objects always include the
 * parameters provided to
 * {@link Gnomonic#Forward Gnomonic.Forward}
 * and
 * {@link Gnomonic#Reverse Gnomonic.Reverse}
 * and it always includes the fields <i>x</i>, <i>y</i>, <i>azi</i>. and
 * <i>rk</i>.
 **********************************************************************/
public struct GnomonicData {
    
    /// latitude of center point of projection (degrees).
    public private(set) var lat0: Double
    
    /// longitude of center point of projection (degrees).
    public private(set) var lon0: Double
    
    /// latitude of point (degrees).
    public private(set) var lat: Double
    
    /// longitude of point (degrees).
    public private(set) var lon: Double
    
    /// easting of point (meters).
    public private(set) var x: Double
    
    /// northing of point (meters).
    public private(set) var y: Double
    
    /// azimuth of geodesic at point (degrees).
    public private(set) var azi: Double
    
    /// reciprocal of azimuthal scale at point.
    public private(set) var rk: Double
    
    /// Constructor initializing all the fields for gnomonic projection of a point
    /// (<i>lat</i>, <i>lon</i>) given a center point of projection (<i>lat0</i>,
    /// <i>lon0</i>).
    ///
    /// - parameter lat0: latitude of center point of projection (degrees).
    /// - paramter lon0: longitude of center point of projection (degrees).
    /// - paramter lat: latitude of point (degrees).
    /// - paramter lon: longitude of point (degrees).
    /// - paramter x: easting of point (meters).
    /// - paramter y: northing of point (meters).
    /// - paramter azi: azimuth of geodesic at point (degrees).
    /// - paramter rk: reciprocal of azimuthal scale at point.
    public init(lat0: Double = .nan, lon0: Double = .nan, lat: Double = .nan, lon: Double = .nan, x: Double = .nan, y: Double = .nan, azi: Double = .nan, rk: Double = .nan) {
        self.lat0 = lat0
        self.lon0 = lon0
        self.lat = lat
        self.lon = lon
        self.x = x
        self.y = y
        self.azi = azi
        self.rk = rk
    }
}
