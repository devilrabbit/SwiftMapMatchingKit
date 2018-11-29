//
//  RoadMapBuilder.swift
//  MapMatching
//
//  Created by devilrabbit on 2018/10/12.
//  Copyright (c) 2018 devilrabbit. All rights reserved.
//

import Foundation

public class RoadMapBuilder {
    
    private var roads = [Int64 : RoadInfo]()
    private var spatial: SpatialOperator
    
    public init(spatial: SpatialOperator) {
        self.spatial = spatial
    }
    
    @discardableResult
    public func addRoad(_ road: RoadInfo) -> Self {
        roads[road.id] = road
        return self
    }
    
    public func addRoads(_ roads: [RoadInfo]) -> Self {
        for r in roads {
            addRoad(r)
        }
        return self
    }
    
    public func build() -> RoadMap {
        return RoadMap(roads: getAllRoads(), spatial: spatial)
    }
    
    private func getAllRoads() -> [Road] {
        var roads = [Road]()
        for roadInfo in self.roads.values {
            if roadInfo.oneWay {
                roads.append(Road(info: roadInfo, heading: .forward))
            } else {
                roads.append(Road(info: roadInfo, heading: .forward))
                roads.append(Road(info: roadInfo, heading: .backward))
            }
        }
        return roads
    }
}
