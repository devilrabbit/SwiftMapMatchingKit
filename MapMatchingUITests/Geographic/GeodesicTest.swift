//
//  GeodesicTest.swift
//  MapMatching
//
//  Created by devilrabbit on 2018/11/05.
//  Copyright (c) 2018 devilrabbit. All rights reserved.
//

import XCTest

class GeodesicTest: XCTestCase {

    private var testcases = [
        [35.60777, -139.44815, 111.098748429560326,
         -11.17491, -69.95921, 129.289270889708762,
         8935244.5604818305, 80.50729714281974, 6273170.2055303837,
         0.16606318447386067, 0.16479116945612937, 12841384694976.432],
        [55.52454, 106.05087, 22.020059880982801,
         77.03196, 197.18234, 109.112041110671519,
         4105086.1713924406, 36.892740690445894, 3828869.3344387607,
         0.80076349608092607, 0.80101006984201008, 61674961290615.615],
        [-21.97856, 142.59065, -32.44456876433189,
         41.84138, 98.56635, -41.84359951440466,
         8394328.894657671, 75.62930491011522, 6161154.5773110616,
         0.24816339233950381, 0.24930251203627892, -6637997720646.717],
        [-66.99028, 112.2363, 173.73491240878403,
         -12.70631, 285.90344, 2.512956620913668,
         11150344.2312080241, 100.278634181155759, 6289939.5670446687,
         -0.17199490274700385, -0.17722569526345708, -121287239862139.744],
        [-17.42761, 173.34268, -159.033557661192928,
         -15.84784, 5.93557, -20.787484651536988,
         16076603.1631180673, 144.640108810286253, 3732902.1583877189,
         -0.81273638700070476, -0.81299800519154474, 97825992354058.708],
        [32.84994, 48.28919, 150.492927788121982,
         -56.28556, 202.29132, 48.113449399816759,
         16727068.9438164461, 150.565799985466607, 3147838.1910180939,
         -0.87334918086923126, -0.86505036767110637, -72445258525585.010],
        [6.96833, 52.74123, 92.581585386317712,
         -7.39675, 206.17291, 90.721692165923907,
         17102477.2496958388, 154.147366239113561, 2772035.6169917581,
         -0.89991282520302447, -0.89986892177110739, -1311796973197.995],
        [-50.56724, -16.30485, -105.439679907590164,
         -33.56571, -94.97412, -47.348547835650331,
         6455670.5118668696, 58.083719495371259, 5409150.7979815838,
         0.53053508035997263, 0.52988722644436602, 41071447902810.047],
        [-58.93002, -8.90775, 140.965397902500679,
         -8.91104, 133.13503, 19.255429433416599,
         11756066.0219864627, 105.755691241406877, 6151101.2270708536,
         -0.26548622269867183, -0.27068483874510741, -86143460552774.735],
        [-68.82867, -74.28391, 93.774347763114881,
         -50.63005, -8.36685, 34.65564085411343,
         3956936.926063544, 35.572254987389284, 3708890.9544062657,
         0.81443963736383502, 0.81420859815358342, -41845309450093.787],
        [-10.62672, -32.0898, -86.426713286747751,
         5.883, -134.31681, -80.473780971034875,
         11470869.3864563009, 103.387395634504061, 6184411.6622659713,
         -0.23138683500430237, -0.23155097622286792, 4198803992123.548],
        [-21.76221, 166.90563, 29.319421206936428,
         48.72884, 213.97627, 43.508671946410168,
         9098627.3986554915, 81.963476716121964, 6299240.9166992283,
         0.13965943368590333, 0.14152969707656796, 10024709850277.476],
        [-19.79938, -174.47484, 71.167275780171533,
         -11.99349, -154.35109, 65.589099775199228,
         2319004.8601169389, 20.896611684802389, 2267960.8703918325,
         0.93427001867125849, 0.93424887135032789, -3935477535005.785],
        [-11.95887, -116.94513, 92.712619830452549,
         4.57352, 7.16501, 78.64960934409585,
         13834722.5801401374, 124.688684161089762, 5228093.177931598,
         -0.56879356755666463, -0.56918731952397221, -9919582785894.853],
        [-87.85331, 85.66836, -65.120313040242748,
         66.48646, 16.09921, -4.888658719272296,
         17286615.3147144645, 155.58592449699137, 2635887.4729110181,
         -0.90697975771398578, -0.91095608883042767, 42667211366919.534],
        [1.74708, 128.32011, -101.584843631173858,
         -11.16617, 11.87109, -86.325793296437476,
         12942901.1241347408, 116.650512484301857, 5682744.8413270572,
         -0.44857868222697644, -0.44824490340007729, 10763055294345.653],
        [-25.72959, -144.90758, -153.647468693117198,
         -57.70581, -269.17879, -48.343983158876487,
         9413446.7452453107, 84.664533838404295, 6356176.6898881281,
         0.09492245755254703, 0.09737058264766572, 74515122850712.444],
        [-41.22777, 122.32875, 14.285113402275739,
         -7.57291, 130.37946, 10.805303085187369,
         3812686.035106021, 34.34330804743883, 3588703.8812128856,
         0.82605222593217889, 0.82572158200920196, -2456961531057.857],
        [11.01307, 138.25278, 79.43682622782374,
         6.62726, 247.05981, 103.708090215522657,
         11911190.819018408, 107.341669954114577, 6070904.722786735,
         -0.29767608923657404, -0.29785143390252321, 17121631423099.696],
        [-29.47124, 95.14681, -163.779130441688382,
         -27.46601, -69.15955, -15.909335945554969,
         13487015.8381145492, 121.294026715742277, 5481428.9945736388,
         -0.51527225545373252, -0.51556587964721788, 104679964020340.318]
    ]
    
    private static let s_polygon = PolygonArea(earth: Geodesic.WGS84, polyline: false)
    private static let s_polyline = PolygonArea(earth: Geodesic.WGS84, polyline: true)
    
    private static func planimeter(_ points: [[Double]]) -> PolygonResult {
        s_polygon.clear()
        for point in points {
            s_polygon.addPoint(lat: point[0], lon: point[1])
        }
        return s_polygon.compute(reverse: false, sign: true)
    }
    
    private static func polyLength(_ points: [[Double]]) -> PolygonResult {
        s_polyline.clear()
        for point in points {
            s_polyline.addPoint(lat: point[0], lon: point[1])
        }
        return s_polyline.compute(reverse: false, sign: true)
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

    func testInverse() {
        for testcase in testcases {
            let lat1 = testcase[0]
            let lon1 = testcase[1]
            let azi1 = testcase[2]
            let lat2 = testcase[3]
            let lon2 = testcase[4]
            let azi2 = testcase[5]
            let s12 = testcase[6]
            let a12 = testcase[7]
            let m12 = testcase[8]
            let M12 = testcase[9]
            let M21 = testcase[10]
            let S12 = testcase[11]
            
            let inv = Geodesic.WGS84.inverse(lat1: lat1, lon1: lon1, lat2: lat2, lon2: lon2, outmask: [.ALL, .LONG_UNROLL])
            
            XCTAssertEqual(lon2, inv.lon2, accuracy: 1e-13)
            XCTAssertEqual(azi1, inv.azi1, accuracy: 1e-13)
            XCTAssertEqual(azi2, inv.azi2, accuracy: 1e-13)
            XCTAssertEqual(s12, inv.s12, accuracy: 1e-8)
            XCTAssertEqual(a12, inv.a12, accuracy: 1e-13)
            XCTAssertEqual(m12, inv.m12, accuracy: 1e-8)
            XCTAssertEqual(M12, inv.M12, accuracy: 1e-15)
            XCTAssertEqual(M21, inv.M21, accuracy: 1e-15)
            XCTAssertEqual(S12, inv.S12, accuracy: 0.1)
        }
    }

    func testDirect() {
        for testcase in testcases {
            let lat1 = testcase[0]
            let lon1 = testcase[1]
            let azi1 = testcase[2]
            let lat2 = testcase[3]
            let lon2 = testcase[4]
            let azi2 = testcase[5]
            let s12 = testcase[6]
            let a12 = testcase[7]
            let m12 = testcase[8]
            let M12 = testcase[9]
            let M21 = testcase[10]
            let S12 = testcase[11]
            
            let dir = Geodesic.WGS84.direct(lat1: lat1, lon1: lon1, azi1: azi1, s12: s12, outmask: [.ALL ,.LONG_UNROLL])
            
            XCTAssertEqual(lat2, dir.lat2, accuracy: 1e-13)
            XCTAssertEqual(lon2, dir.lon2, accuracy: 1e-13)
            XCTAssertEqual(azi2, dir.azi2, accuracy: 1e-13)
            XCTAssertEqual(a12, dir.a12, accuracy: 1e-13)
            XCTAssertEqual(m12, dir.m12, accuracy: 1e-8)
            XCTAssertEqual(M12, dir.M12, accuracy: 1e-15)
            XCTAssertEqual(M21, dir.M21, accuracy: 1e-15)
            XCTAssertEqual(S12, dir.S12, accuracy: 0.1)
        }
    }
    
    func testArcDirect() {
        for testcase in testcases {
            let lat1 = testcase[0]
            let lon1 = testcase[1]
            let azi1 = testcase[2]
            let lat2 = testcase[3]
            let lon2 = testcase[4]
            let azi2 = testcase[5]
            let s12 = testcase[6]
            let a12 = testcase[7]
            let m12 = testcase[8]
            let M12 = testcase[9]
            let M21 = testcase[10]
            let S12 = testcase[11]
            
            let dir = Geodesic.WGS84.arcDirect(lat1: lat1, lon1: lon1, azi1: azi1, a12: a12, outmask: [.ALL, .LONG_UNROLL])
            
            XCTAssertEqual(lat2, dir.lat2, accuracy: 1e-13)
            XCTAssertEqual(lon2, dir.lon2, accuracy: 1e-13)
            XCTAssertEqual(azi2, dir.azi2, accuracy: 1e-13)
            XCTAssertEqual(s12, dir.s12, accuracy: 1e-8)
            XCTAssertEqual(m12, dir.m12, accuracy: 1e-8)
            XCTAssertEqual(M12, dir.M12, accuracy: 1e-15)
            XCTAssertEqual(M21, dir.M21, accuracy: 1e-15)
            XCTAssertEqual(S12, dir.S12, accuracy: 0.1)
        }
    }
    
    func testGeodSolve0() {
        let inv = Geodesic.WGS84.inverse(lat1: 40.6, lon1: -73.8, lat2: 49.01666667, lon2: 2.55)
        XCTAssertEqual(inv.azi1, 53.47022, accuracy: 0.5e-5)
        XCTAssertEqual(inv.azi2, 111.59367, accuracy: 0.5e-5)
        XCTAssertEqual(inv.s12, 5853226, accuracy: 0.5)
    }
    
    func testGeodSolve1() {
        let dir = Geodesic.WGS84.direct(lat1: 40.63972222, lon1: -73.77888889, azi1: 53.5, s12: 5850e3)
        XCTAssertEqual(dir.lat2, 49.01467, accuracy: 0.5e-5)
        XCTAssertEqual(dir.lon2, 2.56106, accuracy: 0.5e-5)
        XCTAssertEqual(dir.azi2, 111.62947, accuracy: 0.5e-5)
    }
    
    func testGeodSolve2() {
        // Check fix for antipodal prolate bug found 2010-09-04
        let geod = Geodesic(a: 6.4e6, f: -1 / 150.0)
        var inv = geod.inverse(lat1: 0.07476, lon1: 0, lat2: -0.07476, lon2: 180)
        XCTAssertEqual(inv.azi1, 90.00078, accuracy: 0.5e-5)
        XCTAssertEqual(inv.azi2, 90.00078, accuracy: 0.5e-5)
        XCTAssertEqual(inv.s12, 20106193, accuracy: 0.5)
        
        inv = geod.inverse(lat1: 0.1, lon1: 0, lat2: -0.1, lon2: 180)
        XCTAssertEqual(inv.azi1, 90.00105, accuracy: 0.5e-5)
        XCTAssertEqual(inv.azi2, 90.00105, accuracy: 0.5e-5)
        XCTAssertEqual(inv.s12, 20106193, accuracy: 0.5)
    }
    
    func testGeodSolve4() {
        // Check fix for short line bug found 2010-05-21
        let inv = Geodesic.WGS84.inverse(lat1: 36.493349428792, lon1: 0, lat2: 36.49334942879201, lon2: 0.0000008)
        XCTAssertEqual(inv.s12, 0.072, accuracy: 0.5e-3)
    }
    
    func testGeodSolve5() {
        // Check fix for point2=pole bug found 2010-05-03
        let dir = Geodesic.WGS84.direct(lat1: 0.01777745589997, lon1: 30, azi1: 0, s12: 10e6)
        XCTAssertEqual(dir.lat2, 90, accuracy: 0.5e-5)
        
        if (dir.lon2 < 0) {
            XCTAssertEqual(dir.lon2, -150, accuracy: 0.5e-5)
            XCTAssertEqual(abs(dir.azi2), 180, accuracy: 0.5e-5)
        } else {
            XCTAssertEqual(dir.lon2, 30, accuracy: 0.5e-5)
            XCTAssertEqual(dir.azi2, 0, accuracy: 0.5e-5)
        }
    }
    
    func testGeodSolve6() {
        // Check fix for volatile sbet12a bug found 2011-06-25 (gcc 4.4.4
        // x86 -O3).  Found again on 2012-03-27 with tdm-mingw32 (g++ 4.6.1).
        var inv = Geodesic.WGS84.inverse(lat1: 88.202499451857, lon1: 0, lat2: -88.202499451857, lon2: 179.981022032992859592)
        XCTAssertEqual(inv.s12, 20003898.214, accuracy: 0.5e-3)
        
        inv = Geodesic.WGS84.inverse(lat1: 89.262080389218, lon1: 0, lat2: -89.262080389218, lon2: 179.992207982775375662)
        XCTAssertEqual(inv.s12, 20003925.854, accuracy: 0.5e-3)
        
        inv = Geodesic.WGS84.inverse(lat1: 89.333123580033, lon1: 0, lat2: -89.333123580032997687, lon2: 179.99295812360148422)
        XCTAssertEqual(inv.s12, 20003926.881, accuracy: 0.5e-3)
    }
    
    func testGeodSolve9() {
        // Check fix for volatile x bug found 2011-06-25 (gcc 4.4.4 x86 -O3)
        let inv = Geodesic.WGS84.inverse(lat1: 56.320923501171, lon1: 0, lat2: -56.320923501171, lon2: 179.664747671772880215)
        XCTAssertEqual(inv.s12, 19993558.287, accuracy: 0.5e-3)
    }
    
    func testGeodSolve10() {
        // Check fix for adjust tol1_ bug found 2011-06-25 (Visual Studio
        // 10 rel + debug)
        let inv = Geodesic.WGS84.inverse(lat1: 52.784459512564, lon1: 0, lat2: -52.784459512563990912, lon2: 179.634407464943777557);
        XCTAssertEqual(inv.s12, 19991596.095, accuracy: 0.5e-3)
    }
    
    func testGeodSolve11() {
        // Check fix for bet2 = -bet1 bug found 2011-06-25 (Visual Studio
        // 10 rel + debug)
        let inv = Geodesic.WGS84.inverse(lat1: 48.522876735459, lon1: 0, lat2: -48.52287673545898293, lon2: 179.599720456223079643)
        XCTAssertEqual(inv.s12, 19989144.774, accuracy: 0.5e-3)
    }
    
    func testGeodSolve12() {
        // Check fix for inverse geodesics on extreme prolate/oblate
        // ellipsoids Reported 2012-08-29 Stefan Guenther
        // <stefan.gunther@embl.de>; fixed 2012-10-07
        let geod = Geodesic(a: 89.8, f: -1.83)
        let inv = geod.inverse(lat1: 0, lon1: 0, lat2: -10, lon2: 160)
        XCTAssertEqual(inv.azi1, 120.27, accuracy: 1e-2)
        XCTAssertEqual(inv.azi2, 105.15, accuracy: 1e-2)
        XCTAssertEqual(inv.s12, 266.7, accuracy: 1e-1)
    }
    
    func testGeodSolve14() {
        // Check fix for inverse ignoring lon12 = nan
        let inv = Geodesic.WGS84.inverse(lat1: 0, lon1: 0, lat2: 1, lon2: .nan)
        XCTAssertTrue(inv.azi1.isNaN)
        XCTAssertTrue(inv.azi2.isNaN)
        XCTAssertTrue(inv.s12.isNaN)
    }
    
    func testGeodSolve15() {
        // Initial implementation of Math::eatanhe was wrong for e^2 < 0.  This
        // checks that this is fixed.
        let geod = Geodesic(a: 6.4e6, f: -1 / 150.0)
        let dir = geod.direct(lat1: 1, lon1: 2, azi1: 3, s12: 4, outmask: .AREA)
        XCTAssertEqual(dir.S12, 23700, accuracy: 0.5)
    }
    
    func testGeodSolve17() {
        // Check fix for LONG_UNROLL bug found on 2015-05-07
        var dir = Geodesic.WGS84.direct(lat1: 40, lon1: -75, azi1: -10, s12: 2e7, outmask: [.STANDARD, .LONG_UNROLL])
        XCTAssertEqual(dir.lat2, -39, accuracy: 1)
        XCTAssertEqual(dir.lon2, -254, accuracy: 1)
        XCTAssertEqual(dir.azi2, -170, accuracy: 1)
        
        let line = Geodesic.WGS84.line(lat1: 40, lon1: -75, azi1: -10)
        dir = line.position(2e7, [.STANDARD, .LONG_UNROLL])
        XCTAssertEqual(dir.lat2, -39, accuracy: 1)
        XCTAssertEqual(dir.lon2, -254, accuracy: 1)
        XCTAssertEqual(dir.azi2, -170, accuracy: 1)
        
        dir = Geodesic.WGS84.direct(lat1: 40, lon1: -75, azi1: -10, s12: 2e7)
        XCTAssertEqual(dir.lat2, -39, accuracy: 1)
        XCTAssertEqual(dir.lon2, 105, accuracy: 1)
        XCTAssertEqual(dir.azi2, -170, accuracy: 1)
        
        dir = line.position(2e7)
        XCTAssertEqual(dir.lat2, -39, accuracy: 1)
        XCTAssertEqual(dir.lon2, 105, accuracy: 1)
        XCTAssertEqual(dir.azi2, -170, accuracy: 1)
    }
    
    func testGeodSolve26() {
        // Check 0/0 problem with area calculation on sphere 2015-09-08
        let geod = Geodesic(a: 6.4e6, f: 0)
        let inv = geod.inverse(lat1: 1, lon1: 2, lat2: 3, lon2: 4, outmask: GeodesicMask.AREA)
        XCTAssertEqual(inv.S12, 49911046115.0, accuracy: 0.5)
    }
    
    func testGeodSolve28() {
        // Check for bad placement of assignment of r.a12 with |f| > 0.01 (bug in
        // Java implementation fixed on 2015-05-19).
        let geod = Geodesic(a: 6.4e6, f: 0.1)
        let dir = geod.direct(lat1: 1, lon1: 2, azi1: 10, s12: 5e6)
        XCTAssertEqual(dir.a12, 48.55570690, accuracy: 0.5e-8)
    }
    
    func testGeodSolve29() {
        // Check longitude unrolling with inverse calculation 2015-09-16
        var dir = Geodesic.WGS84.inverse(lat1: 0, lon1: 539, lat2: 0, lon2: 181)
        XCTAssertEqual(dir.lon1, 179, accuracy: 1e-10)
        XCTAssertEqual(dir.lon2, -179, accuracy: 1e-10)
        XCTAssertEqual(dir.s12, 222639, accuracy: 0.5)
        
        dir = Geodesic.WGS84.inverse(lat1: 0, lon1: 539, lat2: 0, lon2: 181, outmask: [.STANDARD, .LONG_UNROLL])
        XCTAssertEqual(dir.lon1, 539, accuracy: 1e-10)
        XCTAssertEqual(dir.lon2, 541, accuracy: 1e-10)
        XCTAssertEqual(dir.s12, 222639, accuracy: 0.5)
    }
    
    func testGeodSolve33() {
        // Check max(-0.0,+0.0) issues 2015-08-22 (triggered by bugs in Octave --
        // sind(-0.0) = +0.0 -- and in some version of Visual Studio --
        // fmod(-0.0, 360.0) = +0.0.
        var inv = Geodesic.WGS84.inverse(lat1: 0, lon1: 0, lat2: 0, lon2: 179)
        XCTAssertEqual(inv.azi1, 90.00000, accuracy: 0.5e-5)
        XCTAssertEqual(inv.azi2, 90.00000, accuracy: 0.5e-5)
        XCTAssertEqual(inv.s12, 19926189, accuracy: 0.5)
        
        inv = Geodesic.WGS84.inverse(lat1: 0, lon1: 0, lat2: 0, lon2: 179.5)
        XCTAssertEqual(inv.azi1, 55.96650, accuracy: 0.5e-5)
        XCTAssertEqual(inv.azi2, 124.03350, accuracy: 0.5e-5)
        XCTAssertEqual(inv.s12, 19980862, accuracy: 0.5)
        
        inv = Geodesic.WGS84.inverse(lat1: 0, lon1: 0, lat2: 0, lon2: 180)
        XCTAssertEqual(inv.azi1, 0.00000, accuracy: 0.5e-5)
        XCTAssertEqual(abs(inv.azi2), 180.00000, accuracy: 0.5e-5)
        XCTAssertEqual(inv.s12, 20003931, accuracy: 0.5)
        
        inv = Geodesic.WGS84.inverse(lat1: 0, lon1: 0, lat2: 1, lon2: 180)
        XCTAssertEqual(inv.azi1, 0.00000, accuracy: 0.5e-5)
        XCTAssertEqual(abs(inv.azi2), 180.00000, accuracy: 0.5e-5)
        XCTAssertEqual(inv.s12, 19893357, accuracy: 0.5)
        
        var geod = Geodesic(a: 6.4e6, f: 0)
        inv = geod.inverse(lat1: 0, lon1: 0, lat2: 0, lon2: 179)
        XCTAssertEqual(inv.azi1, 90.00000, accuracy: 0.5e-5)
        XCTAssertEqual(inv.azi2, 90.00000, accuracy: 0.5e-5)
        XCTAssertEqual(inv.s12, 19994492, accuracy: 0.5)
        
        inv = geod.inverse(lat1: 0, lon1: 0, lat2: 0, lon2: 180)
        XCTAssertEqual(inv.azi1, 0.00000, accuracy: 0.5e-5)
        XCTAssertEqual(abs(inv.azi2), 180.00000, accuracy: 0.5e-5)
        XCTAssertEqual(inv.s12, 20106193, accuracy: 0.5)
        
        inv = geod.inverse(lat1: 0, lon1: 0, lat2: 1, lon2: 180)
        XCTAssertEqual(inv.azi1, 0.00000, accuracy: 0.5e-5)
        XCTAssertEqual(abs(inv.azi2), 180.00000, accuracy: 0.5e-5)
        XCTAssertEqual(inv.s12, 19994492, accuracy: 0.5)
        
        geod = Geodesic(a: 6.4e6, f: -1 / 300.0)
        inv = geod.inverse(lat1: 0, lon1: 0, lat2: 0, lon2: 179)
        XCTAssertEqual(inv.azi1, 90.00000, accuracy: 0.5e-5)
        XCTAssertEqual(inv.azi2, 90.00000, accuracy: 0.5e-5)
        XCTAssertEqual(inv.s12, 19994492, accuracy: 0.5)
        
        inv = geod.inverse(lat1: 0, lon1: 0, lat2: 0, lon2: 180)
        XCTAssertEqual(inv.azi1, 90.00000, accuracy: 0.5e-5)
        XCTAssertEqual(inv.azi2, 90.00000, accuracy: 0.5e-5)
        XCTAssertEqual(inv.s12, 20106193, accuracy: 0.5)
        
        inv = geod.inverse(lat1: 0, lon1: 0, lat2: 0.5, lon2: 180)
        XCTAssertEqual(inv.azi1, 33.02493, accuracy: 0.5e-5)
        XCTAssertEqual(inv.azi2, 146.97364, accuracy: 0.5e-5)
        XCTAssertEqual(inv.s12, 20082617, accuracy: 0.5)
        
        inv = geod.inverse(lat1: 0, lon1: 0, lat2: 1, lon2: 180)
        XCTAssertEqual(inv.azi1, 0.00000, accuracy: 0.5e-5)
        XCTAssertEqual(abs(inv.azi2), 180.00000, accuracy: 0.5e-5)
        XCTAssertEqual(inv.s12, 20027270, accuracy: 0.5)
    }
    
    func testGeodSolve55() {
        // Check fix for nan + point on equator or pole not returning all nans in
        // Geodesic::Inverse, found 2015-09-23.
        var inv = Geodesic.WGS84.inverse(lat1: .nan, lon1: 0, lat2: 0, lon2: 90)
        XCTAssertTrue(inv.azi1.isNaN)
        XCTAssertTrue(inv.azi2.isNaN)
        XCTAssertTrue(inv.s12.isNaN)
        
        inv = Geodesic.WGS84.inverse(lat1: .nan, lon1: 0, lat2: 90, lon2: 3)
        XCTAssertTrue(inv.azi1.isNaN)
        XCTAssertTrue(inv.azi2.isNaN)
        XCTAssertTrue(inv.s12.isNaN)
    }
    
    func testGeodSolve59() {
        // Check for points close with longitudes close to 180 deg apart.
        let inv = Geodesic.WGS84.inverse(lat1: 5, lon1: 0.00000000000001, lat2: 10, lon2: 180)
        XCTAssertEqual(inv.azi1, 0.000000000000035, accuracy: 1.5e-14)
        XCTAssertEqual(inv.azi2, 179.99999999999996, accuracy: 1.5e-14)
        XCTAssertEqual(inv.s12, 18345191.174332713, accuracy: 4e-9)
    }
    
    func testGeodSolve61() {
        // Make sure small negative azimuths are west-going
        var dir = Geodesic.WGS84.direct(lat1: 45, lon1: 0, azi1: -0.000000000000000003, s12: 1e7, outmask: [.STANDARD, .LONG_UNROLL])
        XCTAssertEqual(dir.lat2, 45.30632, accuracy: 0.5e-5)
        XCTAssertEqual(dir.lon2, -180, accuracy: 0.5e-5)
        XCTAssertEqual(abs(dir.azi2), 180, accuracy: 0.5e-5)
        
        let line = Geodesic.WGS84.inverseLine(lat1: 45, lon1: 0, lat2: 80, lon2: -0.000000000000000003)
        dir = line.position(1e7, [.STANDARD, .LONG_UNROLL])
        XCTAssertEqual(dir.lat2, 45.30632, accuracy: 0.5e-5)
        XCTAssertEqual(dir.lon2, -180, accuracy: 0.5e-5)
        XCTAssertEqual(abs(dir.azi2), 180, accuracy: 0.5e-5)
    }
    
    func testGeodSolve65() {
        // Check for bug in east-going check in GeodesicLine (needed to check for
        // sign of 0) and sign error in area calculation due to a bogus override
        // of the code for alp12.  Found/fixed on 2015-12-19.
        let line = Geodesic.WGS84.inverseLine(lat1: 30, lon1: -0.000000000000000001, lat2: -31, lon2: 180)
        var dir = line.position(1e7, [.ALL, .LONG_UNROLL])
        XCTAssertEqual(dir.lat1, 30.00000, accuracy: 0.5e-5)
        XCTAssertEqual(dir.lon1, -0.00000, accuracy: 0.5e-5)
        XCTAssertEqual(abs(dir.azi1), 180.00000, accuracy: 0.5e-5)
        XCTAssertEqual(dir.lat2, -60.23169, accuracy: 0.5e-5)
        XCTAssertEqual(dir.lon2, -0.00000, accuracy: 0.5e-5)
        XCTAssertEqual(abs(dir.azi2), 180.00000, accuracy: 0.5e-5)
        XCTAssertEqual(dir.s12, 10000000, accuracy: 0.5)
        XCTAssertEqual(dir.a12, 90.06544, accuracy: 0.5e-5)
        XCTAssertEqual(dir.m12, 6363636, accuracy: 0.5)
        XCTAssertEqual(dir.M12, -0.0012834, accuracy: 0.5e7)
        XCTAssertEqual(dir.M21, 0.0013749, accuracy: 0.5e-7)
        XCTAssertEqual(dir.S12, 0, accuracy: 0.5)
        
        dir = line.position(2e7, [.ALL, .LONG_UNROLL])
        XCTAssertEqual(dir.lat1, 30.00000, accuracy: 0.5e-5)
        XCTAssertEqual(dir.lon1, -0.00000, accuracy: 0.5e-5)
        XCTAssertEqual(abs(dir.azi1), 180.00000, accuracy: 0.5e-5)
        XCTAssertEqual(dir.lat2, -30.03547, accuracy: 0.5e-5)
        XCTAssertEqual(dir.lon2, -180.00000, accuracy: 0.5e-5)
        XCTAssertEqual(dir.azi2, -0.00000, accuracy: 0.5e-5)
        XCTAssertEqual(dir.s12, 20000000, accuracy: 0.5)
        XCTAssertEqual(dir.a12, 179.96459, accuracy: 0.5e-5)
        XCTAssertEqual(dir.m12, 54342, accuracy: 0.5)
        XCTAssertEqual(dir.M12, -1.0045592, accuracy: 0.5e7)
        XCTAssertEqual(dir.M21, -0.9954339, accuracy: 0.5e-7)
        XCTAssertEqual(dir.S12, 127516405431022.0, accuracy: 0.5)
    }
    
    func testGeodSolve69() {
        // Check for InverseLine if line is slightly west of S and that s13 is
        // correctly set.
        let line = Geodesic.WGS84.inverseLine(lat1: -5, lon1: -0.000000000000002, lat2: -10, lon2: 180)
        var dir = line.position(2e7, [.STANDARD, .LONG_UNROLL])
        XCTAssertEqual(dir.lat2, 4.96445, accuracy: 0.5e-5)
        XCTAssertEqual(dir.lon2, -180.00000, accuracy: 0.5e-5)
        XCTAssertEqual(dir.azi2, -0.00000, accuracy: 0.5e-5)
        
        dir = line.position(0.5 * line.distance, [.STANDARD, .LONG_UNROLL])
        XCTAssertEqual(dir.lat2, -87.52461, accuracy: 0.5e-5)
        XCTAssertEqual(dir.lon2, -0.00000, accuracy: 0.5e-5)
        XCTAssertEqual(dir.azi2, -180.00000, accuracy: 0.5e-5)
    }
    
    func testGeodSolve71() {
        // Check that DirectLine sets s13.
        let line = Geodesic.WGS84.directLine(lat1: 1, lon1: 2, azi1: 45, s12: 1e7)
        let dir = line.position(0.5 * line.distance, [.STANDARD, .LONG_UNROLL])
        XCTAssertEqual(dir.lat2, 30.92625, accuracy: 0.5e-5)
        XCTAssertEqual(dir.lon2, 37.54640, accuracy: 0.5e-5)
        XCTAssertEqual(dir.azi2, 55.43104, accuracy: 0.5e-5)
    }
    
    func testGeodSolve73() {
        // Check for backwards from the pole bug reported by Anon on 2016-02-13.
        // This only affected the Java implementation.  It was introduced in Java
        // version 1.44 and fixed in 1.46-SNAPSHOT on 2016-01-17.
        let dir = Geodesic.WGS84.direct(lat1: 90, lon1: 10, azi1: 180, s12: -1e6)
        XCTAssertEqual(dir.lat2, 81.04623, accuracy: 0.5e-5)
        XCTAssertEqual(dir.lon2, -170, accuracy: 0.5e-5)
        XCTAssertEqual(dir.azi2, 0, accuracy: 0.5e-5)
    }
    
    func testGeodSolve74() {
        // Check fix for inaccurate areas, bug introduced in v1.46, fixed
        // 2015-10-16.
        let inv = Geodesic.WGS84.inverse(lat1: 54.1589, lon1: 15.3872, lat2: 54.1591, lon2: 15.3877, outmask: .ALL)
        XCTAssertEqual(inv.azi1, 55.723110355, accuracy: 5e-9)
        XCTAssertEqual(inv.azi2, 55.723515675, accuracy: 5e-9)
        XCTAssertEqual(inv.s12, 39.527686385, accuracy: 5e-9)
        XCTAssertEqual(inv.a12, 0.000355495, accuracy: 5e-9)
        XCTAssertEqual(inv.m12, 39.527686385, accuracy: 5e-9)
        XCTAssertEqual(inv.M12, 0.999999995, accuracy: 5e-9)
        XCTAssertEqual(inv.M21, 0.999999995, accuracy: 5e-9)
        XCTAssertEqual(inv.S12, 286698586.30197, accuracy: 5e-4)
    }
    
    func testGeodSolve76() {
        // The distance from Wellington and Salamanca (a classic failure of
        // Vincenty)
        let inv = Geodesic.WGS84.inverse(lat1: -(41 + 19 / 60.0), lon1: 174 + 49 / 60.0, lat2: 40 + 58 / 60.0, lon2: -(5 + 30 / 60.0))
        XCTAssertEqual(inv.azi1, 160.39137649664, accuracy: 0.5e-11)
        XCTAssertEqual(inv.azi2, 19.50042925176, accuracy: 0.5e-11)
        XCTAssertEqual(inv.s12, 19960543.857179, accuracy: 0.5e-6)
    }
    
    func testGeodSolve78() {
        // An example where the NGS calculator fails to converge */
        let inv = Geodesic.WGS84.inverse(lat1: 27.2, lon1: 0.0, lat2: -27.1, lon2: 179.5)
        XCTAssertEqual(inv.azi1, 45.82468716758, accuracy: 0.5e-11)
        XCTAssertEqual(inv.azi2, 134.22776532670, accuracy: 0.5e-11)
        XCTAssertEqual(inv.s12, 19974354.765767, accuracy: 0.5e-6)
    }
    
    func testPlanimeter0() {
        // Check fix for pole-encircling bug found 2011-03-16
        let pa: [[Double]] = [[89, 0], [89, 90], [89, 180], [89, 270]]
        var a = GeodesicTest.planimeter(pa)
        XCTAssertEqual(a.perimeter, 631819.8745, accuracy: 1e-4)
        XCTAssertEqual(a.area, 24952305678.0, accuracy: 1)
        
        let pb: [[Double]] = [[-89, 0], [-89, 90], [-89, 180], [-89, 270]]
        a = GeodesicTest.planimeter(pb)
        XCTAssertEqual(a.perimeter, 631819.8745, accuracy: 1e-4)
        XCTAssertEqual(a.area, -24952305678.0, accuracy: 1)
        
        let pc: [[Double]] = [[0, -1], [-1, 0], [0, 1], [1, 0]]
        a = GeodesicTest.planimeter(pc)
        XCTAssertEqual(a.perimeter, 627598.2731, accuracy: 1e-4)
        XCTAssertEqual(a.area, 24619419146.0, accuracy: 1)
        
        let pd: [[Double]] = [[90, 0], [0, 0], [0, 90]]
        a = GeodesicTest.planimeter(pd)
        XCTAssertEqual(a.perimeter, 30022685, accuracy: 1)
        XCTAssertEqual(a.area, 63758202715511.0, accuracy: 1)
        
        a = GeodesicTest.polyLength(pd)
        XCTAssertEqual(a.perimeter, 20020719, accuracy: 1)
        XCTAssertTrue(a.area.isNaN)
    }
    
    func testPlanimeter5() {
        // Check fix for Planimeter pole crossing bug found 2011-06-24
        let points: [[Double]] = [[89, 0.1], [89, 90.1], [89, -179.9]]
        let a = GeodesicTest.planimeter(points)
        XCTAssertEqual(539297, a.perimeter, accuracy: 1)
        XCTAssertEqual(12476152838.5, a.area, accuracy: 1)
    }
    
    func testPlanimeter6() {
        // Check fix for Planimeter lon12 rounding bug found 2012-12-03
        let pa: [[Double]] = [[9, -0.00000000000001], [9, 180], [9, 0]]
        var a = GeodesicTest.planimeter(pa)
        XCTAssertEqual(a.perimeter, 36026861, accuracy: 1)
        XCTAssertEqual(a.area, 0, accuracy: 1)
        
        let pb: [[Double]] = [[9, 0.00000000000001], [9, 0], [9, 180]]
        a = GeodesicTest.planimeter(pb)
        XCTAssertEqual(a.perimeter, 36026861, accuracy: 1)
        XCTAssertEqual(a.area, 0, accuracy: 1)
        
        let pc: [[Double]] = [[9, 0.00000000000001], [9, 180], [9, 0]]
        a = GeodesicTest.planimeter(pc)
        XCTAssertEqual(a.perimeter, 36026861, accuracy: 1)
        XCTAssertEqual(a.area, 0, accuracy: 1)
        
        let pd: [[Double]] = [[9, -0.00000000000001], [9, 0], [9, 180]]
        a = GeodesicTest.planimeter(pd)
        XCTAssertEqual(a.perimeter, 36026861, accuracy: 1)
        XCTAssertEqual(a.area, 0, accuracy: 1)
    }
    
    func testPlanimeter12() {
        // Area of arctic circle (not really -- adjunct to rhumb-area test)
        let points: [[Double]] = [[66.562222222, 0], [66.562222222, 180]]
        let a = GeodesicTest.planimeter(points)
        XCTAssertEqual(10465729, a.perimeter, accuracy: 1)
        XCTAssertEqual(0, a.area)
    }
    
    func testPlanimeter13() {
        // Check encircling pole twice
        let points: [[Double]] = [[89, -360], [89, -240], [89, -120], [89, 0], [89, 120], [89, 240]]
        let a = GeodesicTest.planimeter(points)
        XCTAssertEqual(1160741, a.perimeter, accuracy: 1)
        XCTAssertEqual(32415230256.0, a.area, accuracy: 1)
    }
}
