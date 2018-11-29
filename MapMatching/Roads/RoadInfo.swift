//
//  RoadInfo.swift
//  MapMatching
//
//  Created by devilrabbit on 2018/10/12.
//  Copyright (c) 2018 devilrabbit. All rights reserved.
//

import Foundation

public struct RoadInfo {
    
    public var geometry: Polyline2D
    public var id: Int64
    public var source: Int64
    public var target: Int64
    public var oneWay: Bool
    public var type: UInt16
    public var priority: Float
    public var maxSpeedForward: Float
    public var maxSpeedBackward: Float
    public var length: Double
}
