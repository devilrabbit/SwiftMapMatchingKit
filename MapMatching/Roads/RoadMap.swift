//
//  RoadMap.swift
//  MapMatching
//
//  Created by devilrabbit on 2018/10/12.
//  Copyright (c) 2018 devilrabbit. All rights reserved.
//

public final class RoadMap: AdjacencyGraph<Road> {
    
    private var index: GeometrySpatialIndex<STRTree<RoadInfo>>
    private var spatial: SpatialOperator
    
    public init(roads: [Road], spatial: SpatialOperator) {
        self.spatial = spatial
        self.index = GeometrySpatialIndex<STRTree<RoadInfo>>(index: STRTree(), spatial: spatial, toPolyline: { (r: RoadInfo) -> Polyline2D in return r.geometry }, toLength: { (r: RoadInfo) -> Double in return r.length })
        super.init(edges: roads)
        self.index.add(items: roads.map { $0.roadInfo })
    }
    
    public func radius(c: Vec2D, r: Double, k: Int = -1) -> [RoadPoint] {
        return self.split(points: self.index.search(at: c, radius: r, k: k))
    }
    
    private func split(points: [(RoadInfo, Double, Vec2D)]) -> [RoadPoint] {
        var result = [RoadPoint]()
        for point in points {
            if let road = edgeMap[point.0.id * 2] {
                result.append(
                    RoadPoint(road: road, fraction: point.1, coordinate: point.2, spatial: spatial))
            }
            
            let backwardRoadId = point.0.id * 2 + 1
            if let road = edgeMap[backwardRoadId]{
                result.append(
                    RoadPoint(road: road, fraction: 1.0 - point.1, coordinate: point.2, spatial: spatial))
            }
        }
        return result
    }
}
