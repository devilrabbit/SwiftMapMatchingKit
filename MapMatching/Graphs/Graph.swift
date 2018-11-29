//
//  Graph.swift
//  MapMatching
//
//  Created by devilrabbit on 2018/10/09.
//  Copyright (c) 2018 devilrabbit. All rights reserved.
//

//
//  Graph.swift
//  Graph
//
//  Created by Andrew McKnight on 5/8/16.
//
import Foundation

public protocol Graph: CustomStringConvertible {
    associatedtype TVertex
    associatedtype TEdge: Edge where TEdge.TVertex == TVertex
    
    var vertices: [TVertex] { get }
    var edges: [TEdge] { get }

    func addVertex(_ v: TVertex)
    func addEdge(_ edge: TEdge)
    
    func edge(source: TVertex, target: TVertex) -> TEdge?
    func edges(of vertex: TVertex) -> [TEdge]
}
