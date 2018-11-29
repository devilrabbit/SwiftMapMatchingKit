//
//  DijkstraRouter.swift
//  MapMatching
//
//  Created by devilrabbit on 2018/10/12.
//  Copyright (c) 2018 devilrabbit. All rights reserved.
//

import Foundation

/// Dijkstra's algorithm implementation of a <see cref="Sandwych.MapMatchingKit.Topology.IGraphRouter{TEdge, P}" />.
/// The routing functions use the Dijkstra algorithm for finding shortest paths according to a customizable cost function.
/// <typeparam name="TEdge">Implementation of <see cref="Sandwych.MapMatchingKit.Topology.IGraphEdge{T}">
/// in a directed <see cref="Sandwych.MapMatchingKit.Topology.IGraph{TEdge}" />.</typeparam>
/// <typeparam name="P"><see cref="Sandwych.MapMatchingKit.Topology.EdgePoint{TEdge}"/> type of positions in the network.</typeparam>
public class DijkstraRouter<TEdge, TPoint: EdgePoint> : GraphRouter where TPoint.TEdge == TEdge, TEdge.TEdge == TEdge {
    
    public typealias Edge = TEdge
    public typealias P = TPoint
    
    public func route(source: TPoint, target: TPoint, cost: ((TEdge) -> Double), bound: ((TEdge) -> Double)?, max: Double) -> [TEdge] {
        return ssmt(source: source, targets: [target], cost: cost, bound: bound, max: max)[target] ?? []
    }
    
    public func route(source: TPoint, targets: [TPoint], cost: ((TEdge) -> Double), bound: ((TEdge) -> Double)?, max: Double) -> [TPoint : [TEdge]] {
        return ssmt(source: source, targets: targets, cost: cost, bound: bound, max: max)
    }
    
    public func route(sources: [TPoint], targets: [TPoint], cost: ((TEdge) -> Double), bound: ((TEdge) -> Double)?, max: Double) -> [TPoint : (TPoint, [TEdge])] {
        return msmt(sources: sources, targets: targets, cost: cost, bound: bound, max: max)
    }
    
    private func ssmt(source: TPoint, targets: [TPoint], cost: ((TEdge) -> Double), bound: ((TEdge) -> Double)?, max: Double) -> [TPoint : [TEdge]] {
        let map = msmt(sources: [source], targets: targets, cost: cost, bound: bound, max: max)
        
        var result = [TPoint : [TEdge]]()
        for entry in map {
            result[entry.key] = entry.value.1
        }
        
        return result
    }
    
    private func msmt(sources: [TPoint], targets: [TPoint], cost: ((TEdge) -> Double), bound: ((TEdge) -> Double)? = nil, max: Double = .nan) -> [TPoint : (TPoint, [TEdge])] {
        
        /*
         * Initialize map of edges to target points.
         */
        var targetEdges = [TEdge : Set<TPoint>]()
        for target in targets {
            // Logger.debug(("initialize target {0} with edge {1} and fraction {2}", target, target.Edge.Id, target.Fraction)
            targetEdges[target.edge, default: Set()].insert(target)
        }
        
        /*
         * Setup data structures
         */
        var priorities = PriorityQueue<RouteMark<TEdge>>(ascending: true)
        var entries = [TEdge : RouteMark<TEdge>]()
        var finishs = [TPoint : RouteMark<TEdge>]()
        var reaches = [RouteMark<TEdge> : TPoint]()
        var starts = [RouteMark<TEdge> : TPoint]()
        
        /*
         * Initialize map of edges with start points
         */
        for source in sources {
            print(source.edge.id)
            
            // initialize sources as start edges
            let startcost = (1.0 - source.fraction) * cost(source.edge)
            let startbound = (1.0 - source.fraction) * (bound?(source.edge) ?? 0)
            
            //Logger.debug("init source {0} with start edge {1} and fraction {2} with {3} cost", source, source.Edge.Id, source.Fraction, startcost)
            
            // On the same edge
            if let targetsMap = targetEdges[source.edge] {
                // start edge reaches target edge
                for target in targetsMap {
                    if target.fraction < source.fraction {
                        continue
                    }
                    
                    let reachcost = startcost - (1.0 - target.fraction) * cost(source.edge)
                    let reachbound = startcost - (1.0 - target.fraction) * (bound?(source.edge) ?? 0)
                    
                    //Logger.debug("reached target {0} with start edge {1} from {2} to {3} with {4} cost", target, source.Edge.Id, source.Fraction, target.Fraction, reachcost)
                    
                    let reach = RouteMark<TEdge>(markedEdge: source.edge, predecessorEdge: nil, cost: reachcost, boundingCost: reachbound)
                    reaches[reach] = target
                    starts[reach] = source
                    priorities.push(reach)
                }
            }
            
            if let start = entries[source.edge] {
                if startcost < start.cost {
                    //Logger.debug("update source {0} with start edge {1} and fraction {2} with {3} cost", source, source.Edge.Id, source.Fraction, startcost)
                    let start = RouteMark<TEdge>(markedEdge: source.edge, predecessorEdge: nil, cost: startcost, boundingCost: startbound)
                    entries[source.edge] = start
                    starts[start] = source
                    priorities.remove(start)
                    priorities.push(start)
                }
            } else {
                //Logger.debug("add source {0} with start edge {1} and fraction {2} with {3} cost", source, source.Edge.Id, source.Fraction, startcost)
                let start = RouteMark<TEdge>(markedEdge: source.edge, predecessorEdge: nil, cost: startcost, boundingCost: startbound)
                entries[source.edge] = start
                starts[start] = source
                priorities.push(start)
            }
        }
        
        /*
         * Dijkstra algorithm.
         */
        while let current = priorities.pop() {
            if targetEdges.count == 0 {
                //Logger.debug("finshed all targets")
                break
            }
            
            if !max.isNaN && current.boundingCost > max {
                //Logger.LogDebug("reached maximum bound")
                continue
            }
            
            /*
             * Finish target if reached.
             */
            if let target = reaches[current] {
                if finishs.keys.contains(target) {
                    continue
                } else {
                    //Logger.debug("finished target {0} with edge {1} and fraction {2} with {3} cost", target, current.MarkedEdge, target.Fraction, current.Cost)
                    
                    finishs[target] = current
                    
                    if let markedEdge = current.markedEdge {
                        targetEdges[markedEdge]?.remove(target)
                        if (targetEdges[markedEdge]?.count ?? 0) == 0 {
                            targetEdges.removeValue(forKey: markedEdge)
                        }
                    }

                    continue
                }
            }
            
            //Logger.debug("succeed edge {0} with {1} cost", current.MarkedEdge.Id, current.Cost)
            
            let successors = current.markedEdge?.successors ?? []
            
            for successor in successors {
                let succcost = current.cost + cost(successor)
                var succbound = 0.0
                if let bound = bound {
                    succbound = current.boundingCost + bound(successor)
                }
                
                if let edges = targetEdges[successor] {
                    // reach target edge
                    for targetEdge in edges {
                        let reachcost = succcost - (1.0 - targetEdge.fraction) * cost(successor)
                        var reachbound = 0.0
                        if let bound = bound {
                            reachbound = succbound - (1.0 - targetEdge.fraction) * bound(successor)
                        }
                        
                        //Logger.debug("reached target {0} with successor edge {1} and fraction {2} with {3} cost", targetEdge, successor.Id, targetEdge.Fraction, reachcost)
                        
                        let reach = RouteMark<TEdge>(markedEdge: successor, predecessorEdge: current.markedEdge, cost: reachcost, boundingCost: reachbound)
                        reaches[reach] = targetEdge
                        priorities.push(reach)
                    }
                }
                
                if !entries.keys.contains(successor) {
                    // Logger.debug("added successor edge {0} with {1} cost", successor.Id, succcost)
                    let mark = RouteMark<TEdge>(markedEdge: successor, predecessorEdge: current.markedEdge, cost: succcost, boundingCost: succbound)
                    entries[successor] = mark
                    priorities.push(mark)
                }
            }
        }
        
        var paths = [TPoint : (TPoint, [TEdge])]()
        
        for targetPoint in targets {
            if finishs.keys.contains(targetPoint) {
                var path = [TEdge]()
                var iterator = finishs[targetPoint]
                var start: RouteMark<TEdge>? = RouteMark<TEdge>.empty
                
                while !(iterator?.isEmpty ?? true) {
                    if let edge = iterator?.markedEdge {
                        path.append(edge)
                    }
                    start = iterator
                    if let edge = iterator?.predecessorEdge {
                        iterator = entries[edge] ?? RouteMark<TEdge>.empty
                    } else {
                        iterator = RouteMark<TEdge>.empty
                    }
                }
                
                path.reverse()
                
                if let start = start, let target = starts[start] {
                    paths[targetPoint] = (target, path)
                }
            }
        }

        return paths
    }
}
