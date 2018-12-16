//
//  MatcherSampleTest.swift
//  MapMatching
//
//  Created by devilrabbit on 2018/10/27.
//  Copyright (c) 2018 devilrabbit. All rights reserved.
//

import XCTest
import CoreLocation

class MatcherSampleTest: XCTestCase {

    override func setUp() {
        continueAfterFailure = true
    }

    override func tearDown() {
        
    }

    func testAzimuth() {
        // Use recording to get started writing UI tests.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        
        let sample1 = MatcherSample(id: 0, time: 0, point: CLLocationCoordinate2D(latitude: 1, longitude: 1), azimuth: -0.1)
        XCTAssertEqual(359.9, sample1.azimuth, accuracy: 0.1)
        
        let sample2 = MatcherSample(id: 0, time: 0, point: CLLocationCoordinate2D(latitude: 1, longitude: 1), azimuth: -359.9)
        XCTAssertEqual(0.1, sample2.azimuth, accuracy: 0.1)
        
        let sample3 = MatcherSample(id: 0, time: 0, point: CLLocationCoordinate2D(latitude: 1, longitude: 1), azimuth: -360.1)
        XCTAssertEqual(359.9, sample3.azimuth, accuracy: 0.1)
        
        let sample4 = MatcherSample(id: 0, time: 0, point: CLLocationCoordinate2D(latitude: 1, longitude: 1), azimuth: 360)
        XCTAssertEqual(0.0, sample4.azimuth, accuracy: 0.1)
        
        let sample5 = MatcherSample(id: 0, time: 0, point: CLLocationCoordinate2D(latitude: 1, longitude: 1), azimuth: 360.1)
        XCTAssertEqual(0.1, sample5.azimuth, accuracy: 0.1)
        
        let sample6 = MatcherSample(id: 0, time: 0, point: CLLocationCoordinate2D(latitude: 1, longitude: 1), azimuth: 720.1)
        XCTAssertEqual(0.1, sample6.azimuth, accuracy: 0.1)
        
        let sample7 = MatcherSample(id: 0, time: 0, point: CLLocationCoordinate2D(latitude: 1, longitude: 1), azimuth: -719.9)
        XCTAssertEqual(0.1, sample7.azimuth, accuracy: 0.1)
        
        let sample8 = MatcherSample(id: 0, time: 0, point: CLLocationCoordinate2D(latitude: 1, longitude: 1), azimuth: -720.1)
        XCTAssertEqual(359.9, sample8.azimuth, accuracy: 0.1)
    }

}
