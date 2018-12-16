//
//  SampleReader.swift
//  MapMatching
//
//  Created by devilrabbit on 2018/12/02.
//  Copyright (c) 2018 devilrabbit. All rights reserved.
//

import Foundation
import CoreLocation

public class SampleReader {
 
    public static func readRoads(with spatial: SpatialOperator) -> [RoadInfo] {
        guard let path = Bundle.main.path(forResource: "osm-kunming-roads-network", ofType: "geojson") else { return [] }
        let url = URL(fileURLWithPath: path)
        guard let data = try? Data(contentsOf: url) else { return [] }
        guard let fc = try? JSONDecoder().decode(FeatureCollection.self, from: data) else { return [] }
        
        var roads = [RoadInfo]()
        for feature in fc.features {
            if let feature = feature as? LineString {
                let gid = Int64((feature.properties?["gid"] as? Int) ?? 0)
                let source = Int64((feature.properties?["source"] as? Int) ?? 0)
                let target = Int64((feature.properties?["target"] as? Int) ?? 0)
                let reverse = (feature.properties?["reverse"] as? Int) ?? 0
                let priority = (feature.properties?["priority"] as? Double) ?? 0
                roads.append(RoadInfo(
                    geometry: feature,
                    id: gid,
                    source: source,
                    target: target,
                    oneWay: reverse >= 0 ? false : true,
                    type: 0,
                    priority: priority,
                    maxSpeedForward: 120,
                    maxSpeedBackward: 120,
                    length: spatial.length(of: feature))
                )
            }

        }

        return roads
    }
    
    public static func readSamples() -> [MatcherSample] {
        guard let path = Bundle.main.path(forResource: "samples.oneday", ofType: "geojson") else { return [] }
        let url = URL(fileURLWithPath: path)
        guard let data = try? Data(contentsOf: url) else { return [] }
        guard let fc = try? JSONDecoder().decode(FeatureCollection.self, from: data) else { return [] }
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd-HH.mm.ss.SSSSSS"

        var samples = [MatcherSample]()
        for feature in fc.features {
            if let feature = feature as? Point {
                if let time = feature.properties?["time"] as? String, let date = formatter.date(from: time) {
                    samples.append(MatcherSample(id: Int64(date.timeIntervalSince1970), time: date, point: feature.geometry))
                }
            }
        }
        
        return samples
    }
}
