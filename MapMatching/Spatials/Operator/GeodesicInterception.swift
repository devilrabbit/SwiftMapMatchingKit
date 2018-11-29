//
//  GeodesicInterception.swift
//  MapMatching
//
//  Created by devilrabbit on 2018/10/10.
//  Copyright (c) 2018 devilrabbit. All rights reserved.
//

import Foundation
import simd

/// Geodesic interception.
/// <i>Note: Intercept.java has been ported to Java from its C++ equivalent Intercept.cpp, authored
/// by C. F. F. Karney and licensed under MIT/X11 license. The following documentation is mostly the
/// same as for its C++ equivalent, but has been adopted to apply to this Java implementation.</i>
///
/// Simple solution to the interception using the gnomonic projection. The interception problem is,
/// given a geodesic <i>a</i> and a point <i>b</i>, determine the point <i>p</i> on the geodesic
/// <i>a</i> that is closest to point <i>b</i>. The gnomonic projection and the solution to the
/// interception problem are derived in Section 8 of
/// <ul>
/// <li>C. F. F. Karney, <a href="http://dx.doi.org/10.1007/s00190-012-0578-z"> Algorithms for
/// geodesics</a>, J. Geodesy <b>87</b>, 43--55 (2013); DOI:
/// <a href="http://dx.doi.org/10.1007/s00190-012-0578-z"> 10.1007/s00190-012-0578-z</a>; addenda:
/// <a href="http://geographiclib.sf.net/geod-addenda.html"> geod-addenda.html</a>.</li>
/// </ul>
/// In gnomonic projection geodesics are nearly straight; and they are exactly straight if they go
/// through the center of projection. The interception can then be found as follows: Guess an
/// interception point. Project the resulting line segments into gnomonic, compute their intersection
/// in this projection, use this intersection point as the new center, and repeat.
///
/// <b>CAUTION:</b> The solution to the interception problem is valid only under the following
/// conditions:
/// <ul>
/// <li>The two points defining the geodesic and the point of interception must be in the same
/// hemisphere centered at the interception point for the gnomonic projection to be defined.</li>
/// </ul>
struct GeodesicInterception {
    
    private static let eps = 0.01 * sqrt(GeoMath.epsilon)
    
    /// Maximum number of iterations for calculation of interception point. (The solution should
    /// usually converge before reaching the maximum number of iterations. The default is 10.)
    public let Maxit = 10
    
    private let _gnom: Gnomonic
    
    /// <summary>
    /// Constructor for Intercept.
    /// </summary>
    /// <param name="earth">the <see cref="GeographicLib.Geodesic"/> object to use for geodesic calculations. By default the WGS84 ellipsoid should be used.</param>
    public init(earth: Geodesic) {
        self._gnom = Gnomonic(earth: earth)
    }
    
    /// <summary>
    /// Interception of a point <i>b</i> to a geodesic <i>a</i>.
    /// </summary>
    /// <param name="lata1">latitude of point <i>1</i> of geodesic <i>a</i> (degrees).</param>
    /// <param name="lona1">longitude of point <i>1</i> of geodesic <i>a</i> (degrees).</param>
    /// <param name="lata2">latitude of point <i>2</i> of geodesic <i>a</i> (degrees).</param>
    /// <param name="lona2">longitude of point <i>2</i> of geodesic <i>a</i> (degrees).</param>
    /// <param name="latb1">latitude of point <i>b</i> (degrees).</param>
    /// <param name="lonb1">longitude of point <i>b</i> (degrees).</param>
    /// <returns>
    /// <para>
    /// a <see cref="GeographicLib.GeodesicData"/> object, defining a geodesic from point <i>b</i> to the
    /// intersection point, with the following fields: <i>lat1</i>, <i>lon1</i>, <i>azi1</i>,
    /// <i>lat2</i>, <i>lon2</i>, <i>azi2</i>, <i>s12</i>, <i>a12</i>.
    /// </para>
    /// <para>
    /// <i>lat1</i> should be in the range [&minus;90&deg;, 90&deg;]; <i>lon1</i> and
    /// <i>azi1</i> should be in the range [&minus;540&deg;, 540&deg;). The values of
    /// <i>lon2</i> and <i>azi2</i> returned are in the range [&minus;180&deg;, 180&deg;).
    /// </para>
    /// </returns>
    public func intercept(lata1: Double, lona1: Double, lata2: Double, lona2: Double, latb1: Double, lonb1: Double) -> GeodesicData {
        if lata1 == lata2 && lona1 == lona2 {
            return _gnom.earth.inverse(lat1: latb1, lon1: lonb1, lat2: lata1, lon2: lona1)
        }
        
        let inv = Geodesic.WGS84.inverse(lat1: lata1, lon1: lona1, lat2: lata2, lon2: lona2)
        let est = Geodesic.WGS84.line(lat1: inv.lat1, lon1: inv.lon1, azi1: inv.azi1).position(inv.s12 * 0.5)
        var latb2 = est.lat2
        var latb2_ = Double.nan
        var lonb2_ = Double.nan
        var lonb2 = est.lon2
        
        for _ in 0..<Maxit {
            let xa1 = _gnom.forward(lat0: latb2, lon0: lonb2, lat: lata1, lon: lona1)
            let xa2 = _gnom.forward(lat0: latb2, lon0: lonb2, lat: lata2, lon: lona2)
            let xb1 = _gnom.forward(lat0: latb2, lon0: lonb2, lat: latb1, lon: lonb1)
            
            let va1 = simd_double3(xa1.x, xa1.y, 1)
            let va2 = simd_double3(xa2.x, xa2.y, 1)
            var la = simd_cross(va1, va2)
            let lb = simd_double3(la.y, -la.x, la.x * xb1.y - la.y * xb1.x)
            var p0 = simd_cross(la, lb)
            p0 = p0 * (1 / p0.z)
            
            latb2_ = latb2
            lonb2_ = lonb2
            
            let rev = _gnom.reverse(lat0: latb2, lon0: lonb2, x: p0.x, y: p0.y)
            latb2 = rev.lat
            lonb2 = rev.lon
            
            if abs(lonb2_ - lonb2) < GeodesicInterception.eps && abs(latb2_ - latb2) < GeodesicInterception.eps {
                break
            }
        }
        
        return _gnom.earth.inverse(lat1: latb1, lon1: lonb1, lat2: latb2, lon2: lonb2)
    }
}
