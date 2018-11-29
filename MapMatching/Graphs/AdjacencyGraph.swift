//
//  AdjacencyGraph.swift
//  MapMatching
//
//  Created by devilrabbit on 2018/10/09.
//  Copyright (c) 2018 devilrabbit. All rights reserved.
//
import Foundation

open class AdjacencyListGraph<V, E: Edge> : Graph where E.TVertex == V {
    public typealias TVertex = V
    public typealias TEdge = E
    
    public private(set) var adjacencyList: [V : [E]] = [:]
    
    open var vertices: [V] {
        return Array(adjacencyList.keys)
    }
    
    open var edges: [E] {
        var allEdges = Set<E>()
        for edges in adjacencyList.values {
            for edge in edges {
                allEdges.insert(edge)
            }
        }
        return Array(allEdges)
    }
    
    open func addVertex() -> V {
        preconditionFailure()
    }
    
    open func addVertex(_ v: V) {
        if !adjacencyList.keys.contains(v) {
            adjacencyList[v] = []
        }
    }
    
    open func addEdge(_ edge: E) {
        adjacencyList[edge.source, default: []].append(edge)
    }
    
    open func edges(of vertex: V) -> [E] {
        return adjacencyList[vertex] ?? []
    }
    
    open func edge(source: V, target: V) -> E? {
        return adjacencyList[source]?.first(where: { $0.target == target })
    }
    
    open var description: String {
        var rows = [String]()
        for (vertex, edges) in adjacencyList {
            var row = [String]()
            for edge in edges {
                var value = "\(edge.source)"
                if let weight = edge.weight {
                    value = "(\(value): \(weight))"
                }
                row.append(value)
            }
            
            rows.append("\(vertex) -> [\(row.joined(separator: ", "))]")
        }
        return rows.joined(separator: "\n")
    }
}

open class AdjacencyGraph<E>: AdjacencyListGraph<Int64, E> where E: GraphEdge, E.TVertex == Int64 {
    
    public private(set) var edgeMap: [Int64 : E] = [:]
    
    public init(edges: [E]) {
        super.init()
        for edge in edges {
            self.edgeMap[edge.id] = edge
            self.addEdge(edge)
        }
        self.commonInit()
    }
    
    open func edge(for id: Int64) -> E? {
        return edgeMap[id]
    }
    
    func commonInit() {
        for edges in self.adjacencyList.values {
            if edges.count > 1 {
                for i in 1..<edges.count {
                    var prevEdge = edges[i - 1]
                    prevEdge.neighbor = edges[i] as? E.TEdge
                    prevEdge.successor = self.adjacencyList[prevEdge.target]?.first as? E.TEdge
                }
            }
            
            if let lastEdge = edges.last {
                var edge = lastEdge
                edge.neighbor = edges.first as? E.TEdge
                edge.successor = self.adjacencyList[lastEdge.target]?.first as? E.TEdge
            }
        }
    }
}
