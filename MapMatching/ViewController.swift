//
//  ViewController.swift
//  MapMatching
//
//  Created by devilrabbit on 2018/10/09.
//  Copyright (c) 2018 devilrabbit. All rights reserved.
//

import UIKit
import MapKit

class ViewController: UIViewController {

    @IBOutlet weak var mapView: MKMapView!
    
    private var editor: GeometryEditController = GeometryEditController()
    private var selectedAnnotation: MKAnnotation?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        mapView.delegate = self
        editor.mapView = mapView
        editor.editingType = .polygon
        
        let dictionary = ["geometry": ["coordinates": [[
            [139.6856689453125, 35.69745580725804],
            [139.78179931640625, 35.574682600980914],
            [139.84771728515625, 35.619349222857494],
            [139.85595703125, 35.735365718650236],
            [139.76531982421872, 35.762114795721],
            [139.6856689453125, 35.69745580725804]
        ]]]]
        editor.polygon = Polygon(dictionary: dictionary)
        
        let gestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(self.mapViewDidTap))
        gestureRecognizer.delegate = self
        mapView.addGestureRecognizer(gestureRecognizer)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        doMatch()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @objc func mapViewDidTap(_ sender: UITapGestureRecognizer) {
        guard sender.state == .ended else { return }
        let point = sender.location(in: self.mapView)
        let coordinate = self.mapView.convert(point, toCoordinateFrom: self.mapView)
        self.editor.add(coordinate)
    }
    
    private func doMatch() {
        let spatial = GeographySpatialOperator()
        let mapBuilder = RoadMapBuilder(spatial: spatial)
        
        print("Loading road map...")
        let roads = SampleReader.readRoads(with: spatial)
        let map = mapBuilder.addRoads(roads).build()
        print("The road map has been loaded")
        
        let router = DijkstraRouter<Road, RoadPoint>()
        let matcher = Matcher(map: map, router: router, cost: Costs.timePriorityCost, spatial: spatial)
        matcher.maxDistance = 1000 // set maximum searching distance between two GPS points to 1000 meters.
        matcher.maxRadius = 200 // sets maximum radius for candidate selection to 200 meters
        
        print("Loading GPS samples...")
        let samples = SampleReader.readSamples().sorted(by: { $0.time < $1.time })
        print("GPS samples loaded. [count=\(samples.count)]")
        
        print("Starting Offline map-matching...")
        offlineMatch(matcher: matcher, samples: samples)
        
        print("Starting Online map-matching...");
        onlineMatch(matcher: matcher, samples: samples)
    }
    
    private func onlineMatch(matcher: Matcher, samples: [MatcherSample]) {
        // Create initial (empty) state memory
        let state = MatcherKState()
    
        // Iterate over sequence (stream) of samples
        for sample in samples {
            // Execute matcher with single sample and update state memory
            var vector = state.vector()
            vector = matcher.execute(predecessors: vector, previous: state.sample, sample: sample)
            state.update(vector: vector, sample: sample)
    
            // Access map matching result: estimate for most recent sample
            if let estimated = state.estimate() {
                // The id of the road in your map
                print("RoadID=\(estimated.point.edge.roadInfo.id)")
            }
        }
    }
    
    private func offlineMatch(matcher: Matcher, samples: [MatcherSample]) {
        let state = MatcherKState()
    
        //Do the offline map-matching
        print("Doing map-matching...")
        let startedOn = Date().timeIntervalSince1970
        
        for (i, sample) in samples.enumerated() {
            let vector = matcher.execute(predecessors: state.vector(), previous: state.sample, sample: sample)
            state.update(vector: vector, sample: sample)
            print("updated \(i)")
        }
    
        print("Fetching map-matching results...")
        let candidates = state.sequence()
        
        let timeElapsed = Date().timeIntervalSince1970 - startedOn
        let speed = Double(samples.count) / timeElapsed
        print("Map-matching elapsed time: \(timeElapsed), Speed=\(speed) samples/second")
        print("Results: [count=\(candidates.count)]")
    
        for candidate in candidates {
            let roadId = candidate.point.edge.roadInfo.id   // original road id
            let heading = candidate.point.edge.heading      // heading
            let coordinate = candidate.point.coordinate     // GPS position (on the road)
            let date = candidate.sample.time
            let azimuth = candidate.point.azimuth
            
            print("road=\(roadId), heading=\(heading), date=\(date), x=\(coordinate.x), y=\(coordinate.y), azimuth=\(azimuth)")
            if candidate.hasTransition {
                // path geometry(LineString) from last matching candidate
                if let route = candidate.transition?.route {
                    print(route.toGeometry())
                    //print(route.edges) // Road segments between two GPS position
                }
            }
        }
        
        let matchedCount = candidates.count
        let rate = matchedCount * 100 / samples.count
        print("Matched Candidates: \(matchedCount), Rate: \(rate)%")
    }
}

extension ViewController: MKMapViewDelegate {
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        if let view = mapView.dequeueReusableAnnotationView(withIdentifier: "Pin") {
            return view
        }
        
        let view = MKPinAnnotationView(annotation: annotation, reuseIdentifier: "Pin")
        view.isDraggable = true
        view.canShowCallout = true
        
        let button = UIButton(frame: CGRect(x: 0, y: 0, width: 30, height: 30))
        button.setTitle("remove", for: .normal)
        button.setTitleColor(.black, for: .normal)
        button.addTarget(self, action: #selector(self.calloutViewDidTapSelect), for: .touchUpInside)
        view.rightCalloutAccessoryView = button
        
        return view
    }
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        self.selectedAnnotation = view.annotation
    }
    
    func mapView(_ mapView: MKMapView, didDeselect view: MKAnnotationView) {
        self.selectedAnnotation = nil
    }
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        switch overlay {
        case let overlay as MKPolyline:
            let renderer = MKPolylineRenderer(overlay: overlay)
            renderer.strokeColor = .red
            renderer.lineWidth = 2
            return renderer
        case let overlay as MKPolygon:
            let renderer = MKPolygonRenderer(overlay: overlay)
            renderer.strokeColor = .red
            renderer.lineWidth = 2
            return renderer
        default:
            return MKPolylineRenderer()
        }
    }
    
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, didChange newState: MKAnnotationView.DragState, fromOldState oldState: MKAnnotationView.DragState) {
        guard newState == .ending else { return }
        guard let annotation = view.annotation else { return }
        editor.update(annotation)
    }
    
    @objc func calloutViewDidTapSelect() {
        guard let annotation = self.selectedAnnotation else { return }
        editor.remove(annotation)
    }
}

extension ViewController: UIGestureRecognizerDelegate {
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        guard self.selectedAnnotation == nil else { return false }
        return !(touch.view is MKPinAnnotationView)
    }
}

