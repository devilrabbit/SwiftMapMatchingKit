//
//  GeoMath.swift
//  MapMatching
//
//  Created by devilrabbit on 2018/10/16.
//  Copyright (c) 2018 devilrabbit. All rights reserved.
//

import Foundation

/// Mathematical functions needed by GeographicLib.
/// Define mathematical functions and constants so that any version of Java
/// can be used.
public final class GeoMath {
    
    /// The number of binary digits in the fraction of a double precision
    /// number (equivalent to C++'s {@code numeric_limits<double>::digits}).
    public static let digits = 53
    
    /// Equivalent to C++'s {@code numeric_limits<double>::epsilon()}.  In Java
    /// version 1.5 and later, Math.ulp(1.0) can be used.
    public static let epsilon: Double = pow(0.5, Double(digits - 1))
    
    /// Equivalent to C++'s {@code numeric_limits<double>::min()}.  In Java
    /// version 1.6 and later, Double.MIN_NORMAL can be used.
    public static let min = pow(0.5, 1022.0)
    
    /// Square a number.
    /// - parameter x: the argument.
    /// - returns: <i>x</i><sup>2</sup>.
    public static func sq(_ x: Double) -> Double {
        return x * x
    }
    
    /// The hypotenuse function avoiding underflow and overflow.  In Java version
    /// 1.5 and later, Math.hypot can be used.
    /// - parameter x: the first argument.
    /// - parameter y: the second argument.
    /// - returns: sqrt(<i>x</i><sup>2</sup> + <i>y</i><sup>2</sup>).
    public static func hypot(_ x: Double, _ y: Double) -> Double {
        return Foundation.hypot(x, y)
        /*
        let xx = abs(x)
        let yy = abs(y)
        let a = max(xx, yy)
        let b = min(xx, yy) / (a != 0 ? a : 1)
        return a * sqrt(1 + b * b)
        // For an alternative method see
        // C. Moler and D. Morrision (1983) https://doi.org/10.1147/rd.276.0577
        // and A. A. Dubrulle (1983) https://doi.org/10.1147/rd.276.0582
        */
    }
    
    /// log(1 + <i>x</i>) accurate near <i>x</i> = 0.  In Java version 1.5 and
    /// later, Math.log1p can be used.
    /// This is taken from D. Goldberg,
    /// <a href="https://doi.org/10.1145/103162.103163">What every computer
    /// scientist should know about floating-point arithmetic</a> (1991),
    /// Theorem 4.  See also, N. J. Higham, Accuracy and Stability of Numerical
    /// Algorithms, 2nd Edition (SIAM, 2002), Answer to Problem 1.5, p 528.
    /// - parameter x: the argument.
    /// - returns: log(1 + <i>x</i>).
    public static func log1p(_ x: Double) -> Double {
        return Foundation.log1p(x)
        /*
        let y = 1 + x
        let z = y - 1
        // Here's the explanation for this magic: y = 1 + z, exactly, and z
        // approx x, thus log(y)/z (which is nearly constant near z = 0) returns
        // a good approximation to the true log(1 + x)/x.  The multiplication x *
        // (log(y)/z) introduces little additional error.
        return z == 0 ? x : x * log(y) / z
        */
    }
    
    /// The inverse hyperbolic tangent function.  This is defined in terms of
    /// GeoMath.log1p(<i>x</i>) in order to maintain accuracy near <i>x</i> = 0.
    /// In addition, the odd parity of the function is enforced.
    /// - parameter x: the argument.
    /// - returns: atanh(<i>x</i>).
    public static func atanh(_ x: Double) -> Double {
        return Foundation.atanh(x)
        /*
        var y = abs(x)     // Enforce odd parity
        y = log1p(2 * y / (1 - y)) / 2
        return x < 0 ? -y : y
        */
    }
    
    /// Copy the sign.  In Java version 1.6 and later, Math.copysign can be used.
    /// - parameter x: gives the magitude of the result.
    /// - parameter y: gives the sign of the result.
    /// - returns: value with the magnitude of <i>x</i> and with the sign of <i>y</i>.
    public static func copySign(_ x: Double, _ y: Double) -> Double {
        return Foundation.copysign(x, y)
        //return abs(x) * (y < 0 || (y == 0 && 1 / y < 0) ? -1 : 1)
    }
    
    /// The cube root function.  In Java version 1.5 and later, Math.cbrt can be used.
    /// - parameter x: the argument.
    /// - returns: the real cube root of <i>x</i>.
    public static func cbrt(_ x: Double) -> Double {
        return Foundation.cbrt(x)
        /*
        let y = pow(abs(x), 1 / 3.0) // Return the real cube root
        return x < 0 ? -y : y
        */
    }
    
    public static func norm(_ sinx: Double, _ cosx: Double) -> (Double, Double) {
        let r = hypot(sinx, cosx)
        return (sinx / r, cosx / r)
    }
    
    /// The error-free sum of two numbers.
    /// - parameter u: the first number in the sum.
    /// - parameter v: the second number in the sum.
    /// - returns: Pair(<i>s</i>, <i>t</i>) with <i>s</i> = round(<i>u</i> +
    ///   <i>v</i>) and <i>t</i> = <i>u</i> + <i>v</i> - <i>s</i>.
    /// See D. E. Knuth, TAOCP, Vol 2, 4.2.2, Theorem B.
    public static func sum(_ u: Double, _ v: Double) -> (Double, Double) {
        let s = u + v
        var up = s - v
        var vpp = s - up
        up -= u
        vpp -= v
        let t = -(up + vpp)
        // u + v =       s      + t
        //       = round(u + v) + t
        return (s, t)
    }
    
    /// Evaluate a polynomial.
    /// Evaluate <i>y</i> = &sum;<sub><i>n</i>=0..<i>N</i></sub>
    /// <i>p</i><sub><i>s</i>+<i>n</i></sub>
    /// <i>x</i><sup><i>N</i>&minus;<i>n</i></sup>.  Return 0 if <i>N</i> &lt; 0.
    /// Return <i>p</i><sub><i>s</i></sub>, if <i>N</i> = 0 (even if <i>x</i> is
    /// infinite or a nan).  The evaluation uses Horner's method.
    /// - parameter n: the order of the polynomial.
    /// - parameter p: the coefficient array (of size <i>N</i> + <i>s</i> + 1 or more).
    /// - parameter s: starting index for the array.
    /// - parameter x: the variable.
    /// - returns: the value of the polynomial.
    public static func polyval(n: Int, p: [Double], s: Int, x: Double) -> Double {
        var y = n < 0 ? 0 : p[s]
        var i = s + 1
        if n > 0 {
            for _ in 0...(n-1) {
                y = y * x + p[i]
                i += 1
            }
        }
        return y
    }
    
    public static func angRound(_ x: Double) -> Double {
        // The makes the smallest gap in x = 1/16 - nextafter(1/16, 0) = 1/2^57
        // for reals = 0.7 pm on the earth if x is an angle in degrees.  (This
        // is about 1000 times more resolution than we get with angles around 90
        // degrees.)  We use this to avoid having to deal with near singular
        // cases when x is non-zero but tiny (e.g., 1.0e-200).  This converts -0 to
        // +0; however tiny negative numbers get converted to -0.
        let z = 1.0 / 16.0
        if x == 0 {
            return 0.0
        }
        
        var y = abs(x)
        // The compiler mustn't "simplify" z - (z - y) to y
        y = y < z ? z - (z - y) : y
        return x < 0 ? -y : y
    }
    
    /// Normalize an angle (restricted input range).
    /// - parameter x: the angle in degrees.
    /// - returns: the angle reduced to the range [&minus;180&deg;, 180&deg;).
    /// The range of <i>x</i> is unrestricted.
    public static func angNormalize(_ x: Double) -> Double {
        let xx = x.truncatingRemainder(dividingBy: 360.0)
        return xx <= -180 ? xx + 360 : (xx <= 180 ? xx : xx - 360)
    }
    
    /// Normalize a latitude.
    /// - parameter x: the angle in degrees.
    /// - returns: x if it is in the range [&minus;90&deg;, 90&deg;], otherwise return NaN.
    public static func latFix(_ x: Double) -> Double {
        return abs(x) > 90 ? Double.nan : x
    }
    
    /// The exact difference of two angles reduced to (&minus;180&deg;, 180&deg;].
    /// - parameter x: the first angle in degrees.
    /// - parameter y: the second angle in degrees.
    /// - returns: Pair(<i>d</i>, <i>e</i>) with <i>d</i> being the rounded
    /// difference and <i>e</i> being the error.
    /// The computes <i>z</i> = <i>y</i> &minus; <i>x</i> exactly, reduced to
    /// (&minus;180&deg;, 180&deg;]; and then sets <i>z</i> = <i>d</i> + <i>e</i>
    /// where <i>d</i> is the nearest representable number to <i>z</i> and
    /// <i>e</i> is the truncation error.  If <i>d</i> = &minus;180, then <i>e</i>
    /// &gt; 0; If <i>d</i> = 180, then <i>e</i> &le; 0.
    public static func angDiff(_ x: Double, _ y: Double) -> (Double, Double) {
        let r = sum(angNormalize(-x), angNormalize(y))
        let d = angNormalize(r.0)
        let t = r.1
        return sum(d == 180 && t > 0 ? -180.0 : d, t)
    }
    
    /// Evaluate the sine and cosine function with the argument in degrees
    /// - parameter x: in degrees.
    /// - returns: Pair(<i>s</i>, <i>t</i>) with <i>s</i> = sin(<i>x</i>) and
    ///   <i>c</i> = cos(<i>x</i>).
    /// The results obey exactly the elementary properties of the trigonometric
    /// functions, e.g., sin 9&deg; = cos 81&deg; = &minus; sin 123456789&deg;.
    public static func sincosd(_ x: Double) -> (Double, Double) {
        // In order to minimize round-off errors, this function exactly reduces
        // the argument to the range [-45, 45] before converting it to radians.
        var r = x.truncatingRemainder(dividingBy: 360.0)
        if r.isNaN {
            return (.nan, .nan)
        }
        
        let q = Int(floor(r / 90 + 0.5))
        
        r -= 90.0 * Double(q)
        // now abs(r) <= 45
        r = toRadians(r)
        
        // Possibly could call the gnu extension sincos
        let s = sin(r)
        let c = cos(r)
        
        var sinx: Double
        var cosx: Double
        
        switch (q & 3) {
        case 0:
            sinx = s
            cosx = c
        case 1:
            sinx = c
            cosx = -s
        case 2:
            sinx = -s
            cosx = -c
        default:
            sinx = -c
            cosx = s // case 3
        }

        if x != 0 {
            sinx += 0.0
            cosx += 0.0
        }

        return (sinx, cosx)
    }
    
    /// Evaluate the atan2 function with the result in degrees
    /// - parameter y: the sine of the angle
    /// - parameter x: the cosine of the angle
    /// - returns: atan2(<i>y</i>, <i>x</i>) in degrees.
    ///
    /// The result is in the range (&minus;180&deg; 180&deg;].  N.B.,
    /// atan2d(&plusmn;0, &minus;1) = +180&deg;; atan2d(&minus;&epsilon;,
    /// &minus;1) = &minus;180&deg;, for &epsilon; positive and tiny;
    /// atan2d(&plusmn;0, 1) = &plusmn;0&deg;.
    public static func atan2d(_ y: Double, _ x: Double) -> Double {
        // In order to minimize round-off errors, this function rearranges the
        // arguments so that result of atan2 is in the range [-pi/4, pi/4] before
        // converting it to degrees and mapping the result to the correct
        // quadrant.
        var xx = x
        var yy = y
        var q = 0
        
        if abs(y) > abs(x) {
            let t = x
            xx = y
            yy = t
            q = 2
        }
        
        if xx < 0 {
            xx = -xx
            q += 1
        }
        
        // here x >= 0 and x >= abs(y), so angle is in [-pi/4, pi/4]
        var ang = toDegrees(atan2(yy, xx))
        switch q {
        // Note that atan2d(-0.0, 1.0) will return -0.  However, we expect that
        // atan2d will not be called with y = -0.  If need be, include
        //
        //   case 0: ang = 0 + ang; break;
        //
        // and handle mpfr as in AngRound.
        case 1:
            ang = (yy >= 0 ? 180 : -180) - ang
        case 2:
            ang = 90 - ang
        case 3:
            ang = -90 + ang
        default:
            break
        }
        
        return ang
    }
    
    /// Test for finiteness.
    /// - parameter x: the argument.
    /// - returns: true if number is finite, false if NaN or infinite.
    public static func isFinite(_ x: Double) -> Bool {
        return x.isFinite
        //return abs(x) <= Double.greatestFiniteMagnitude
    }
    
    public static func toDegrees(_ r: Double) -> Double {
        return 180.0 / .pi * r
    }
    
    public static func toRadians(_ d: Double) -> Double {
        return .pi / 180.0 * d
    }
}
