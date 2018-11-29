//
//  MatcherSample.swift
//  MapMatching
//
//  Created by devilrabbit on 2018/10/14.
//  Copyright (c) 2018 devilrabbit. All rights reserved.
//

import CoreLocation

public struct MatcherSample: Sample {
    
    public var id: Int64
    public var time: Date
    public var azimuth: Double
    public var coordinate: Coordinate2D
    
    public var isNaN: Bool {
        return self.id < 0
    }
    
    public var hasAzimuth: Bool {
        return !self.azimuth.isNaN
    }
    
    public init(id: Int64, time: Int64, lng: Double, lat: Double, azimuth: Double = .nan) {
        self.id = id
        self.time = Date(timeIntervalSince1970: TimeInterval(time))
        self.coordinate = CLLocationCoordinate2D(latitude: lat, longitude: lng)
        self.azimuth = MatcherSample.normAzimuth(azimuth)
    }
    
    public init(id: Int64, time: Int64, point: Coordinate2D, azimuth: Double = .nan) {
        self.id = id
        self.time = Date(timeIntervalSince1970: TimeInterval(time))
        self.coordinate = point
        self.azimuth = MatcherSample.normAzimuth(azimuth)
    }
    
    public init(id: Int64, time: Date, point: Coordinate2D, azimuth: Double = .nan) {
        self.id = id
        self.time = time
        self.coordinate = point
        self.azimuth = MatcherSample.normAzimuth(azimuth)
    }
    
    public init(id: Int64, time: Date, x: Double, y: Double, azimuth: Double = .nan) {
        self.id = id
        self.time = time
        self.coordinate = CLLocationCoordinate2D(latitude: y, longitude: x)
        self.azimuth = MatcherSample.normAzimuth(azimuth)
    }
    
    private static func normAzimuth(_ azimuth: Double) -> Double {
        return azimuth >= 360 ?
        azimuth - (360 * floor(azimuth / 360)) :
        (azimuth < 0 ? azimuth - (360 * (ceil(azimuth / 360) - 1)) : azimuth)
    }
}
