//
//  CartesianSpatialOperator.swift
//  MapMatching
//
//  Created by devilrabbit on 2018/10/10.
//  Copyright (c) 2018 devilrabbit. All rights reserved.
//

import Foundation

public final class CartesianSpatialOperator: SpatialOperator {
    
    private let TwoPi = Double.pi * 2
    private let Rad2Deg = 180.0 / Double.pi
    
    private static let sharedInstance = CartesianSpatialOperator()
    public static var shared: CartesianSpatialOperator {
        return sharedInstance
    }
    
    public func distance(_ a: Coordinate2D, _ b: Coordinate2D) -> Double {
        return a.distance(b)
    }
    
    public func length(of line: Polyline2D) -> Double {
        let coordinates = line.coordinates
        var d = 0.0
        for i in 1..<coordinates.count {
            d += distance(coordinates[i - 1], coordinates[i])
        }
        return d
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
            ds = distance(a, b)
            
            var f_ = intercept(a, b, c);
            f_ = (f_ > 1) ? 1 : (f_ < 0) ? 0 : f_;
            
            let x = interpolate(a, b, f_);
            let d_ = distance(c, x);
            
            if d_ < d {
                sf = (f_ * ds) + s
                d = d_
            }
            
            s = s + ds
            a = b
        }
        
        return s == 0 ? 0 : sf / s
    }
    
    public func intercept(_ a: Coordinate2D, _ b: Coordinate2D, _ p: Coordinate2D) -> Double {
        let d_ab = a.distance(b)
        let d_ap = a.distance(p)
        let d_abp = GeometryMath.distancePointLinePerpendicular(p: p, A: a, B: b)
        let d = sqrt(d_ap * d_ap - d_abp * d_abp)
        return d / d_ab
    }
    
    public func interpolate(_ a: Coordinate2D, _ b: Coordinate2D, _ f: Double) -> Coordinate2D {
        let l = a.distance(b)
        let d = l * f
        return Vector2D(x: a.x + d, y: a.y + d)
    }
    
    public func interpolate(_ path: Polyline2D, _ f: Double) -> Coordinate2D {
        let l = length(of: path)
        return interpolate(path, l, f)
    }
    
    public func interpolate(_ path: Polyline2D, _ l: Double, _ f: Double) -> Coordinate2D {
        if !(f >= 0 && f <= 1) {
            assertionFailure("f is out of range.")
        }
        
        let coordinates = path.coordinates
        
        let p0 = coordinates[0]
        let d = l * f
        
        var a = p0
        var s = 0.0
        var ds = 0.0
        
        if f < 0 + 1E-10 {
            return p0
        }
        
        if f > 1 - 1E-10 {
            return coordinates[coordinates.count - 1]
        }
        
        for i in 1..<coordinates.count {
            let b = coordinates[i]
            ds = distance(a, b)
            
            if (s + ds) >= d {
                return interpolate(a, b, (d - s) / ds)
            }
            
            s = s + ds
            a = b
        }
        
        return Vector2D(x: .nan, y: .nan)
    }
    
    public func azimuth(_ a: Coordinate2D, _ b: Coordinate2D, _ f: Double) -> Double {
        let dx = b.x - a.x
        let dy = b.y - b.y
        return 90 - (180 / .pi * atan2(dy, dx))
    }
    
    public func azimuth(_ path: Polyline2D, _ f: Double) -> Double {
        let l = length(of: path)
        return azimuth(path, l, f)
    }
    
    public func azimuth(_ path: Polyline2D, _ l: Double, _ f: Double) -> Double {
        let coordinates = path.coordinates
        let d = l * f
        
        var s = 0.0
        for i in 1..<coordinates.count {
            let a = coordinates[i - 1]
            let b = coordinates[i]
            let ds = a.distance(b);
            if (s + ds) >= d {
                return azimuth(a, b, (d - s) / ds)
            }
            s += ds
        }
        
        return Double.nan
    }
    
    
    public func envelope(_ c: Coordinate2D, _ radius: Double) -> Rect2D {
        let min = Vector2D(x: c.x - radius, y: c.y - radius)
        let max = Vector2D(x: c.x + radius, y: c.y + radius)
        return Rectangle2D(min: min, max: max)
    }
    
    public func envelope(_ line: Polyline2D) -> Rect2D {
        var minX = Double.greatestFiniteMagnitude
        var maxX = -Double.greatestFiniteMagnitude
        var minY = Double.greatestFiniteMagnitude
        var maxY = -Double.greatestFiniteMagnitude
        for coordinate in line.coordinates {
            if minX > coordinate.x {
                minX = coordinate.x
            }
            if maxX < coordinate.x {
                maxX = coordinate.x
            }
            if minY > coordinate.y {
                minY = coordinate.y
            }
            if maxY < coordinate.y {
                maxY = coordinate.y
            }
        }
        let min = Vector2D(x: minX, y: minY)
        let max = Vector2D(x: maxX, y: maxY)
        return Rectangle2D(min: min, max: max)
    }
}
