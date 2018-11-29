//
//  Geodesic.swift
//  MapMatching
//
//  Created by devilrabbit on 2018/10/16.
//  Copyright (c) 2018 devilrabbit. All rights reserved.
//

import Foundation

/// The order of the expansions used by Geodesic.
private let GEOGRAPHICLIB_GEODESIC_ORDER = 6

/**
 * Geodesic calculations.
 * <p>
 * The shortest path between two points on a ellipsoid at (<i>lat1</i>,
 * <i>lon1</i>) and (<i>lat2</i>, <i>lon2</i>) is called the geodesic.  Its
 * length is <i>s12</i> and the geodesic from point 1 to point 2 has azimuths
 * <i>azi1</i> and <i>azi2</i> at the two end points.  (The azimuth is the
 * heading measured clockwise from north.  <i>azi2</i> is the "forward"
 * azimuth, i.e., the heading that takes you beyond point 2 not back to point
 * 1.)
 * <p>
 * Given <i>lat1</i>, <i>lon1</i>, <i>azi1</i>, and <i>s12</i>, we can
 * determine <i>lat2</i>, <i>lon2</i>, and <i>azi2</i>.  This is the
 * <i>direct</i> geodesic problem and its solution is given by the function
 * {@link #Direct Direct}.  (If <i>s12</i> is sufficiently large that the
 * geodesic wraps more than halfway around the earth, there will be another
 * geodesic between the points with a smaller <i>s12</i>.)
 * <p>
 * Given <i>lat1</i>, <i>lon1</i>, <i>lat2</i>, and <i>lon2</i>, we can
 * determine <i>azi1</i>, <i>azi2</i>, and <i>s12</i>.  This is the
 * <i>inverse</i> geodesic problem, whose solution is given by {@link #Inverse
 * Inverse}.  Usually, the solution to the inverse problem is unique.  In cases
 * where there are multiple solutions (all with the same <i>s12</i>, of
 * course), all the solutions can be easily generated once a particular
 * solution is provided.
 * <p>
 * The standard way of specifying the direct problem is the specify the
 * distance <i>s12</i> to the second point.  However it is sometimes useful
 * instead to specify the arc length <i>a12</i> (in degrees) on the auxiliary
 * sphere.  This is a mathematical construct used in solving the geodesic
 * problems.  The solution of the direct problem in this form is provided by
 * {@link #ArcDirect ArcDirect}.  An arc length in excess of 180&deg; indicates
 * that the geodesic is not a shortest path.  In addition, the arc length
 * between an equatorial crossing and the next extremum of latitude for a
 * geodesic is 90&deg;.
 * <p>
 * This class can also calculate several other quantities related to
 * geodesics.  These are:
 * <ul>
 * <li>
 *   <i>reduced length</i>.  If we fix the first point and increase
 *   <i>azi1</i> by <i>dazi1</i> (radians), the second point is displaced
 *   <i>m12</i> <i>dazi1</i> in the direction <i>azi2</i> + 90&deg;.  The
 *   quantity <i>m12</i> is called the "reduced length" and is symmetric under
 *   interchange of the two points.  On a curved surface the reduced length
 *   obeys a symmetry relation, <i>m12</i> + <i>m21</i> = 0.  On a flat
 *   surface, we have <i>m12</i> = <i>s12</i>.  The ratio <i>s12</i>/<i>m12</i>
 *   gives the azimuthal scale for an azimuthal equidistant projection.
 * <li>
 *   <i>geodesic scale</i>.  Consider a reference geodesic and a second
 *   geodesic parallel to this one at point 1 and separated by a small distance
 *   <i>dt</i>.  The separation of the two geodesics at point 2 is <i>M12</i>
 *   <i>dt</i> where <i>M12</i> is called the "geodesic scale".  <i>M21</i> is
 *   defined similarly (with the geodesics being parallel at point 2).  On a
 *   flat surface, we have <i>M12</i> = <i>M21</i> = 1.  The quantity
 *   1/<i>M12</i> gives the scale of the Cassini-Soldner projection.
 * <li>
 *   <i>area</i>.  The area between the geodesic from point 1 to point 2 and
 *   the equation is represented by <i>S12</i>; it is the area, measured
 *   counter-clockwise, of the geodesic quadrilateral with corners
 *   (<i>lat1</i>,<i>lon1</i>), (0,<i>lon1</i>), (0,<i>lon2</i>), and
 *   (<i>lat2</i>,<i>lon2</i>).  It can be used to compute the area of any
 *   simple geodesic polygon.
 * </ul>
 * <p>
 * The quantities <i>m12</i>, <i>M12</i>, <i>M21</i> which all specify the
 * behavior of nearby geodesics obey addition rules.  If points 1, 2, and 3 all
 * lie on a single geodesic, then the following rules hold:
 * <ul>
 * <li>
 *   <i>s13</i> = <i>s12</i> + <i>s23</i>
 * <li>
 *   <i>a13</i> = <i>a12</i> + <i>a23</i>
 * <li>
 *   <i>S13</i> = <i>S12</i> + <i>S23</i>
 * <li>
 *   <i>m13</i> = <i>m12</i> <i>M23</i> + <i>m23</i> <i>M21</i>
 * <li>
 *   <i>M13</i> = <i>M12</i> <i>M23</i> &minus; (1 &minus; <i>M12</i>
 *   <i>M21</i>) <i>m23</i> / <i>m12</i>
 * <li>
 *   <i>M31</i> = <i>M32</i> <i>M21</i> &minus; (1 &minus; <i>M23</i>
 *   <i>M32</i>) <i>m12</i> / <i>m23</i>
 * </ul>
 * <p>
 * The results of the geodesic calculations are bundled up into a {@link
 * GeodesicData} object which includes the input parameters and all the
 * computed results, i.e., <i>lat1</i>, <i>lon1</i>, <i>azi1</i>, <i>lat2</i>,
 * <i>lon2</i>, <i>azi2</i>, <i>s12</i>, <i>a12</i>, <i>m12</i>, <i>M12</i>,
 * <i>M21</i>, <i>S12</i>.
 * <p>
 * The functions {@link #Direct(double, double, double, double, int) Direct},
 * {@link #ArcDirect(double, double, double, double, int) ArcDirect}, and
 * {@link #Inverse(double, double, double, double, int) Inverse} include an
 * optional final argument <i>outmask</i> which allows you specify which
 * results should be computed and returned.  If you omit <i>outmask</i>, then
 * the "standard" geodesic results are computed (latitudes, longitudes,
 * azimuths, and distance).  <i>outmask</i> is bitor'ed combination of {@link
 * GeodesicMask} values.  For example, if you wish just to compute the distance
 * between two points you would call, e.g.,
 * <pre>
 * {@code
 *  GeodesicData g = Geodesic.WGS84.Inverse(lat1, lon1, lat2, lon2,
 *                      GeodesicMask.DISTANCE); }</pre>
 * <p>
 * Additional functionality is provided by the {@link GeodesicLine} class,
 * which allows a sequence of points along a geodesic to be computed.
 * <p>
 * The shortest distance returned by the solution of the inverse problem is
 * (obviously) uniquely defined.  However, in a few special cases there are
 * multiple azimuths which yield the same shortest distance.  Here is a
 * catalog of those cases:
 * <ul>
 * <li>
 *   <i>lat1</i> = &minus;<i>lat2</i> (with neither point at a pole).  If
 *   <i>azi1</i> = <i>azi2</i>, the geodesic is unique.  Otherwise there are
 *   two geodesics and the second one is obtained by setting [<i>azi1</i>,
 *   <i>azi2</i>] &rarr; [<i>azi2</i>, <i>azi1</i>], [<i>M12</i>, <i>M21</i>]
 *   &rarr; [<i>M21</i>, <i>M12</i>], <i>S12</i> &rarr; &minus;<i>S12</i>.
 *   (This occurs when the longitude difference is near &plusmn;180&deg; for
 *   oblate ellipsoids.)
 * <li>
 *   <i>lon2</i> = <i>lon1</i> &plusmn; 180&deg; (with neither point at a
 *   pole).  If <i>azi1</i> = 0&deg; or &plusmn;180&deg;, the geodesic is
 *   unique.  Otherwise there are two geodesics and the second one is obtained
 *   by setting [ <i>azi1</i>, <i>azi2</i>] &rarr; [&minus;<i>azi1</i>,
 *   &minus;<i>azi2</i>], <i>S12</i> &rarr; &minus; <i>S12</i>.  (This occurs
 *   when <i>lat2</i> is near &minus;<i>lat1</i> for prolate ellipsoids.)
 * <li>
 *   Points 1 and 2 at opposite poles.  There are infinitely many geodesics
 *   which can be generated by setting [<i>azi1</i>, <i>azi2</i>] &rarr;
 *   [<i>azi1</i>, <i>azi2</i>] + [<i>d</i>, &minus;<i>d</i>], for arbitrary
 *   <i>d</i>.  (For spheres, this prescription applies when points 1 and 2 are
 *   antipodal.)
 * <li>
 *   <i>s12</i> = 0 (coincident points).  There are infinitely many geodesics
 *   which can be generated by setting [<i>azi1</i>, <i>azi2</i>] &rarr;
 *   [<i>azi1</i>, <i>azi2</i>] + [<i>d</i>, <i>d</i>], for arbitrary <i>d</i>.
 * </ul>
 * <p>
 * The calculations are accurate to better than 15 nm (15 nanometers) for the
 * WGS84 ellipsoid.  See Sec. 9 of
 * <a href="https://arxiv.org/abs/1102.1215v1">arXiv:1102.1215v1</a> for
 * details.  The algorithms used by this class are based on series expansions
 * using the flattening <i>f</i> as a small parameter.  These are only accurate
 * for |<i>f</i>| &lt; 0.02; however reasonably accurate results will be
 * obtained for |<i>f</i>| &lt; 0.2.  Here is a table of the approximate
 * maximum error (expressed as a distance) for an ellipsoid with the same
 * equatorial radius as the WGS84 ellipsoid and different values of the
 * flattening.<pre>
 *     |f|      error
 *     0.01     25 nm
 *     0.02     30 nm
 *     0.05     10 um
 *     0.1     1.5 mm
 *     0.2     300 mm </pre>
 * <p>
 * The algorithms are described in
 * <ul>
 * <li>C. F. F. Karney,
 *   <a href="https://doi.org/10.1007/s00190-012-0578-z">
 *   Algorithms for geodesics</a>,
 *   J. Geodesy <b>87</b>, 43&ndash;55 (2013)
 *   (<a href="https://geographiclib.sourceforge.io/geod-addenda.html">addenda</a>).
 * </ul>
 * <p>
 * Example of use:
 * <pre>
 * {@code
 * // Solve the direct geodesic problem.
 *
 * // This program reads in lines with lat1, lon1, azi1, s12 and prints
 * // out lines with lat2, lon2, azi2 (for the WGS84 ellipsoid).
 *
 * import java.util.*;
 * import net.sf.geographiclib.*;
 * public class Direct {
 *   public static void main(String[] args) {
 *     try {
 *       Scanner in = new Scanner(System.in);
 *       double lat1, lon1, azi1, s12;
 *       while (true) {
 *         lat1 = in.nextDouble(); lon1 = in.nextDouble();
 *         azi1 = in.nextDouble(); s12 = in.nextDouble();
 *         GeodesicData g = Geodesic.WGS84.Direct(lat1, lon1, azi1, s12);
 *         System.out.println(g.lat2 + " " + g.lon2 + " " + g.azi2);
 *       }
 *     }
 *     catch (Exception e) {}
 *   }
 * }}</pre>
 **********************************************************************/
public final class Geodesic {
    
    static let nA1 = GEOGRAPHICLIB_GEODESIC_ORDER
    static let nC1 = GEOGRAPHICLIB_GEODESIC_ORDER
    static let nC1p = GEOGRAPHICLIB_GEODESIC_ORDER
    static let nA2 = GEOGRAPHICLIB_GEODESIC_ORDER
    static let nC2 = GEOGRAPHICLIB_GEODESIC_ORDER
    static let nA3 = GEOGRAPHICLIB_GEODESIC_ORDER
    static let nA3x = nA3
    static let nC3 = GEOGRAPHICLIB_GEODESIC_ORDER
    static let nC3x = (nC3 * (nC3 - 1)) / 2
    static let nC4 = GEOGRAPHICLIB_GEODESIC_ORDER
    static let nC4x = (nC4 * (nC4 + 1)) / 2
    
    private let maxit1 = 20
    private let maxit2 = 20 + GeoMath.digits + 10
    
    // Underflow guard.  We require
    //   tiny_ * epsilon() > 0
    //   tiny_ + epsilon() == epsilon()
    internal static let tiny = sqrt(GeoMath.min)
    private static let tol0 = GeoMath.epsilon
    
    // Increase multiplier in defn of tol1_ from 100 to 200 to fix inverse case
    // 52.784459512564 0 -52.784459512563990912 179.634407464943777557
    // which otherwise failed for Visual Studio 10 (Release and Debug)
    private static let tol1 = 200 * tol0
    private static let tol2 = sqrt(tol0)
    
    // Check on bisection interval
    private static let tolb = tol0 * tol2
    private static let xthresh = 1000 * tol2
    
    let a: Double
    let f: Double
    let f1: Double
    let e2: Double
    let ep2: Double
    let b: Double
    let c2: Double
    
    private let n: Double
    private let etol2: Double
    
    private var A3x: [Double]
    private var C3x: [Double]
    private var C4x: [Double]
    
    /**
     * Constructor for a ellipsoid with
     * <p>
     * @param a equatorial radius (meters).
     * @param f flattening of ellipsoid.  Setting <i>f</i> = 0 gives a sphere.
     *   Negative <i>f</i> gives a prolate ellipsoid.
     * @exception GeographicErr if <i>a</i> or (1 &minus; <i>f</i> ) <i>a</i> is
     *   not positive.
     **********************************************************************/
    public init(a: Double, f: Double) {
        self.a = a
        self.f = f
        self.f1 = 1 - f
        self.e2 = f * (2 - f)
        self.ep2 = e2 / GeoMath.sq(f1) // e2 / (1 - e2)
        self.n = f / (2 - f)
        
        let b = a * f1
        self.b = b
        self.c2 = (GeoMath.sq(a) + GeoMath.sq(b) * (e2 == 0 ? 1 : (e2 > 0 ? GeoMath.atanh(sqrt(e2)) : atan(sqrt(-e2))) / sqrt(abs(e2)))) / 2 // authalic radius squared
        
        // The sig12 threshold for "really short".  Using the auxiliary sphere
        // solution with dnm computed at (bet1 + bet2) / 2, the relative error in
        // the azimuth consistency check is sig12^2 * abs(f) * min(1, 1-f/2) / 2.
        // (Error measured for 1/100 < b/a < 100 and abs(f) >= 1/1000.  For a
        // given f and sig12, the max error occurs for lines near the pole.  If
        // the old rule for computing dnm = (dn1 + dn2)/2 is used, then the error
        // increases by a factor of 2.)  Setting this equal to epsilon gives
        // sig12 = etol2.  Here 0.1 is a safety factor (error decreased by 100)
        // and max(0.001, abs(f)) stops etol2 getting too large in the nearly
        // spherical case.
        self.etol2 = 0.1 * Geodesic.tol2 / sqrt(max(0.001, abs(f)) * min(1.0, 1 - f / 2) / 2)

        assert(GeoMath.isFinite(a) && a > 0, "Equatorial radius is not positive")
        assert(GeoMath.isFinite(b) && b > 0, "Polar semi-axis is not positive")

        self.A3x = Array<Double>(repeating: 0, count: Geodesic.nA3x)
        self.C3x = Array<Double>(repeating: 0, count: Geodesic.nC3x)
        self.C4x = Array<Double>(repeating: 0, count: Geodesic.nC4x)
        
        A3coeff()
        C3coeff()
        C4coeff()
    }
    
    /**
     * Solve the direct geodesic problem where the length of the geodesic
     * is specified in terms of distance.
     * <p>
     * @param lat1 latitude of point 1 (degrees).
     * @param lon1 longitude of point 1 (degrees).
     * @param azi1 azimuth at point 1 (degrees).
     * @param s12 distance between point 1 and point 2 (meters); it can be
     *   negative.
     * @return a {@link GeodesicData} object with the following fields:
     *   <i>lat1</i>, <i>lon1</i>, <i>azi1</i>, <i>lat2</i>, <i>lon2</i>,
     *   <i>azi2</i>, <i>s12</i>, <i>a12</i>.
     * <p>
     * <i>lat1</i> should be in the range [&minus;90&deg;, 90&deg;].  The values
     * of <i>lon2</i> and <i>azi2</i> returned are in the range [&minus;180&deg;,
     * 180&deg;].
     * <p>
     * If either point is at a pole, the azimuth is defined by keeping the
     * longitude fixed, writing <i>lat</i> = &plusmn;(90&deg; &minus; &epsilon;),
     * and taking the limit &epsilon; &rarr; 0+.  An arc length greater that
     * 180&deg; signifies a geodesic which is not a shortest path.  (For a
     * prolate ellipsoid, an additional condition is necessary for a shortest
     * path: the longitudinal extent must not exceed of 180&deg;.)
     **********************************************************************/
    public func direct(lat1: Double, lon1: Double, azi1: Double, s12: Double) -> GeodesicData {
        return direct(lat1: lat1, lon1: lon1, azi1: azi1, arcmode: false, s12_a12: s12, outmask: GeodesicMask.STANDARD)
    }
    
    /**
     * Solve the direct geodesic problem where the length of the geodesic is
     * specified in terms of distance and with a subset of the geodesic results
     * returned.
     * <p>
     * @param lat1 latitude of point 1 (degrees).
     * @param lon1 longitude of point 1 (degrees).
     * @param azi1 azimuth at point 1 (degrees).
     * @param s12 distance between point 1 and point 2 (meters); it can be
     *   negative.
     * @param outmask a bitor'ed combination of {@link GeodesicMask} values
     *   specifying which results should be returned.
     * @return a {@link GeodesicData} object with the fields specified by
     *   <i>outmask</i> computed.
     * <p>
     * <i>lat1</i>, <i>lon1</i>, <i>azi1</i>, <i>s12</i>, and <i>a12</i> are
     * always included in the returned result.  The value of <i>lon2</i> returned
     * is in the range [&minus;180&deg;, 180&deg;], unless the <i>outmask</i>
     * includes the {@link GeodesicMask#LONG_UNROLL} flag.
     **********************************************************************/
    public func direct(lat1: Double, lon1: Double, azi1: Double, s12: Double, outmask: GeodesicMask) -> GeodesicData {
        return direct(lat1: lat1, lon1: lon1, azi1: azi1, arcmode: false, s12_a12: s12, outmask: outmask)
    }
    
    /**
     * Solve the direct geodesic problem where the length of the geodesic
     * is specified in terms of arc length.
     * <p>
     * @param lat1 latitude of point 1 (degrees).
     * @param lon1 longitude of point 1 (degrees).
     * @param azi1 azimuth at point 1 (degrees).
     * @param a12 arc length between point 1 and point 2 (degrees); it can
     *   be negative.
     * @return a {@link GeodesicData} object with the following fields:
     *   <i>lat1</i>, <i>lon1</i>, <i>azi1</i>, <i>lat2</i>, <i>lon2</i>,
     *   <i>azi2</i>, <i>s12</i>, <i>a12</i>.
     * <p>
     * <i>lat1</i> should be in the range [&minus;90&deg;, 90&deg;].  The values
     * of <i>lon2</i> and <i>azi2</i> returned are in the range [&minus;180&deg;,
     * 180&deg;].
     * <p>
     * If either point is at a pole, the azimuth is defined by keeping the
     * longitude fixed, writing <i>lat</i> = &plusmn;(90&deg; &minus; &epsilon;),
     * and taking the limit &epsilon; &rarr; 0+.  An arc length greater that
     * 180&deg; signifies a geodesic which is not a shortest path.  (For a
     * prolate ellipsoid, an additional condition is necessary for a shortest
     * path: the longitudinal extent must not exceed of 180&deg;.)
     **********************************************************************/
    public func arcDirect(lat1: Double, lon1: Double, azi1: Double, a12: Double) -> GeodesicData {
        return direct(lat1: lat1, lon1: lon1, azi1: azi1, arcmode: true, s12_a12: a12, outmask: GeodesicMask.STANDARD)
    }
    
    /**
     * Solve the direct geodesic problem where the length of the geodesic is
     * specified in terms of arc length and with a subset of the geodesic results
     * returned.
     * <p>
     * @param lat1 latitude of point 1 (degrees).
     * @param lon1 longitude of point 1 (degrees).
     * @param azi1 azimuth at point 1 (degrees).
     * @param a12 arc length between point 1 and point 2 (degrees); it can
     *   be negative.
     * @param outmask a bitor'ed combination of {@link GeodesicMask} values
     *   specifying which results should be returned.
     * @return a {@link GeodesicData} object with the fields specified by
     *   <i>outmask</i> computed.
     * <p>
     * <i>lat1</i>, <i>lon1</i>, <i>azi1</i>, and <i>a12</i> are always included
     * in the returned result.  The value of <i>lon2</i> returned is in the range
     * [&minus;180&deg;, 180&deg;], unless the <i>outmask</i> includes the {@link
     * GeodesicMask#LONG_UNROLL} flag.
     **********************************************************************/
    public func arcDirect(lat1: Double, lon1: Double, azi1: Double, a12: Double, outmask: GeodesicMask) -> GeodesicData {
        return direct(lat1: lat1, lon1: lon1, azi1: azi1, arcmode: true, s12_a12: a12, outmask: outmask)
    }
    
    /**
     * The general direct geodesic problem.  {@link #Direct Direct} and
     * {@link #ArcDirect ArcDirect} are defined in terms of this function.
     * <p>
     * @param lat1 latitude of point 1 (degrees).
     * @param lon1 longitude of point 1 (degrees).
     * @param azi1 azimuth at point 1 (degrees).
     * @param arcmode bool flag determining the meaning of the
     *   <i>s12_a12</i>.
     * @param s12_a12 if <i>arcmode</i> is false, this is the distance between
     *   point 1 and point 2 (meters); otherwise it is the arc length between
     *   point 1 and point 2 (degrees); it can be negative.
     * @param outmask a bitor'ed combination of {@link GeodesicMask} values
     *   specifying which results should be returned.
     * @return a {@link GeodesicData} object with the fields specified by
     *   <i>outmask</i> computed.
     * <p>
     * The {@link GeodesicMask} values possible for <i>outmask</i> are
     * <ul>
     * <li>
     *   <i>outmask</i> |= {@link GeodesicMask#LATITUDE} for the latitude
     *   <i>lat2</i>;
     * <li>
     *   <i>outmask</i> |= {@link GeodesicMask#LONGITUDE} for the latitude
     *   <i>lon2</i>;
     * <li>
     *   <i>outmask</i> |= {@link GeodesicMask#AZIMUTH} for the latitude
     *   <i>azi2</i>;
     * <li>
     *   <i>outmask</i> |= {@link GeodesicMask#DISTANCE} for the distance
     *   <i>s12</i>;
     * <li>
     *   <i>outmask</i> |= {@link GeodesicMask#REDUCEDLENGTH} for the reduced
     *   length <i>m12</i>;
     * <li>
     *   <i>outmask</i> |= {@link GeodesicMask#GEODESICSCALE} for the geodesic
     *   scales <i>M12</i> and <i>M21</i>;
     * <li>
     *   <i>outmask</i> |= {@link GeodesicMask#AREA} for the area <i>S12</i>;
     * <li>
     *   <i>outmask</i> |= {@link GeodesicMask#ALL} for all of the above;
     * <li>
     *   <i>outmask</i> |= {@link GeodesicMask#LONG_UNROLL}, if set then
     *   <i>lon1</i> is unchanged and <i>lon2</i> &minus; <i>lon1</i> indicates
     *   how many times and in what sense the geodesic encircles the ellipsoid.
     *   Otherwise <i>lon1</i> and <i>lon2</i> are both reduced to the range
     *   [&minus;180&deg;, 180&deg;].
     * </ul>
     * <p>
     * The function value <i>a12</i> is always computed and returned and this
     * equals <i>s12_a12</i> is <i>arcmode</i> is true.  If <i>outmask</i>
     * includes {@link GeodesicMask#DISTANCE} and <i>arcmode</i> is false, then
     * <i>s12</i> = <i>s12_a12</i>.  It is not necessary to include {@link
     * GeodesicMask#DISTANCE_IN} in <i>outmask</i>; this is automatically
     * included is <i>arcmode</i> is false.
     **********************************************************************/
    public func direct(lat1: Double, lon1: Double, azi1: Double, arcmode: Bool, s12_a12: Double, outmask: GeodesicMask) -> GeodesicData {
        var mask = outmask
        // Automatically supply DISTANCE_IN if necessary
        if !arcmode {
            mask.insert(GeodesicMask.DISTANCE_IN)
        }

        return GeodesicLine(g: self, lat1: lat1, lon1: lon1, azi1: azi1, caps: mask).position(arcmode, s12_a12, mask)
    }
    
    /**
     * Define a {@link GeodesicLine} in terms of the direct geodesic problem
     * specified in terms of distance with all capabilities included.
     * <p>
     * @param lat1 latitude of point 1 (degrees).
     * @param lon1 longitude of point 1 (degrees).
     * @param azi1 azimuth at point 1 (degrees).
     * @param s12 distance between point 1 and point 2 (meters); it can be
     *   negative.
     * @return a {@link GeodesicLine} object.
     * <p>
     * This function sets point 3 of the GeodesicLine to correspond to point 2
     * of the direct geodesic problem.
     * <p>
     * <i>lat1</i> should be in the range [&minus;90&deg;, 90&deg;].
     **********************************************************************/
    public func directLine(lat1: Double, lon1: Double, azi1: Double, s12: Double) -> GeodesicLine {
        return directLine(lat1: lat1, lon1: lon1, azi1: azi1, s12: s12, caps: GeodesicMask.ALL)
    }
    
    /**
     * Define a {@link GeodesicLine} in terms of the direct geodesic problem
     * specified in terms of distance with a subset of the capabilities included.
     * <p>
     * @param lat1 latitude of point 1 (degrees).
     * @param lon1 longitude of point 1 (degrees).
     * @param azi1 azimuth at point 1 (degrees).
     * @param s12 distance between point 1 and point 2 (meters); it can be
     *   negative.
     * @param caps bitor'ed combination of {@link GeodesicMask} values
     *   specifying the capabilities the GeodesicLine object should possess,
     *   i.e., which quantities can be returned in calls to
     *   {@link GeodesicLine#Position GeodesicLine.Position}.
     * @return a {@link GeodesicLine} object.
     * <p>
     * This function sets point 3 of the GeodesicLine to correspond to point 2
     * of the direct geodesic problem.
     * <p>
     * <i>lat1</i> should be in the range [&minus;90&deg;, 90&deg;].
     **********************************************************************/
    public func directLine(lat1: Double, lon1: Double, azi1: Double, s12: Double, caps: GeodesicMask) -> GeodesicLine {
        return genDirectLine(lat1: lat1, lon1: lon1, azi1: azi1, arcmode: false, s12_a12: s12, caps: caps)
    }
    
    /**
     * Define a {@link GeodesicLine} in terms of the direct geodesic problem
     * specified in terms of arc length with all capabilities included.
     * <p>
     * @param lat1 latitude of point 1 (degrees).
     * @param lon1 longitude of point 1 (degrees).
     * @param azi1 azimuth at point 1 (degrees).
     * @param a12 arc length between point 1 and point 2 (degrees); it can
     *   be negative.
     * @return a {@link GeodesicLine} object.
     * <p>
     * This function sets point 3 of the GeodesicLine to correspond to point 2
     * of the direct geodesic problem.
     * <p>
     * <i>lat1</i> should be in the range [&minus;90&deg;, 90&deg;].
     **********************************************************************/
    public func arcDirectLine(lat1: Double, lon1: Double, azi1: Double, a12: Double) -> GeodesicLine {
        return arcDirectLine(lat1: lat1, lon1: lon1, azi1: azi1, a12: a12, caps: GeodesicMask.ALL)
    }
    
    /**
     * Define a {@link GeodesicLine} in terms of the direct geodesic problem
     * specified in terms of arc length with a subset of the capabilities
     * included.
     * <p>
     * @param lat1 latitude of point 1 (degrees).
     * @param lon1 longitude of point 1 (degrees).
     * @param azi1 azimuth at point 1 (degrees).
     * @param a12 arc length between point 1 and point 2 (degrees); it can
     *   be negative.
     * @param caps bitor'ed combination of {@link GeodesicMask} values
     *   specifying the capabilities the GeodesicLine object should possess,
     *   i.e., which quantities can be returned in calls to
     *   {@link GeodesicLine#Position GeodesicLine.Position}.
     * @return a {@link GeodesicLine} object.
     * <p>
     * This function sets point 3 of the GeodesicLine to correspond to point 2
     * of the direct geodesic problem.
     * <p>
     * <i>lat1</i> should be in the range [&minus;90&deg;, 90&deg;].
     **********************************************************************/
    public func arcDirectLine(lat1: Double, lon1: Double, azi1: Double, a12: Double, caps: GeodesicMask) -> GeodesicLine {
        return genDirectLine(lat1: lat1, lon1: lon1, azi1: azi1, arcmode: true, s12_a12: a12, caps: caps)
    }
    
    /**
     * Define a {@link GeodesicLine} in terms of the direct geodesic problem
     * specified in terms of either distance or arc length with a subset of the
     * capabilities included.
     * <p>
     * @param lat1 latitude of point 1 (degrees).
     * @param lon1 longitude of point 1 (degrees).
     * @param azi1 azimuth at point 1 (degrees).
     * @param arcmode bool flag determining the meaning of the <i>s12_a12</i>.
     * @param s12_a12 if <i>arcmode</i> is false, this is the distance between
     *   point 1 and point 2 (meters); otherwise it is the arc length between
     *   point 1 and point 2 (degrees); it can be negative.
     * @param caps bitor'ed combination of {@link GeodesicMask} values
     *   specifying the capabilities the GeodesicLine object should possess,
     *   i.e., which quantities can be returned in calls to
     *   {@link GeodesicLine#Position GeodesicLine.Position}.
     * @return a {@link GeodesicLine} object.
     * <p>
     * This function sets point 3 of the GeodesicLine to correspond to point 2
     * of the direct geodesic problem.
     * <p>
     * <i>lat1</i> should be in the range [&minus;90&deg;, 90&deg;].
     **********************************************************************/
    public func genDirectLine(lat1: Double, lon1: Double, azi1: Double, arcmode: Bool, s12_a12: Double, caps: GeodesicMask) -> GeodesicLine {
        let azi = GeoMath.angNormalize(azi1)
        
        // Guard against underflow in salp0.  Also -0 is converted to +0.
        let p = GeoMath.sincosd(GeoMath.angRound(azi))
        let salp1 = p.0
        let calp1 = p.1
        
        var mask = caps
        // Automatically supply DISTANCE_IN if necessary
        if !arcmode {
            mask.insert(GeodesicMask.DISTANCE_IN)
        }
        
        return GeodesicLine(g: self, lat1: lat1, lon1: lon1, azi1: azi, salp1: salp1, calp1: calp1, caps: mask, arcmode: arcmode, s13_a13: s12_a12)
    }
    
    /**
     * Solve the inverse geodesic problem.
     * <p>
     * @param lat1 latitude of point 1 (degrees).
     * @param lon1 longitude of point 1 (degrees).
     * @param lat2 latitude of point 2 (degrees).
     * @param lon2 longitude of point 2 (degrees).
     * @return a {@link GeodesicData} object with the following fields:
     *   <i>lat1</i>, <i>lon1</i>, <i>azi1</i>, <i>lat2</i>, <i>lon2</i>,
     *   <i>azi2</i>, <i>s12</i>, <i>a12</i>.
     * <p>
     * <i>lat1</i> and <i>lat2</i> should be in the range [&minus;90&deg;,
     * 90&deg;].  The values of <i>azi1</i> and <i>azi2</i> returned are in the
     * range [&minus;180&deg;, 180&deg;].
     * <p>
     * If either point is at a pole, the azimuth is defined by keeping the
     * longitude fixed, writing <i>lat</i> = &plusmn;(90&deg; &minus; &epsilon;),
     * taking the limit &epsilon; &rarr; 0+.
     * <p>
     * The solution to the inverse problem is found using Newton's method.  If
     * this fails to converge (this is very unlikely in geodetic applications
     * but does occur for very eccentric ellipsoids), then the bisection method
     * is used to refine the solution.
     **********************************************************************/
    public func inverse(lat1: Double, lon1: Double, lat2: Double, lon2: Double) -> GeodesicData {
        return inverse(lat1: lat1, lon1: lon1, lat2: lat2, lon2: lon2, outmask: GeodesicMask.STANDARD)
    }
    
    struct InverseData {
        var geodesic: GeodesicData
        var salp1: Double
        var calp1: Double
        var salp2: Double
        var calp2: Double

        init() {
            self.geodesic = GeodesicData()
            self.salp1 = .nan
            self.salp2 = .nan
            self.calp1 = .nan
            self.calp2 = .nan
        }
    }
    
    private func inverseInt(_ inlat1: Double, _ inlon1: Double, _ inlat2: Double, _ inlon2: Double, _ outmask: GeodesicMask) -> InverseData {
        var result = InverseData()
        
        // Compute longitude difference (AngDiff does this carefully).  Result is
        // in [-180, 180] but -180 is only for west-going geodesics.  180 is for
        // east-going and meridional geodesics.
        var lat1 = GeoMath.latFix(inlat1)
        var lat2 = GeoMath.latFix(inlat2)
        result.geodesic.lat1 = lat1
        result.geodesic.lat2 = lat2
        
        // If really close to the equator, treat as on equator.
        lat1 = GeoMath.angRound(lat1)
        lat2 = GeoMath.angRound(lat2)
        
        let lon1 = inlon1
        let lon2 = inlon2
        
        var lon12 = 0.0
        var lon12s = 0.0
        do {
            let p = GeoMath.angDiff(lon1, lon2)
            lon12 = p.0
            lon12s = p.1
        }
        
        if outmask.containsAny(GeodesicMask.LONG_UNROLL) {
            result.geodesic.lon1 = lon1
            result.geodesic.lon2 = (lon1 + lon12) + lon12s
        } else {
            result.geodesic.lon1 = GeoMath.angNormalize(lon1)
            result.geodesic.lon2 = GeoMath.angNormalize(lon2)
        }
        
        // Make longitude difference positive.
        var lonsign: Double = lon12 >= 0 ? 1 : -1
        
        // If very close to being on the same half-meridian, then make it so.
        lon12 = lonsign * GeoMath.angRound(lon12)
        lon12s = GeoMath.angRound((180 - lon12) - lonsign * lon12s)
        
        let lam12 = GeoMath.toRadians(lon12)
        let slam12: Double
        let clam12: Double
        do {
            let p = GeoMath.sincosd(lon12 > 90 ? lon12s : lon12)
            slam12 = p.0
            clam12 = (lon12 > 90 ? -1 : 1) * p.1
        }
        
        // Swap points so that point with higher (abs) latitude is point 1
        // If one latitude is a nan, then it becomes lat1.
        let swapp: Double = abs(lat1) < abs(lat2) ? -1 : 1
        if swapp < 0 {
            lonsign *= -1
            Swift.swap(&lat1, &lat2)
        }
        
        // Make lat1 <= 0
        let latsign: Double = lat1 < 0 ? 1 : -1
        lat1 *= latsign
        lat2 *= latsign
        
        // Now we have
        //
        //     0 <= lon12 <= 180
        //     -90 <= lat1 <= 0
        //     lat1 <= lat2 <= -lat1
        //
        // longsign, swapp, latsign register the transformation to bring the
        // coordinates to this canonical form.  In all cases, 1 means no change was
        // made.  We make these transformations so that there are few cases to
        // check, e.g., on verifying quadrants in atan2.  In addition, this
        // enforces some symmetries in the results returned.
        
        var sbet1 = 0.0
        var cbet1 = 0.0
        var sbet2: Double
        var cbet2: Double
        var s12x: Double = .nan
        var m12x: Double = .nan
        
        do {
            let p = GeoMath.sincosd(lat1)
            sbet1 = f1 * p.0
            cbet1 = p.1
        }
        
        // Ensure cbet1 = +epsilon at poles; doing the fix on beta means that sig12
        // will be <= 2*tiny for two points at the same pole.
        do {
            let p = GeoMath.norm(sbet1, cbet1)
            sbet1 = p.0
            cbet1 = p.1
        }
        cbet1 = max(Geodesic.tiny, cbet1)
        
        do {
            let p = GeoMath.sincosd(lat2)
            sbet2 = f1 * p.0
            cbet2 = p.1
        }
 
        // Ensure cbet2 = +epsilon at poles
        do {
            let p = GeoMath.norm(sbet2, cbet2)
            sbet2 = p.0
            cbet2 = p.1
        }
        cbet2 = max(Geodesic.tiny, cbet2)
        
        // If cbet1 < -sbet1, then cbet2 - cbet1 is a sensitive measure of the
        // |bet1| - |bet2|.  Alternatively (cbet1 >= -sbet1), abs(sbet2) + sbet1 is
        // a better measure.  This logic is used in assigning calp2 in Lambda12.
        // Sometimes these quantities vanish and in that case we force bet2 = +/-
        // bet1 exactly.  An example where is is necessary is the inverse problem
        // 48.522876735459 0 -48.52287673545898293 179.599720456223079643
        // which failed with Visual Studio 10 (Release and Debug)
        
        if cbet1 < -sbet1 {
            if cbet2 == cbet1 {
                sbet2 = sbet2 < 0 ? sbet1 : -sbet1
            }
        } else {
            if abs(sbet2) == -sbet1 {
                cbet2 = cbet1
            }
        }
        
        let dn1 = sqrt(1 + ep2 * GeoMath.sq(sbet1))
        let dn2 = sqrt(1 + ep2 * GeoMath.sq(sbet2))
        
        var a12 = Double.nan
        var sig12 = Double.nan
        var calp1 = Double.nan
        var salp1 = Double.nan
        var calp2 = Double.nan
        var salp2 = Double.nan
        
        // index zero elements of these arrays are unused
        var C1a = Array<Double>(repeating: 0, count: Geodesic.nC1 + 1)
        var C2a = Array<Double>(repeating: 0, count: Geodesic.nC2 + 1)
        var C3a = Array<Double>(repeating: 0, count: Geodesic.nC3)
        
        var meridian = lat1 == -90 || slam12 == 0
        
        if meridian {
            // Endpoints are on a single full meridian, so the geodesic might lie on
            // a meridian.
            
            calp1 = clam12
            salp1 = slam12  // Head to the target longitude
            calp2 = 1
            salp2 = 0       // At the target we're heading north
            
            // tan(bet) = tan(sig) * cos(alp)
            let ssig1 = sbet1
            let csig1 = calp1 * cbet1
            let ssig2 = sbet2
            let csig2 = calp2 * cbet2
            
            // sig12 = sig2 - sig1
            sig12 = atan2(max(0.0, csig1 * ssig2 - ssig1 * csig2), csig1 * csig2 + ssig1 * ssig2)
            do {
                let v = lengths(n, sig12, ssig1, csig1, dn1,
                            ssig2, csig2, dn2, cbet1, cbet2,
                            [outmask, GeodesicMask.DISTANCE, GeodesicMask.REDUCEDLENGTH],
                            &C1a, &C2a)
                s12x = v.s12b
                m12x = v.m12b
                
                if outmask.containsAny(GeodesicMask.GEODESICSCALE) {
                    result.geodesic.M12 = v.M12
                    result.geodesic.M21 = v.M21
                }
            }
            
            // Add the check for sig12 since zero length geodesics might yield m12 <
            // 0.  Test case was
            //
            //    echo 20.001 0 20.001 0 | GeodSolve -i
            //
            // In fact, we will have sig12 > pi/2 for meridional geodesic which is
            // not a shortest path.
            if sig12 < 1 || m12x >= 0 {
                // Need at least 2, to handle 90 0 90 180
                if sig12 < 3 * Geodesic.tiny {
                    sig12 = 0
                    m12x = 0
                    s12x = 0
                }
                
                m12x *= b
                s12x *= b
                a12 = GeoMath.toDegrees(sig12)
            } else {
                // m12 < 0, i.e., prolate and too close to anti-podal
                meridian = false
            }
        }
        
        var omg12 = Double.nan
        var somg12 = 2.0
        var comg12 = Double.nan
        if !meridian &&
            sbet1 == 0 &&   // and sbet2 == 0
            // Mimic the way Lambda12 works with calp1 = 0
            (f <= 0 || lon12s >= f * 180) {
            
            // Geodesic runs along equator
            calp1 = 0
            calp2 = 0
            salp1 = 1
            salp2 = 1
            s12x = a * lam12
            sig12 = lam12 / f1
            omg12 = sig12
            m12x = b * sin(sig12)
            
            if outmask.containsAny(GeodesicMask.GEODESICSCALE) {
                result.geodesic.M12 = cos(sig12)
                result.geodesic.M21 = result.geodesic.M12
            }
            
            a12 = lon12 / f1
        } else if !meridian {
            // Now point1 and point2 belong within a hemisphere bounded by a
            // meridian and geodesic is neither meridional or equatorial.
            
            // Figure a starting point for Newton's method
            var dnm: Double
            do {
                let v = inverseStart(sbet1, cbet1, dn1, sbet2, cbet2, dn2, lam12, slam12, clam12, &C1a, &C2a)
                sig12 = v.sig12
                salp1 = v.salp1
                calp1 = v.calp1
                salp2 = v.salp2
                calp2 = v.calp2
                dnm = v.dnm
            }
            
            if sig12 >= 0 {
                // Short lines (InverseStart sets salp2, calp2, dnm)
                s12x = sig12 * b * dnm
                m12x = GeoMath.sq(dnm) * b * sin(sig12 / dnm)
                
                if outmask.containsAny(GeodesicMask.GEODESICSCALE) {
                    result.geodesic.M12 = cos(sig12 / dnm)
                    result.geodesic.M21 = result.geodesic.M12
                }
                
                a12 = GeoMath.toDegrees(sig12)
                omg12 = lam12 / (f1 * dnm)
            } else {
                // Newton's method.  This is a straightforward solution of f(alp1) =
                // lambda12(alp1) - lam12 = 0 with one wrinkle.  f(alp) has exactly one
                // root in the interval (0, pi) and its derivative is positive at the
                // root.  Thus f(alp) is positive for alp > alp1 and negative for alp <
                // alp1.  During the course of the iteration, a range (alp1a, alp1b) is
                // maintained which brackets the root and with each evaluation of
                // f(alp) the range is shrunk, if possible.  Newton's method is
                // restarted whenever the derivative of f is negative (because the new
                // value of alp1 is then further from the solution) or if the new
                // estimate of alp1 lies outside (0,pi); in this case, the new starting
                // guess is taken to be (alp1a + alp1b) / 2.
                var ssig1 = Double.nan
                var csig1 = Double.nan
                var ssig2 = Double.nan
                var csig2 = Double.nan
                var eps = Double.nan
                var domg12 = Double.nan
                
                // Bracketing range
                var salp1a = Geodesic.tiny
                var calp1a = 1.0
                var salp1b = Geodesic.tiny
                var calp1b = -1.0
                
                var tripn = false
                var tripb = false
                
                for numit in 0..<maxit2 {
                    // the WGS84 test set: mean = 1.47, sd = 1.25, max = 16
                    // WGS84 and random input: mean = 2.85, sd = 0.60
                    var v: Double
                    var dv: Double
                    do {
                        let w = lambda12(sbet1, cbet1, dn1, sbet2, cbet2, dn2, salp1, calp1, slam12, clam12, numit < maxit1, &C1a, &C2a, &C3a)
                        v = w.lam12
                        salp2 = w.salp2
                        calp2 = w.calp2
                        sig12 = w.sig12
                        ssig1 = w.ssig1
                        csig1 = w.csig1
                        ssig2 = w.ssig2
                        csig2 = w.csig2
                        eps = w.eps
                        domg12 = w.domg12
                        dv = w.dlam12
                    }
                    
                    // 2 * tol0 is approximately 1 ulp for a number in [0, pi].
                    // Reversed test to allow escape with NaNs
                    if tripb || !(abs(v) >= (tripn ? 8 : 1) * Geodesic.tol0) {
                        break
                    }
                    
                    // Update bracketing values
                    if v > 0 && (numit > maxit1 || calp1 / salp1 > calp1b / salp1b) {
                        salp1b = salp1
                        calp1b = calp1
                    } else if v < 0 && (numit > maxit1 || calp1 / salp1 < calp1a / salp1a) {
                        salp1a = salp1
                        calp1a = calp1
                    }
                    
                    if numit < maxit1 && dv > 0 {
                        let dalp1 = -v / dv
                        let sdalp1 = sin(dalp1)
                        let cdalp1 = cos(dalp1)
                        let nsalp1 = salp1 * cdalp1 + calp1 * sdalp1
                        
                        if nsalp1 > 0 && abs(dalp1) < .pi {
                            calp1 = calp1 * cdalp1 - salp1 * sdalp1
                            salp1 = nsalp1
                            do {
                                let p = GeoMath.norm(salp1, calp1)
                                salp1 = p.0
                                calp1 = p.1
                            }
                            
                            // In some regimes we don't get quadratic convergence because
                            // slope -> 0.  So use convergence conditions based on epsilon
                            // instead of sqrt(epsilon).
                            tripn = abs(v) <= 16 * Geodesic.tol0
                            continue
                        }
                    }
                    
                    // Either dv was not positive or updated value was outside legal
                    // range.  Use the midpoint of the bracket as the next estimate.
                    // This mechanism is not needed for the WGS84 ellipsoid, but it does
                    // catch problems with more eccentric ellipsoids.  Its efficacy is
                    // such for the WGS84 test set with the starting guess set to alp1 =
                    // 90deg:
                    // the WGS84 test set: mean = 5.21, sd = 3.93, max = 24
                    // WGS84 and random input: mean = 4.74, sd = 0.99
                    salp1 = (salp1a + salp1b) / 2
                    calp1 = (calp1a + calp1b) / 2
                    do {
                        let p = GeoMath.norm(salp1, calp1)
                        salp1 = p.0
                        calp1 = p.1
                    }
                    tripn = false
                    tripb = (abs(salp1a - salp1) + (calp1a - calp1) < Geodesic.tolb || abs(salp1 - salp1b) + (calp1 - calp1b) < Geodesic.tolb)
                }
                
                do {
                    // Ensure that the reduced length and geodesic scale are computed in
                    // a "canonical" way, with the I2 integral.
                    let lengthmask = outmask.union(
                        outmask.containsAny([GeodesicMask.REDUCEDLENGTH, GeodesicMask.GEODESICSCALE]) ?
                                GeodesicMask.DISTANCE : GeodesicMask.NONE)
                    
                    let v = lengths(eps, sig12, ssig1, csig1, dn1, ssig2, csig2, dn2, cbet1, cbet2, lengthmask, &C1a, &C2a)
                    s12x = v.s12b
                    m12x = v.m12b
                    
                    if outmask.containsAny(GeodesicMask.GEODESICSCALE) {
                        result.geodesic.M12 = v.M12
                        result.geodesic.M21 = v.M21
                    }
                }
                
                m12x *= b
                s12x *= b
                a12 = GeoMath.toDegrees(sig12)
                
                if outmask.containsAny(GeodesicMask.AREA) {
                    // omg12 = lam12 - domg12
                    let sdomg12 = sin(domg12)
                    let cdomg12 = cos(domg12)
                    somg12 = slam12 * cdomg12 - clam12 * sdomg12
                    comg12 = clam12 * cdomg12 + slam12 * sdomg12
                }
            }
        }
        
        if outmask.containsAny(GeodesicMask.DISTANCE) {
            result.geodesic.s12 = 0 + s12x           // Convert -0 to 0
        }
        
        if outmask.containsAny(GeodesicMask.REDUCEDLENGTH) {
            result.geodesic.m12 = 0 + m12x           // Convert -0 to 0
        }
        
        if outmask.containsAny(GeodesicMask.AREA) {
            // From Lambda12: sin(alp1) * cos(bet1) = sin(alp0)
            let salp0 = salp1 * cbet1
            let calp0 = GeoMath.hypot(calp1, salp1 * sbet1) // calp0 > 0
            var alp12 = 0.0
            if calp0 != 0 && salp0 != 0 {
                // From Lambda12: tan(bet) = tan(sig) * cos(alp)
                var ssig1 = sbet1
                var csig1 = calp1 * cbet1
                var ssig2 = sbet2
                var csig2 = calp2 * cbet2
                let k2 = GeoMath.sq(calp0) * ep2
                let eps = k2 / (2 * (1 + sqrt(1 + k2)) + k2)
                
                // Multiplier = a^2 * e^2 * cos(alpha0) * sin(alpha0).
                let A4 = GeoMath.sq(a) * calp0 * salp0 * e2
                    
                do {
                    let p = GeoMath.norm(ssig1, csig1)
                    ssig1 = p.0
                    csig1 = p.1
                }
                
                do {
                    let p = GeoMath.norm(ssig2, csig2)
                    ssig2 = p.0
                    csig2 = p.1
                }
                
                var C4a = Array<Double>(repeating: 0, count: Geodesic.nC4)
                C4f(eps, &C4a)
                
                let B41 = Geodesic.sincosSeries(false, ssig1, csig1, C4a)
                let B42 = Geodesic.sincosSeries(false, ssig2, csig2, C4a)
                result.geodesic.S12 = A4 * (B42 - B41)
            } else {
                // Avoid problems with indeterminate sig1, sig2 on equator
                result.geodesic.S12 = 0
            }
            
            if !meridian && somg12 > 1 {
                somg12 = sin(omg12)
                comg12 = cos(omg12)
            }
            
            if !meridian &&
                comg12 > -0.7071 &&     // Long difference not too big
                sbet2 - sbet1 < 1.75 {  // Lat difference not too big
                // Use tan(Gamma/2) = tan(omg12/2)
                // * (tan(bet1/2)+tan(bet2/2))/(1+tan(bet1/2)*tan(bet2/2))
                // with tan(x/2) = sin(x)/(1+cos(x))
                let domg12 = 1 + comg12
                let dbet1 = 1 + cbet1
                let dbet2 = 1 + cbet2
                alp12 = 2 * atan2(
                    somg12 * (sbet1 * dbet2 + sbet2 * dbet1),
                    domg12 * (sbet1 * sbet2 + dbet1 * dbet2)
                )
            } else {
                // alp12 = alp2 - alp1, used in atan2 so no need to normalize
                var salp12 = salp2 * calp1 - calp2 * salp1
                var calp12 = calp2 * calp1 + salp2 * salp1
                
                // The right thing appears to happen if alp1 = +/-180 and alp2 = 0, viz
                // salp12 = -0 and alp12 = -180.  However this depends on the sign
                // being attached to 0 correctly.  The following ensures the correct
                // behavior.
                if salp12 == 0 && calp12 < 0 {
                    salp12 = Geodesic.tiny * calp1
                    calp12 = -1.0
                }
                
                alp12 = atan2(salp12, calp12)
            }
            
            result.geodesic.S12 += c2 * alp12
            result.geodesic.S12 *= swapp * lonsign * latsign
            // Convert -0 to 0
            result.geodesic.S12 += 0
        }
        
        // Convert calp, salp to azimuth accounting for lonsign, swapp, latsign.
        if swapp < 0 {
            swap(&salp1, &salp2)
            swap(&calp1, &calp2)
            if outmask.containsAny(GeodesicMask.GEODESICSCALE) {
                let t = result.geodesic.M12
                result.geodesic.M12 = result.geodesic.M21
                result.geodesic.M21 = t
            }
        }
        
        salp1 *= swapp * lonsign
        calp1 *= swapp * latsign
        salp2 *= swapp * lonsign
        calp2 *= swapp * latsign
        
        // Returned value in [0, 180]
        result.geodesic.a12 = a12
        result.salp1 = salp1
        result.calp1 = calp1
        result.salp2 = salp2
        result.calp2 = calp2
        
        return result
    }
    
    /**
     * Solve the inverse geodesic problem with a subset of the geodesic results
     * returned.
     * <p>
     * @param lat1 latitude of point 1 (degrees).
     * @param lon1 longitude of point 1 (degrees).
     * @param lat2 latitude of point 2 (degrees).
     * @param lon2 longitude of point 2 (degrees).
     * @param outmask a bitor'ed combination of {@link GeodesicMask} values
     *   specifying which results should be returned.
     * @return a {@link GeodesicData} object with the fields specified by
     *   <i>outmask</i> computed.
     * <p>
     * The {@link GeodesicMask} values possible for <i>outmask</i> are
     * <ul>
     * <li>
     *   <i>outmask</i> |= {@link GeodesicMask#DISTANCE} for the distance
     *   <i>s12</i>;
     * <li>
     *   <i>outmask</i> |= {@link GeodesicMask#AZIMUTH} for the latitude
     *   <i>azi2</i>;
     * <li>
     *   <i>outmask</i> |= {@link GeodesicMask#REDUCEDLENGTH} for the reduced
     *   length <i>m12</i>;
     * <li>
     *   <i>outmask</i> |= {@link GeodesicMask#GEODESICSCALE} for the geodesic
     *   scales <i>M12</i> and <i>M21</i>;
     * <li>
     *   <i>outmask</i> |= {@link GeodesicMask#AREA} for the area <i>S12</i>;
     * <li>
     *   <i>outmask</i> |= {@link GeodesicMask#ALL} for all of the above.
     * <li>
     *   <i>outmask</i> |= {@link GeodesicMask#LONG_UNROLL}, if set then
     *   <i>lon1</i> is unchanged and <i>lon2</i> &minus; <i>lon1</i> indicates
     *   whether the geodesic is east going or west going.  Otherwise <i>lon1</i>
     *   and <i>lon2</i> are both reduced to the range [&minus;180&deg;,
     *   180&deg;].
     * </ul>
     * <p>
     * <i>lat1</i>, <i>lon1</i>, <i>lat2</i>, <i>lon2</i>, and <i>a12</i> are
     * always included in the returned result.
     **********************************************************************/
    public func inverse(lat1: Double, lon1: Double, lat2: Double, lon2: Double, outmask: GeodesicMask) -> GeodesicData {
        let mask = outmask.intersection(GeodesicMask.OUT_MASK)
        let result = inverseInt(lat1, lon1, lat2, lon2, mask)
        
        let r = result.geodesic
        if mask.containsAny(GeodesicMask.AZIMUTH) {
            r.azi1 = GeoMath.atan2d(result.salp1, result.calp1)
            r.azi2 = GeoMath.atan2d(result.salp2, result.calp2)
        }
        
        return r
    }
    
    /**
     * Define a {@link GeodesicLine} in terms of the inverse geodesic problem
     * with all capabilities included.
     * <p>
     * @param lat1 latitude of point 1 (degrees).
     * @param lon1 longitude of point 1 (degrees).
     * @param lat2 latitude of point 2 (degrees).
     * @param lon2 longitude of point 2 (degrees).
     * @return a {@link GeodesicLine} object.
     * <p>
     * This function sets point 3 of the GeodesicLine to correspond to point 2
     * of the inverse geodesic problem.
     * <p>
     * <i>lat1</i> and <i>lat2</i> should be in the range [&minus;90&deg;,
     * 90&deg;].
     **********************************************************************/
    public func inverseLine(lat1: Double, lon1: Double, lat2: Double, lon2: Double) -> GeodesicLine {
        return inverseLine(lat1: lat1, lon1: lon1, lat2: lat2, lon2: lon2, caps: GeodesicMask.ALL)
    }
    
    /**
     * Define a {@link GeodesicLine} in terms of the inverse geodesic problem
     * with a subset of the capabilities included.
     * <p>
     * @param lat1 latitude of point 1 (degrees).
     * @param lon1 longitude of point 1 (degrees).
     * @param lat2 latitude of point 2 (degrees).
     * @param lon2 longitude of point 2 (degrees).
     * @param caps bitor'ed combination of {@link GeodesicMask} values specifying
     *   the capabilities the GeodesicLine object should possess, i.e., which
     *   quantities can be returned in calls to
     *   {@link GeodesicLine#Position GeodesicLine.Position}.
     * @return a {@link GeodesicLine} object.
     * <p>
     * This function sets point 3 of the GeodesicLine to correspond to point 2
     * of the inverse geodesic problem.
     * <p>
     * <i>lat1</i> and <i>lat2</i> should be in the range [&minus;90&deg;,
     * 90&deg;].
     **********************************************************************/
    public func inverseLine(lat1: Double, lon1: Double, lat2: Double, lon2: Double, caps: GeodesicMask) -> GeodesicLine {
        let result = inverseInt(lat1, lon1, lat2, lon2, .NONE)
        let salp1 = result.salp1
        let calp1 = result.calp1
        let azi1 = GeoMath.atan2d(salp1, calp1)
        let a12 = result.geodesic.a12
        
        var mask = caps
        // Ensure that a12 can be converted to a distance
        if caps.containsAny(GeodesicMask.OUT_MASK.intersection(GeodesicMask.DISTANCE_IN)) {
            mask.insert(GeodesicMask.DISTANCE)
        }
        
        return GeodesicLine(g: self, lat1: lat1, lon1: lon1, azi1: azi1, salp1: salp1, calp1: calp1, caps: mask, arcmode: true, s13_a13: a12)
    }
    
    /**
     * Set up to compute several points on a single geodesic with all
     * capabilities included.
     * <p>
     * @param lat1 latitude of point 1 (degrees).
     * @param lon1 longitude of point 1 (degrees).
     * @param azi1 azimuth at point 1 (degrees).
     * @return a {@link GeodesicLine} object.
     * <p>
     * <i>lat1</i> should be in the range [&minus;90&deg;, 90&deg;].  The full
     * set of capabilities is included.
     * <p>
     * If the point is at a pole, the azimuth is defined by keeping the
     * <i>lon1</i> fixed, writing <i>lat1</i> = &plusmn;(90 &minus; &epsilon;),
     * taking the limit &epsilon; &rarr; 0+.
     **********************************************************************/
    public func line(lat1: Double, lon1: Double, azi1: Double) -> GeodesicLine {
        return line(lat1: lat1, lon1: lon1, azi1: azi1, caps: GeodesicMask.ALL)
    }
    
    /**
     * Set up to compute several points on a single geodesic with a subset of the
     * capabilities included.
     * <p>
     * @param lat1 latitude of point 1 (degrees).
     * @param lon1 longitude of point 1 (degrees).
     * @param azi1 azimuth at point 1 (degrees).
     * @param caps bitor'ed combination of {@link GeodesicMask} values specifying
     *   the capabilities the {@link GeodesicLine} object should possess, i.e.,
     *   which quantities can be returned in calls to {@link
     *   GeodesicLine#Position GeodesicLine.Position}.
     * @return a {@link GeodesicLine} object.
     * <p>
     * The {@link GeodesicMask} values are
     * <ul>
     * <li>
     *   <i>caps</i> |= {@link GeodesicMask#LATITUDE} for the latitude
     *   <i>lat2</i>; this is added automatically;
     * <li>
     *   <i>caps</i> |= {@link GeodesicMask#LONGITUDE} for the latitude
     *   <i>lon2</i>;
     * <li>
     *   <i>caps</i> |= {@link GeodesicMask#AZIMUTH} for the azimuth <i>azi2</i>;
     *   this is added automatically;
     * <li>
     *   <i>caps</i> |= {@link GeodesicMask#DISTANCE} for the distance
     *   <i>s12</i>;
     * <li>
     *   <i>caps</i> |= {@link GeodesicMask#REDUCEDLENGTH} for the reduced length
     *   <i>m12</i>;
     * <li>
     *   <i>caps</i> |= {@link GeodesicMask#GEODESICSCALE} for the geodesic
     *   scales <i>M12</i> and <i>M21</i>;
     * <li>
     *   <i>caps</i> |= {@link GeodesicMask#AREA} for the area <i>S12</i>;
     * <li>
     *   <i>caps</i> |= {@link GeodesicMask#DISTANCE_IN} permits the length of
     *   the geodesic to be given in terms of <i>s12</i>; without this capability
     *   the length can only be specified in terms of arc length;
     * <li>
     *   <i>caps</i> |= {@link GeodesicMask#ALL} for all of the above.
     * </ul>
     * <p>
     * If the point is at a pole, the azimuth is defined by keeping <i>lon1</i>
     * fixed, writing <i>lat1</i> = &plusmn;(90 &minus; &epsilon;), and taking
     * the limit &epsilon; &rarr; 0+.
     **********************************************************************/
    public func line(lat1: Double, lon1: Double, azi1: Double, caps: GeodesicMask) -> GeodesicLine {
        return GeodesicLine(g: self, lat1: lat1, lon1: lon1, azi1: azi1, caps: caps)
    }
    
    /**
     * @return <i>a</i> the equatorial radius of the ellipsoid (meters).  This is
     *   the value used in the constructor.
     **********************************************************************/
    public var majorRadius: Double {
        return a
    }
    
    /**
     * @return <i>f</i> the  flattening of the ellipsoid.  This is the
     *   value used in the constructor.
     **********************************************************************/
    public var flattening: Double {
        return f
    }
    
    /**
     * @return total area of ellipsoid in meters<sup>2</sup>.  The area of a
     *   polygon encircling a pole can be found by adding EllipsoidArea()/2 to
     *   the sum of <i>S12</i> for each side of the polygon.
     **********************************************************************/
    public func ellipsoidArea() -> Double {
        return 4 * .pi * c2
    }
    
    /**
     * A global instantiation of Geodesic with the parameters for the WGS84
     * ellipsoid.
     **********************************************************************/
    private static let _wgs84: Geodesic = Geodesic(a: WGS84_a, f: WGS84_f)
    
    public static var WGS84: Geodesic {
        return _wgs84
    }
    
    // This is a reformulation of the geodesic problem.  The notation is as
    // follows:
    // - at a general point (no suffix or 1 or 2 as suffix)
    //   - phi = latitude
    //   - beta = latitude on auxiliary sphere
    //   - omega = longitude on auxiliary sphere
    //   - lambda = longitude
    //   - alpha = azimuth of great circle
    //   - sigma = arc length along great circle
    //   - s = distance
    //   - tau = scaled distance (= sigma at multiples of pi/2)
    // - at northwards equator crossing
    //   - beta = phi = 0
    //   - omega = lambda = 0
    //   - alpha = alpha0
    //   - sigma = s = 0
    // - a 12 suffix means a difference, e.g., s12 = s2 - s1.
    // - s and c prefixes mean sin and cos
    static func sincosSeries(_ sinp: Bool, _ sinx: Double, _ cosx: Double, _ c: [Double]) -> Double {
        // Evaluate
        // y = sinp ? sum(c[i] * sin( 2*i    * x), i, 1, n) :
        //            sum(c[i] * cos((2*i+1) * x), i, 0, n-1)
        // using Clenshaw summation.  N.B. c[0] is unused for sin series
        // Approx operation count = (n + 5) mult and (2 * n + 2) add
        
        var k = c.count                             // Point to one beyond last element
        var n = k - (sinp ? 1 : 0)
        let ar = 2 * (cosx - sinx) * (cosx + sinx)  // 2 * cos(2 * x)
        
        var y0 = 0.0
        var y1 = 0.0                                // accumulators for sum
        
        if (n & 1) != 0 {
            k -= 1
            y0 = c[k]
        }
        
        // Now n is even
        n /= 2
        for _ in (0..<n) {
            // Unroll loop x 2, so accumulators return to their original role
            k -= 1
            y1 = ar * y0 - y1 + c[k]
            k -= 1
            y0 = ar * y1 - y0 + c[k]
        }
        
        return sinp ? 2 * sinx * cosx * y0      // sin(2 * x) * y0
                        : cosx * (y0 - y1)      // cos(x) * (y0 - y1)
    }
    
    struct LengthsV {
        var s12b: Double
        var m12b: Double
        var m0: Double
        var M12: Double
        var M21: Double
        
        init() {
            self.s12b = .nan
            self.m12b = .nan
            self.m0 = .nan
            self.M12 = .nan
            self.M21 = .nan
        }
    }
    
    private func lengths(_ eps: Double, _ sig12: Double,
                         _ ssig1: Double, _ csig1: Double, _ dn1: Double,
                         _ ssig2: Double, _ csig2: Double, _ dn2: Double,
                         _ cbet1: Double, _ cbet2: Double,
                         _ mask: GeodesicMask,
                         // Scratch areas of the right size
                         _ C1a: inout [Double], _ C2a: inout [Double]) -> LengthsV {
        // Return m12b = (reduced length)/_b; also calculate s12b = distance/_b,
        // and m0 = coefficient of secular term in expression for reduced length.
        
        let outmask = mask.union(GeodesicMask.OUT_MASK)
        var v = LengthsV() // To hold s12b, m12b, m0, M12, M21;
        
        var m0x = 0.0
        var J12 = 0.0
        var A1 = 0.0
        var A2 = 0.0
        if outmask.containsAny([GeodesicMask.DISTANCE, GeodesicMask.REDUCEDLENGTH, GeodesicMask.GEODESICSCALE]) {
            A1 = Geodesic.A1m1f(eps)
            Geodesic.C1f(eps, &C1a)
            if outmask.containsAny([GeodesicMask.REDUCEDLENGTH, GeodesicMask.GEODESICSCALE]) {
                A2 = Geodesic.A2m1f(eps)
                Geodesic.C2f(eps, &C2a)
                m0x = A1 - A2
                A2 = 1 + A2
            }
            A1 = 1 + A1
        }
        
        if outmask.containsAny(GeodesicMask.DISTANCE) {
            let B1 = Geodesic.sincosSeries(true, ssig2, csig2, C1a) - Geodesic.sincosSeries(true, ssig1, csig1, C1a)
            // Missing a factor of _b
            v.s12b = A1 * (sig12 + B1)
            if outmask.containsAny([GeodesicMask.REDUCEDLENGTH, GeodesicMask.GEODESICSCALE]) {
                let B2 = Geodesic.sincosSeries(true, ssig2, csig2, C2a) - Geodesic.sincosSeries(true, ssig1, csig1, C2a)
                J12 = m0x * sig12 + (A1 * B1 - A2 * B2)
            }
        } else if outmask.containsAny([GeodesicMask.REDUCEDLENGTH, GeodesicMask.GEODESICSCALE]) {
            // Assume here that nC1_ >= nC2_
            for l in 1...Geodesic.nC2 {
                C2a[l] = A1 * C1a[l] - A2 * C2a[l]
            }
            J12 = m0x * sig12 + (Geodesic.sincosSeries(true, ssig2, csig2, C2a) - Geodesic.sincosSeries(true, ssig1, csig1, C2a))
        }
        
        if outmask.containsAny(GeodesicMask.REDUCEDLENGTH) {
            v.m0 = m0x
            // Missing a factor of _b.
            // Add parens around (csig1 * ssig2) and (ssig1 * csig2) to ensure
            // accurate cancellation in the case of coincident points.
            v.m12b = dn2 * (csig1 * ssig2) - dn1 * (ssig1 * csig2) - csig1 * csig2 * J12
        }
        
        if outmask.containsAny(GeodesicMask.GEODESICSCALE) {
            let csig12 = csig1 * csig2 + ssig1 * ssig2
            let t = ep2 * (cbet1 - cbet2) * (cbet1 + cbet2) / (dn1 + dn2)
            v.M12 = csig12 + (t * ssig2 - csig2 * J12) * ssig1 / dn1
            v.M21 = csig12 - (t * ssig1 - csig1 * J12) * ssig2 / dn2
        }
        
        return v
    }
    
    private static func astroid(_ x: Double, _ y: Double) -> Double {
        // Solve k^4+2*k^3-(x^2+y^2-1)*k^2-2*y^2*k-y^2 = 0 for positive root k.
        // This solution is adapted from Geocentric::Reverse.
        var k = 0.0
        let p = GeoMath.sq(x)
        let q = GeoMath.sq(y)
        let r = (p + q - 1) / 6
        
        if !(q == 0 && r <= 0) {
            // Avoid possible division by zero when r = 0 by multiplying equations
            // for s and t by r^3 and r, resp.
            let S = p * q / 4            // S = r^3 * s
            let r2 = GeoMath.sq(r)
            let r3 = r * r2
            
            // The discriminant of the quadratic equation for T3.  This is zero on
            // the evolute curve p^(1/3)+q^(1/3) = 1
            let disc = S * (S + 2 * r3);
            var u = r
            
            if disc >= 0 {
                var T3 = S + r3
                // Pick the sign on the sqrt to maximize abs(T3).  This minimizes loss
                // of precision due to cancellation.  The result is unchanged because
                // of the way the T is used in definition of u.
                T3 += T3 < 0 ? -sqrt(disc) : sqrt(disc)      // T3 = (r * t)^3
                
                // N.B. cbrt always returns the double root.  cbrt(-8) = -2.
                let T = GeoMath.cbrt(T3)                     // T = r * t
                
                // T can be zero; but then r2 / T -> 0.
                u += T + (T != 0 ? r2 / T : 0)
            } else {
                // T is complex, but the way u is defined the result is double.
                let ang = atan2(sqrt(-disc), -(S + r3))
                
                // There are three possible cube roots.  We choose the root which
                // avoids cancellation.  Note that disc < 0 implies that r < 0.
                u += 2 * r * cos(ang / 3)
            }
            
            let v = sqrt(GeoMath.sq(u) + q)        // guaranteed positive
            
            // Avoid loss of accuracy when u < 0.
            let uv = u < 0 ? q / (v - u) : u + v        // u+v, guaranteed positive
            
            let w = (uv - q) / (2 * v)                  // positive?
            
            // Rearrange expression for k to avoid loss of accuracy due to
            // subtraction.  Division by 0 not possible because uv > 0, w >= 0.
            k = uv / (sqrt(uv + GeoMath.sq(w)) + w);    // guaranteed positive
        } else {    // q == 0 && r <= 0
            // y = 0 with |x| <= 1.  Handle this case directly.
            // for y small, positive root is k = abs(y)/sqrt(1-x^2)
            k = 0
        }
        
        return k
    }
    
    struct InverseStartV {
        var sig12: Double
        var salp1: Double
        var calp1: Double
        // Only updated if return val >= 0
        var salp2: Double
        var calp2: Double
        // Only updated for short lines
        var dnm: Double
        
        init() {
            self.sig12 = .nan
            self.salp1 = .nan
            self.calp1 = .nan
            self.salp2 = .nan
            self.calp2 = .nan
            self.dnm = .nan
        }
    }
    
    private func inverseStart(_ sbet1: Double, _ cbet1: Double, _ dn1: Double,
                              _ sbet2: Double, _ cbet2: Double, _ dn2: Double,
                              _ lam12: Double, _ slam12: Double, _ clam12: Double,
                              // Scratch areas of the right size
                              _ C1a: inout [Double], _ C2a: inout [Double]) -> InverseStartV {
        // Return a starting point for Newton's method in salp1 and calp1 (function
        // value is -1).  If Newton's method doesn't need to be used, return also
        // salp2 and calp2 and function value is sig12.
        
        // To hold sig12, salp1, calp1, salp2, calp2, dnm.
        var w = InverseStartV()
        w.sig12 = -1               // Return value
        
        // bet12 = bet2 - bet1 in [0, pi); bet12a = bet2 + bet1 in (-pi, 0]
        let sbet12 = sbet2 * cbet1 - cbet2 * sbet1
        let cbet12 = cbet2 * cbet1 + sbet2 * sbet1
        let sbet12a = sbet2 * cbet1 + cbet2 * sbet1
        let shortline = cbet12 >= 0 && sbet12 < 0.5 && cbet2 * lam12 < 0.5
        var somg12 = 0.0
        var comg12 = 0.0
        
        if shortline {
            var sbetm2 = GeoMath.sq(sbet1 + sbet2)
            // sin((bet1+bet2)/2)^2
            // =  (sbet1 + sbet2)^2 / ((sbet1 + sbet2)^2 + (cbet1 + cbet2)^2)
            sbetm2 /= sbetm2 + GeoMath.sq(cbet1 + cbet2)
            w.dnm = sqrt(1 + ep2 * sbetm2)
            
            let omg12 = lam12 / (f1 * w.dnm)
            somg12 = sin(omg12)
            comg12 = cos(omg12)
        } else {
            somg12 = slam12
            comg12 = clam12
        }
        
        w.salp1 = cbet2 * somg12
        w.calp1 = comg12 >= 0 ?
            sbet12 + cbet2 * sbet1 * GeoMath.sq(somg12) / (1 + comg12) :
            sbet12a - cbet2 * sbet1 * GeoMath.sq(somg12) / (1 - comg12)
        
        let ssig12 = GeoMath.hypot(w.salp1, w.calp1)
        let csig12 = sbet1 * sbet2 + cbet1 * cbet2 * comg12
        
        if shortline && ssig12 < etol2 {
            // really short lines
            w.salp2 = cbet1 * somg12
            w.calp2 = sbet12 - cbet1 * sbet2 * (comg12 >= 0 ? GeoMath.sq(somg12) / (1 + comg12) : 1 - comg12)
            
            do {
                let p = GeoMath.norm(w.salp2, w.calp2)
                w.salp2 = p.0
                w.calp2 = p.1
            }
            
            // Set return value
            w.sig12 = atan2(ssig12, csig12)
        } else if abs(n) > 0.1 || // Skip astroid calc if too eccentric
            csig12 >= 0 ||
            ssig12 >= 6 * abs(n) * .pi * GeoMath.sq(cbet1) {
            // Nothing to do, zeroth order spherical approximation is OK
        } else {
            // Scale lam12 and bet2 to x, y coordinate system where antipodal point
            // is at origin and singular point is at y = 0, x = -1.
            var y = 0.0
            var lamscale = 0.0
            var betscale = 0.0
            
            // In C++ volatile declaration needed to fix inverse case
            // 56.320923501171 0 -56.320923501171 179.664747671772880215
            // which otherwise fails with g++ 4.4.4 x86 -O3
            var x = 0.0
            let lam12x = atan2(-slam12, -clam12) // lam12 - pi
            
            if f >= 0 {            // In fact f == 0 does not get here
                // x = dlong, y = dlat
                do {
                    let k2 = GeoMath.sq(sbet1) * ep2
                    let eps = k2 / (2 * (1 + sqrt(1 + k2)) + k2)
                    lamscale = f * cbet1 * A3f(eps) * .pi
                }
                betscale = lamscale * cbet1;
                
                x = lam12x / lamscale;
                y = sbet12a / betscale;
            } else {                  // _f < 0
                // x = dlat, y = dlong
                let cbet12a = cbet2 * cbet1 - sbet2 * sbet1
                let bet12a = atan2(sbet12a, cbet12a);
                var m12b = 0.0
                var m0 = 0.0
                
                // In the case of lon12 = 180, this repeats a calculation made in
                // Inverse.
                let v = lengths(n, .pi + bet12a,
                                sbet1, -cbet1, dn1, sbet2, cbet2, dn2,
                                cbet1, cbet2, GeodesicMask.REDUCEDLENGTH, &C1a, &C2a)
                
                m12b = v.m12b
                m0 = v.m0
                
                x = -1 + m12b / (cbet1 * cbet2 * m0 * .pi)
                betscale = x < -0.01 ? sbet12a / x : -f * GeoMath.sq(cbet1) * .pi
                lamscale = betscale / cbet1
                y = lam12x / lamscale
            }
            
            if y > -Geodesic.tol1 && x > -1 - Geodesic.xthresh {
                // strip near cut
                if f >= 0 {
                    w.salp1 = min(1.0, -x)
                    w.calp1 = -sqrt(1 - GeoMath.sq(w.salp1))
                } else {
                    w.calp1 = max(x > -Geodesic.tol1 ? 0.0 : -1.0, x)
                    w.salp1 = sqrt(1 - GeoMath.sq(w.calp1))
                }
            } else {
                // Estimate alp1, by solving the astroid problem.
                //
                // Could estimate alpha1 = theta + pi/2, directly, i.e.,
                //   calp1 = y/k; salp1 = -x/(1+k);  for _f >= 0
                //   calp1 = x/(1+k); salp1 = -y/k;  for _f < 0 (need to check)
                //
                // However, it's better to estimate omg12 from astroid and use
                // spherical formula to compute alp1.  This reduces the mean number of
                // Newton iterations for astroid cases from 2.24 (min 0, max 6) to 2.12
                // (min 0 max 5).  The changes in the number of iterations are as
                // follows:
                //
                // change percent
                //    1       5
                //    0      78
                //   -1      16
                //   -2       0.6
                //   -3       0.04
                //   -4       0.002
                //
                // The histogram of iterations is (m = number of iterations estimating
                // alp1 directly, n = number of iterations estimating via omg12, total
                // number of trials = 148605):
                //
                //  iter    m      n
                //    0   148    186
                //    1 13046  13845
                //    2 93315 102225
                //    3 36189  32341
                //    4  5396      7
                //    5   455      1
                //    6    56      0
                //
                // Because omg12 is near pi, estimate work with omg12a = pi - omg12
                let k = Geodesic.astroid(x, y)
                let omg12a = lamscale * (f >= 0 ? -x * k / (1 + k) : -y * (1 + k) / k)
                somg12 = sin(omg12a)
                comg12 = -cos(omg12a)
                
                // Update spherical estimate of alp1 using omg12 instead of lam12
                w.salp1 = cbet2 * somg12;
                w.calp1 = sbet12a - cbet2 * sbet1 * GeoMath.sq(somg12) / (1 - comg12)
            }
        }
        
        // Sanity check on starting guess.  Backwards check allows NaN through.
        if !(w.salp1 <= 0) {
            let p = GeoMath.norm(w.salp1, w.calp1)
            w.salp1 = p.0
            w.calp1 = p.1
        } else {
            w.salp1 = 1
            w.calp1 = 0
        }
        
        return w
    }
    
    struct Lambda12V {
        var lam12: Double
        var salp2: Double
        var calp2: Double
        var sig12: Double
        var ssig1: Double
        var csig1: Double
        var ssig2: Double
        var csig2: Double
        var eps: Double
        var domg12: Double
        var dlam12: Double
        
        init() {
            self.lam12 = .nan
            self.salp2 = .nan
            self.calp2 = .nan
            self.sig12 = .nan
            self.ssig1 = .nan
            self.csig1 = .nan
            self.ssig2 = .nan
            self.csig2 = .nan
            self.eps = .nan
            self.domg12 = .nan
            self.dlam12 = .nan
        }
    }
    
    private func lambda12(_ sbet1: Double, _ cbet1: Double, _ dn1: Double,
                          _ sbet2: Double, _ cbet2: Double, _ dn2: Double,
                          _ salp1: Double, _ calp1: Double,
                          _ slam120: Double, _ clam120: Double,
                          _ diffp: Bool,
                          // Scratch areas of the right size
                          _ C1a: inout [Double], _ C2a: inout [Double], _ C3a: inout [Double]) -> Lambda12V {
        // Object to hold lam12, salp2, calp2, sig12, ssig1, csig1, ssig2, csig2,
        // eps, domg12, dlam12;
        
        var w = Lambda12V()
        var _calp1 = calp1
        
        if sbet1 == 0 && _calp1 == 0 {
            // Break degeneracy of equatorial line.  This case has already been
            // handled.
            _calp1 = -Geodesic.tiny
        }
        
        // sin(alp1) * cos(bet1) = sin(alp0)
        let salp0 = salp1 * cbet1
        let calp0 = GeoMath.hypot(_calp1, salp1 * sbet1)     // calp0 > 0
        
        // tan(bet1) = tan(sig1) * cos(alp1)
        // tan(omg1) = sin(alp0) * tan(sig1) = tan(omg1)=tan(alp1)*sin(bet1)
        let somg1 = salp0 * sbet1
        let comg1 = _calp1 * cbet1
        w.ssig1 = sbet1
        w.csig1 = comg1
        
        do {
            let p = GeoMath.norm(w.ssig1, w.csig1)
            w.ssig1 = p.0
            w.csig1 = p.1
        }
        // GeoMath.norm(somg1, comg1); -- don't need to normalize!
        
        // Enforce symmetries in the case abs(bet2) = -bet1.  Need to be careful
        // about this case, since this can yield singularities in the Newton
        // iteration.
        // sin(alp2) * cos(bet2) = sin(alp0)
        w.salp2 = cbet2 != cbet1 ? salp0 / cbet2 : salp1
        
        // calp2 = sqrt(1 - sq(salp2))
        //       = sqrt(sq(calp0) - sq(sbet2)) / cbet2
        // and subst for calp0 and rearrange to give (choose positive sqrt
        // to give alp2 in [0, pi/2]).
        w.calp2 = cbet2 != cbet1 || abs(sbet2) != -sbet1 ? sqrt(GeoMath.sq(_calp1 * cbet1) +
            (cbet1 < -sbet1 ?
                (cbet2 - cbet1) * (cbet1 + cbet2) :
                (sbet1 - sbet2) * (sbet1 + sbet2))) / cbet2 : abs(_calp1)
        
        // tan(bet2) = tan(sig2) * cos(alp2)
        // tan(omg2) = sin(alp0) * tan(sig2).
        let somg2 = salp0 * sbet2
        let comg2 = w.calp2 * cbet2
        w.ssig2 = sbet2
        w.csig2 = comg2
        
        do {
            let p = GeoMath.norm(w.ssig2, w.csig2)
            w.ssig2 = p.0
            w.csig2 = p.1
        }
        // GeoMath.norm(somg2, comg2); -- don't need to normalize!
        
        // sig12 = sig2 - sig1, limit to [0, pi]
        w.sig12 = atan2(max(0.0, w.csig1 * w.ssig2 - w.ssig1 * w.csig2), w.csig1 * w.csig2 + w.ssig1 * w.ssig2)
        
        // omg12 = omg2 - omg1, limit to [0, pi]
        let somg12 = max(0.0, comg1 * somg2 - somg1 * comg2)
        let comg12 = comg1 * comg2 + somg1 * somg2
        
        // eta = omg12 - lam120
        let eta = atan2(somg12 * clam120 - comg12 * slam120, comg12 * clam120 + somg12 * slam120)
        let k2 = GeoMath.sq(calp0) * ep2
        w.eps = k2 / (2 * (1 + sqrt(1 + k2)) + k2)
        
        C3f(w.eps, &C3a)
        
        let B312 = Geodesic.sincosSeries(true, w.ssig2, w.csig2, C3a) - Geodesic.sincosSeries(true, w.ssig1, w.csig1, C3a)
        w.domg12 = -f * A3f(w.eps) * salp0 * (w.sig12 + B312)
        w.lam12 = eta + w.domg12
        
        if diffp {
            if w.calp2 == 0 {
                w.dlam12 = -2 * f1 * dn1 / sbet1
            } else {
                let v = lengths(w.eps, w.sig12, w.ssig1, w.csig1,
                                dn1, w.ssig2, w.csig2, dn2,
                                cbet1, cbet2, GeodesicMask.REDUCEDLENGTH,
                                &C1a, &C2a)
                w.dlam12 = v.m12b
                w.dlam12 *= f1 / (w.calp2 * cbet2)
            }
        }
        
        return w
    }
    
    func A3f(_ eps: Double) -> Double {
        // Evaluate A3
        return GeoMath.polyval(n: Geodesic.nA3 - 1, p: A3x, s: 0, x: eps)
    }
    
    func C3f(_ eps: Double, _ c: inout [Double]) {
        // Evaluate C3 coeffs
        // Elements c[1] thru c[nC3_ - 1] are set
        var mult = 1.0
        var o = 0
        for l in 1..<Geodesic.nC3 {     // l is index of C3[l]
            let m = Geodesic.nC3 - l - 1        // order of polynomial in eps
            mult *= eps
            c[l] = mult * GeoMath.polyval(n: m, p: C3x, s: o, x: eps)
            o += m + 1
        }
    }
    
    func C4f(_ eps: Double, _ c: inout [Double]) {
        // Evaluate C4 coeffs
        // Elements c[0] thru c[nC4_ - 1] are set
        var mult = 1.0
        var o = 0
        for l in 0..<Geodesic.nC4 {             // l is index of C4[l]
            let m = Geodesic.nC4 - l - 1;       // order of polynomial in eps
            c[l] = mult * GeoMath.polyval(n: m, p: C4x, s: o, x: eps)
            o += m + 1
            mult *= eps
        }
    }
    
    // The scale factor A1-1 = mean value of (d/dsigma)I1 - 1
    static func A1m1f(_ eps: Double) -> Double {
        let coeff: [Double] = [
            // (1-eps)*A1-1, polynomial in eps2 of order 3
            1, 4, 64, 0, 256,
        ]
        let m = nA1 / 2
        let t = GeoMath.polyval(n: m, p: coeff, s: 0, x: GeoMath.sq(eps)) / coeff[m + 1]
        return (t + eps) / (1 - eps)
    }
    
    // The coefficients C1[l] in the Fourier expansion of B1
    static func C1f(_ eps: Double, _ c: inout [Double]) {
        let coeff: [Double] = [
            // C1[1]/eps^1, polynomial in eps2 of order 2
            -1, 6, -16, 32,
            // C1[2]/eps^2, polynomial in eps2 of order 2
            -9, 64, -128, 2048,
            // C1[3]/eps^3, polynomial in eps2 of order 1
            9, -16, 768,
            // C1[4]/eps^4, polynomial in eps2 of order 1
            3, -5, 512,
            // C1[5]/eps^5, polynomial in eps2 of order 0
            -7, 1280,
            // C1[6]/eps^6, polynomial in eps2 of order 0
            -7, 2048,
        ]
            
        let eps2 = GeoMath.sq(eps)
        var d = eps
        var o = 0
        for l in 1...nC1 {              // l is index of C1p[l]
            let m = (nC1 - l) / 2       // order of polynomial in eps^2
            c[l] = d * GeoMath.polyval(n: m, p: coeff, s: o, x: eps2) / coeff[o + m + 1]
            o += m + 2
            d *= eps
        }
    }
    
    // The coefficients C1p[l] in the Fourier expansion of B1p
    static func C1pf(_ eps: Double, _ c: inout [Double]) {
        let coeff: [Double] = [
            // C1p[1]/eps^1, polynomial in eps2 of order 2
            205, -432, 768, 1536,
            // C1p[2]/eps^2, polynomial in eps2 of order 2
            4005, -4736, 3840, 12288,
            // C1p[3]/eps^3, polynomial in eps2 of order 1
            -225, 116, 384,
            // C1p[4]/eps^4, polynomial in eps2 of order 1
            -7173, 2695, 7680,
            // C1p[5]/eps^5, polynomial in eps2 of order 0
            3467, 7680,
            // C1p[6]/eps^6, polynomial in eps2 of order 0
            38081, 61440,
        ]
        
        let eps2 = GeoMath.sq(eps)
        var d = eps
        var o = 0
        for l in 1...nC1p {            // l is index of C1p[l]
            let m = (nC1p - l) / 2     // order of polynomial in eps^2
            c[l] = d * GeoMath.polyval(n: m, p: coeff, s: o, x: eps2) / coeff[o + m + 1]
            o += m + 2
            d *= eps
        }
    }
    
    // The scale factor A2-1 = mean value of (d/dsigma)I2 - 1
    static func A2m1f(_ eps: Double) -> Double {
        let coeff: [Double] = [
            // (eps+1)*A2-1, polynomial in eps2 of order 3
            -11, -28, -192, 0, 256,
        ]
        
        let m = nA2 / 2
        let t = GeoMath.polyval(n: m, p: coeff, s: 0, x: GeoMath.sq(eps)) / coeff[m + 1]
        return (t - eps) / (1 + eps)
    }
    
    // The coefficients C2[l] in the Fourier expansion of B2
    static func C2f(_ eps: Double, _ c: inout [Double]) {
        let coeff: [Double] = [
            // C2[1]/eps^1, polynomial in eps2 of order 2
            1, 2, 16, 32,
            // C2[2]/eps^2, polynomial in eps2 of order 2
            35, 64, 384, 2048,
            // C2[3]/eps^3, polynomial in eps2 of order 1
            15, 80, 768,
            // C2[4]/eps^4, polynomial in eps2 of order 1
            7, 35, 512,
            // C2[5]/eps^5, polynomial in eps2 of order 0
            63, 1280,
            // C2[6]/eps^6, polynomial in eps2 of order 0
            77, 2048,
        ]
        
        let eps2 = GeoMath.sq(eps)
        var d = eps
        var o = 0
        for l in 1...nC2 {             // l is index of C2[l]
            let m = (nC2 - l) / 2      // order of polynomial in eps^2
            c[l] = d * GeoMath.polyval(n: m, p: coeff, s: o, x: eps2) / coeff[o + m + 1]
            o += m + 2
            d *= eps
        }
    }
    
    // The scale factor A3 = mean value of (d/dsigma)I3
    func A3coeff() {
        let coeff: [Double] = [
            // A3, coeff of eps^5, polynomial in n of order 0
            -3, 128,
            // A3, coeff of eps^4, polynomial in n of order 1
            -2, -3, 64,
            // A3, coeff of eps^3, polynomial in n of order 2
            -1, -3, -1, 16,
            // A3, coeff of eps^2, polynomial in n of order 2
            3, -1, -2, 8,
            // A3, coeff of eps^1, polynomial in n of order 1
            1, -1, 2,
            // A3, coeff of eps^0, polynomial in n of order 0
            1, 1,
        ]
        
        var o = 0
        var k = 0
        let n = Geodesic.nA3 - 1
        for j in (0...n).reversed() {               // coeff of eps^j
            let m = min(Geodesic.nA3 - j - 1, j)    // order of polynomial in n
            A3x[k] = GeoMath.polyval(n: m, p: coeff, s: o, x: self.n) / coeff[o + m + 1]
            k += 1
            o += m + 2
        }
    }
    
    // The coefficients C3[l] in the Fourier expansion of B3
    func C3coeff() {
        let coeff: [Double] = [
            // C3[1], coeff of eps^5, polynomial in n of order 0
            3, 128,
            // C3[1], coeff of eps^4, polynomial in n of order 1
            2, 5, 128,
            // C3[1], coeff of eps^3, polynomial in n of order 2
            -1, 3, 3, 64,
            // C3[1], coeff of eps^2, polynomial in n of order 2
            -1, 0, 1, 8,
            // C3[1], coeff of eps^1, polynomial in n of order 1
            -1, 1, 4,
            // C3[2], coeff of eps^5, polynomial in n of order 0
            5, 256,
            // C3[2], coeff of eps^4, polynomial in n of order 1
            1, 3, 128,
            // C3[2], coeff of eps^3, polynomial in n of order 2
            -3, -2, 3, 64,
            // C3[2], coeff of eps^2, polynomial in n of order 2
            1, -3, 2, 32,
            // C3[3], coeff of eps^5, polynomial in n of order 0
            7, 512,
            // C3[3], coeff of eps^4, polynomial in n of order 1
            -10, 9, 384,
            // C3[3], coeff of eps^3, polynomial in n of order 2
            5, -9, 5, 192,
            // C3[4], coeff of eps^5, polynomial in n of order 0
            7, 512,
            // C3[4], coeff of eps^4, polynomial in n of order 1
            -14, 7, 512,
            // C3[5], coeff of eps^5, polynomial in n of order 0
            21, 2560,
        ]
        
        var o = 0
        var k = 0
        for l in 1..<Geodesic.nC3 {                     // l is index of C3[l]
            let n = Geodesic.nC3 - 1
            for j in (l...n).reversed() {               // coeff of eps^j
                let m = min(Geodesic.nC3 - j - 1, j)    // order of polynomial in n
                C3x[k] = GeoMath.polyval(n: m, p: coeff, s: o, x: self.n) / coeff[o + m + 1]
                k += 1
                o += m + 2
            }
        }
    }
    
    func C4coeff() {
        let coeff: [Double] = [
            // C4[0], coeff of eps^5, polynomial in n of order 0
            97, 15015,
            // C4[0], coeff of eps^4, polynomial in n of order 1
            1088, 156, 45045,
            // C4[0], coeff of eps^3, polynomial in n of order 2
            -224, -4784, 1573, 45045,
            // C4[0], coeff of eps^2, polynomial in n of order 3
            -10656, 14144, -4576, -858, 45045,
            // C4[0], coeff of eps^1, polynomial in n of order 4
            64, 624, -4576, 6864, -3003, 15015,
            // C4[0], coeff of eps^0, polynomial in n of order 5
            100, 208, 572, 3432, -12012, 30030, 45045,
            // C4[1], coeff of eps^5, polynomial in n of order 0
            1, 9009,
            // C4[1], coeff of eps^4, polynomial in n of order 1
            -2944, 468, 135135,
            // C4[1], coeff of eps^3, polynomial in n of order 2
            5792, 1040, -1287, 135135,
            // C4[1], coeff of eps^2, polynomial in n of order 3
            5952, -11648, 9152, -2574, 135135,
            // C4[1], coeff of eps^1, polynomial in n of order 4
            -64, -624, 4576, -6864, 3003, 135135,
            // C4[2], coeff of eps^5, polynomial in n of order 0
            8, 10725,
            // C4[2], coeff of eps^4, polynomial in n of order 1
            1856, -936, 225225,
            // C4[2], coeff of eps^3, polynomial in n of order 2
            -8448, 4992, -1144, 225225,
            // C4[2], coeff of eps^2, polynomial in n of order 3
            -1440, 4160, -4576, 1716, 225225,
            // C4[3], coeff of eps^5, polynomial in n of order 0
            -136, 63063,
            // C4[3], coeff of eps^4, polynomial in n of order 1
            1024, -208, 105105,
            // C4[3], coeff of eps^3, polynomial in n of order 2
            3584, -3328, 1144, 315315,
            // C4[4], coeff of eps^5, polynomial in n of order 0
            -128, 135135,
            // C4[4], coeff of eps^4, polynomial in n of order 1
            -2560, 832, 405405,
            // C4[5], coeff of eps^5, polynomial in n of order 0
            128, 99099,
        ]
        
        var o = 0
        var k = 0
        for l in 0..<Geodesic.nC4 {                     // l is index of C4[l]
            let n = Geodesic.nC4 - 1
            for j in (l...n).reversed() {               // coeff of eps^j
                let m = Geodesic.nC4 - j - 1            // order of polynomial in n
                C4x[k] = GeoMath.polyval(n: m, p: coeff, s: o, x: self.n) / coeff[o + m + 1]
                k += 1
                o += m + 2
            }
        }
    }
}
