//
//  MatcherTest.swift
//  MapMatching
//
//  Created by devilrabbit on 2018/10/28.
//  Copyright (c) 2018 devilrabbit. All rights reserved.
//

import XCTest
import CoreLocation

class MatcherTest: XCTestCase {
    
    class MockedRoadReader {
        private var entries: [(Int64, Int64, Int64, Bool, [[Double]])] = [
            (0, 0, 1, false, [[48.000, 11.000], [48.000, 11.010]]),
            (1, 1, 2, false, [[48.000, 11.010], [48.000, 11.020]]),
            (2, 2, 3, false, [[48.000, 11.020], [48.000, 11.030]]),
            (3, 1, 4, true, [[48.000, 11.010], [47.999, 11.011]]),
            (4, 4, 5, true, [[47.999, 11.011], [47.999, 11.021]]),
            (5, 5, 6, true, [[47.999, 11.021], [48.010, 11.021]])
        ]
        
        var roads = [RoadInfo]()
        
        public init(spatial: SpatialOperator) {
            for e in entries {
                let geom = LineString(coordinates: e.4)!
                let info = RoadInfo(geometry: geom,
                                    id: e.0, source: e.1, target: e.2,
                                    oneWay: e.3, type: 0, priority: 1.0,
                                    maxSpeedForward: 100, maxSpeedBackward: 100,
                                    length: spatial.length(of: geom))
                roads.append(info)
            }
        }
    }
    
    private static let spatial: SpatialOperator = GeographySpatialOperator()
    private var router = DijkstraRouter<Road, RoadPoint>()
    
    private var map: RoadMap = {
        let reader = MockedRoadReader(spatial: spatial)
        let builder = RoadMapBuilder(spatial: spatial)
        return builder.addRoads(reader.roads).build()
    }()
    
    private var cost = Costs.timeCost
    
    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.

        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false

        // UI tests must launch the application that they test. Doing this in setup will make sure it happens for each test method.
        XCUIApplication().launch()

        // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testCandidates() {
        let filter = Matcher(map: map, router: router, cost: cost, spatial: MatcherTest.spatial)

        filter.maxRadius = 100
        let sample = CLLocationCoordinate2D(latitude: 48.001, longitude: 11.001)
        let candidates = filter.candidates(predecessors: [MatcherCandidate](), sample: MatcherSample(id: 0, time: 0, point: sample))
        XCTAssertEqual(candidates.count, 0)
        
        let assertCandidate = { (_ radius: Double, _ sample: Coordinate2D, _ refsetIds: [Int64]) -> Void in
            filter.maxRadius = radius
            
            let candidates = filter.candidates(predecessors: [MatcherCandidate](), sample: MatcherSample(id: 0, time: 0, point: sample))
            
            let refset = Set<Int64>(refsetIds)
            var set = Set<Int64>()
            
            for candidate in candidates {
                XCTAssert(refset.contains(candidate.candidate.point.edge.id))
                self.assertCandidate(candidate, sample)
                set.insert(candidate.candidate.point.edge.id)
            }

            XCTAssertEqual(refset, set)
        }
        
        assertCandidate(200, CLLocationCoordinate2D(latitude: 48.001, longitude: 11.001), [0, 1])
        assertCandidate(200, CLLocationCoordinate2D(latitude: 48.000, longitude: 11.010), [0, 3])
        assertCandidate(200, CLLocationCoordinate2D(latitude: 48.001, longitude: 11.011), [0, 2, 3])
        assertCandidate(300, CLLocationCoordinate2D(latitude: 48.001, longitude: 11.011), [0, 2, 3, 8])
        assertCandidate(300, CLLocationCoordinate2D(latitude: 48.001, longitude: 11.011), [0, 2, 3, 8])
        assertCandidate(200, CLLocationCoordinate2D(latitude: 48.001, longitude: 11.019), [2, 3, 5, 10])
    }

    func testTransitions() {
        let filter = Matcher(map: map, router: router, cost: cost, spatial: MatcherTest.spatial)
        filter.maxRadius = 200
        
        do {
            let sample1 = MatcherSample(id: 0, time: 0, point: CLLocationCoordinate2D(latitude: 48.001, longitude: 11.001))
            let sample2 = MatcherSample(id: 1, time: 60000, point: CLLocationCoordinate2D(latitude: 48.001, longitude: 11.019))
            
            var predecessors = Set<MatcherCandidate>()
            var candidates = Set<MatcherCandidate>()
            
            for candidate in filter.candidates(predecessors: [], sample: sample1) {
                predecessors.insert(candidate.candidate)
            }
            
            for candidate in filter.candidates(predecessors: [], sample: sample2) {
                candidates.insert(candidate.candidate)
            }
            
            XCTAssertEqual(2, predecessors.count)
            XCTAssertEqual(4, candidates.count)
            
            let transitions = filter.transitions(predecessors: Matcher.SampleCandidates(sample: sample1, candidates: Array(predecessors)), candidates: Matcher.SampleCandidates(sample: sample2, candidates: Array(candidates)))
            
            XCTAssertEqual(2, transitions.count)
            
            for source in transitions {
                XCTAssertEqual(4, source.value.count)
                
                for target in source.value {
                    assertTransition(target.value, (source.key, sample1), (target.key, sample2), filter.lambda)
                }
            }
        }
        
        do {
            let sample1 = MatcherSample(id: 0, time: 0, point: CLLocationCoordinate2D(latitude: 48.001, longitude: 11.019))
            let sample2 = MatcherSample(id: 1, time: 60000, point: CLLocationCoordinate2D(latitude: 48.001, longitude: 11.001))
            
            var predecessors = Set<MatcherCandidate>()
            var candidates = Set<MatcherCandidate>()
            
            for candidate in filter.candidates(predecessors: [], sample: sample1) {
                predecessors.insert(candidate.candidate)
            }
            
            for candidate in filter.candidates(predecessors: [], sample: sample2) {
                candidates.insert(candidate.candidate)
            }
            
            XCTAssertEqual(4, predecessors.count)
            XCTAssertEqual(2, candidates.count)
            
            let transitions = filter.transitions(predecessors: Matcher.SampleCandidates(sample: sample1, candidates: Array(predecessors)), candidates: Matcher.SampleCandidates(sample: sample2, candidates: Array(candidates)))
            
            XCTAssertEqual(4, transitions.count)
            
            for source in transitions {
                if source.key.point.edge.id == 10 {
                    XCTAssertEqual(0, source.value.count)
                } else {
                    XCTAssertEqual(2, source.value.count)
                }
                
                for target in source.value {
                    assertTransition(target.value, (source.key, sample1), (target.key, sample2), filter.lambda)
                }
            }
        }
    }
    
    private func assertCandidate(_ candidate: Matcher.CandidateProbability, _ sample: Coordinate2D) {
        let polyline = map.edge(for: candidate.candidate.point.edge.id)!.geometry
        let f = MatcherTest.spatial.intercept(polyline, sample)
        let i = MatcherTest.spatial.interpolate(polyline, f)
        let l = MatcherTest.spatial.distance(i, sample)
        let sig2 = pow(5.0, 2.0)
        let sqrt_2pi_sig2 = sqrt(2.0 * Double.pi * sig2)
        let p = 1 / sqrt_2pi_sig2 * exp((-1) * l * l / (2 * sig2))
        
        XCTAssertEqual(f, candidate.candidate.point.fraction, accuracy: 10E-6)
        XCTAssertEqual(p, candidate.probability, accuracy: 10E-6)
    }
    
    private func assertTransition(_ transition: Matcher.TransitionProbability, _ source: (MatcherCandidate, MatcherSample), _ target: (MatcherCandidate, MatcherSample), _ lambda: Double) {
        let edges = router.route(source: source.0.point, target: target.0.point, cost: cost)
        XCTAssertNotNil(edges)
        
        let route = Route(startPoint: source.0.point, endPoint: target.0.point, edges: edges)
        
        XCTAssertEqual(route.length, transition.transition.route.length, accuracy: 10E-6)
        XCTAssertEqual(route.startPoint.edge.id, transition.transition.route.startPoint.edge.id)
        XCTAssertEqual(route.endPoint.edge.id, transition.transition.route.endPoint.edge.id)
        
        let beta = lambda == 0 ? 2.0 * (target.1.time.timeIntervalSince1970 - source.1.time.timeIntervalSince1970) : 1 / lambda
        let base = 1.0 * MatcherTest.spatial.distance(source.1.coordinate, target.1.coordinate) / 60
        let p = (1 / beta) * exp((-1.0) * max(0.0, route.cost(Costs.timePriorityCost) - base) / beta)
        
        XCTAssertEqual(transition.probability, p, accuracy: 10E-6)
    }
}
