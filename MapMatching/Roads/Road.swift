//
//  Road.swift
//  MapMatching
//
//  Created by devilrabbit on 2018/10/12.
//  Copyright (c) 2018 devilrabbit. All rights reserved.
//

public class Road: GraphEdge {
    
    public private(set) var id: Int64
    public private(set) var source: Int64
    public private(set) var target: Int64
    public private(set) var weight: Double?
    public var neighbor: Road?
    public var successor: Road?
    
    public internal(set) var roadInfo: RoadInfo
    public internal(set) var heading: Heading
    public internal(set) var geometry: Polyline2D
    
    public init(info: RoadInfo, heading: Heading) {
        self.id = heading == .forward ? info.id * 2 : info.id * 2 + 1
        self.source = heading == .forward ? info.source : info.target
        self.target = heading == .forward ? info.target : info.source
        self.roadInfo = info
        self.heading = heading
        
        if heading == .forward {
            self.geometry = info.geometry
        } else {
            self.geometry = info.geometry.reversed()
        }
    }
    
    public var length: Double {
        return roadInfo.length
    }
    
    public var maxSpeed: Float {
        return heading == .forward ? roadInfo.maxSpeedForward : roadInfo.maxSpeedBackward
    }
    
    public var priority: Float {
        return self.roadInfo.priority
    }
}
