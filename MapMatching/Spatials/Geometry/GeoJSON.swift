//
//  GeoJSON.swift
//  MapMatching
//
//  Created by devilrabbit on 2018/10/23.
//  Copyright (c) 2018 devilrabbit. All rights reserved.
//

import Foundation
import CoreLocation

public typealias GeoJSONDictionary = [AnyHashable: Any]

public protocol GeoJSONConvertible {
    init?(dictionary: GeoJSONDictionary)
    func geoJSONRepresentation() -> GeoJSONDictionary
}

public protocol CoordinateConvertible {
    associatedtype CoordinateRepresentationType
    init?(coordinates: CoordinateRepresentationType)
    func coordinateRepresentation() -> CoordinateRepresentationType
}

public protocol GeometryConvertible {
    associatedtype GeometryType
    var geometry: GeometryType { get set }
    init(geometry: GeometryType)
}

public protocol Feature: GeoJSONConvertible, CoordinateConvertible, GeometryConvertible {}

extension Feature {
    public init?(dictionary: GeoJSONDictionary) {
        guard let coordinates = (dictionary["geometry"] as? [AnyHashable: Any])?["coordinates"] as? CoordinateRepresentationType else { return nil }
        self.init(coordinates: coordinates)
    }
}

open class Point: Feature {
    
    public typealias GeometryType = CLLocationCoordinate2D
    public typealias CoordinateRepresentationType = [Double]
    
    open var geometry: CLLocationCoordinate2D
    
    public required init(geometry: CLLocationCoordinate2D) {
        self.geometry = geometry
    }
    
    public required init?(coordinates: CoordinateRepresentationType) {
        guard let position = CLLocationCoordinate2D(coordinates: coordinates) else { return nil }
        geometry = position
    }
    
    open func coordinateRepresentation() -> CoordinateRepresentationType {
        return geometry.geoJSONRepresentation
    }
}

extension Point: Coordinate2D {
    
    public var x: Double {
        return geometry.x
    }
    
    public var y: Double {
        return geometry.y
    }
    
    public func distance(_ other: Vec2D) -> Double {
        let dx = self.x - other.x
        let dy = self.y - other.y
        return sqrt(dx * dx + dy * dy)
    }
    
}

open class LineString: Feature {
    
    public typealias GeometryType = [CLLocationCoordinate2D]
    public typealias CoordinateRepresentationType = [[Double]]
    
    open var geometry: [CLLocationCoordinate2D]
    
    public required init(geometry: [CLLocationCoordinate2D]) {
        self.geometry = geometry
    }
    
    public init(geometry: [Coordinate2D]) {
        self.geometry = geometry.map { CLLocationCoordinate2D(latitude: $0.y, longitude: $0.x) }
    }
    
    public required init?(coordinates: CoordinateRepresentationType) {
        self.geometry = coordinates.map { CLLocationCoordinate2D(latitude: $0[0], longitude: $0[1]) }
    }
    
    open func coordinateRepresentation() -> CoordinateRepresentationType {
        return geometry.map { $0.geoJSONRepresentation }
    }
}

extension LineString: Polyline2D {
    
    public var coordinates: [Coordinate2D] {
        return geometry
    }
    
    public var length: Double {
        return (Turf.shared.length(self) ?? 0) * 1000
    }
    
    public var bbox: Rect2D {
        return Turf.shared.bbox(self) ?? Rectangle2D()
    }
    
    public func reversed() -> Polyline2D {
        return LineString(geometry: self.geometry.reversed())
    }
    
}

open class Polygon: Feature {
    
    public typealias GeometryType = [[CLLocationCoordinate2D]]
    public typealias CoordinateRepresentationType = [[[Double]]]
    
    open var geometry: [[CLLocationCoordinate2D]]
    
    public required init(geometry: [[CLLocationCoordinate2D]]) {
        self.geometry = geometry
    }
    
    public required init?(coordinates: CoordinateRepresentationType) {
        guard let linearRings = coordinates.map({ $0.compactMap(CLLocationCoordinate2D.init) }) as GeometryType? else { return nil }
        for linearRing in linearRings {
            guard linearRing.first == linearRing.last else { return nil }
        }
        self.geometry = linearRings
    }
    
    open func coordinateRepresentation() -> CoordinateRepresentationType {
        return geometry.map { $0.map { $0.geoJSONRepresentation } }
    }
}

public typealias MultiPoint = Multi<Point>

public typealias MultiLineString = Multi<LineString>

public typealias MultiPolygon = Multi<Polygon>

open class Multi<FeatureType: Feature> : Feature {
    
    public typealias GeometryType = [FeatureType.GeometryType]
    public typealias CoordinateRepresentationType = [FeatureType.CoordinateRepresentationType]
    
    open var features: [FeatureType] = []
    open var geometry: [FeatureType.GeometryType] = []
    
    public required init() {
        
    }
    
    public required init(geometry: [FeatureType.GeometryType]) {
        self.features = geometry.compactMap { FeatureType(geometry: $0) }
        self.geometry = geometry
    }
    
    public required init?(coordinates: CoordinateRepresentationType) {
        self.features = coordinates.compactMap { FeatureType(coordinates: $0) }
        self.geometry = features.map { $0.geometry }
    }
    
    open func coordinateRepresentation() -> [FeatureType.CoordinateRepresentationType] {
        return features.map { $0.coordinateRepresentation() }
    }
    
}

extension Multi where FeatureType == LineString {
    
    public var coordinates: [[Coordinate2D]] {
        return self.features.map { $0.coordinates }
    }
    
    public var length: Double {
        return (Turf.shared.length(self) ?? 0) * 1000
    }
}

open class FeatureCollection: GeoJSONConvertible {
    
    open var features: [GeoJSONConvertible]
    
    public required init(features: [GeoJSONConvertible]) {
        self.features = features
    }
    
    public required init?(dictionary: GeoJSONDictionary) {
        
        let geoJSONfeatures = dictionary["features"] as? [GeoJSONDictionary]
        
        self.features = geoJSONfeatures?
            .compactMap { feature in
                let type = (feature["geometry"] as? [AnyHashable: Any])?["type"] as! String
                switch type {
                case "Point":       return Point(dictionary: feature)
                case "Polygon":     return Polygon(dictionary: feature)
                case "LineString":  return LineString(dictionary: feature)
                default:
                    print("GeoJSON type", type, "not implemented!")
                    return nil
                }
            } ?? []
    }
    
    open func geoJSONRepresentation() -> GeoJSONDictionary {
        return [
            "type": "FeatureCollection",
            "features": features.map { $0.geoJSONRepresentation() },
            "properties": NSNull()
        ]
    }
}

extension Feature {
    
    public func geoJSONRepresentation() -> GeoJSONDictionary {
        return [
            "type": "Feature",
            "geometry": [
                "type": String(describing: type(of: self)),
                "coordinates": coordinateRepresentation() as AnyObject,
                "properties": NSNull()
            ],
            "properties": NSNull()
        ]
    }
}

extension CLLocationCoordinate2D: Equatable {
    
    public init?(coordinates: [Double]) {
        guard coordinates.count == 2 else { return nil }
        self.init(latitude: coordinates[1], longitude: coordinates[0])
    }
    
    public var geoJSONRepresentation: [Double] {
        return [longitude, latitude]
    }
    
    public static func == (lhs: CLLocationCoordinate2D, rhs: CLLocationCoordinate2D) -> Bool {
        return lhs.latitude == rhs.latitude && lhs.longitude == rhs.longitude
    }
}

public func +(lhs: FeatureCollection, rhs: FeatureCollection) -> FeatureCollection {
    return FeatureCollection(features: lhs.features+rhs.features)
}
