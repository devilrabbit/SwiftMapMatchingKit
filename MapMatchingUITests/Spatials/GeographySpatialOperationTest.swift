//
//  GeographySpatialOperationTest.swift
//  MapMatching
//
//  Created by devilrabbit on 2018/11/05.
//  Copyright (c) 2018 devilrabbit. All rights reserved.
//

import XCTest
import CoreLocation

class GeographySpatialOperationTest: XCTestCase {
    
    var spatial = GeographySpatialOperator()

    private func distance(_ a: Coordinate2D, _ b: Coordinate2D) -> Double {
        return spatial.distance(a, b)
    }
    
    private func intercept(_ a: Coordinate2D, _ b: Coordinate2D, _ c: Coordinate2D) -> (Coordinate2D, Double, Double) {
        let iter = 1000
        var res = (a, spatial.distance(a, c), 0.0)
    
        for f in 1...iter {
            let p = spatial.interpolate(a, b, Double(f) / Double(iter))
            let s = spatial.distance(p, c)
    
            if s < res.1 {
                res.0 = p
                res.1 = s
                res.2 = Double(f) / Double(iter)
            }
        }
        
        return res
    }
    
    private func azimuth(_ a: Coordinate2D, _ b: Coordinate2D, _ left: Bool) -> Double {
        let geod = Geodesic.WGS84.inverse(lat1: a.y, lon1: a.x, lat2: b.y, lon2: b.x)
        let azi = left ? geod.azi1 : geod.azi2
        return azi < 0 ? azi + 360 : azi
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

    func testDistance() {
        let reyk = CLLocationCoordinate2D(latitude: -21.933333, longitude: 64.15)
        let berl = CLLocationCoordinate2D(latitude: 13.408056, longitude: 52.518611)
        let mosk = CLLocationCoordinate2D(latitude: 37.616667, longitude: 55.75)
        
        var dist_geog = spatial.distance(mosk, reyk)
        var dist_esri = distance(mosk, reyk)
        XCTAssertEqual(dist_geog, dist_esri, accuracy: 10E-6)
        
        dist_geog = spatial.distance(berl, reyk)
        dist_esri = distance(berl, reyk)
        XCTAssertEqual(dist_geog, dist_esri, accuracy: 10E-6)
    }

    func testGnomonic() {
        let reyk = CLLocationCoordinate2D(latitude: 64.15, longitude: -21.933333)
        let berl = CLLocationCoordinate2D(latitude: 52.518611, longitude: 13.408056)
        let mosk = CLLocationCoordinate2D(latitude: 55.75, longitude: 37.616667)
        
        let f = spatial.intercept(reyk, mosk, berl)
        let p = spatial.interpolate(reyk, mosk, f)
        let res = intercept(reyk, mosk, berl)
        
        XCTAssertEqual(f, res.2, accuracy: 0.1)
        XCTAssertEqual(p.x, res.0.x, accuracy: 10E-2)
        XCTAssertEqual(p.y, res.0.y, accuracy: 10E-2)
    }
    
    func testLineInterception() {
        let a = CLLocationCoordinate2D(latitude: 48.1403687, longitude: 11.4047661)
        let b = CLLocationCoordinate2D(latitude: 48.141055, longitude: 11.4053519)
        
        let points = [
            CLLocationCoordinate2D(latitude: 48.14051652560591, longitude: 11.406501117689324), // East
            CLLocationCoordinate2D(latitude: 48.14182906667162, longitude: 11.406713245538327), // Northeast
            CLLocationCoordinate2D(latitude: 48.14258477213369, longitude: 11.404923416812364), // North
            CLLocationCoordinate2D(latitude: 48.14105540093837, longitude: 11.403300759321036), // Northwest
            CLLocationCoordinate2D(latitude: 48.140881120346386, longitude: 11.403193249043934), // West
            CLLocationCoordinate2D(latitude: 48.13987351306362, longitude: 11.40327279698731), // Southwest
            CLLocationCoordinate2D(latitude: 48.1392039845402, longitude: 11.405221721600025), // South
            CLLocationCoordinate2D(latitude: 48.13963486923349, longitude: 11.406255844863914) // Southeast
        ]
    
        for c in points {
            let f = spatial.intercept(a, b, c)
            let p = spatial.interpolate(a, b, f)
            let res = intercept(a, b, c)
            let s = spatial.distance(p, c)
            let s_esri = distance(p, c)
    
            XCTAssertEqual(f > 1 ? 1 : f < 0 ? 0 : f, res.2, accuracy: 0.2)
            XCTAssertEqual(p.x, res.0.x, accuracy: 10E-2)
            XCTAssertEqual(p.y, res.0.y, accuracy: 10E-2)
            XCTAssertEqual(s, s_esri, accuracy: 10E-6)
        }
    }
    
    func testLineAzimuth() {
        let reyk = CLLocationCoordinate2D(latitude: 64.15, longitude: -21.933333)
        let berl = CLLocationCoordinate2D(latitude: 52.518611, longitude: 13.408056)
        let mosk = CLLocationCoordinate2D(latitude: 55.75, longitude: 37.616667)
    
        XCTAssertEqual(azimuth(berl, mosk, true), spatial.azimuth(berl, mosk, 0), accuracy: 1E-9)
        XCTAssertEqual(azimuth(berl, mosk, false), spatial.azimuth(berl, mosk, 1), accuracy: 1E-9)
        XCTAssertEqual(azimuth(berl, reyk, true), spatial.azimuth(berl, reyk, 0), accuracy: 1E-9)
        XCTAssertTrue(spatial.azimuth(berl, mosk, 0) < spatial.azimuth(berl, mosk, 0.5)
            && spatial.azimuth(berl, mosk, 0.5) < spatial.azimuth(berl, mosk, 1))
    }
    
    func testPathInterception1() {
        let c = CLLocationCoordinate2D(latitude: 48.144161, longitude: 11.410624)
        let ab = LineString(coordinates: [
            [48.1402147, 11.4047013],
            [48.1402718, 11.4047038],
            [48.1403687, 11.4047661],
            [48.141055, 11.4053519],
            [48.1411901, 11.4054617],
            [48.1421968, 11.4062664],
            [48.1424479, 11.4064586],
            [48.1427372, 11.4066449],
            [48.1429028, 11.4067254],
            [48.1430673, 11.4067864],
            [48.1433303, 11.4068647],
            [48.1436822, 11.4069456],
            [48.1440368, 11.4070524],
            [48.1443314, 11.4071569],
            [48.1445915, 11.4072635],
            [48.1448641, 11.4073887],
            [48.1450729, 11.4075228],
            [48.1454843, 11.407806],
            [48.1458112, 11.4080135],
            [48.1463167, 11.4083012],
            [48.1469061, 11.4086211],
            [48.1471386, 11.4087461],
            [48.1474078, 11.4088719],
            [48.1476014, 11.4089422],
            [48.1478353, 11.409028],
            [48.1480701, 11.409096],
            [48.1483459, 11.4091568],
            [48.1498536, 11.4094282]
        ])!
    
        let f = spatial.intercept(ab, c)
        let l = spatial.length(of: ab)
        let p = spatial.interpolate(ab, l, f)
        let d = spatial.distance(p, c)
    
        XCTAssertEqual(p.x, 11.407547966254612, accuracy: 10E-6)
        XCTAssertEqual(p.y, 48.14510945890138, accuracy: 10E-6)
        XCTAssertEqual(f, 0.5175157549609246, accuracy: 10E-6)
        XCTAssertEqual(l, 1138.85464239099, accuracy: 10E-6)
        XCTAssertEqual(d, 252.03375312704165, accuracy: 10E-6)
    }
    
    func testPathInterception2() {
        let c = CLLocationCoordinate2D(latitude: 48.17578656762985, longitude: 11.584009286555187)
        let ab = LineString(coordinates: [
            [48.1761996, 11.5852021],
            [48.175924, 11.585284],
            [48.1758945, 11.5852937]
        ])!
    
        let f = spatial.intercept(ab, c)
        let l = spatial.length(of: ab)
        let p = spatial.interpolate(ab, l, f)
        let d = spatial.distance(p, c)
    
        XCTAssertEqual(p.x, 11.585274842230357, accuracy: 10E-6)
        XCTAssertEqual(p.y, 48.17595481677191, accuracy: 10E-6)
        XCTAssertEqual(f, 0.801975106391962, accuracy: 10E-6)
        XCTAssertEqual(l, 34.603061318901396, accuracy: 10E-6)
        XCTAssertEqual(d, 95.96239015496631, accuracy: 10E-6)
    }
    
    func testPathAzimuth() {
        let reyk = CLLocationCoordinate2D(latitude: 64.15, longitude: -21.933333)
        let berl = CLLocationCoordinate2D(latitude: 52.518611, longitude: 13.408056)
        let mosk = CLLocationCoordinate2D(latitude: 55.75, longitude: 37.616667)
        
        let p = LineString(geometry: [berl, mosk, reyk])
        
        XCTAssertEqual(azimuth(berl, mosk, true), spatial.azimuth(p, 0), accuracy: 1E-9)
        XCTAssertEqual(azimuth(mosk, reyk, false), spatial.azimuth(p, 1), accuracy: 1E-9)
        XCTAssertEqual(azimuth(berl, mosk, false), spatial.azimuth(p, spatial.distance(berl, mosk) / spatial.length(of: p)), accuracy: 1E-9)
        
        let c = spatial.interpolate(berl, mosk, 0.5)
        XCTAssertEqual(azimuth(berl, c, false), spatial.azimuth(p, spatial.distance(berl, c) / spatial.length(of: p)), accuracy: 1E-9)
        
        let d = spatial.interpolate(mosk, reyk, 0.5)
        XCTAssertEqual(azimuth(mosk, d, false), spatial.azimuth(p, (spatial.distance(berl, mosk) + spatial.distance(mosk, d)) / spatial.length(of: p)), accuracy: 1E-9)
    }
}
