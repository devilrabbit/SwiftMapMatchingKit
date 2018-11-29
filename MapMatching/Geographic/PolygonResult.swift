//
//  PolygonResult.swift
//  MapMatching
//
//  Created by devilrabbit on 2018/10/18.
//  Copyright (c) 2018 devilrabbit. All rights reserved.
//

import Foundation

/// A container for the results from PolygonArea.
public struct PolygonResult {
    
    /// The number of vertices in the polygon
    public private(set) var num: Int
    
    /// The Perimeter of the polygon or the length of the polyline (meters).
    public private(set) var perimeter: Double
    
    /// The Area of the polygon (meters<sup>2</sup>).
    public private(set) var area: Double
}
