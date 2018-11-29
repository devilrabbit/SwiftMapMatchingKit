//
//  SpatialIndex.swift
//  MapMatching
//
//  Created by devilrabbit on 2018/10/14.
//  Copyright (c) 2018 devilrabbit. All rights reserved.
//

import Foundation

public protocol SpatialIndex {
    associatedtype Item
    
    func insert(in bounds: Rect2D, item: Item)
    func query(in bounds: Rect2D) -> [Item]
}
