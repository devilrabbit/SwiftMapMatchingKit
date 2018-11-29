//
//  Polyline2D.swift
//  MapMatching
//
//  Created by devilrabbit on 2018/10/22.
//  Copyright (c) 2018 devilrabbit. All rights reserved.
//

import Foundation

public protocol Polyline2D {
    var coordinates: [Coordinate2D] { get }
    func reversed() -> Polyline2D
}
