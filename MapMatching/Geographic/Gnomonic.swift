//
//  Gnomonic.swift
//  MapMatching
//
//  Created by devilrabbit on 2018/10/18.
//  Copyright (c) 2018 devilrabbit. All rights reserved.
//

import Foundation

/*
 * <p>
 * <i>Note: Gnomonic.java has been ported to Java from its C++ equivalent
 * Gnomonic.cpp, authored by C. F. F. Karney and licensed under MIT/X11
 * license.  The following documentation is mostly the same as for its C++
 * equivalent, but has been adopted to apply to this Java implementation.</i>
 * <p>
 * Gnomonic projection centered at an arbitrary position <i>C</i> on the
 * ellipsoid. This projection is derived in Section 8 of
 * <ul>
 * <li>
 * C. F. F. Karney, <a href="https://doi.org/10.1007/s00190-012-0578-z">
 * Algorithms for geodesics</a>, J. Geodesy <b>87</b>, 43&ndash;55 (2013);
 * DOI: <a href="https://doi.org/10.1007/s00190-012-0578-z">
 * 10.1007/s00190-012-0578-z</a>; addenda:
 * <a href="https://geographiclib.sourceforge.io/geod-addenda.html">
 * geod-addenda.html</a>.
 * </li>
 * </ul>
 * <p>
 * The gnomonic projection of a point <i>P</i> on the ellipsoid is defined as
 * follows: compute the geodesic line from <i>C</i> to <i>P</i>; compute the
 * reduced length <i>m12</i>, geodesic scale <i>M12</i>, and &rho; =
 * <i>m12</i>/<i>M12</i>; finally, this gives the coordinates <i>x</i> and
 * <i>y</i> of <i>P</i> in gnomonic projection with <i>x</i> = &rho; sin
 * <i>azi1</i>; <i>y</i> = &rho; cos <i>azi1</i>, where <i>azi1</i> is the
 * azimuth of the geodesic at <i>C</i>. The method
 * {@link Gnomonic#Forward(double, double, double, double)} performs the
 * forward projection and
 * {@link Gnomonic#Reverse(double, double, double, double)} is the
 * inverse of the projection. The methods also return the azimuth
 * <i>azi</i> of the geodesic at <i>P</i> and reciprocal scale
 * <i>rk</i> in the azimuthal direction. The scale in the radial
 * direction is 1/<i>rk</i><sup>2</sup>.
 * <p>
 * For a sphere, &rho; reduces to <i>a</i> tan(<i>s12</i>/<i>a</i>), where
 * <i>s12</i> is the length of the geodesic from <i>C</i> to <i>P</i>, and the
 * gnomonic projection has the property that all geodesics appear as straight
 * lines. For an ellipsoid, this property holds only for geodesics interesting
 * the centers. However geodesic segments close to the center are approximately
 * straight.
 * <p>
 * Consider a geodesic segment of length <i>l</i>. Let <i>T</i> be the point on
 * the geodesic (extended if necessary) closest to <i>C</i>, the center of the
 * projection, and <i>t</i>, be the distance <i>CT</i>. To lowest order, the
 * maximum deviation (as a true distance) of the corresponding gnomonic line
 * segment (i.e., with the same end points) from the geodesic is<br>
 * <br>
 * (<i>K</i>(<i>T</i>) &minus; <i>K</i>(<i>C</i>))
 * <i>l</i><sup>2</sup> <i>t</i> / 32.
 * <br>
 * <br>
 * where <i>K</i> is the Gaussian curvature.
 * <p>
 * This result applies for any surface. For an ellipsoid of revolution,
 * consider all geodesics whose end points are within a distance <i>r</i> of
 * <i>C</i>.  For a given <i>r</i>, the deviation is maximum when the latitude
 * of <i>C</i> is 45&deg;, when endpoints are a distance <i>r</i> away, and
 * when their azimuths from the center are &plusmn; 45&deg; or &plusmn;
 * 135&deg;. To lowest order in <i>r</i> and the flattening <i>f</i>, the
 * deviation is <i>f</i> (<i>r</i>/2<i>a</i>)<sup>3</sup> <i>r</i>.
 * <p>
 * <b>CAUTION:</b> The definition of this projection for a sphere is standard.
 * However, there is no standard for how it should be extended to an ellipsoid.
 * The choices are:
 * <ul>
 * <li>
 * Declare that the projection is undefined for an ellipsoid.
 * </li>
 * <li>
 * Project to a tangent plane from the center of the ellipsoid. This causes
 * great ellipses to appear as straight lines in the projection; i.e., it
 * generalizes the spherical great circle to a great ellipse. This was proposed
 * by independently by Bowring and Williams in 1997.
 * </li>
 * <li>
 * Project to the conformal sphere with the constant of integration chosen so
 * that the values of the latitude match for the center point and perform a
 * central projection onto the plane tangent to the conformal sphere at the
 * center point. This causes normal sections through the center point to appear
 * as straight lines in the projection; i.e., it generalizes the spherical
 * great circle to a normal section. This was proposed by I. G. Letoval'tsev,
 * Generalization of the gnomonic projection for a spheroid and the principal
 * geodetic problems involved in the alignment of surface routes, Geodesy and
 * Aerophotography (5), 271&ndash;274 (1963).
 * </li>
 * <li>
 * The projection given here. This causes geodesics close to the center point
 * to appear as straight lines in the projection; i.e., it generalizes the
 * spherical great circle to a geodesic.
 * </li>
 * </ul>
 * <p>
 * Example of use:
 *
 * <pre>
 * // Example of using the Gnomonic.java class
 * import net.sf.geographiclib.Geodesic;
 * import net.sf.geographiclib.Gnomonic;
 * import net.sf.geographiclib.GnomonicData;
 * public class ExampleGnomonic {
 *   public static void main(String[] args) {
 *     Geodesic geod = Geodesic.WGS84;
 *     double lat0 = 48 + 50 / 60.0, lon0 = 2 + 20 / 60.0; // Paris
 *     Gnomonic gnom = new Gnomonic(geod);
 *     {
 *       // Sample forward calculation
 *       double lat = 50.9, lon = 1.8; // Calais
 *       GnomonicData proj = gnom.Forward(lat0, lon0, lat, lon);
 *       System.out.println(proj.x + &quot; &quot; + proj.y);
 *     }
 *     {
 *       // Sample reverse calculation
 *       double x = -38e3, y = 230e3;
 *       GnomonicData proj = gnom.Reverse(lat0, lon0, x, y);
 *       System.out.println(proj.lat + &quot; &quot; + proj.lon);
 *     }
 *   }
 * }
 * </pre>
 */

/// Gnomonic projection.
public struct Gnomonic {
    
    private static let eps_ = 0.01 * sqrt(GeoMath.epsilon)
    private static let numit_ = 10;
    
    public var earth: Geodesic
    
    /// Constructor for Gnomonic.
    /// - parameter earth: earth the <see cref="GeographicLib.Geodesic"/> object to use for geodesic calculations
    public init(earth: Geodesic) {
        self.earth = earth
    }
    
    /// Forward projection, from geographic to gnomonic.
    ///
    /// - parameter lat0: latitude of center point of projection (degrees).
    /// - parameter lon0: longitude of center point of projection (degrees).
    /// - parameter lat: latitude of point (degrees).
    /// - parameter lon: longitude of point (degrees).
    /// - returns: {@link GnomonicData} object with the following fields:
    ///   <i>lat0</i>, <i>lon0</i>, <i>lat</i>, <i>lon</i>, <i>x</i>, <i>y</i>,
    ///   <i>azi</i>, <i>rk</i>.
    ///
    /// <i>lat0</i> and <i>lat</i> should be in the range [&minus;90&deg;,
    /// 90&deg;] and <i>lon0</i> and <i>lon</i> should be in the range
    /// [&minus;540&deg;, 540&deg;). The scale of the projection is
    /// 1/<i>rk<sup>2</sup></i> in the "radial" direction, <i>azi</i> clockwise
    /// from true north, and is 1/<i>rk</i> in the direction perpendicular to
    /// this. If the point lies "over the horizon", i.e., if <i>rk</i> &le; 0,
    /// then NaNs are returned for <i>x</i> and <i>y</i> (the correct values are
    /// returned for <i>azi</i> and <i>rk</i>). A call to Forward followed by a
    /// call to Reverse will return the original (<i>lat</i>, <i>lon</i>) (to
    /// within roundoff) provided the point in not over the horizon.
    public func forward(lat0: Double, lon0: Double, lat: Double, lon: Double) -> GnomonicData {
        let inv = earth.inverse(lat1: lat0, lon1: lon0, lat2: lat, lon2: lon, outmask:
            [.AZIMUTH, .GEODESICSCALE, .REDUCEDLENGTH])
        
        if inv.M12 > 0 {
            let rho = inv.m12 / inv.M12
            let p = GeoMath.sincosd(inv.azi1)
            let x = rho * p.0
            let y = rho * p.1
            return GnomonicData(lat0: lat0, lon0: lon0, lat: lat, lon: lon, x: x, y: y, azi: inv.azi2, rk: inv.M12)
        }
        
        return GnomonicData(lat0: lat0, lon0: lon0, lat: lat, lon: lon, x: .nan, y: .nan, azi: inv.azi2, rk: inv.M12)
    }
    
    /**
     * Reverse projection, from gnomonic to geographic.
     * <p>
     * @param lat0 latitude of center point of projection (degrees).
     * @param lon0 longitude of center point of projection (degrees).
     * @param x easting of point (meters).
     * @param y northing of point (meters).
     * @return {@link GnomonicData} object with the following fields:
     *   <i>lat0</i>, <i>lon0</i>, <i>lat</i>, <i>lon</i>, <i>x</i>, <i>y</i>,
     *   <i>azi</i>, <i>rk</i>.
     * <p>
     * <i>lat0</i> should be in the range [&minus;90&deg;, 90&deg;] and
     * <i>lon0</i> should be in the range [&minus;540&deg;, 540&deg;).
     * <i>lat</i> will be in the range [&minus;90&deg;, 90&deg;] and <i>lon</i>
     * will be in the range [&minus;180&deg;, 180&deg;]. The scale of the
     * projection is 1/<i>rk<sup>2</sup></i> in the "radial" direction,
     * <i>azi</i> clockwise from true north, and is 1/<i>rk</i> in the direction
     * perpendicular to this. Even though all inputs should return a valid
     * <i>lat</i> and <i>lon</i>, it's possible that the procedure fails to
     * converge for very large <i>x</i> or <i>y</i>; in this case NaNs are
     * returned for all the output arguments. A call to Reverse followed by a
     * call to Forward will return the original (<i>x</i>, <i>y</i>) (to
     * roundoff).
     */
    public func reverse(lat0: Double, lon0: Double, x: Double, y: Double) -> GnomonicData {
        let azi0 = GeoMath.atan2d(x, y)
        var rho = GeoMath.hypot(x, y)
        var s = self.majorRadius * atan(rho / self.majorRadius)
        let little = rho <= self.majorRadius
        
        if !little {
            rho = 1 / rho
        }
        
        let line = self.earth.line(lat1: lat0, lon1: lon0, azi1: azi0, caps:
            [.LATITUDE, .LONGITUDE, .AZIMUTH, .DISTANCE_IN, .REDUCEDLENGTH, .GEODESICSCALE])
        
        var trip = 0
        var pos = GeodesicData()
        
        for _ in 0..<Gnomonic.numit_ {
            pos = line.position(s, [.LONGITUDE, .LATITUDE, .AZIMUTH, .DISTANCE_IN, .REDUCEDLENGTH, .GEODESICSCALE])
            
            if trip > 0 {
                break
            }
            
            let ds = little ?
                ((pos.m12 / pos.M12) - rho) * pos.M12 * pos.M12 :
                (rho - (pos.M12 / pos.m12)) * pos.m12 * pos.m12
            
            s -= ds
            
            if (abs(ds) <= Gnomonic.eps_ * self.majorRadius) {
                trip += 1
            }
        }
        
        if trip == 0 {
            return GnomonicData(lat0: lat0, lon0: lon0, lat: .nan, lon: .nan, x: x, y: y, azi: .nan, rk: .nan)
        }

        return GnomonicData(lat0: lat0, lon0: lon0, lat: pos.lat2, lon: pos.lon2, x: x, y: y, azi: pos.azi2, rk: pos.M12)
    }
    
    /// return <i>a</i> the equatorial radius of the ellipsoid (meters).  This is
    /// the value inherited from the Geodesic object used in the constructor.
    public var majorRadius: Double {
        return self.earth.majorRadius
    }
    
    /// return <i>f</i> the  flattening of the ellipsoid.  This is
    /// the value inherited from the Geodesic object used in the constructor.
    public var flattening: Double {
        return self.earth.flattening
    }
}
