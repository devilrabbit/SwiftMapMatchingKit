//
//  EdgePoint.swift
//  MapMatching
//
//  Created by devilrabbit on 2018/10/09.
//  Copyright (c) 2018 devilrabbit. All rights reserved.
//

import Foundation

public protocol EdgePoint: class, Hashable {
    associatedtype TEdge : GraphEdge
    var edge: TEdge { get }
    var fraction: Double { get }
}
