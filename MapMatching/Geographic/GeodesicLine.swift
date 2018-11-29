//
//  GeodesicLine.swift
//  MapMatching
//
//  Created by devilrabbit on 2018/10/18.
//  Copyright (c) 2018 devilrabbit. All rights reserved.
//

import Foundation

/**
 * A geodesic line.
 * <p>
 * GeodesicLine facilitates the determination of a series of points on a single
 * geodesic.  The starting point (<i>lat1</i>, <i>lon1</i>) and the azimuth
 * <i>azi1</i> are specified in the constructor; alternatively, the {@link
 * Geodesic#Line Geodesic.Line} method can be used to create a GeodesicLine.
 * {@link #Position Position} returns the location of point 2 a distance
 * <i>s12</i> along the geodesic.  Alternatively {@link #ArcPosition
 * ArcPosition} gives the position of point 2 an arc length <i>a12</i> along
 * the geodesic.
 * <p>
 * You can register the position of a reference point 3 a distance (arc
 * length), <i>s13</i> (<i>a13</i>) along the geodesic with the
 * {@link #SetDistance SetDistance} ({@link #SetArc SetArc}) functions.  Points
 * a fractional distance along the line can be found by providing, for example,
 * 0.5 * {@link #Distance} as an argument to {@link #Position Position}.  The
 * {@link Geodesic#InverseLine Geodesic.InverseLine} or
 * {@link Geodesic#DirectLine Geodesic.DirectLine} methods return GeodesicLine
 * objects with point 3 set to the point 2 of the corresponding geodesic
 * problem.  GeodesicLine objects created with the public constructor or with
 * {@link Geodesic#Line Geodesic.Line} have <i>s13</i> and <i>a13</i> set to
 * NaNs.
 * <p>
 * The calculations are accurate to better than 15 nm (15 nanometers).  See
 * Sec. 9 of
 * <a href="https://arxiv.org/abs/1102.1215v1">arXiv:1102.1215v1</a> for
 * details.  The algorithms used by this class are based on series expansions
 * using the flattening <i>f</i> as a small parameter.  These are only accurate
 * for |<i>f</i>| &lt; 0.02; however reasonably accurate results will be
 * obtained for |<i>f</i>| &lt; 0.2.
 * <p>
 * The algorithms are described in
 * <ul>
 * <li>
 *   C. F. F. Karney,
 *   <a href="https://doi.org/10.1007/s00190-012-0578-z">
 *   Algorithms for geodesics</a>,
 *   J. Geodesy <b>87</b>, 43&ndash;55 (2013)
 *   (<a href="https://geographiclib.sourceforge.io/geod-addenda.html">addenda</a>).
 * </ul>
 * <p>
 * Here's an example of using this class
 * <pre>
 * {@code
 * import net.sf.geographiclib.*;
 * public class GeodesicLineTest {
 *   public static void main(String[] args) {
 *     // Print waypoints between JFK and SIN
 *     Geodesic geod = Geodesic.WGS84;
 *     double
 *       lat1 = 40.640, lon1 = -73.779, // JFK
 *       lat2 =  1.359, lon2 = 103.989; // SIN
 *     GeodesicLine line = geod.InverseLine(lat1, lon1, lat2, lon2,
 *                                          GeodesicMask.DISTANCE_IN |
 *                                          GeodesicMask.LATITUDE |
 *                                          GeodesicMask.LONGITUDE);
 *     double ds0 = 500e3;     // Nominal distance between points = 500 km
 *     // The number of intervals
 *     int num = (int)(Math.ceil(line.Distance() / ds0));
 *     {
 *       // Use intervals of equal length
 *       double ds = line.Distance() / num;
 *       for (int i = 0; i <= num; ++i) {
 *         GeodesicData g = line.Position(i * ds,
 *                                        GeodesicMask.LATITUDE |
 *                                        GeodesicMask.LONGITUDE);
 *         System.out.println(i + " " + g.lat2 + " " + g.lon2);
 *       }
 *     }
 *     {
 *       // Slightly faster, use intervals of equal arc length
 *       double da = line.Arc() / num;
 *       for (int i = 0; i <= num; ++i) {
 *         GeodesicData g = line.ArcPosition(i * da,
 *                                           GeodesicMask.LATITUDE |
 *                                           GeodesicMask.LONGITUDE);
 *         System.out.println(i + " " + g.lat2 + " " + g.lon2);
 *       }
 *     }
 *   }
 * }}</pre>
 **********************************************************************/
public final class GeodesicLine {
    
    private let nC1 = Geodesic.nC1
    private let nC1p = Geodesic.nC1p
    private let nC2 = Geodesic.nC2
    private let nC3 = Geodesic.nC3
    private let nC4 = Geodesic.nC4
    
    private var lat1: Double = .nan
    private var lon1: Double = .nan
    private var azi1: Double = .nan
    private var a: Double = .nan
    private var f: Double = .nan
    private var b: Double = .nan
    private var c2: Double = .nan
    private var f1: Double = .nan
    private var salp0: Double = .nan
    private var calp0: Double = .nan
    private var k2: Double = .nan
    private var salp1: Double = .nan
    private var calp1: Double = .nan
    private var ssig1: Double = .nan
    private var csig1: Double = .nan
    private var dn1: Double = .nan
    private var stau1: Double = .nan
    private var ctau1: Double = .nan
    private var somg1: Double = .nan
    private var comg1: Double = .nan
    private var A1m1: Double = .nan
    private var A2m1: Double = .nan
    private var A3c: Double = .nan
    private var B11: Double = .nan
    private var B21: Double = .nan
    private var B31: Double = .nan
    private var A4: Double = .nan
    private var B41: Double = .nan
    private var a13: Double = .nan
    private var s13: Double = .nan
    
    // index zero elements of C1a, C1pa, C2a, C3a are unused
    private var C1a: [Double] = []
    private var C1pa: [Double] = []
    private var C2a: [Double] = []
    private var C3a: [Double] = []
    private var C4a: [Double] = []    // all the elements of C4a are used
    
    private var caps: GeodesicMask = .NONE
    
    /**
     * Constructor for a geodesic line staring at latitude <i>lat1</i>, longitude
     * <i>lon1</i>, and azimuth <i>azi1</i> (all in degrees).
     * <p>
     * @param g A {@link Geodesic} object used to compute the necessary
     *   information about the GeodesicLine.
     * @param lat1 latitude of point 1 (degrees).
     * @param lon1 longitude of point 1 (degrees).
     * @param azi1 azimuth at point 1 (degrees).
     * <p>
     * <i>lat1</i> should be in the range [&minus;90&deg;, 90&deg;].
     * <p>
     * If the point is at a pole, the azimuth is defined by keeping <i>lon1</i>
     * fixed, writing <i>lat1</i> = &plusmn;(90&deg; &minus; &epsilon;), and
     * taking the limit &epsilon; &rarr; 0+.
     **********************************************************************/
    public convenience init(g: Geodesic, lat1: Double, lon1: Double, azi1: Double) {
        self.init(g: g, lat1: lat1, lon1: lon1, azi1: azi1, caps: .ALL)
    }
    
    
    /// Constructor for a geodesic line staring at latitude <i>lat1</i>, longitude
    /// <i>lon1</i>, and azimuth <i>azi1</i> (all in degrees) with a subset of the
    /// capabilities included.
    /// <p>
    /// @param g A {@link Geodesic} object used to compute the necessary
    ///   information about the GeodesicLine.
    /// @param lat1 latitude of point 1 (degrees).
    /// @param lon1 longitude of point 1 (degrees).
    /// @param azi1 azimuth at point 1 (degrees).
    /// @param caps bitor'ed combination of {@link GeodesicMask} values
    ///   specifying the capabilities the GeodesicLine object should possess,
    ///   i.e., which quantities can be returned in calls to {@link #Position
    ///   Position}.
    /// <p>
    /// The {@link GeodesicMask} values are
    /// <ul>
    /// <li>
    ///   <i>caps</i> |= {@link GeodesicMask#LATITUDE} for the latitude
    ///   <i>lat2</i>; this is added automatically;
    /// <li>
    ///   <i>caps</i> |= {@link GeodesicMask#LONGITUDE} for the latitude
    ///   <i>lon2</i>;
    /// <li>
    ///   <i>caps</i> |= {@link GeodesicMask#AZIMUTH} for the latitude
    ///   <i>azi2</i>; this is added automatically;
    /// <li>
    ///   <i>caps</i> |= {@link GeodesicMask#DISTANCE} for the distance
    ///   <i>s12</i>;
    /// <li>
    ///   <i>caps</i> |= {@link GeodesicMask#REDUCEDLENGTH} for the reduced length
    ///   <i>m12</i>;
    /// <li>
    ///   <i>caps</i> |= {@link GeodesicMask#GEODESICSCALE} for the geodesic
    ///   scales <i>M12</i> and <i>M21</i>;
    /// <li>
    ///   <i>caps</i> |= {@link GeodesicMask#AREA} for the area <i>S12</i>;
    /// <li>
    ///   <i>caps</i> |= {@link GeodesicMask#DISTANCE_IN} permits the length of
    ///   the geodesic to be given in terms of <i>s12</i>; without this capability
    ///   the length can only be specified in terms of arc length;
    /// <li>
    ///   <i>caps</i> |= {@link GeodesicMask#ALL} for all of the above.
    /// </ul>
    public init(g: Geodesic, lat1: Double, lon1: Double, azi1: Double, caps: GeodesicMask) {
        self.azi1 = GeoMath.angNormalize(azi1)
        let p = GeoMath.sincosd(GeoMath.angRound(azi1))
        let salp1 = p.0
        let calp1 = p.1
        commonInit(g: g, lat1: lat1, lon1: lon1, azi1: azi1, salp1: salp1, calp1: calp1, caps: caps)
    }
    
    init(g: Geodesic, lat1: Double, lon1: Double, azi1: Double, salp1: Double, calp1: Double, caps: GeodesicMask, arcmode: Bool, s13_a13: Double) {
        commonInit(g: g, lat1: lat1, lon1: lon1, azi1: azi1, salp1: salp1, calp1: calp1, caps: caps)
        genSetDistance(arcmode, s13_a13)
    }
    
    /// A default constructor.  If GeodesicLine.Position is called on the
    /// resulting object, it returns immediately (without doing any calculations).
    /// The object can be set with a call to {@link Geodesic.Line}.  Use {@link
    /// Init()} to test whether object is still in this uninitialized state.
    /// (This constructor was useful in C++, e.g., to allow vectors of
    /// GeodesicLine objects.  It may not be needed in Java, so make it private.)
    private init() {
        self.caps = .NONE
    }
    
    private func commonInit(g: Geodesic, lat1: Double, lon1: Double, azi1: Double, salp1: Double, calp1: Double, caps: GeodesicMask) {
        
        self.a = g.a
        self.f = g.f
        self.b = g.b
        self.c2 = g.c2
        self.f1 = g.f1
        
        // Always allow latitude and azimuth and unrolling the longitude
        self.caps = caps.union([GeodesicMask.LATITUDE, GeodesicMask.AZIMUTH, GeodesicMask.LONG_UNROLL])
        
        self.lat1 = GeoMath.latFix(lat1)
        self.lon1 = lon1
        self.azi1 = azi1
        self.salp1 = salp1
        self.calp1 = calp1
        
        let p1 = GeoMath.sincosd(GeoMath.angRound(self.lat1))
        var sbet1 = f1 * p1.0
        var cbet1 = p1.1
        
        // Ensure cbet1 = +epsilon at poles
        let p2 = GeoMath.norm(sbet1, cbet1)
        sbet1 = p2.0
        cbet1 = max(Geodesic.tiny, p2.1)
        self.dn1 = sqrt(1 + g.ep2 * GeoMath.sq(sbet1))
        
        // Evaluate alp0 from sin(alp1) * cos(bet1) = sin(alp0),
        self.salp0 = salp1 * cbet1 // alp0 in [0, pi/2 - |bet1|]
        
        // Alt: calp0 = hypot(sbet1, calp1 * cbet1).  The following
        // is slightly better (consider the case salp1 = 0).
        self.calp0 = GeoMath.hypot(calp1, salp1 * sbet1)
        
        // Evaluate sig with tan(bet1) = tan(sig1) * cos(alp1).
        // sig = 0 is nearest northward crossing of equator.
        // With bet1 = 0, alp1 = pi/2, we have sig1 = 0 (equatorial line).
        // With bet1 =  pi/2, alp1 = -pi, sig1 =  pi/2
        // With bet1 = -pi/2, alp1 =  0 , sig1 = -pi/2
        // Evaluate omg1 with tan(omg1) = sin(alp0) * tan(sig1).
        // With alp0 in (0, pi/2], quadrants for sig and omg coincide.
        // No atan2(0,0) ambiguity at poles since cbet1 = +epsilon.
        // With alp0 = 0, omg1 = 0 for alp1 = 0, omg1 = pi for alp1 = pi.
        self.ssig1 = sbet1
        self.somg1 = salp0 * sbet1
        self.csig1 = sbet1 != 0 || calp1 != 0 ? cbet1 * calp1 : 1
        self.comg1 = self.csig1
        
        let p3 = GeoMath.norm(ssig1, csig1);
        self.ssig1 = p3.0
        self.csig1 = p3.1
        // sig1 in (-pi, pi]
        // GeoMath.norm(_somg1, _comg1); -- don't need to normalize!
        
        self.k2 = GeoMath.sq(calp0) * g.ep2
        let eps = k2 / (2 * (1 + sqrt(1 + k2)) + k2)
        
        if caps.contains(GeodesicMask.CAP_C1) {
            self.A1m1 = Geodesic.A1m1f(eps)
            self.C1a = Array<Double>(repeating: 0, count: nC1 + 1)
            Geodesic.C1f(eps, &C1a)
            
            self.B11 = Geodesic.sincosSeries(true, ssig1, csig1, C1a)
            
            let s = sin(B11)
            let c = cos(B11)
            
            // tau1 = sig1 + B11
            self.stau1 = ssig1 * c + csig1 * s
            self.ctau1 = csig1 * c - ssig1 * s
            // Not necessary because C1pa reverts C1a
            //    _B11 = -SinCosSeries(true, _stau1, _ctau1, _C1pa, nC1p_);
        }
        
        if caps.contains(GeodesicMask.CAP_C1p) {
            self.C1pa = Array<Double>(repeating: 0, count: nC1p + 1)
            Geodesic.C1pf(eps, &C1pa)
        }
        
        if caps.contains(GeodesicMask.CAP_C2) {
            self.C2a = Array<Double>(repeating: 0, count: nC2 + 1)
            self.A2m1 = Geodesic.A2m1f(eps)
            Geodesic.C2f(eps, &C2a)
            self.B21 = Geodesic.sincosSeries(true, ssig1, csig1, C2a)
        }
        
        if caps.contains(GeodesicMask.CAP_C3) {
            self.C3a = Array<Double>(repeating: 0, count: nC3)
            g.C3f(eps, &C3a)
            self.A3c = -f * salp0 * g.A3f(eps)
            self.B31 = Geodesic.sincosSeries(true, ssig1, csig1, C3a)
        }
        
        if caps.contains(GeodesicMask.CAP_C4) {
            self.C4a = Array<Double>(repeating: 0, count: nC4)
            g.C4f(eps, &C4a)
            // Multiplier = a^2 * e^2 * cos(alpha0) * sin(alpha0)
            self.A4 = GeoMath.sq(a) * calp0 * salp0 * g.e2
            self.B41 = Geodesic.sincosSeries(false, ssig1, csig1, C4a)
        }
    }
    
    /// Compute the position of point 2 which is a distance <i>s12</i> (meters)
    /// from point 1.
    ///
    /// - parameter s12: distance from point 1 to point 2 (meters); it can be
    ///   negative.
    /// - returns: a {@link GeodesicData} object with the following fields:
    ///   <i>lat1</i>, <i>lon1</i>, <i>azi1</i>, <i>lat2</i>, <i>lon2</i>,
    ///   <i>azi2</i>, <i>s12</i>, <i>a12</i>.  Some of these results may be
    ///   missing if the GeodesicLine did not include the relevant capability.
    ///
    /// The values of <i>lon2</i> and <i>azi2</i> returned are in the range
    /// [&minus;180&deg;, 180&deg;].
    ///
    /// The GeodesicLine object <i>must</i> have been constructed with <i>caps</i>
    /// |= {@link GeodesicMask#DISTANCE_IN}; otherwise no parameters are set.
    public func position(_ s12: Double) -> GeodesicData {
        return position(false, s12, GeodesicMask.STANDARD)
    }
    
    /// Compute the position of point 2 which is a distance <i>s12</i> (meters)
    /// from point 1 and with a subset of the geodesic results returned.
    ///
    /// - parameter s12: distance from point 1 to point 2 (meters); it can be
    ///   negative.
    /// - parameter outmask: a bitor'ed combination of {@link GeodesicMask} values
    ///   specifying which results should be returned.
    /// - returns: a {@link GeodesicData} object including the requested results.
    ///
    /// The GeodesicLine object <i>must</i> have been constructed with <i>caps</i>
    /// |= {@link GeodesicMask#DISTANCE_IN}; otherwise no parameters are set.
    /// Requesting a value which the GeodesicLine object is not capable of
    /// computing is not an error (no parameters will be set).  The value of
    /// <i>lon2</i> returned is normally in the range [&minus;180&deg;, 180&deg;];
    /// however if the <i>outmask</i> includes the
    /// {@link GeodesicMask#LONG_UNROLL} flag, the longitude is "unrolled" so that
    /// the quantity <i>lon2</i> &minus; <i>lon1</i> indicates how many times and
    /// in what sense the geodesic encircles the ellipsoid.
    public func position(_ s12: Double, _ outmask: GeodesicMask) -> GeodesicData {
        return position(false, s12, outmask)
    }
    
    /// Compute the position of point 2 which is an arc length <i>a12</i>
    /// (degrees) from point 1.
    ///
    /// - parameter a12: arc length from point 1 to point 2 (degrees); it can
    ///   be negative.
    /// - returns: a {@link GeodesicData} object with the following fields:
    ///   <i>lat1</i>, <i>lon1</i>, <i>azi1</i>, <i>lat2</i>, <i>lon2</i>,
    ///   <i>azi2</i>, <i>s12</i>, <i>a12</i>.  Some of these results may be
    ///   missing if the GeodesicLine did not include the relevant capability.
    ///
    /// The values of <i>lon2</i> and <i>azi2</i> returned are in the range
    /// [&minus;180&deg;, 180&deg;].
    ///
    /// The GeodesicLine object <i>must</i> have been constructed with <i>caps</i>
    /// |= {@link GeodesicMask#DISTANCE_IN}; otherwise no parameters are set.
    public func arcPosition(_ a12: Double) -> GeodesicData {
        return position(true, a12, GeodesicMask.STANDARD)
    }
    
    /// Compute the position of point 2 which is an arc length <i>a12</i>
    /// (degrees) from point 1 and with a subset of the geodesic results returned.
    ///
    /// - parameter a12: arc length from point 1 to point 2 (degrees); it can
    ///   be negative.
    /// - parameter outmask: a bitor'ed combination of {@link GeodesicMask} values
    ///   specifying which results should be returned.
    /// - returns: a {@link GeodesicData} object giving <i>lat1</i>, <i>lon2</i>,
    ///   <i>azi2</i>, and <i>a12</i>.
    ///
    /// Requesting a value which the GeodesicLine object is not capable of
    /// computing is not an error (no parameters will be set).  The value of
    /// <i>lon2</i> returned is in the range [&minus;180&deg;, 180&deg;], unless
    /// the <i>outmask</i> includes the {@link GeodesicMask#LONG_UNROLL} flag.
    public func arcPosition(_ a12: Double, _ outmask: GeodesicMask) -> GeodesicData {
        return position(true, a12, outmask)
    }
    
    /// The general position function.  {@link #Position(double, int) Position}
    /// and {@link #arcPosition(double, int) ArcPosition} are defined in terms of
    /// this function.
    ///
    /// - parameter arcmode: bool flag determining the meaning of the second
    ///   parameter; if arcmode is false, then the GeodesicLine object must have
    ///   been constructed with <i>caps</i> |= {@link GeodesicMask#DISTANCE_IN}.
    /// - parameter s12_a12: if <i>arcmode</i> is false, this is the distance between
    ///   point 1 and point 2 (meters); otherwise it is the arc length between
    ///   point 1 and point 2 (degrees); it can be negative.
    /// - parameter outmask: a bitor'ed combination of {@link GeodesicMask} values
    ///   specifying which results should be returned.
    /// - returns: a {@link GeodesicData} object with the requested results.
    ///
    /// The {@link GeodesicMask} values possible for <i>outmask</i> are
    /// <ul>
    /// <li>
    ///   <i>outmask</i> |= {@link GeodesicMask#LATITUDE} for the latitude
    ///   <i>lat2</i>;
    /// <li>
    ///   <i>outmask</i> |= {@link GeodesicMask#LONGITUDE} for the latitude
    ///   <i>lon2</i>;
    /// <li>
    ///   <i>outmask</i> |= {@link GeodesicMask#AZIMUTH} for the latitude
    ///   <i>azi2</i>;
    /// <li>
    ///   <i>outmask</i> |= {@link GeodesicMask#DISTANCE} for the distance
    ///   <i>s12</i>;
    /// <li>
    ///   <i>outmask</i> |= {@link GeodesicMask#REDUCEDLENGTH} for the reduced
    ///   length <i>m12</i>;
    /// <li>
    ///   <i>outmask</i> |= {@link GeodesicMask#GEODESICSCALE} for the geodesic
    ///   scales <i>M12</i> and <i>M21</i>;
    /// <li>
    ///   <i>outmask</i> |= {@link GeodesicMask#ALL} for all of the above;
    /// <li>
    ///   <i>outmask</i> |= {@link GeodesicMask#LONG_UNROLL} to unroll <i>lon2</i>
    ///   (instead of reducing it to the range [&minus;180&deg;, 180&deg;]).
    /// </ul>
    ///
    /// Requesting a value which the GeodesicLine object is not capable of
    /// computing is not an error; Double.NaN is returned instead.
    public func position(_ arcmode: Bool, _ s12_a12: Double, _ mask: GeodesicMask) -> GeodesicData {
        let outmask = mask.intersection(caps).intersection(GeodesicMask.OUT_MASK)
        
        let r = GeodesicData()
        if !(isInitialized && (arcmode || caps.containsAny(GeodesicMask.OUT_MASK.intersection(GeodesicMask.DISTANCE_IN)))) {
            // Uninitialized or impossible distance calculation requested
            return r
        }
        
        r.lat1 = lat1
        r.azi1 = azi1
        r.lon1 = outmask.containsAny(GeodesicMask.LONG_UNROLL) ? lon1 : GeoMath.angNormalize(lon1)
        
        // Avoid warning about uninitialized B12.
        var sig12: Double
        var ssig12: Double
        var csig12: Double
        var B12: Double = 0
        var AB1: Double = 0
        if arcmode {
            // Interpret s12_a12 as spherical arc length
            r.a12 = s12_a12
            sig12 = GeoMath.toRadians(s12_a12)
            
            let p = GeoMath.sincosd(s12_a12);
            ssig12 = p.0
            csig12 = p.1
        } else {
            // Interpret s12_a12 as distance
            r.s12 = s12_a12
            
            let tau12 = s12_a12 / (b * (1 + A1m1))
            let s = sin(tau12)
            let c = cos(tau12)
            // tau2 = tau1 + tau12
            B12 = -Geodesic.sincosSeries(true, stau1 * c + ctau1 * s, ctau1 * c - stau1 * s, C1pa)
            sig12 = tau12 - (B12 - B11)
            ssig12 = sin(sig12)
            csig12 = cos(sig12)
            if abs(f) > 0.01 {
                // Reverted distance series is inaccurate for |f| > 1/100, so correct
                // sig12 with 1 Newton iteration.  The following table shows the
                // approximate maximum error for a = WGS_a() and various f relative to
                // GeodesicExact.
                //     erri = the error in the inverse solution (nm)
                //     errd = the error in the direct solution (series only) (nm)
                //     errda = the error in the direct solution
                //             (series + 1 Newton) (nm)
                //
                //       f     erri  errd errda
                //     -1/5    12e6 1.2e9  69e6
                //     -1/10  123e3  12e6 765e3
                //     -1/20   1110 108e3  7155
                //     -1/50  18.63 200.9 27.12
                //     -1/100 18.63 23.78 23.37
                //     -1/150 18.63 21.05 20.26
                //      1/150 22.35 24.73 25.83
                //      1/100 22.35 25.03 25.31
                //      1/50  29.80 231.9 30.44
                //      1/20   5376 146e3  10e3
                //      1/10  829e3  22e6 1.5e6
                //      1/5   157e6 3.8e9 280e6
                let ssig2 = ssig1 * csig12 + csig1 * ssig12
                let csig2 = csig1 * csig12 - ssig1 * ssig12
                
                B12 = Geodesic.sincosSeries(true, ssig2, csig2, C1a)
                
                let serr = (1 + A1m1) * (sig12 + (B12 - B11)) - s12_a12 / b
                
                sig12 = sig12 - serr / sqrt(1 + k2 * GeoMath.sq(ssig2))
                ssig12 = sin(sig12)
                csig12 = cos(sig12)
                // Update B12 below
            }
            
            r.a12 = GeoMath.toDegrees(sig12)
        }
        
        // sig2 = sig1 + sig12
        let ssig2 = ssig1 * csig12 + csig1 * ssig12
        var csig2 = csig1 * csig12 - ssig1 * ssig12
        let dn2 = sqrt(1 + k2 * GeoMath.sq(ssig2))
        if outmask.containsAny([GeodesicMask.DISTANCE, GeodesicMask.REDUCEDLENGTH, GeodesicMask.GEODESICSCALE]) {
            if arcmode || abs(f) > 0.01 {
                B12 = Geodesic.sincosSeries(true, ssig2, csig2, C1a)
            }
            AB1 = (1 + A1m1) * (B12 - B11)
        }
        
        // sin(bet2) = cos(alp0) * sin(sig2)
        let sbet2 = calp0 * ssig2
        // Alt: cbet2 = hypot(csig2, salp0 * ssig2)
        var cbet2 = GeoMath.hypot(salp0, calp0 * csig2)
        if cbet2 == 0 {
            // I.e., salp0 = 0, csig2 = 0.  Break the degeneracy in this case
            cbet2 = Geodesic.tiny
            csig2 = Geodesic.tiny
        }
        
        // tan(alp0) = cos(sig2)*tan(alp2)
        let salp2 = salp0
        let calp2 = calp0 * csig2 // No need to normalize
        
        if outmask.containsAny(GeodesicMask.DISTANCE) && arcmode {
            r.s12 = b * ((1 + A1m1) * sig12 + AB1);
        }
        
        if outmask.containsAny(GeodesicMask.LONGITUDE) {
            // tan(omg2) = sin(alp0) * tan(sig2)
            let somg2 = salp0 * ssig2
            let comg2 = csig2                       // No need to normalize
            let E = GeoMath.copySign(1, salp0);    // east or west going?
            
            // omg12 = omg2 - omg1
            let omg12 = outmask.containsAny(GeodesicMask.LONG_UNROLL) ?
                E * (sig12 - (atan2(ssig2, csig2) - atan2(ssig1, csig1)) + (atan2(E * somg2, comg2) - atan2(E * somg1, comg1))) :
                atan2(somg2 * comg1 - comg2 * somg1, comg2 * comg1 + somg2 * somg1)
            
            let lam12 = omg12 + A3c * (sig12 + (Geodesic.sincosSeries(true, ssig2, csig2, C3a) - B31))
            let lon12 = GeoMath.toDegrees(lam12)
            r.lon2 = outmask.containsAny(GeodesicMask.LONG_UNROLL) ? lon1 + lon12 : GeoMath.angNormalize(r.lon1 + GeoMath.angNormalize(lon12))
        }
        
        if outmask.containsAny(GeodesicMask.LATITUDE) {
            r.lat2 = GeoMath.atan2d(sbet2, f1 * cbet2)
        }
        
        if outmask.containsAny(GeodesicMask.AZIMUTH) {
            r.azi2 = GeoMath.atan2d(salp2, calp2);
        }
        
        if outmask.containsAny([GeodesicMask.REDUCEDLENGTH, GeodesicMask.GEODESICSCALE]) {
            let B22 = Geodesic.sincosSeries(true, ssig2, csig2, C2a)
            let AB2 = (1 + A2m1) * (B22 - B21)
            let J12 = (A1m1 - A2m1) * sig12 + (AB1 - AB2)
            
            if outmask.containsAny(GeodesicMask.REDUCEDLENGTH) {
            // Add parens around (_csig1 * ssig2) and (_ssig1 * csig2) to ensure
            // accurate cancellation in the case of coincident points.
                r.m12 = b * ((dn2 * (csig1 * ssig2) - dn1 * (ssig1 * csig2)) - csig1 * csig2 * J12)
            }
            
            if outmask.containsAny(GeodesicMask.GEODESICSCALE) {
                let t = k2 * (ssig2 - ssig1) * (ssig2 + ssig1) / (dn1 + dn2)
                r.M12 = csig12 + (t * ssig2 - csig2 * J12) * ssig1 / dn1
                r.M21 = csig12 - (t * ssig1 - csig1 * J12) * ssig2 / dn2
            }
        }
        
        if outmask.containsAny(GeodesicMask.AREA) {
            let B42 = Geodesic.sincosSeries(false, ssig2, csig2, C4a)
            let salp12: Double
            let calp12: Double
            if calp0 == 0 || salp0 == 0 {
                // alp12 = alp2 - alp1, used in atan2 so no need to normalize
                salp12 = salp2 * calp1 - calp2 * salp1
                calp12 = calp2 * calp1 + salp2 * salp1
            } else {
                // tan(alp) = tan(alp0) * sec(sig)
                // tan(alp2-alp1) = (tan(alp2) -tan(alp1)) / (tan(alp2)*tan(alp1)+1)
                // = calp0 * salp0 * (csig1-csig2) / (salp0^2 + calp0^2 * csig1*csig2)
                // If csig12 > 0, write
                //   csig1 - csig2 = ssig12 * (csig1 * ssig12 / (1 + csig12) + ssig1)
                // else
                //   csig1 - csig2 = csig1 * (1 - csig12) + ssig12 * ssig1
                // No need to normalize
                salp12 = calp0 * salp0 * (csig12 <= 0 ? csig1 * (1 - csig12) + ssig12 * ssig1 : ssig12 * (csig1 * ssig12 / (1 + csig12) + ssig1))
                calp12 = GeoMath.sq(salp0) + GeoMath.sq(calp0) * csig1 * csig2
            }
            
            r.S12 = c2 * atan2(salp12, calp12) + A4 * (B42 - B41)
        }
        
        return r
    }
    
    /// Specify position of point 3 in terms of distance.
    ///
    /// - parameter s13: the distance from point 1 to point 3 (meters); it
    ///   can be negative.
    ///
    /// This is only useful if the GeodesicLine object has been constructed
    /// with <i>caps</i> |= {@link GeodesicMask#DISTANCE_IN}.
    public func setDistance(_ s13: Double) {
        self.s13 = s13
        let g = position(false, s13, .NONE)
        self.a13 = g.a12
    }
    
    /// Specify position of point 3 in terms of arc length.
    ///
    /// - parameter a13: the arc length from point 1 to point 3 (degrees); it
    ///   can be negative.
    ///
    /// The distance <i>s13</i> is only set if the GeodesicLine object has been
    ///constructed with <i>caps</i> |= {@link GeodesicMask#DISTANCE}.
    func setArc(_ a13: Double) {
        self.a13 = a13
        let g = position(true, a13, .DISTANCE)
        self.s13 = g.s12
    }
    
    /// Specify position of point 3 in terms of either distance or arc length.
    ///
    /// - parameter arcmode: bool flag determining the meaning of the second
    ///   parameter; if <i>arcmode</i> is false, then the GeodesicLine object must
    ///   have been constructed with <i>caps</i> |=
    ///  {@link GeodesicMask#DISTANCE_IN}.
    /// - parameter s13_a13: if <i>arcmode</i> is false, this is the distance from
    ///   point 1 to point 3 (meters); otherwise it is the arc length from
    ///   point 1 to point 3 (degrees); it can be negative.
    public func genSetDistance(_ arcmode: Bool, _ s13_a13: Double) {
        if arcmode {
            setArc(s13_a13)
        } else {
            setDistance(s13_a13)
        }
    }
    
    /// return true if the object has been initialized.
    private var isInitialized: Bool {
        return self.caps != .NONE
    }
    
    /// return <i>lat1</i> the latitude of point 1 (degrees).
    public var latitude: Double {
        return isInitialized ? self.lat1 : .nan
    }
    
    /// return <i>lon1</i> the longitude of point 1 (degrees).
    public var longitude: Double {
        return isInitialized ? self.lon1 : .nan
    }
    
    /// return <i>azi1</i> the azimuth (degrees) of the geodesic line at point 1.
    public var azimuth: Double {
        return isInitialized ? self.azi1 : .nan
    }
    
    /// - returns: pair of sine and cosine of <i>azi1</i> the azimuth (degrees) of
    ///  the geodesic line at point 1.
    public func azimuthCosines() -> (Double, Double) {
        return isInitialized ? (self.salp1, self.calp1) : (.nan, .nan)
    }
    
    /// - returns: <i>azi0</i> the azimuth (degrees) of the geodesic line as it
    ///  crosses the equator in a northward direction.
    public func equatorialAzimuth() -> Double {
        return isInitialized ? GeoMath.atan2d(self.salp0, self.calp0) : .nan
    }
    
    /// - returns: pair of sine and cosine of <i>azi0</i> the azimuth of the geodesic
    ///  line as it crosses the equator in a northward direction.
    public func equatorialAzimuthCosines() -> (Double, Double) {
        return isInitialized ? (self.salp0, self.calp0) : (.nan, .nan)
    }
    
    /// - returns: <i>a1</i> the arc length (degrees) between the northward
    ///  equatorial crossing and point 1.
    public func equatorialArc() -> Double {
        return isInitialized ? GeoMath.atan2d(self.ssig1, self.csig1) : .nan
    }
    
    /// return <i>a</i> the equatorial radius of the ellipsoid (meters).  This is
    /// the value inherited from the Geodesic object used in the constructor.
    public var majorRadius: Double {
        return isInitialized ? self.a : .nan
    }
    
    /// return <i>f</i> the flattening of the ellipsoid.  This is the value
    /// inherited from the Geodesic object used in the constructor.
    public var flattening: Double {
        return isInitialized ? self.f : .nan
    }
    
    /// return <i>caps</i> the computational capabilities that this object was
    ///  constructed with.  LATITUDE and AZIMUTH are always included.
    public var capabilities: GeodesicMask {
        return self.caps
    }
    
    /// - parameter testcaps: a set of bitor'ed {@link GeodesicMask} values.
    /// - returns: true if the GeodesicLine object has all these capabilities.
    public func capabilities(_ testcaps: GeodesicMask) -> Bool {
        return self.caps.contains(testcaps)
    }
    
    /// The distance or arc length to point 3.
    /// - parameter arcmode: bool flag determining the meaning of returned value.
    /// - returns: <i>s13</i> if <i>arcmode</i> is false; <i>a13</i> if <i>arcmode</i> is true.
    public func genDistance(_ arcmode: Bool) -> Double {
        return isInitialized ? (arcmode ? self.a13 : self.s13) : .nan
    }
    
    /// return <i>s13</i>, the distance to point 3 (meters).
    public var distance: Double {
        return genDistance(false)
    }
    
    /// return <i>a13</i>, the arc length to point 3 (degrees).
    public var arc: Double {
        return genDistance(true)
    }
    
}
