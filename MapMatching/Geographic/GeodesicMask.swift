//
//  GeodesicMask.swift
//  MapMatching
//
//  Created by devilrabbit on 2018/10/18.
//  Copyright (c) 2018 devilrabbit. All rights reserved.
//

import Foundation

/**
 * Bit masks for what geodesic calculations to do.
 * <p>
 * These masks do double duty.  They specify (via the <i>outmask</i> parameter)
 * which results to return in the {@link GeodesicData} object returned by the
 * general routines {@link Geodesic#Direct(double, double, double, double, int)
 * Geodesic.Direct} and {@link Geodesic#Inverse(double, double, double, double,
 * int) Geodesic.Inverse} routines.  They also signify (via the <i>caps</i>
 * parameter) to the {@link GeodesicLine#GeodesicLine(Geodesic, double, double,
 * double, int) GeodesicLine.GeodesicLine} constructor and to {@link
 * Geodesic#Line(double, double, double, int) Geodesic.Line} what capabilities
 * should be included in the {@link GeodesicLine} object.
 **********************************************************************/

public struct GeodesicMask: OptionSet {
    
    public let rawValue: Int
    
    static let CAP_NONE = GeodesicMask(rawValue: 0)
    static let CAP_C1 = GeodesicMask(rawValue: 1 << 0)
    static let CAP_C1p = GeodesicMask(rawValue: 1 << 1)
    static let CAP_C2 = GeodesicMask(rawValue: 1 << 2)
    static let CAP_C3 = GeodesicMask(rawValue: 1 << 3)
    static let CAP_C4 = GeodesicMask(rawValue: 1 << 4)
    static let CAP_ALL = GeodesicMask(rawValue: 0x1f)
    static let CAP_MASK = GeodesicMask(rawValue: 0x1f)
    static let OUT_ALL = GeodesicMask(rawValue: 0x7f80)
    static let OUT_MASK = GeodesicMask(rawValue: 0xff80) // Include LONG_UNROLL
    
    public init(rawValue: Int) {
        self.rawValue = rawValue
    }
    
    init(rawValues: [Int]) {
        self.rawValue = rawValues.reduce(0) { $0 + (1 << $1) }
    }
    
    /// No capabilities, no output.
    public static let NONE = GeodesicMask(rawValue: 0)
    
    /// Calculate latitude <i>lat2</i>.  (It's not necessary to include this as a
    /// capability to {@link GeodesicLine} because this is included by default.)
    public static let LATITUDE = GeodesicMask(rawValue: 1 << 7 | CAP_NONE.rawValue)
    
    /// Calculate longitude <i>lon2</i>.
    public static let LONGITUDE = GeodesicMask(rawValue: 1 << 8 | CAP_C3.rawValue)
    
    /// Calculate azimuths <i>azi1</i> and <i>azi2</i>.  (It's not necessary to
    /// include this as a capability to {@link GeodesicLine} because this is
    /// included by default.)
    public static let AZIMUTH = GeodesicMask(rawValue: 1 << 9 | CAP_NONE.rawValue)
    
    /// Calculate distance <i>s12</i>.
    public static let DISTANCE = GeodesicMask(rawValue: 1 << 10 | CAP_C1.rawValue)
    
    /// All of the above, the "standard" output and capabilities.
    public static let STANDARD = GeodesicMask(rawValue: LATITUDE.rawValue | LONGITUDE.rawValue |
        AZIMUTH.rawValue | DISTANCE.rawValue)
    
    /// Allow distance <i>s12</i> to be used as <i>input</i> in the direct geodesic problem.
    public static let DISTANCE_IN = GeodesicMask(rawValue: 1 << 11 | CAP_C1.rawValue | CAP_C1p.rawValue)
    
    /// Calculate reduced length <i>m12</i>.
    public static let REDUCEDLENGTH = GeodesicMask(rawValue: 1 << 12 | CAP_C1.rawValue | CAP_C2.rawValue)
    
    /// Calculate geodesic scales <i>M12</i> and <i>M21</i>.
    public static let GEODESICSCALE = GeodesicMask(rawValue: 1 << 13 | CAP_C1.rawValue | CAP_C2.rawValue)
    
    /// Calculate area <i>S12</i>.
    public static let AREA = GeodesicMask(rawValue: 1 << 14 | CAP_C4.rawValue)
        
    /// All capabilities, calculate everything.  (LONG_UNROLL is not included in this mask.)
    public static let ALL = GeodesicMask(rawValue: OUT_ALL.rawValue | CAP_ALL.rawValue)
    
    /// Unroll <i>lon2</i>.
    public static let LONG_UNROLL = GeodesicMask(rawValue: 1 << 15)
    
}

extension OptionSet {
    
    public func containsAny(_ member: Self) -> Bool {
        return !self.isDisjoint(with: member)
    }
}
