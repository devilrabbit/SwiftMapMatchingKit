//
//  PolygonArea.swift
//  MapMatching
//
//  Created by devilrabbit on 2018/10/18.
//  Copyright (c) 2018 devilrabbit. All rights reserved.
//

import Foundation

/**
 * Polygon areas.
 * <p>
 * This computes the area of a geodesic polygon using the method given
 * Section 6 of
 * <ul>
 * <li>
 *   C. F. F. Karney,
 *   <a href="https://doi.org/10.1007/s00190-012-0578-z">
 *   Algorithms for geodesics</a>,
 *   J. Geodesy <b>87</b>, 43&ndash;55 (2013)
 *   (<a href="https://geographiclib.sourceforge.io/geod-addenda.html">
 *   addenda</a>).
 * </ul>
 * <p>
 * This class lets you add vertices one at a time to the polygon.  The area
 * and perimeter are accumulated at two times the standard floating point
 * precision to guard against the loss of accuracy with many-sided polygons.
 * At any point you can ask for the perimeter and area so far.  There's an
 * option to treat the points as defining a polyline instead of a polygon; in
 * that case, only the perimeter is computed.
 * <p>
 * Example of use:
 * <pre>
 * {@code
 * // Compute the area of a geodesic polygon.
 *
 * // This program reads lines with lat, lon for each vertex of a polygon.
 * // At the end of input, the program prints the number of vertices,
 * // the perimeter of the polygon and its area (for the WGS84 ellipsoid).
 *
 * import java.util.*;
 * import net.sf.geographiclib.*;
 *
 * public class Planimeter {
 *   public static void main(String[] args) {
 *     PolygonArea p = new PolygonArea(Geodesic.WGS84, false);
 *     try {
 *       Scanner in = new Scanner(System.in);
 *       while (true) {
 *         double lat = in.nextDouble(), lon = in.nextDouble();
 *         p.AddPoint(lat, lon);
 *       }
 *     }
 *     catch (Exception e) {}
 *     PolygonResult r = p.Compute();
 *     System.out.println(r.num + " " + r.perimeter + " " + r.area);
 *   }
 * }}</pre>
 **********************************************************************/
public final class PolygonArea {
    
    private var _earth: Geodesic
    private var _area0: Double  // Full ellipsoid area
    private var _polyline: Bool // Assume polyline (don't close and skip area)
    private var _mask: GeodesicMask
    private var _num: Int
    private var _crossings: Int
    private var _areasum: Accumulator
    private var _perimetersum: Accumulator
    private var _lat0: Double
    private var _lon0: Double
    private var _lat1: Double
    private var _lon1: Double
    
    private static func transit(lon1: Double, lon2: Double) -> Int {
        // Return 1 or -1 if crossing prime meridian in east or west direction.
        // Otherwise return zero.
        // Compute lon12 the same way as Geodesic.Inverse.
        let l1 = GeoMath.angNormalize(lon1)
        let l2 = GeoMath.angNormalize(lon2)
        let lon12 = GeoMath.angDiff(l1, l2).0
        let cross = l1 <= 0 && l2 > 0 && lon12 > 0 ? 1 : (l2 <= 0 && l1 > 0 && lon12 < 0 ? -1 : 0)
        return cross
    }
    
    // an alternate version of transit to deal with longitudes in the direct
    // problem.
    private static func transitDirect(lon1: Double, lon2: Double) -> Int {
        // We want to compute exactly
        //   int(floor(lon2 / 360)) - int(floor(lon1 / 360))
        // Since we only need the parity of the result we can use std::remquo but
        // this is buggy with g++ 4.8.3 and requires C++11.  So instead we do
        let l1 = lon1.truncatingRemainder(dividingBy: 720)
        let l2 = lon2.truncatingRemainder(dividingBy: 720)
        return (((l2 >= 0 && l2 < 360) || l2 < -360 ? 0 : 1) - ((l1 >= 0 && l1 < 360) || l1 < -360 ? 0 : 1))
    }
    
    /// Constructor for PolygonArea.
    /// - parameter earth: the Geodesic object to use for geodesic calculations.
    /// - parameter polyline: if true that treat the points as defining a polyline instead of a polygon.
    public init(earth: Geodesic, polyline: Bool) {
        self._earth = earth
        self._area0 = _earth.ellipsoidArea()
        self._polyline = polyline
        
        self._mask = [.LATITUDE, .LONGITUDE, .DISTANCE]
        if polyline {
            self._mask.insert(.NONE)
        } else {
            self._mask.insert([.AREA, .LONG_UNROLL])
        }
        
        self._perimetersum = Accumulator(0)
        self._areasum = Accumulator(0)

        self._num = 0
        self._crossings = 0
        self._lat0 = .nan
        self._lon0 = .nan
        self._lat1 = .nan
        self._lon1 = .nan
    }
    
    /// Clear PolygonArea, allowing a new polygon to be started.
    public func clear() {
        self._num = 0
        self._crossings = 0
        self._perimetersum.set(0)
        if !self._polyline {
            self._areasum.set(0)
        }
        self._lat0 = .nan
        self._lon0 = .nan
        self._lat1 = .nan
        self._lon1 = .nan
    }
    
    /// Add a point to the polygon or polyline.
    /// - parameter lat: the latitude of the point (degrees).
    /// - parameter lon: the latitude of the point (degrees).
    /// <i>lat</i> should be in the range [&minus;90&deg;, 90&deg;].
    public func addPoint(lat: Double, lon: Double) {
        let nlon = GeoMath.angNormalize(lon)
        if _num == 0 {
            _lat0 = lat
            _lat1 = lat
            _lon0 = nlon
            _lon1 = nlon
        } else {
            let g = _earth.inverse(lat1: _lat1, lon1: _lon1, lat2: lat, lon2: nlon, outmask: _mask)
            _perimetersum.add(g.s12)
            if !_polyline {
                _areasum.add(g.S12)
                _crossings += PolygonArea.transit(lon1: _lon1, lon2: nlon)
            }
            _lat1 = lat
            _lon1 = nlon
        }
        _num += 1
    }
    
    /// Add an edge to the polygon or polyline.
    /// - parameter azi: azimuth at current point (degrees).
    /// - parameter s: distance from current point to next point (meters).
    /// This does nothing if no points have been added yet.  Use
    /// PolygonArea.CurrentPoint to determine the position of the new vertex.
    public func addEdge(azi: Double, s: Double) {
        if _num > 0 {             // Do nothing if _num is zero
            let g = _earth.direct(lat1: _lat1, lon1: _lon1, azi1: azi, s12: s, outmask: _mask)
            _perimetersum.add(g.s12)
            if !_polyline {
                _areasum.add(g.S12);
                _crossings += PolygonArea.transitDirect(lon1: _lon1, lon2: g.lon2)
            }
            _lat1 = g.lat2
            _lon1 = g.lon2
            _num += 1
        }
    }
    
    /// Return the results so far.
    /// - returns: PolygonResult(<i>num</i>, <i>perimeter</i>, <i>area</i>) where
    ///  <i>num</i> is the number of vertices, <i>perimeter</i> is the perimeter
    ///  of the polygon or the length of the polyline (meters), and <i>area</i>
    ///  is the area of the polygon (meters<sup>2</sup>) or Double.NaN of
    ///  <i>polyline</i> is true in the constructor.
    ///
    /// Counter-clockwise traversal counts as a positive area.
    public func compute() -> PolygonResult {
        return compute(reverse: false, sign: true)
    }
    
    /// Return the results so far.
    /// - parameter reverse: if true then clockwise (instead of counter-clockwise)
    ///  traversal counts as a positive area.
    /// - parameter sign: if true then return a signed result for the area if
    ///  the polygon is traversed in the "wrong" direction instead of returning
    ///  the area for the rest of the earth.
    /// - returns: PolygonResult(<i>num</i>, <i>perimeter</i>, <i>area</i>) where
    ///  <i>num</i> is the number of vertices, <i>perimeter</i> is the perimeter
    ///  of the polygon or the length of the polyline (meters), and <i>area</i>
    ///  is the area of the polygon (meters<sup>2</sup>) or Double.NaN of
    ///  <i>polyline</i> is true in the constructor.
    ///
    /// More points can be added to the polygon after this call.
    public func compute(reverse: Bool, sign: Bool) -> PolygonResult {
        if _num < 2 {
            return PolygonResult(num: _num, perimeter: 0, area: _polyline ? Double.nan : 0)
        }
        if _polyline {
            return PolygonResult(num: _num, perimeter: _perimetersum.sum(), area: Double.nan)
        }
        
        let g = _earth.inverse(lat1: _lat1, lon1: _lon1, lat2: _lat0, lon2: _lon0, outmask: _mask)
        var tempsum = Accumulator(_areasum)
        tempsum.add(g.S12)
        
        let crossings = _crossings + PolygonArea.transit(lon1: _lon1, lon2: _lon0);
        if (crossings & 1) != 0 {
            tempsum.add((tempsum.sum() < 0 ? 1 : -1) * _area0 / 2)
        }
        
        // area is with the clockwise sense.  If !reverse convert to
        // counter-clockwise convention.
        if !reverse {
            tempsum.negate()
        }
        
        // If sign put area in (-area0/2, area0/2], else put area in [0, area0)
        if sign {
            if tempsum.sum() > _area0 / 2 {
                tempsum.add(-_area0)
            } else if tempsum.sum() <= -_area0 / 2 {
                tempsum.add(+_area0)
            }
        } else {
            if tempsum.sum() >= _area0 {
                tempsum.add(-_area0)
            } else if tempsum.sum() < 0 {
                tempsum.add(+_area0)
            }
        }
        
        return PolygonResult(num: _num, perimeter: _perimetersum.sum(g.s12), area: 0 + tempsum.sum())
    }
    
    /// Return the results assuming a tentative final test point is added;
    /// however, the data for the test point is not saved.  This lets you report
    /// a running result for the perimeter and area as the user moves the mouse
    /// cursor.  Ordinary floating point arithmetic is used to accumulate the
    /// data for the test point; thus the area and perimeter returned are less
    /// accurate than if AddPoint and Compute are used.
    ///
    /// - parameter lat: the latitude of the test point (degrees).
    /// - parameter lon: the longitude of the test point (degrees).
    /// - parameter reverse: if true then clockwise (instead of counter-clockwise)
    ///  traversal counts as a positive area.
    /// - parameter sign: if true then return a signed result for the area if
    ///  the polygon is traversed in the "wrong" direction instead of returning
    ///  the area for the rest of the earth.
    /// - returns: PolygonResult(<i>num</i>, <i>perimeter</i>, <i>area</i>) where
    ///  <i>num</i> is the number of vertices, <i>perimeter</i> is the perimeter
    ///  of the polygon or the length of the polyline (meters), and <i>area</i>
    ///  is the area of the polygon (meters<sup>2</sup>) or Double.NaN of
    ///  <i>polyline</i> is true in the constructor.
    ///
    /// <i>lat</i> should be in the range [&minus;90&deg;, 90&deg;].
    public func testPoint(lat: Double, lon: Double, reverse: Bool, sign: Bool) -> PolygonResult {
        if _num == 0 {
            return PolygonResult(num: 1, perimeter: 0, area: _polyline ? Double.nan : 0)
        }
            
        var perimeter = _perimetersum.sum()
        var tempsum = _polyline ? 0 : _areasum.sum()
        var crossings = _crossings
        let num = _num + 1
        for i in 0..<(_polyline ? 1 : 2) {
            let g = _earth.inverse(lat1: i == 0 ? _lat1 : lat, lon1: i == 0 ? _lon1 : lon,
                                   lat2: i != 0 ? _lat0 : lat, lon2: i != 0 ? _lon0 : lon,
                                   outmask: _mask)
            perimeter += g.s12
            if !_polyline {
                tempsum += g.S12
                crossings += PolygonArea.transit(lon1: i == 0 ? _lon1 : lon, lon2: i != 0 ? _lon0 : lon)
            }
        }
        
        if _polyline {
            return PolygonResult(num: num, perimeter: perimeter, area: .nan)
        }
        
        if (crossings & 1) != 0 {
            tempsum += (tempsum < 0 ? 1 : -1) * _area0 / 2
        }
        
        // area is with the clockwise sense.  If !reverse convert to
        // counter-clockwise convention.
        if !reverse {
            tempsum *= -1
        }
        
        // If sign put area in (-area0/2, area0/2], else put area in [0, area0)
        if sign {
            if tempsum > _area0 / 2 {
                tempsum -= _area0
            } else if tempsum <= -_area0 / 2 {
                tempsum += _area0
            }
        } else {
            if tempsum >= _area0 {
                tempsum -= _area0
            } else if tempsum < 0 {
                tempsum += _area0
            }
        }
        
        return PolygonResult(num: num, perimeter: perimeter, area: 0 + tempsum)
    }
    
    /// Return the results assuming a tentative final test point is added via an
    /// azimuth and distance; however, the data for the test point is not saved.
    /// This lets you report a running result for the perimeter and area as the
    /// user moves the mouse cursor.  Ordinary floating point arithmetic is used
    /// to accumulate the data for the test point; thus the area and perimeter
    /// returned are less accurate than if AddPoint and Compute are used.
    ///
    /// - parameter azi: azimuth at current point (degrees).
    /// - parameter s: distance from current point to final test point (meters).
    /// - parameter reverse: if true then clockwise (instead of counter-clockwise)
    ///   traversal counts as a positive area.
    /// - parameter sign: if true then return a signed result for the area if
    ///  the polygon is traversed in the "wrong" direction instead of returning
    ///  the area for the rest of the earth.
    /// - returns: PolygonResult(<i>num</i>, <i>perimeter</i>, <i>area</i>) where
    ///  <i>num</i> is the number of vertices, <i>perimeter</i> is the perimeter
    ///  of the polygon or the length of the polyline (meters), and <i>area</i>
    ///  is the area of the polygon (meters<sup>2</sup>) or Double.NaN of
    ///  <i>polyline</i> is true in the constructor.
    public func testEdge(azi: Double, s: Double, reverse: Bool, sign: Bool) -> PolygonResult {
        if _num == 0 {              // we don't have a starting point!
            return PolygonResult(num: 0, perimeter: Double.nan, area: Double.nan)
        }
        
        let num = _num + 1
        var perimeter = _perimetersum.sum() + s
        if _polyline {
            return PolygonResult(num: num, perimeter: perimeter, area: .nan)
        }
        
        var tempsum = _areasum.sum()
        var crossings = _crossings
        
        var g = _earth.direct(lat1: _lat1, lon1: _lon1, azi1: azi, arcmode: false, s12_a12: s, outmask: _mask)
        tempsum += g.S12
        crossings += PolygonArea.transitDirect(lon1: _lon1, lon2: g.lon2)
        g = _earth.inverse(lat1: g.lat2, lon1: g.lon2, lat2: _lat0, lon2: _lon0, outmask: _mask)
        perimeter += g.s12
        tempsum += g.S12
        crossings += PolygonArea.transit(lon1: g.lon2, lon2: _lon0)
        
        if (crossings & 1) != 0 {
            tempsum += (tempsum < 0 ? 1 : -1) * _area0 / 2
        }
        
        // area is with the clockwise sense.  If !reverse convert to
        // counter-clockwise convention.
        if !reverse {
            tempsum *= -1
        }
        
        // If sign put area in (-area0/2, area0/2], else put area in [0, area0)
        if sign {
            if tempsum > _area0 / 2 {
                tempsum -= _area0
            } else if tempsum <= -_area0 / 2 {
                tempsum += _area0
            }
        } else {
            if tempsum >= _area0 {
                tempsum -= _area0
            } else if tempsum < 0 {
                tempsum += _area0
            }
        }
    
        return PolygonResult(num: num, perimeter: perimeter, area: 0 + tempsum)
    }
    
    /// <i>a</i> the equatorial radius of the ellipsoid (meters).  This is
    ///  the value inherited from the Geodesic object used in the constructor.
    public var majorRadius: Double {
        return _earth.majorRadius
    }
    
    /// <i>f</i> the flattening of the ellipsoid.  This is the value
    /// inherited from the Geodesic object used in the constructor.
    public var flattening: Double {
        return _earth.flattening
    }
    
    /// Report the previous vertex added to the polygon or polyline.
    /// - returns: Pair(<i>lat</i>, <i>lon</i>), the current latitude and longitude.
    /// If no points have been added, then Double.NaN is returned.  Otherwise,
    /// <i>lon</i> will be in the range [&minus;180&deg;, 180&deg;].
    public func currentPoint() -> (Double, Double) {
        return (_lat1, _lon1)
    }
}
