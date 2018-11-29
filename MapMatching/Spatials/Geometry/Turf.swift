//
//  Turf.swift
//  MapMatching
//
//  Created by devilrabbit on 2018/10/24.
//  Copyright (c) 2018 devilrabbit. All rights reserved.
//

import Foundation

import JavaScriptCore

public final class Turf {
    
    private static let sharedInstance = Turf()
    public static var shared: Turf {
        return sharedInstance
    }
    
    private let context = JSContext()
    
    public enum Units: String {
        case meters = "meters"
        case kilometers = "kilometers"
        case feet = "feet"
        case miles = "miles"
        case degrees = "degrees"
    }
    
    private init() {
        
        let path = Bundle(for: Turf.self).path(forResource: "bundle", ofType: "js")!
        var js = try! String(contentsOfFile: path, encoding: String.Encoding.utf8)
        
        // Make browserify work
        js = "var window = this; \(js)"
        _ = context?.evaluateScript(js)
        
        context?.exceptionHandler = { context, exception in
            print(exception as Any)
        }
    }
    
    /// Calculates a buffer for input features for a given radius. Units supported are meters, kilometers, feet, miles, and degrees.
    ///
    /// - parameter feature:  input to be buffered
    /// - parameter distance: distance to draw the buffer
    /// - parameter units: .meters, .kilometers, .feet, .miles, or .degrees
    ///
    /// - returns: Polygon?
    public func buffer<G: GeoJSONConvertible>(_ feature: G, distance: Double, units: Units = .meters) -> Polygon? {
        
        let fn = self.context?.objectForKeyedSubscript("buffer")!
        let args: [AnyObject] = [feature.geoJSONRepresentation() as AnyObject, distance as AnyObject, ["units": units.rawValue as AnyObject, "steps": 90 as AnyObject] as AnyObject]
        
        if let bufferedGeoJSON = fn?.call(withArguments: args)?.toDictionary() {
            return Polygon(dictionary: bufferedGeoJSON)
        } else {
            return nil
        }
    }
    
    /// Takes a set of features, calculates the bbox of all input features, and returns a bounding box.
    /// - parameter geojson: any GeoJSON object
    /// - returns: bbox extent in minX, minY, maxX, maxY order
    public func bbox<G: GeoJSONConvertible>(_ geojson: G) -> Rect2D? {
        
        let fn = self.context?.objectForKeyedSubscript("bbox")
        let args: [AnyObject] = [geojson.geoJSONRepresentation() as AnyObject]
        
        if let result = fn?.call(withArguments: args)?.toArray() as? [Double] {
            return Rectangle2D(minX: result[0], minY: result[1], maxX: result[2], maxY: result[3])
        } else {
            return nil
        }
    }
    
    /// Takes a Polygon and returns Points at all self-intersections.
    ///
    /// - parameter feature: input polygon
    ///
    /// - returns: FeatureCollection?
    public func kinks(_ feature: Polygon) -> FeatureCollection? {
        
        let fn = self.context?.objectForKeyedSubscript("kinks")!
        let args: [AnyObject] = [feature.geoJSONRepresentation() as AnyObject]
        
        if let kinks = fn?.call(withArguments: args)?.toDictionary() {
            return FeatureCollection(dictionary: kinks)
        } else {
            return nil
        }
    }
    
    /// Takes a GeoJSON and measures its length in the specified units, (Multi)Point 's distance are ignored.
    /// - parameter geojson: GeoJSON to measure
    /// - parameter units: can be degrees, radians, miles, or kilometers
    /// - returns: length of GeoJSON
    public func length<G: GeoJSONConvertible>(_ geojson: G, units: Units = .kilometers) -> Double? {
        
        let fn = self.context?.objectForKeyedSubscript("length")
        let args: [AnyObject] = [geojson.geoJSONRepresentation() as AnyObject, ["units": units.rawValue as AnyObject] as AnyObject]
        
        return fn?.call(withArguments: args)?.toDouble()
    }
    
    /// Takes two line strings or polygon GeoJSON and returns points of intersection
    ///
    /// - parameter feature: line strings or polygon GeoJSON
    ///
    /// - returns: FeatureCollection?
    public func lineIntersect(_ line1: LineString, _ line2: LineString) -> FeatureCollection? {
        
        let fn = self.context?.objectForKeyedSubscript("lineIntersect")!
        let args: [AnyObject] = [line1.geoJSONRepresentation() as AnyObject, line2.geoJSONRepresentation() as AnyObject]
        
        if let intersect = fn?.call(withArguments: args)?.toDictionary() {
            return FeatureCollection(dictionary: intersect)
        } else {
            return nil
        }
    }
    
    /// Takes two line strings or polygon GeoJSON and returns points of intersection
    ///
    /// - parameter feature: line strings or polygon GeoJSON
    ///
    /// - returns: FeatureCollection?
    public func destination(point: Point, distanceMeters: Double, bearing: Double, units: Units = .meters) -> Point? {
        
        let fn = self.context?.objectForKeyedSubscript("destination")!
        let args: [AnyObject] = [point.geoJSONRepresentation()  as AnyObject, distanceMeters as AnyObject, bearing as AnyObject, ["units": units.rawValue as AnyObject] as AnyObject]
        
        if let destinationPoint = fn?.call(withArguments: args)?.toDictionary() {
            return Point(dictionary: destinationPoint)
        } else {
            return nil
        }
    }
}
