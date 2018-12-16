//
//  GeoJSON.swift
//  MapMatching
//
//  Created by devilrabbit on 2018/10/23.
//  Copyright (c) 2018 devilrabbit. All rights reserved.
//

import Foundation
import CoreLocation

public typealias GeoJSONDictionary = [AnyHashable : Any]

public protocol GeoJSONConvertible {
    init?(dictionary: GeoJSONDictionary)
    
    var properties: [String : Any]? { get }
    
    func toDictionary() -> GeoJSONDictionary
    func toGeoJSONString() -> String?
}

public enum GeoJSONError: Error {
    case invalidFormat
}

public extension GeoJSONConvertible {
    public func toGeoJSONString() -> String? {
        guard let data = try? JSONSerialization.data(withJSONObject: self.toDictionary()) else { return nil }
        return String(bytes: data, encoding: .utf8)
    }
}

public protocol CoordinateConvertible {
    associatedtype CoordinateRepresentationType
    init?(coordinates: CoordinateRepresentationType)
    func coordinateRepresentation() -> CoordinateRepresentationType
}

public protocol GeometryConvertible {
    associatedtype GeometryType: Codable
    var geometry: GeometryType { get set }
    init(geometry: GeometryType)
}

public protocol Feature: Codable, GeoJSONConvertible, CoordinateConvertible, GeometryConvertible {}

enum CodingKeys: String, CodingKey {
    case type
    case features
    case geometry
    case coordinates
    case properties
}

enum FeatureTypes: String, Decodable {
    case point = "Point"
    case lineString = "LineString"
    case polygon = "Polygon"
    case multiPoint = "MultiPoint"
    case multiLineString = "MultiLineString"
    case multiPolygon = "MultiPolygon"
}

extension Feature {
    
    public init?(dictionary: GeoJSONDictionary) {
        guard let coordinates = (dictionary["geometry"] as? [AnyHashable: Any])?["coordinates"] as? CoordinateRepresentationType else { return nil }
        self.init(coordinates: coordinates)
    }
    
    public func toDictionary() -> GeoJSONDictionary {
        if let properties = self.properties {
            return [
                "type": "Feature",
                "geometry": [
                    "type": String(describing: type(of: self)),
                    "coordinates": coordinateRepresentation() as AnyObject,
                    "properties": properties as AnyObject
                ]
            ]
        }
        return [
            "type": "Feature",
            "geometry": [
                "type": String(describing: type(of: self)),
                "coordinates": coordinateRepresentation() as AnyObject
            ]
        ]
    }
}

open class Point: Feature {
    
    public typealias GeometryType = CLLocationCoordinate2D
    public typealias CoordinateRepresentationType = [Double]
    
    open var geometry: CLLocationCoordinate2D
    open var properties: [String : Any]?
    
    public required init(geometry: CLLocationCoordinate2D) {
        self.geometry = geometry
    }
    
    public required init?(coordinates: CoordinateRepresentationType) {
        guard let position = CLLocationCoordinate2D(coordinates: coordinates) else { return nil }
        self.geometry = position
    }
    
    public required init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        guard "Feature" == (try values.decode(String.self, forKey: .type)) else { throw GeoJSONError.invalidFormat }
        let geometry = try values.nestedContainer(keyedBy: CodingKeys.self, forKey: .geometry)
        guard "Point" == (try geometry.decode(String.self, forKey: .type)) else { throw GeoJSONError.invalidFormat }
        self.geometry = try geometry.decode(CLLocationCoordinate2D.self, forKey: .coordinates)
        self.properties = try values.decodeIfPresent([String : Any].self, forKey: .properties)
    }
    
    open func encode(to encoder: Encoder) throws {
        
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
    open var properties: [String : Any]?
    
    public required init(geometry: [CLLocationCoordinate2D]) {
        self.geometry = geometry
    }
    
    public init(geometry: [Coordinate2D]) {
        self.geometry = geometry.map { CLLocationCoordinate2D(latitude: $0.y, longitude: $0.x) }
    }
    
    public required init?(coordinates: CoordinateRepresentationType) {
        self.geometry = coordinates.map { CLLocationCoordinate2D(latitude: $0[0], longitude: $0[1]) }
    }
    
    public required init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        guard "Feature" == (try values.decode(String.self, forKey: .type)) else { throw GeoJSONError.invalidFormat }
        let geometry = try values.nestedContainer(keyedBy: CodingKeys.self, forKey: .geometry)
        guard "LineString" == (try geometry.decode(String.self, forKey: .type)) else { throw GeoJSONError.invalidFormat }
        self.geometry = try geometry.decode([CLLocationCoordinate2D].self, forKey: .coordinates)
        self.properties = try values.decodeIfPresent([String : Any].self, forKey: .properties)
    }
    
    open func encode(to encoder: Encoder) throws {
        
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
    open var properties: [String : Any]?
    
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
    
    public required init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        guard "Feature" == (try values.decode(String.self, forKey: .type)) else { throw GeoJSONError.invalidFormat }
        let geometry = try values.nestedContainer(keyedBy: CodingKeys.self, forKey: .geometry)
        guard "Polygon" == (try geometry.decode(String.self, forKey: .type)) else { throw GeoJSONError.invalidFormat }
        self.geometry = try geometry.decode([[CLLocationCoordinate2D]].self, forKey: .coordinates)
        self.properties = try values.decodeIfPresent([String : Any].self, forKey: .properties)
    }
    
    open func encode(to encoder: Encoder) throws {
        
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
    open var properties: [String : Any]?
    
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
    
    public required init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        let coordinates = try values.decode(GeometryType.self, forKey: CodingKeys.coordinates)
        self.features = coordinates.compactMap { FeatureType(geometry: $0) }
        self.geometry = features.map { $0.geometry }
        self.properties = try values.decodeIfPresent([String : Any].self, forKey: .properties)
    }
    
    open func encode(to encoder: Encoder) throws {
        
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

open class FeatureCollection: Codable, GeoJSONConvertible {
    
    open var features: [GeoJSONConvertible]
    open var properties: [String : Any]?
    
    public required init(features: [GeoJSONConvertible]) {
        self.features = features
    }
    
    public required init?(dictionary: GeoJSONDictionary) {
        
        let geoJSONfeatures = dictionary["features"] as? [GeoJSONDictionary]
        
        self.features = geoJSONfeatures?.compactMap { feature in
            let type = (feature["geometry"] as? [AnyHashable: Any])?["type"] as! String
            switch type {
            case "Point":
                return Point(dictionary: feature)
            case "LineString":
                return LineString(dictionary: feature)
            case "Polygon":
                return Polygon(dictionary: feature)

            default:
                print("GeoJSON type", type, "not implemented!")
                return nil
            }
        } ?? []
    }
    
    public required init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        let type = try values.decode(String.self, forKey: .type)
        guard type == "FeatureCollection" else { throw GeoJSONError.invalidFormat }
        
        var features = [GeoJSONConvertible]()
        var featuresArrayForType = try values.nestedUnkeyedContainer(forKey: .features)
        var featuresArray = featuresArrayForType
        while !featuresArrayForType.isAtEnd {
            do {
            let feature = try featuresArrayForType.nestedContainer(keyedBy: CodingKeys.self)
            let geometry = try feature.nestedContainer(keyedBy: CodingKeys.self, forKey: .geometry)
            let type = try geometry.decode(String.self, forKey: .type)
            switch type {
            case "Point":
                features.append(try featuresArray.decode(Point.self))
            case "LineString":
                features.append(try featuresArray.decode(LineString.self))
            case "Polygon":
                features.append(try featuresArray.decode(Polygon.self))
            case "MultiPoint":
                features.append(try featuresArray.decode(Multi<Point>.self))
            case "MultiLineString":
                features.append(try featuresArray.decode(Multi<LineString>.self))
            case "MultiPolygon":
                features.append(try featuresArray.decode(Multi<Polygon>.self))
            default:
                break
            }
            } catch {
                print(error)
            }
        }
        
        self.features = features
        self.properties = try values.decodeIfPresent([String : Any].self, forKey: .properties)
    }
    
    open func encode(to encoder: Encoder) throws {
        
    }
    
    open func toDictionary() -> GeoJSONDictionary {
        if let properties = properties {
            return [
                "type": "FeatureCollection",
                "features": features.map { $0.toDictionary() },
                "properties": properties
            ]
        }
        return ["type": "FeatureCollection", "features": features.map { $0.toDictionary() }]
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

extension CLLocationCoordinate2D: Codable {
    
    public init(from decoder: Decoder) throws {
        self.init()
        
        let container = try decoder.singleValueContainer()
        let values = try container.decode([Double].self)
        self.latitude = values[1]
        self.longitude = values[0]
    }
    
    public func encode(to encoder: Encoder) throws {
        
    }
}

public func +(lhs: FeatureCollection, rhs: FeatureCollection) -> FeatureCollection {
    return FeatureCollection(features: lhs.features+rhs.features)
}

struct JSONCodingKeys: CodingKey {
    var stringValue: String
    
    init?(stringValue: String) {
        self.stringValue = stringValue
    }
    
    var intValue: Int?
    
    init?(intValue: Int) {
        self.init(stringValue: "\(intValue)")
        self.intValue = intValue
    }
}


extension KeyedDecodingContainer {
    
    func decode(_ type: Dictionary<String, Any>.Type, forKey key: K) throws -> Dictionary<String, Any> {
        let container = try self.nestedContainer(keyedBy: JSONCodingKeys.self, forKey: key)
        return try container.decode(type)
    }
    
    func decodeIfPresent(_ type: Dictionary<String, Any>.Type, forKey key: K) throws -> Dictionary<String, Any>? {
        guard contains(key) else {
            return nil
        }
        return try decode(type, forKey: key)
    }
    
    func decode(_ type: Array<Any>.Type, forKey key: K) throws -> Array<Any> {
        var container = try self.nestedUnkeyedContainer(forKey: key)
        return try container.decode(type)
    }
    
    func decodeIfPresent(_ type: Array<Any>.Type, forKey key: K) throws -> Array<Any>? {
        guard contains(key) else {
            return nil
        }
        return try decode(type, forKey: key)
    }
    
    func decode(_ type: Dictionary<String, Any>.Type) throws -> Dictionary<String, Any> {
        var dictionary = Dictionary<String, Any>()
        
        for key in allKeys {
            if let boolValue = try? decode(Bool.self, forKey: key) {
                dictionary[key.stringValue] = boolValue
            } else if let stringValue = try? decode(String.self, forKey: key) {
                dictionary[key.stringValue] = stringValue
            } else if let intValue = try? decode(Int.self, forKey: key) {
                dictionary[key.stringValue] = intValue
            } else if let doubleValue = try? decode(Double.self, forKey: key) {
                dictionary[key.stringValue] = doubleValue
            } else if let nestedDictionary = try? decode(Dictionary<String, Any>.self, forKey: key) {
                dictionary[key.stringValue] = nestedDictionary
            } else if let nestedArray = try? decode(Array<Any>.self, forKey: key) {
                dictionary[key.stringValue] = nestedArray
            }
        }
        return dictionary
    }
}

extension UnkeyedDecodingContainer {
    
    mutating func decode(_ type: Array<Any>.Type) throws -> Array<Any> {
        var array: [Any] = []
        while isAtEnd == false {
            if let value = try? decode(Bool.self) {
                array.append(value)
            } else if let value = try? decode(Double.self) {
                array.append(value)
            } else if let value = try? decode(String.self) {
                array.append(value)
            } else if let nestedDictionary = try? decode(Dictionary<String, Any>.self) {
                array.append(nestedDictionary)
            } else if let nestedArray = try? decode(Array<Any>.self) {
                array.append(nestedArray)
            }
        }
        return array
    }
    
    mutating func decode(_ type: Dictionary<String, Any>.Type) throws -> Dictionary<String, Any> {
        
        let nestedContainer = try self.nestedContainer(keyedBy: JSONCodingKeys.self)
        return try nestedContainer.decode(type)
    }
}
