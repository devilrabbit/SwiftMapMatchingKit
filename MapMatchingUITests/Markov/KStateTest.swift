//
//  KStateTest.swift
//  MapMatching
//
//  Created by devilrabbit on 2018/11/04.
//  Copyright (c) 2018 devilrabbit. All rights reserved.
//

import XCTest

class KStateTest: XCTestCase {
    
    struct MockStateTransition {
        
    }
    
    class MockElement: StateCandidate {
        typealias TCandidate = MockElement
        typealias TTransition = MockStateTransition
        typealias TSample = MockSample
        
        var id: Int64
        
        var seqprob: Double
        var filtprob: Double
        var predecessor: TCandidate?
        var transition: TTransition?
        
        public init(id: Int64, seqprob: Double, filtprob: Double, pred: MockElement?) {
            self.id = id
            self.seqprob = seqprob
            self.filtprob = filtprob
            self.predecessor = pred
        }
        
        public func hash(into hasher: inout Hasher) {
            hasher.combine(id)
        }
        
        static func == (lhs: MockElement, rhs: MockElement) -> Bool {
            return lhs.id == rhs.id
        }
    }

    struct MockSample: Sample {
        var time: Date
        public init(_ time: Int64) {
            self.time = Date(timeIntervalSince1970: Double(time) / 1000.0)
        }
    }
    
    override func setUp() {
        continueAfterFailure = true
    }

    override func tearDown() {
        
    }

    func testKStateUnbound() {
        var elements = [Int : MockElement]()
        elements[0] = MockElement(id: 0, seqprob: log10(0.3), filtprob: 0.3, pred: nil)
        elements[1] = MockElement(id: 1, seqprob: log10(0.2), filtprob: 0.2, pred: nil)
        elements[2] = MockElement(id: 2, seqprob: log10(0.5), filtprob: 0.5, pred: nil)
        
        let state = KState<MockElement, MockStateTransition, MockSample>()
        
        let vector1 = [elements[0]!, elements[1]!, elements[2]!]
        state.update(vector: vector1, sample: MockSample(0))
        
        XCTAssertEqual(3, state.count)
        XCTAssertEqual(2, state.estimate()!.id)
        
        elements[3] = MockElement(id: 3, seqprob: log10(0.3), filtprob: 0.3, pred: elements[1])
        elements[4] = MockElement(id: 4, seqprob: log10(0.2), filtprob: 0.2, pred: elements[1])
        elements[5] = MockElement(id: 5, seqprob: log10(0.4), filtprob: 0.4, pred: elements[2])
        elements[6] = MockElement(id: 6, seqprob: log10(0.1), filtprob: 0.1, pred: elements[2])
        
        let vector2 = [elements[3]!, elements[4]!, elements[5]!, elements[6]!]
        state.update(vector: vector2, sample: MockSample(1))
            
        XCTAssertEqual(6, state.count)
        XCTAssertEqual(5, state.estimate()!.id)
            
        var sequence1: [Int64] = [2, 5]
        for i in 0..<state.sequence().count - 1 {
            XCTAssertEqual(sequence1[i], state.sequence()[i].id)
        }
        
        elements[7] = MockElement(id: 7, seqprob: log10(0.3), filtprob: 0.3, pred: elements[5])
        elements[8] = MockElement(id: 8, seqprob: log10(0.2), filtprob: 0.2, pred: elements[5])
        elements[9] = MockElement(id: 9, seqprob: log10(0.4), filtprob: 0.4, pred: elements[6])
        elements[10] = MockElement(id: 10, seqprob: log10(0.1), filtprob: 0.1, pred: elements[6])
        
        let vector3 = [elements[7]!, elements[8]!, elements[9]!, elements[10]!]
        state.update(vector: vector3, sample: MockSample(2))
        
        XCTAssertEqual(7, state.count)
        XCTAssertEqual(9, state.estimate()!.id)
            
        var sequence2: [Int64] = [2, 6, 9]
        for i in 0..<state.sequence().count - 1 {
            XCTAssertEqual(sequence2[i], state.sequence()[i].id)
        }
        
        elements[11] = MockElement(id: 11, seqprob: log10(0.3), filtprob: 0.3, pred: nil)
        elements[12] = MockElement(id: 12, seqprob: log10(0.2), filtprob: 0.2, pred: nil)
        elements[13] = MockElement(id: 13, seqprob: log10(0.4), filtprob: 0.4, pred: nil)
        elements[14] = MockElement(id: 14, seqprob: log10(0.1), filtprob: 0.1, pred: nil)
        
        let vector4 = [elements[11]!, elements[12]!, elements[13]!, elements[14]!]
        state.update(vector: vector4, sample: MockSample(3))
            
        XCTAssertEqual(8, state.count)
        XCTAssertEqual(13, state.estimate()!.id)
            
        var sequence3: [Int64] = [2, 6, 9, 13]
        for i in 0..<state.sequence().count - 1 {
            XCTAssertEqual(sequence3[i], state.sequence()[i].id)
        }
        
        let vector5 = [MockElement]()
        state.update(vector: vector5, sample: MockSample(4))
            
        XCTAssertEqual(8, state.count)
        XCTAssertEqual(13, state.estimate()!.id)
            
        var sequence4: [Int64] = [2, 6, 9, 13]
        for i in 0..<state.sequence().count - 1 {
            XCTAssertEqual(sequence4[i], state.sequence()[i].id)
        }
    }

    func testBreak() {
        // Test k-state in case of HMM break 'no transition' as reported in barefoot issue #83.
        // Tests only 'no transitions', no emissions is empty vector and, hence, input to update
        // operation.
        
        let state = KState<MockElement, MockStateTransition, MockSample>()
        var elements = [Int : MockElement]()
        elements[0] = MockElement(id: 0, seqprob: log10(0.4), filtprob: 0.4, pred: nil)
            
        let vector1 = [elements[0]!]
        state.update(vector: vector1, sample: MockSample(0))

        elements[1] = MockElement(id: 1, seqprob: log(0.7), filtprob: 0.6, pred: nil)
        elements[2] = MockElement(id: 2, seqprob: log(0.3), filtprob: 0.4, pred: elements[0])
        
        let vector2 = [elements[1]!, elements[2]!]
        state.update(vector: vector2, sample: MockSample(1))
        
        elements[3] = MockElement(id: 3, seqprob: log(0.5), filtprob: 0.6, pred: nil)
        
        let vector3 = [elements[3]!]
        state.update(vector: vector3, sample: MockSample(2))
        
        let seq = state.sequence()
        XCTAssertEqual(0, seq[0].id)
        XCTAssertEqual(1, seq[1].id)
        XCTAssertEqual(3, seq[2].id)
    }
    
    func testKState() {
        var elements = [Int : MockElement]()
        elements[0] = MockElement(id: 0, seqprob: log10(0.3), filtprob: 0.3, pred: nil)
        elements[1] = MockElement(id: 1, seqprob: log10(0.2), filtprob: 0.2, pred: nil)
        elements[2] = MockElement(id: 2, seqprob: log10(0.5), filtprob: 0.5, pred: nil)
        
        let state = KState<MockElement, MockStateTransition, MockSample>(k: 1)
        
        let vector1 = [elements[0]!, elements[1]!, elements[2]!]
        state.update(vector: vector1, sample: MockSample(0))
        
        XCTAssertEqual(3, state.count)
        XCTAssertEqual(2, state.estimate()?.id)
        
        elements[3] = MockElement(id: 3, seqprob: log10(0.3), filtprob: 0.3, pred: elements[1])
        elements[4] = MockElement(id: 4, seqprob: log10(0.2), filtprob: 0.2, pred: elements[1])
        elements[5] = MockElement(id: 5, seqprob: log10(0.4), filtprob: 0.4, pred: elements[2])
        elements[6] = MockElement(id: 6, seqprob: log10(0.1), filtprob: 0.1, pred: elements[2])
        
        let vector2 = [elements[3]!, elements[4]!, elements[5]!, elements[6]!]
        state.update(vector: vector2, sample: MockSample(1))
            
        XCTAssertEqual(6, state.count)
        XCTAssertEqual(5, state.estimate()?.id)
            
        let sequence1: [Int64] = [2, 5]
        for i in 0..<state.sequence().count - 1 {
            XCTAssertEqual(sequence1[i], state.sequence()[i].id)
        }
        
        elements[7] = MockElement(id: 7, seqprob: log10(0.3), filtprob: 0.3, pred: elements[5])
        elements[8] = MockElement(id: 8, seqprob: log10(0.2), filtprob: 0.2, pred: elements[5])
        elements[9] = MockElement(id: 9, seqprob: log10(0.4), filtprob: 0.4, pred: elements[6])
        elements[10] = MockElement(id: 10, seqprob: log10(0.1), filtprob: 0.1, pred: elements[6])
        
        let vector3 = [elements[7]!, elements[8]!, elements[9]!, elements[10]!]
        state.update(vector: vector3, sample: MockSample(2))
            
        XCTAssertEqual(6, state.count)
        XCTAssertEqual(9, state.estimate()?.id)
            
        let sequence2: [Int64] = [6, 9]
        for i in 0..<state.sequence().count - 1 {
            XCTAssertEqual(sequence2[i], state.sequence()[i].id)
        }
        
        elements[11] = MockElement(id: 11, seqprob: log10(0.3), filtprob: 0.3, pred: nil)
        elements[12] = MockElement(id: 12, seqprob: log10(0.2), filtprob: 0.2, pred: nil)
        elements[13] = MockElement(id: 13, seqprob: log10(0.4), filtprob: 0.4, pred: nil)
        elements[14] = MockElement(id: 14, seqprob: log10(0.1), filtprob: 0.1, pred: nil)
        
        let vector4 = [elements[11]!, elements[12]!, elements[13]!, elements[14]!]
        state.update(vector: vector4, sample: MockSample(3))
            
        XCTAssertEqual(5, state.count)
        XCTAssertEqual(13, state.estimate()?.id)
            
        let sequence3: [Int64] = [9, 13]
        for i in 0..<state.sequence().count - 1 {
            XCTAssertEqual(sequence3[i], state.sequence()[i].id)
        }
    
        let vector5 = [MockElement]()
        state.update(vector: vector5, sample: MockSample(4))
            
        XCTAssertEqual(5, state.count)
        XCTAssertEqual(13, state.estimate()?.id)
            
        let sequence4: [Int64] = [9, 13]
        for i in 0..<state.sequence().count - 1 {
            XCTAssertEqual(sequence4[i], state.sequence()[i].id)
        }
    }
    
    func testTState() {
        var elements = [Int : MockElement]()
        elements[0] = MockElement(id: 0, seqprob: log10(0.3), filtprob: 0.3, pred: nil)
        elements[1] = MockElement(id: 1, seqprob: log10(0.2), filtprob: 0.2, pred: nil)
        elements[2] = MockElement(id: 2, seqprob: log10(0.5), filtprob: 0.5, pred: nil)
        
        let state = KState<MockElement, MockStateTransition, MockSample>(t: 0.001)
        
        let vector1 = [elements[0]!, elements[1]!, elements[2]!]
        state.update(vector: vector1, sample: MockSample(0))
        
        XCTAssertEqual(3, state.count)
        XCTAssertEqual(2, state.estimate()?.id)
        
        elements[3] = MockElement(id: 3, seqprob: log10(0.3), filtprob: 0.3, pred: elements[1])
        elements[4] = MockElement(id: 4, seqprob: log10(0.2), filtprob: 0.2, pred: elements[1])
        elements[5] = MockElement(id: 5, seqprob: log10(0.4), filtprob: 0.4, pred: elements[2])
        elements[6] = MockElement(id: 6, seqprob: log10(0.1), filtprob: 0.1, pred: elements[2])
        
        let vector2 = [elements[3]!, elements[4]!, elements[5]!, elements[6]!]
        state.update(vector: vector2, sample: MockSample(1))
        
        XCTAssertEqual(6, state.count)
        XCTAssertEqual(5, state.estimate()?.id)
        
        var sequence1: [Int64] = [2, 5]
        for i in 0..<state.sequence().count - 1 {
            XCTAssertEqual(sequence1[i], state.sequence()[i].id)
        }
        
        elements[7] = MockElement(id: 7, seqprob: log10(0.3), filtprob: 0.3, pred: elements[5])
        elements[8] = MockElement(id: 8, seqprob: log10(0.2), filtprob: 0.2, pred: elements[5])
        elements[9] = MockElement(id: 9, seqprob: log10(0.4), filtprob: 0.4, pred: elements[6])
        elements[10] = MockElement(id: 10, seqprob: log10(0.1), filtprob: 0.1, pred: elements[6])
        
        let vector3 = [elements[7]!, elements[8]!, elements[9]!, elements[10]!]
        state.update(vector: vector3, sample: MockSample(2))
            
        XCTAssertEqual(6, state.count)
        XCTAssertEqual(9, state.estimate()?.id)
            
        var sequence2: [Int64] = [6, 9]
        for i in 0..<state.sequence().count - 1 {
            XCTAssertEqual(sequence2[i], state.sequence()[i].id)
        }
        
        elements[11] = MockElement(id: 11, seqprob: log10(0.3), filtprob: 0.3, pred: nil)
        elements[12] = MockElement(id: 12, seqprob: log10(0.2), filtprob: 0.2, pred: nil)
        elements[13] = MockElement(id: 13, seqprob: log10(0.4), filtprob: 0.4, pred: nil)
        elements[14] = MockElement(id: 14, seqprob: log10(0.1), filtprob: 0.1, pred: nil)
        
        let vector4 = [elements[11]!, elements[12]!, elements[13]!, elements[14]!]
        state.update(vector: vector4, sample: MockSample(3))
        
        XCTAssertEqual(5, state.count)
        XCTAssertEqual(13, state.estimate()?.id)
        
        var sequence3: [Int64] = [9, 13]
        for i in 0..<state.sequence().count - 1 {
            XCTAssertEqual(sequence3[i], state.sequence()[i].id)
        }
        
        let vector5 = [MockElement]()
        state.update(vector: vector5, sample: MockSample(4))
        
        XCTAssertEqual(5, state.count)
        XCTAssertEqual(13, state.estimate()?.id)
        
        var sequence4: [Int64] = [9, 13]
        for i in 0..<state.sequence().count - 1 {
            XCTAssertEqual(sequence4[i], state.sequence()[i].id)
        }
    }
}
