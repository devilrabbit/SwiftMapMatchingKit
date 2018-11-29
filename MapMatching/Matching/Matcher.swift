//
//  Matcher.swift
//  MapMatching
//
//  Created by devilrabbit on 2018/10/14.
//  Copyright (c) 2018 devilrabbit. All rights reserved.
//

import Foundation

public class Matcher : AbstractFilter<MatcherCandidate, MatcherTransition, MatcherSample> {
    
    private var map: RoadMap
    private var router: AnyGraphRouter<Road, RoadPoint>
    private var spatial: SpatialOperator
    private var cost: ((Road)->(Double))
    
    private var sig2 = pow(5.0, 2.0)
    private var sigA = pow(10.0, 2.0)
    private var sqrt_2pi_sig2 = sqrt(2 * .pi * pow(5.0, 2.0))
    private var sqrt_2pi_sigA = sqrt(2 * .pi * pow(10.0, 2.0))
    
    
    /// Creates a HMM map matching filter for some map, router, cost function, and spatial operator.
    /// - parameter map: map <see cref=“RoadMap” /> object of the map to be matched to.
    /// - parameter router: router <see cref=“IGraphRouter{TEdge, TPoint}”/> object to be used for route estimation.
    /// - parameter cost: Cost function to be used for routing.
    /// - parameter spatial: Spatial operator for spatial calculations.
    public init<Router: GraphRouter>(map: RoadMap, router: Router, cost: @escaping ((Road)->(Double)), spatial: SpatialOperator) where Router.Point == RoadPoint
    {
        self.map = map
        self.router = AnyGraphRouter(router)
        self.cost = cost
        self.spatial = spatial
    }
    
    /// Gets or sets standard deviation in meters of gaussian distribution for defining emission
    /// probabilities (default is 5 meters).
    public var sigma: Double {
        get {
            return sqrt(self.sig2)
        }
        set {
            self.sig2 = pow(newValue, 2)
            self.sqrt_2pi_sig2 = sqrt(2 * .pi * self.sig2)
        }
    }
    
    /// Get or sets lambda parameter of negative exponential distribution defining transition probabilities
    /// (default is 0.0). It uses adaptive parameterization, if lambda is set to 0.0.
    /// Lambda parameter of negative exponential distribution defining transition probabilities.
    public var lambda: Double = 0
    
    /// Gets or sets maximum radius for candidate selection in meters (default is 100 meters).
    public var maxRadius: Double = 100
    
    /// Gets or sets maximum transition distance in meters (default is 15000 meters).
    public var maxDistance: Double = 15000
    
    /// Gets or sets maximum number of candidates per state
    public var maxCandidates: Int = 8
    
    public override func candidates(predecessors: [MatcherCandidate], sample: MatcherSample) -> [CandidateProbability] {
        let points_ = map.radius(c: sample.coordinate, r: maxRadius, k: maxCandidates)
        var points = Minset.minimize(points_)
        
        var dict = [Int64 : RoadPoint]()
        for point in points {
            dict[point.edge.id] = point
        }
        
        for predecessor in predecessors {
            if let point = dict[predecessor.point.edge.id] {
                if ((point.edge.heading == .forward && point.fraction < predecessor.point.fraction)
                        || (point.edge.heading == .backward && point.fraction > predecessor.point.fraction))
                    && spatial.distance(point.coordinate, predecessor.point.coordinate) < sigma {
                    points.remove(point)
                    points.insert(predecessor.point)
                }
            }
        }
        
        var results = [CandidateProbability]()
        for point in points {
            let dz = spatial.distance(sample.coordinate, point.coordinate)
            let emission = computeEmissionProbability(sample: sample, candidates: point, dz: dz)
            let candidate = MatcherCandidate(sample: sample, point: point)
            results.append(CandidateProbability(candidate: candidate, probability: emission))
        }
        return results
    }
    
    public override func transition(predecessor: SampleCandidate, candidate: SampleCandidate) -> TransitionProbability {
        fatalError("Not supported")
    }
    
    public override func transitions(predecessors: SampleCandidates, candidates: SampleCandidates) -> [MatcherCandidate:[MatcherCandidate:TransitionProbability]] {
        let targets = candidates.candidates.map { $0.point }
        var transitions = [MatcherCandidate: [MatcherCandidate : TransitionProbability]]()
        let base = 1.0 * spatial.distance(predecessors.sample.coordinate, candidates.sample.coordinate) / 60.0
        let bound = max(1000.0, min(self.maxDistance, (candidates.sample.time.timeIntervalSince1970 - predecessors.sample.time.timeIntervalSince1970) * 100.0))
        
        for predecessor in predecessors.candidates {
            var map = [MatcherCandidate : TransitionProbability]()
            //TODO check return
            var routes = router.route(source: predecessor.point, targets: targets, cost: cost, bound: Costs.distanceCost, max: bound)
            
            for candidate in candidates.candidates {
                if let edges = routes[candidate.point] {
                    let route = Route(startPoint: predecessor.point, endPoint: candidate.point, edges: edges)
                    
                    // According to Newson and Krumm 2009, transition probability is lambda *
                    // Math.exp((-1.0) * lambda * Math.abs(dt - route.length())), however, we
                    // experimentally choose lambda * Math.exp((-1.0) * lambda * Math.max(0,
                    // route.length() - dt)) to avoid unnecessary routes in case of u-turns.
                    
                    let beta = self.lambda == 0 ? 2.0 * max(1, candidates.sample.time.timeIntervalSince1970 - predecessors.sample.time.timeIntervalSince1970) : 1 / self.lambda
                    let transition = (1 / beta) * exp((-1.0) * max(0, route.cost(cost) - base) / beta)
                    
                    map[candidate] = TransitionProbability(transition: MatcherTransition(route: route), probability: transition)
                }
            }
            
            transitions[predecessor] = map
        }
        
        return transitions
    }
    
    
    private func computeEmissionProbability(sample: MatcherSample, candidates: RoadPoint, dz: Double) -> Double {
        var emission = 1 / sqrt_2pi_sig2 * exp((-1) * dz * dz / (2 * sig2));
        if sample.hasAzimuth {
            let da = sample.azimuth > candidates.azimuth ?
                min(sample.azimuth - candidates.azimuth, 360 - (sample.azimuth - candidates.azimuth)) :
                min(candidates.azimuth - sample.azimuth, 360 - (candidates.azimuth - sample.azimuth))
            emission *= max(1E-2, 1 / sqrt_2pi_sigA * exp((-1) * da / (2 * sigA)))
        }
        return emission
    }
}

/// Minimizes a set of matching candidates represented as <see cref="RoadPoint"/> to remove semantically
/// redundant candidates.
private class Minset {
    
    /// Floating point precision for considering a {@link RoadPoint} be the same as a vertex,
    /// fraction is zero or one (default: 1E-8).
    public static let precision = 1E-8
    
    private static func round(_ value: Double) -> Double {
        return Foundation.round(value / precision) * precision
    }
    
    /// Removes semantically redundant matching candidates from a set of matching candidates (as
    ///  <see cref="RoadPoint"/> object) and returns a minimized (reduced) subset.
    /// Given a position measurement, a matching candidate is each road in a certain radius of the
    /// measured position, and in particular that point on each road that is closest to the measured
    /// position. Hence, there are as many state candidates as roads in that area. The idea is to
    /// conserve only possible routes through the area and use each route with its closest point to
    /// the measured position as a matching candidate. Since roads are split into multiple segments,
    /// the number of matching candidates is significantly higher than the respective number of
    /// routes. To give an example, assume the following matching candidates as <see cref="RoadPoint"/>
    /// objects with a road id and a fraction:
    ///
    /// <ul>
    /// <li><i>(r<sub>i</sub>, 0.5)</i>
    /// <li><i>(r<sub>j</sub>, 0.0)</i>
    /// <li><i>(r<sub>k</sub>, 0.0)</i>
    /// </ul>
    ///
    /// where they are connected as <i>r<sub>i</sub> &#8594; r<sub>j</sub></i> and <i>r<sub>i</sub>
    /// &#8594; r<sub>k</sub></i>. Here, matching candidates <i>r<sub>j</sub></i> and
    /// <i>r<sub>k</sub></i> can be removed if we see routes as matching candidates. This is because
    /// both, <i>r<sub>j</sub></i> and <i>r<sub>k</sub></i>, are reachable from <i>r<sub>i</sub></i>.
    ///
    /// <b>Note:</b> Of course, <i>r<sub>j</sub></i> and <i>r<sub>k</sub></i> may be seen as relevant
    /// matching candidates, however, in the present HMM map matching algorithm there is no
    /// optimization of matching candidates along the road, instead it only considers the closest
    /// point of a road as a matching candidate.
    ///
    /// - parameter candidates: candidates Set of matching candidates as <see cref="RoadPoint"> objects.
    /// - returns: Minimized (reduced) set of matching candidates as <see cref="RoadPoint"/> objects.
    public static func minimize(_ candidates: [RoadPoint]) -> Set<RoadPoint> {
        var map = [Int64 : RoadPoint]()
        var misses = [Int64 : Int]()
        var removes = [Int64]()
        
        for candidate in candidates {
            map[candidate.edge.id] = candidate
            misses[candidate.edge.id] = 0
        }
        
        for candidate in candidates {
            let successors = candidate.edge.successors
            let id = candidate.edge.id
            
            for successor in successors {
                if let point = map[successor.id] {
                    if round(point.fraction) == 0 {
                        removes.append(successor.id)
                        misses[id, default: 0] += 1
                    }
                } else {
                    misses[id, default: 0] += 1
                }
            }
        }
        
        for candidate in candidates {
            let id = candidate.edge.id
            if map.keys.contains(id) && !removes.contains(id) && round(candidate.fraction) == 1 && misses[id] == 0 {
                removes.append(id)
            }
        }
        
        for id in removes {
            map.removeValue(forKey: id)
        }
        
        return Set<RoadPoint>(map.values)
    }
}
