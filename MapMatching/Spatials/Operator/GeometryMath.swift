//
//  GeometryMath.swift
//  MapMatching
//
//  Created by devilrabbit on 2018/10/10.
//  Copyright (c) 2018 devilrabbit. All rights reserved.
//

import CoreLocation

public final class GeometryMath {

    /// Computes the perpendicular distance from a point p
    /// to the (infinite) line containing the points AB
    /// Copy from NTS
    /// - parameter p: The point to compute the distance for.
    /// - parameter A: One point of the line.
    /// - parameter B: Another point of the line (must be different to A).
    /// - returns: The perpendicular distance from p to line AB.
    public static func distancePointLinePerpendicular(p: Coordinate2D, A: Coordinate2D, B: Coordinate2D) -> Double {
        // use comp.graphics.algorithms Frequently Asked Questions method
        /*(2)
         (Ay-Cy)(Bx-Ax)-(Ax-Cx)(By-Ay)
         s = -----------------------------
         Curve^2
         Then the distance from C to Point = |s|*Curve.
         */
        let len2 = ((B.x - A.x) * (B.x - A.x) + (B.y - A.y) * (B.y - A.y))
        let s = ((A.y - p.y) * (B.x - A.x) - (A.x - p.x) * (B.y - A.y)) / len2
        return abs(s) * sqrt(len2)
    }
    
    /// Computes the distance from a point p to a line segment AB.
    /// Note: NON-ROBUST!
    /// - parameter p: The point to compute the distance for.
    /// - parameter A: One point of the line.
    /// - parameter B: Another point of the line (must be different to A).
    /// - returns: The distance from p to line segment AB.
    public static func distancePointLine(p: Vec2D, A: Vec2D, B: Vec2D) -> Double {
        // if start = end, then just compute distance to one of the endpoints
        if A.x == B.x && A.y == B.y {
            return p.distance(A)
        }
        
        // otherwise use comp.graphics.algorithms Frequently Asked Questions method
        /*(1)
             AC dot AB
         r = ---------
             ||AB||^2
         r has the following meaning:
         r=0 Point = A
         r=1 Point = B
         r<0 Point is on the backward extension of AB
         r>1 Point is on the forward extension of AB
         0<r<1 Point is interior to AB
         */
        let len2 = ((B.x - A.x) * (B.x - A.x) + (B.y - A.y) * (B.y - A.y))
        let r = ((p.x - A.x) * (B.y - A.y) + (p.y - A.y) * (B.y - A.y)) / len2
        
        if r <= 0.0 {
            return p.distance(A)
        }
        if r >= 1.0 {
            return p.distance(B)
        }
        
        
        /*(2)
             (Ay-Cy)(Bx-Ax)-(Ax-Cx)(By-Ay)
         s = -----------------------------
                        Curve^2
         Then the distance from C to Point = |s|*Curve.
         This is the same calculation as {@link #distancePointLinePerpendicular}.
         Unrolled here for performance.
         */
        let s = ((A.y - p.y) * (B.x - A.x) - (A.x - p.x) * (B.y - A.y)) / len2
        return abs(s) * sqrt(len2)
    }
}
