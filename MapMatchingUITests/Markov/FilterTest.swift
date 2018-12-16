//
//  FilterTest.swift
//  MapMatching
//
//  Created by devilrabbit on 2018/10/26.
//  Copyright (c) 2018 devilrabbit. All rights reserved.
//

import XCTest

class FilterTest: XCTestCase {

    struct MockStateTransition {
        
    }
    
    struct MockSample: Sample {
        var time: Date
        public init(_ time: TimeInterval) {
            self.time = Date(timeIntervalSince1970: time / 1000.0)
        }
    }
    
    class MockElement: StateCandidate {
        typealias TCandidate = MockElement
        typealias TTransition = MockStateTransition
        typealias TSample = MockSample
        
        var sample: MockSample?
        var id: Int64
        
        var seqprob: Double
        var filtprob: Double
        var predecessor: TCandidate?
        var transition: TTransition?
        
        public init(sample: MockSample?, id: Int64) {
            self.sample = sample
            self.id = id
            self.seqprob = 0
            self.filtprob = 0
        }
        
        public convenience init(id: Int64, filtprob: Double, seqprob: Double) {
            self.init(sample: nil, id: id)
            self.filtprob = filtprob
            self.seqprob = seqprob
        }
        
        public func hash(into hasher: inout Hasher) {
            hasher.combine(id)
        }
        
        static func == (lhs: FilterTest.MockElement, rhs: FilterTest.MockElement) -> Bool {
            return lhs.id == rhs.id
        }
    }
    
    class MockStates {
        private var matrix: [[Double]]
        private var seqprob: [Double]
        private var filtprob: [Double]
        private var pred: [Int]
        
        public init(matrix: [[Double]]) {
            self.matrix = matrix
            
            let count = matrix[0].count - 2
            self.seqprob = Array<Double>(repeating: -Double.infinity, count: count)
            self.filtprob = Array<Double>(repeating: 0, count: count)
            self.pred = Array<Int>(repeating: 0, count: count)

            calculate()
        }
        
        private func calculate() {
            var normsum = 0.0
            for c in 0..<NumCandidates {
                var hasTransition = false
                for p in 0..<NumPredecessors {
                    let pred = predecessor(p)
                    if transition(p, c) == 0 {
                        continue
                    }
                    
                    hasTransition = true
                    self.filtprob[c] += pred.0 * transition(p, c)
                    let seqprob = pred.1 + log10(transition(p, c)) + log10(emission(c))
        
                    if seqprob > self.seqprob[c] {
                        self.pred[c] = p
                        self.seqprob[c] = seqprob
                    }
                }
        
                if hasTransition == false {
                    self.filtprob[c] = emission(c)
                    self.seqprob[c] = log10(emission(c))
                    self.pred[c] = -1
                } else {
                    self.filtprob[c] *= emission(c)
                }
        
                normsum += self.filtprob[c]
            }
            
            for c in 0..<NumCandidates {
                self.filtprob[c] /= normsum
            }
        }
        
        public var NumCandidates: Int {
            return matrix[0].count - 2
        }
        
        public var NumPredecessors: Int {
            return matrix.count - 1
        }
        
        public func emission(_ candidate: Int) -> Double {
            return matrix[0][candidate + 2]
        }
        
        public func transition(_ predecessor: Int, _ candidate: Int) -> Double {
            return matrix[predecessor + 1][candidate + 2]
        }
        
        public func predecessor(_ predecessor: Int) -> (Double, Double) {
            return (matrix[predecessor + 1][0], log10(matrix[predecessor + 1][1]))
        }
        
        public func seqprob(_ candidate: Int64) -> Double {
            return self.seqprob[Int(candidate)]
        }
        
        public func filtprob(_ candidate: Int64) -> Double {
            return self.filtprob[Int(candidate)]
        }
        
        public func pred(_ candidate: Int64) -> Int64 {
            return Int64(self.pred[Int(candidate)])
        }
    }
    
    class MockFilter: AbstractFilter<MockElement, MockStateTransition, MockSample> {
        private var states: MockStates
        
        public init(states: MockStates) {
            self.states = states
        }
        
        public override func candidates(predecessors: [TCandidate], sample: TSample) -> [CandidateProbability] {
            var results = [CandidateProbability]()
            for c in 0..<states.NumCandidates {
                results.append(CandidateProbability(candidate: MockElement(sample: sample, id: Int64(c)), probability: states.emission(c)))
            }
            return results
        }
        
        public override func transition(predecessor: SampleCandidate, candidate: SampleCandidate) -> TransitionProbability {
            return TransitionProbability(transition: MockStateTransition(), probability: states.transition(Int(predecessor.candidate.id), Int(candidate.candidate.id)))
        }
        
        public func execute() -> [MockElement] {
            var predecessors = [MockElement]()
            for p in 0..<states.NumPredecessors {
                let pred = states.predecessor(p)
                predecessors.append(MockElement(id: Int64(p), filtprob: pred.0, seqprob: pred.1))
            }
            return execute(predecessors: predecessors, previous: MockSample(0), sample: MockSample(1))
        }
    }
    
    override func setUp() {
        continueAfterFailure = true
    }

    override func tearDown() {
        
    }

    func testFilterInitial() {
        let states = MockStates(matrix: [[0, 0, 0.6, 1.0, 0.4]])
        let filter = MockFilter(states: states)
        let result = filter.execute()
        
        XCTAssertEqual(states.NumCandidates, result.count)
        
        for element in result {
            XCTAssertEqual(states.filtprob(element.id), element.filtprob, accuracy: 10E-6);
            XCTAssertEqual(states.seqprob(element.id), element.seqprob, accuracy: 10E-6)
            if states.pred(element.id) == -1 {
                XCTAssertNil(element.predecessor)
                XCTAssertFalse(element.hasTransition)
            } else {
                XCTAssertEqual(states.pred(element.id), element.predecessor?.id)
                XCTAssertFalse(element.hasTransition)
            }
        }
    }

    func testFilterSubsequent() {
        let states = MockStates(matrix: [
            [0, 0, 0.6, 1.0, 0.4],
            [0.2, 0.3, 0.01, 0.02, 0.3],
            [0.3, 0.4, 0.2, 0.05, 0.02]
        ])
        let filter = MockFilter(states: states)
        let result = filter.execute()
    
        XCTAssertEqual(states.NumCandidates, result.count)
    
        for element in result {
            XCTAssertEqual(states.filtprob(element.id), element.filtprob, accuracy: 10E-6)
            XCTAssertEqual(states.seqprob(element.id), element.seqprob, accuracy: 10E-6)
            if states.pred(element.id) == -1 {
                XCTAssertNil(element.predecessor)
                XCTAssertFalse(element.hasTransition)
            } else {
                XCTAssertEqual(states.pred(element.id), element.predecessor?.id)
                XCTAssertTrue(element.hasTransition)
            }
        }
    }
    
    func testFilterBreakTransition() {
        let states = MockStates(matrix: [
            [0, 0, 0.6, 1.0, 0.4],
            [0.2, 0.3, 0, 0, 0],
            [0.3, 0.4, 0, 0, 0]
        ])
        let filter = MockFilter(states: states)
        let result = filter.execute()
        
        XCTAssertEqual(states.NumCandidates, result.count)
        
        for element in result {
            XCTAssertEqual(states.filtprob(element.id), element.filtprob, accuracy: 10E-6)
            XCTAssertEqual(states.seqprob(element.id), element.seqprob, accuracy: 10E-6)
            if states.pred(element.id) == -1 {
                XCTAssertNil(element.predecessor)
                XCTAssertFalse(element.hasTransition)
            } else {
                XCTAssertEqual(states.pred(element.id), element.predecessor?.id)
                XCTAssertTrue(element.hasTransition)
            }
        }
    }
    
    func testFilterBreakCandidates() {
        let states = MockStates(matrix: [
            [0, 0],
            [0.2, 0.3],
            [0.3, 0.4]
        ])
        let filter = MockFilter(states: states)
        let result = filter.execute()
    
        XCTAssertEqual(states.NumCandidates, result.count)
    
        for element in result {
            XCTAssertEqual(states.filtprob(element.id), element.filtprob, accuracy: 10E-6)
            XCTAssertEqual(states.seqprob(element.id), element.seqprob, accuracy: 10E-6)
            if states.pred(element.id) == -1 {
                XCTAssertNil(element.predecessor)
                XCTAssertFalse(element.hasTransition)
            } else {
                XCTAssertEqual(states.pred(element.id), element.predecessor?.id)
                XCTAssertTrue(element.hasTransition)
            }
        }
    }
}
