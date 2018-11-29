//
//  GeometrySpatialIndex.swift
//  MapMatching
//
//  Created by devilrabbit on 2018/10/14.
//  Copyright (c) 2018 devilrabbit. All rights reserved.
//

public class GeometrySpatialIndex<Indexer: SpatialIndex> {
    public typealias Item = Indexer.Item
    
    var index: Indexer
    var spatial: SpatialOperator
    var toPolyline: ((Item) -> (Polyline2D))
    var toLength: ((Item) -> (Double))
    
    public init(index: Indexer, spatial: SpatialOperator, toPolyline: @escaping ((Item) -> (Polyline2D)), toLength: @escaping ((Item) -> (Double))) {
        self.index = index
        self.spatial = spatial
        self.toPolyline = toPolyline
        self.toLength = toLength
    }
    
    public func add(item: Item) {
        let bounds = spatial.envelope(toPolyline(item))
        self.index.insert(in: bounds, item: item)
    }
    
    public func add(items: [Item]) {
        for item in items {
            self.add(item: item)
        }
    }
    
    public func search(in bounds: Rect2D) -> [Item] {
        return self.index.query(in: bounds)
    }
    
    /// Gets objects stored in the index that are within a certain radius or overlap a certain radius.
    /// - parameter center: Center point for radius search.
    /// - parameter radius: Radius in meters
    /// - parameter k: maximum number of candidates
    /// - returns: Result set of object(s) that are within a the given radius or overlap the radius, limited by k.
    public func search(at center: Coordinate2D, radius: Double, k: Int = -1) -> [(item: Item, distance: Double, point: Coordinate2D)] {
        var neighbors = [(item: Item, distance: Double, point: Coordinate2D)]()
        let bounds = spatial.envelope(center, radius)
        let candidates = self.index.query(in: bounds)
        for candidate in candidates {
            let geometry = toPolyline(candidate)
            let f = spatial.intercept(geometry, center)
            let p = spatial.interpolate(geometry, toLength(candidate), f)
            let d = spatial.distance(p, center)
            
            if d <= radius {
                neighbors.append((item: candidate, distance: f, point: p))
            }
        }
        
        if k > 0 {
            return Array(neighbors.sorted(by: { $0.distance < $1.distance }).prefix(k))
        }
        
        return neighbors
    }
}
