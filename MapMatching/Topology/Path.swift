//
//  Path.swift
//  MapMatching
//
//  Created by devilrabbit on 2018/10/09.
//  Copyright (c) 2018 devilrabbit. All rights reserved.
//

import Foundation

public protocol Path {
    associatedtype TEdge
    associatedtype TPoint: EdgePoint where TPoint.TEdge == TEdge
    
    var startPoint: TPoint { get }
    var endPoint: TPoint { get }
    var edges: [TEdge] { get }
    var length: Double { get }
    func cost(_ costFunc: ((TEdge)->(Double))) -> Double
}
