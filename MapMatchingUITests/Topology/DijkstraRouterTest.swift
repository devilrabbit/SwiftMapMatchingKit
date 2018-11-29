//
//  DijkstraRouterTest.swift
//  MapMatching
//
//  Created by devilrabbit on 2018/11/16.
//  Copyright (c) 2018 devilrabbit. All rights reserved.
//

import XCTest

class DijkstraRouterTest: XCTestCase {
    
    public class Road: GraphEdge {
        
        public var id: Int64
        public var source: Int64
        public var target: Int64
        public var weight: Double?
        
        public var neighbor: Road?
        public var successor: Road?
        
        public init(id: Int64, source: Int64, target: Int64, weight: Double) {
            self.id = id
            self.source = source
            self.target = target
            self.weight = weight
        }
    }
    
    public class Graph: AdjacencyGraph<Road> {
        
    }
    
    public class RoadPoint: EdgePoint, Equatable {
        
        public var edge: Road
        public var fraction: Double
        
        public init(road: Road, fraction: Double) {
            self.edge = road
            self.fraction = fraction
        }
        
        public func hash(into hasher: inout Hasher) {
            hasher.combine(edge)
            hasher.combine(fraction)
        }
        
        public static func == (lhs: RoadPoint, rhs: RoadPoint) -> Bool {
            return lhs.edge == rhs.edge && abs(lhs.fraction - rhs.fraction) < 10E-6
        }
    }

    private func assertSinglePath(_ expectedPath: [Int64], _ sources: [RoadPoint], _ targets: [RoadPoint], _ routes: [RoadPoint : (RoadPoint, [Road])]) {
        XCTAssertEqual(1, routes.count)
        
        let route = routes[targets.first!]!
        XCTAssertEqual(expectedPath.first, route.0.edge.id)
        XCTAssertEqual(expectedPath, route.1.map { $0.id })
    }
    
    private func assertMultiplePaths(_ routes: [RoadPoint : (RoadPoint, [Road])], _ expectedPaths: [Int64 : [Int64]], _ sources: [RoadPoint], _ targets: [RoadPoint]) {
        XCTAssertEqual(expectedPaths.count, routes.count)
    
        for pair in routes {
            let route = pair.value.1
            let expectedPath = expectedPaths[pair.key.edge.id]!
    
            XCTAssertNotNil(route)
            XCTAssertEqual(expectedPath.first, pair.value.0.edge.id)
            XCTAssertEqual(expectedPath.count, route.count)
            XCTAssertEqual(expectedPath, route.map { $0.id })
        }
    }
    
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

    func testSameRoad() {
        let graph = Graph(edges: [
            Road(id: 0, source: 0, target: 1, weight: 100),
            Road(id: 1, source: 1, target: 0, weight: 20),
            Road(id: 2, source: 0, target: 2, weight: 100),
            Road(id: 3, source: 1, target: 2, weight: 100),
            Road(id: 4, source: 1, target: 3, weight: 100)
        ])
        let cost = { (e: Road) in return e.weight ?? .nan }
        
        let router = DijkstraRouter<Road, RoadPoint>()
        
        do {
            let expectedPath: [Int64] = [0]
            let sources = [RoadPoint(road: graph.edgeMap[0]!, fraction: 0.3)]
            let targets = [RoadPoint(road: graph.edgeMap[0]!, fraction: 0.3)]
            let routes = router.route(sources: sources, targets: targets, cost: cost, bound: nil, max: .nan)
            assertSinglePath(expectedPath, sources, targets, routes)
        }
        
        do {
            let expectedPath: [Int64] = [0]
            let sources = [RoadPoint(road: graph.edgeMap[0]!, fraction: 0.3)]
            let targets = [RoadPoint(road: graph.edgeMap[0]!, fraction: 0.7)]
            let routes = router.route(sources: sources, targets: targets, cost: cost, bound: nil, max: .nan)
            assertSinglePath(expectedPath, sources, targets, routes)
        }
        
        do {
            let expectedPath: [Int64] = [0, 1, 0]
            let sources = [RoadPoint(road: graph.edgeMap[0]!, fraction: 0.7)]
            let targets = [RoadPoint(road: graph.edgeMap[0]!, fraction: 0.3)]
            let routes = router.route(sources: sources, targets: targets, cost: cost, bound: nil, max: .nan)
            assertSinglePath(expectedPath, sources, targets, routes)
        }
        
        do {
            let expectedPath: [Int64] = [1, 0]
            let sources = [RoadPoint(road: graph.edgeMap[0]!, fraction: 0.8), RoadPoint(road: graph.edgeMap[1]!, fraction: 0.2)]
            let targets = [RoadPoint(road: graph.edgeMap[0]!, fraction: 0.7)]
            let routes = router.route(sources: sources, targets: targets, cost: cost, bound: nil, max: .nan)
            assertSinglePath(expectedPath, sources, targets, routes)
        }
    }

    func testSelfLoop() {
        let graph = Graph(edges: [
            Road(id: 0, source: 0, target: 0, weight: 100),
            Road(id: 1, source: 0, target: 0, weight: 100)
        ])
        let cost = { (e: Road) in return e.weight ?? .nan }
        
        let router = DijkstraRouter<Road, RoadPoint>()
        
        do {
            let expectedPath: [Int64] = [0]
            let sources = [RoadPoint(road: graph.edgeMap[0]!, fraction: 0.3)]
            let targets = [RoadPoint(road: graph.edgeMap[0]!, fraction: 0.7)]
            let routes = router.route(sources: sources, targets: targets, cost: cost, bound: nil, max: .nan)
            assertSinglePath(expectedPath, sources, targets, routes)
        }
        
        do {
            let expectedPath: [Int64] = [0, 0]
            let sources = [RoadPoint(road: graph.edgeMap[0]!, fraction: 0.7)]
            let targets = [RoadPoint(road: graph.edgeMap[0]!, fraction: 0.3)]
            let routes = router.route(sources: sources, targets: targets, cost: cost, bound: nil, max: .nan)
            assertSinglePath(expectedPath, sources, targets, routes)
        }
        
        do {
            let expectedPath: [Int64] = [0, 0]
            let sources = [RoadPoint(road: graph.edgeMap[0]!, fraction: 0.8), RoadPoint(road: graph.edgeMap[1]!, fraction: 0.2)]
            let targets = [RoadPoint(road: graph.edgeMap[0]!, fraction: 0.2)]
            let routes = router.route(sources: sources, targets: targets, cost: cost, bound: nil, max: .nan)
            assertSinglePath(expectedPath, sources, targets, routes)
        }
        
        do {
            let expectedPath: [Int64] = [1, 0]
            let sources = [RoadPoint(road: graph.edgeMap[0]!, fraction: 0.4), RoadPoint(road: graph.edgeMap[1]!, fraction: 0.6)]
            let targets = [RoadPoint(road: graph.edgeMap[0]!, fraction: 0.3)]
            let routes = router.route(sources: sources, targets: targets, cost: cost, bound: nil, max: .nan)
            assertSinglePath(expectedPath, sources, targets, routes)
        }
    }
}
