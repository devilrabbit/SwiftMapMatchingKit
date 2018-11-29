//
//  Costs.swift
//  MapMatching
//
//  Created by devilrabbit on 2018/10/12.
//  Copyright (c) 2018 devilrabbit. All rights reserved.
//

import Foundation

public class Costs {
    
    private static let heuristicSpeed = 130.0
    private static let heuristicPriority = 1.0
    
    public static func distanceCost(_ road: Road) -> Double {
        return Double(road.length)
    }
    
    public static func timeCost(_ road: Road) -> Double {
        return distanceCost(road) * 3.6 / min(Double(road.maxSpeed), heuristicSpeed)
    }
    
    public static func timePriorityCost(_ road: Road) -> Double {
        return timeCost(road) * max(heuristicPriority, Double(road.priority))
    }
}
