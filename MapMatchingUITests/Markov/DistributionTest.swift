//
//  DistributionTest.swift
//  MapMatching
//
//  Created by devilrabbit on 2018/10/26.
//  Copyright (c) 2018年 devilrabbit. All rights reserved.
//

import XCTest

class DistributionTest: XCTestCase {

    override func setUp() {
        continueAfterFailure = true
    }

    override func tearDown() {
        
    }

    private let precision: Double = 1e-8
    
    func testLogNormalDistribution() {
        XCTAssertEqual(
            log(Distributions.normalDistribution(sigma: 5, x: 6)),
            Distributions.logNormalDistribution(sigma: 5, x: 6),
            accuracy: precision)
    }
    
    func testLogExponentialDistribution() {
        XCTAssertEqual(
            log(Distributions.exponentialDistribution(beta: 5, x: 6)),
            Distributions.logExponentialDistribution(beta: 5, x: 6),
            accuracy: precision)
    }

}
