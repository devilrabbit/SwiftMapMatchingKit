//
//  GeographySpatialOperator.swift
//  MapMatching
//
//  Created by devilrabbit on 2018/10/10.
//  Copyright (c) 2018 devilrabbit. All rights reserved.
//

import Foundation
import CoreLocation

public final class GeographySpatialOperator: SpatialOperator {
    
    private static let sharedInstance = GeographySpatialOperator()
    public static var shared: GeographySpatialOperator {
        return sharedInstance
    }
    
    public func distance(_ a: Coordinate2D, _ b: Coordinate2D) -> Double {
        return Geodesic.WGS84.inverse(lat1: a.y, lon1: a.x, lat2: b.y, lon2: b.x).s12
    }
    
    public func length(of line: Polyline2D) -> Double {
        return self.length(of: line.coordinates)
    }
    
    public func intercept(_ p: Polyline2D, _ c: Coordinate2D) -> Double {
        let coordinates = p.coordinates
        var d = Double.greatestFiniteMagnitude
        var a = coordinates[0]
        var s = 0.0
        var sf = 0.0
        var ds = 0.0
        
        for i in 1..<coordinates.count {
            let b = coordinates[i]
            let interceptTuple = interceptInternal(a, b, c)
            ds = interceptTuple.distance
            var f_ = interceptTuple.fraction
            f_ = (f_ > 1) ? 1 : (f_ < 0) ? 0 : f_
            let x = interpolate(a, b, f_)
            let d_ = distance(c, x)
            
            if (d_ < d) {
                sf = (f_ * ds) + s;
                d = d_;
            }
            
            s = s + ds;
            a = b;
        }
        
        return s == 0 ? 0 : sf / s
    }
    
    public func intercept(_ a: Coordinate2D, _ b: Coordinate2D, _ p: Coordinate2D) -> Double {
        return interceptInternal(a, b, p).fraction
    }
    
    public func interpolate(_ a: Coordinate2D, _ b: Coordinate2D, _ f: Double) -> Coordinate2D {
        return interpolateInternal(a, b, f).point
    }
    
    public func interpolate(_ path: Polyline2D, _ f: Double) -> Coordinate2D {
        return interpolate(path, length(of: path), f)
    }
    
    public func interpolate(_ path: Polyline2D, _ l: Double, _ f: Double) -> Coordinate2D {
        assert(f >= 0 && f <= 1, "f (\(f)) is out of range")
        
        let numberOfPoint = path.coordinates.count
        let p0 = path.coordinates[0]
        var a = p0;
        let d = l * f;
        var s = 0.0
        var ds = 0.0
        
        if f < 0 + 1E-10 {
            return p0
        }
        
        if f > 1 - 1E-10 {
            return path.coordinates[numberOfPoint - 1]
        }
        
        for i in 1..<numberOfPoint {
            let b = path.coordinates[i]
            ds = distance(a, b)
            
            if (s + ds) >= d {
                return interpolate(a, b, (d - s) / ds)
            }
            
            s += ds
            a = b
        }
        
        return CLLocationCoordinate2D(latitude: .nan, longitude: .nan)
    }
    
    public func azimuth(_ a: Coordinate2D, _ b: Coordinate2D, _ f: Double) -> Double {
        var azi = 0.0
        if f < 0 + 1E-10 {
            azi = Geodesic.WGS84.inverse(lat1: a.y, lon1: a.x, lat2: b.y, lon2: b.x).azi1
        } else if f > 1 - 1E-10 {
            azi = Geodesic.WGS84.inverse(lat1: a.y, lon1: a.x, lat2: b.y, lon2: b.x).azi2
        } else {
            let c = interpolate(a, b, f)
            azi = Geodesic.WGS84.inverse(lat1: a.y, lon1: a.x, lat2: c.y, lon2: c.x).azi2
        }
        return azi < 0 ? azi + 360 : azi
    }
    
    public func azimuth(_ path: Polyline2D, _ f: Double) -> Double {
        return azimuth(path, length(of: path), f)
    }
    
    public func azimuth(_ path: Polyline2D, _ l: Double, _ f: Double) -> Double {
        assert(f >= 0 && f <= 1, "f (\(f)) is out of range")
    
        let numberOfPoint = path.coordinates.count
        var a = path.coordinates[0]
        let d = l * f
        var s = 0.0
        var ds = 0.0
    
        if f < 0 + 1E-10 {
            return azimuth(path.coordinates[0], path.coordinates[1], 0)
        }
    
        if f > 1 - 1E-10 {
            return azimuth(path.coordinates[numberOfPoint - 2], path.coordinates[numberOfPoint - 1], f)
        }
    
        for i in 1..<numberOfPoint {
            let b = path.coordinates[i]
            ds = distance(a, b)
    
            if (s + ds) >= d {
                return azimuth(a, b, (d - s) / ds)
            }
    
            s = s + ds
            a = b
        }
    
        return Double.nan
    }
    
    public func envelope(_ c: Coordinate2D, _ radius: Double) -> Rect2D {
        let ymax = Geodesic.WGS84.direct(lat1: c.y, lon1: c.x, azi1: 0, s12: radius).lat2
        let ymin = Geodesic.WGS84.direct(lat1: c.y, lon1: c.x, azi1: -180, s12: radius).lat2
        let xmax = Geodesic.WGS84.direct(lat1: c.y, lon1: c.x, azi1: 90, s12: radius).lon2
        let xmin = Geodesic.WGS84.direct(lat1: c.y, lon1: c.x, azi1: -90, s12: radius).lon2
        return Rectangle2D(minX: xmin, minY: ymin, maxX: xmax, maxY: ymax)
    }
    
    public func envelope(_ line: Polyline2D) -> Rect2D {
        let lineString: LineString
        if let line = line as? LineString {
            lineString = line
        } else {
            lineString = LineString(geometry: line.coordinates)
        }
        return Turf.shared.bbox(lineString) ?? Rectangle2D()
    }
    
    private func length(of coordinates: [Coordinate2D]) -> Double {
        var d = 0.0
        for i in 1..<coordinates.count {
            d += distance(coordinates[i - 1], coordinates[i])
        }
        return d
    }
    
    private func interpolateInternal(_ a: Coordinate2D, _ b: Coordinate2D, _ f: Double) -> (point: Coordinate2D, distance: Double) {
        let inv = Geodesic.WGS84.inverse(lat1: a.y, lon1: a.x, lat2: b.y, lon2: b.x)
        let pos = Geodesic.WGS84.line(lat1: inv.lat1, lon1: inv.lon1, azi1: inv.azi1).position(inv.s12 * f)
        return (CLLocationCoordinate2D(latitude: pos.lat2, longitude: pos.lon2), inv.s12 * f)
    }
    
    private func interceptInternal(_ a: Coordinate2D, _ b: Coordinate2D, _ c: Coordinate2D) -> (distance: Double, fraction: Double) {
        if a.x == b.x && a.y == b.y {
            return (distance: 0, fraction: 0)
        }
        let inter = GeodesicInterception(earth: Geodesic.WGS84)
        let ci = inter.intercept(lata1: a.y, lona1: a.x, lata2: b.y, lona2: b.x, latb1: c.y, lonb1: c.x)
        let ai = Geodesic.WGS84.inverse(lat1: a.y, lon1: a.x, lat2: ci.lat2, lon2: ci.lon2)
        let ab = Geodesic.WGS84.inverse(lat1: a.y, lon1: a.x, lat2: b.y, lon2: b.x)
        let fraction = (abs(ai.azi1 - ab.azi1) < 1) ? ai.s12 / ab.s12 : (-1) * ai.s12 / ab.s12
        return (distance: ab.s12, fraction: fraction)
    }
    
}
