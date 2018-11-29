//
//  MapMatchTest.swift
//  MapMatching
//
//  Created by devilrabbit on 2018/10/25.
//  Copyright (c) 2018 devilrabbit. All rights reserved.
//

import XCTest

/*
class MapMatchTest: XCTestCase {

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

    func testExample() {
        // Use recording to get started writing UI tests.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        
        var spatial = GeographySpatialOperation()
        var mapBuilder = RoadMapBuilder(spatial: spatial)
        
        print("Loading road map...")
        var roads = readRoads(spatial)
        var map = mapBuilder.AddRoads(roads).Build()
        print("The road map has been loaded")
        
        
        let router = DijkstraRouter<Road, RoadPoint>()
        let matcher = Matcher<MatcherCandidate, MatcherTransition, MatcherSample>(
            map, router, Costs.TimePriorityCost, spatial)
        matcher.MaxDistance = 1000 // set maximum searching distance between two GPS points to 1000 meters.
        matcher.MaxRadius = 200 // sets maximum radius for candidate selection to 200 meters
        
        
        print("Loading GPS samples...")
        var samples = ReadSamples().OrderBy(s => s.Time).ToList();
        print("GPS samples loaded. [count={0}]", samples.Count)
        
        print("Starting Offline map-matching...");
        OfflineMatch(matcher, samples);
        
        
        print("Starting Online map-matching...");
        //Uncomment below line to see how online-matching works
        //OnlineMatch(matcher, samples);
        
        print("All done!")
    }

    private func offlineMatch(matcher: Matcher<MatcherCandidate, MatcherTransition, MatcherSample>, samples: [MatcherSample]) {
        var kstate = MatcherKState()
        
        //Do the offline map-matching
        print("Doing map-matching...")
        
        var startedOn = Date()
        for sample in samples {
            var vector = matcher.execute(predecessors: kstate.vector(), previous: kstate.sample, sample: sample)
            kstate.update(vector, sample)
        }
        
        print("Fetching map-matching results...")
        var candidatesSequence = kstate.Sequence();
        var timeElapsed = DateTime.Now - startedOn;
        Console.WriteLine("Map-matching elapsed time: {0}, Speed={1} samples/second", timeElapsed, samples.Count / timeElapsed.TotalSeconds);
        Console.WriteLine("Results: [count={0}]", candidatesSequence.Count());
        var csvLines = new List<string>();
        csvLines.Add("time,lng,lat,azimuth");
        int matchedCandidateCount = 0;
        foreach (var cand in candidatesSequence)
        {
            var roadId = cand.Point.Edge.RoadInfo.Id; // original road id
            var heading = cand.Point.Edge.Headeing; // heading
            var coord = cand.Point.Coordinate; // GPS position (on the road)
            csvLines.Add(string.Format("{0},{1},{2},{3}", cand.Sample.Time.ToUnixTimeSeconds(), coord.X, coord.Y, cand.Point.Azimuth));
            if (cand.HasTransition)
            {
                var geom = cand.Transition.Route.ToGeometry(); // path geometry(LineString) from last matching candidate
                //cand.Transition.Route.Edges // Road segments between two GPS position
            }
            matchedCandidateCount++;
        }
        Console.WriteLine("Matched Candidates: {0}, Rate: {1}%", matchedCandidateCount, matchedCandidateCount * 100 / samples.Count());
        
        var csvFile = System.IO.Path.Combine(s_dataDir, "samples.output.csv");
        Console.WriteLine("Writing output file: {0}", csvFile);
        File.WriteAllLines(csvFile, csvLines);
    }
    
    
    private static IEnumerable<MatcherSample> ReadSamples() {
    var json = File.ReadAllText(System.IO.Path.Combine(s_dataDir, @"samples.oneday.geojson"));
    var reader = new GeoJsonReader();
    var fc = reader.Read<FeatureCollection>(json);
    var timeFormat = "yyyy-MM-dd-HH.mm.ss";
    var samples = new List<MatcherSample>();
    foreach (var i in fc.Features)
    {
    var p = i.Geometry as IPoint;
    var coord2D = new Coordinate2D(p.X, p.Y);
    var timeStr = i.Attributes["time"].ToString().Substring(0, timeFormat.Length);
    var time = DateTimeOffset.ParseExact(timeStr, timeFormat, CultureInfo.InvariantCulture);
    var longTime = time.ToUnixTimeMilliseconds();
    yield return new MatcherSample(longTime, time, coord2D);
    }
    }
    
    
    private static IEnumerable<RoadInfo> ReadRoads(ISpatialOperation spatial)
{
    var json = File.ReadAllText(Path.Combine(s_dataDir, @"osm-kunming-roads-network.geojson"));
    var reader = new GeoJsonReader();
    var fc = reader.Read<FeatureCollection>(json);
    foreach (var feature in fc.Features)
    {
    var lineGeom = feature.Geometry as ILineString;
    yield return new RoadInfo(
    Convert.ToInt64(feature.Attributes["gid"]),
    Convert.ToInt64(feature.Attributes["source"]),
    Convert.ToInt64(feature.Attributes["target"]),
    (double)feature.Attributes["reverse"] >= 0D ? false : true,
    (short)0,
    Convert.ToSingle(feature.Attributes["priority"]),
    120f,
    120f,
    Convert.ToSingle(spatial.Length(lineGeom)),
    lineGeom);
    }
    }
}
*/
