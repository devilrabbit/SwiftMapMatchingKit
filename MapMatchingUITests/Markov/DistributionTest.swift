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
