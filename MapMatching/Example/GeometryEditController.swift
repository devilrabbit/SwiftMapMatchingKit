//
//  GeometryEditController.swift
//  MapMatching
//
//  Created by devilrabbit on 2018/12/01.
//  Copyright (c) 2018 devilrabbit. All rights reserved.
//

import Foundation
import MapKit

public class GeometryEditController {

    public enum GeometryEditingType {
        case point
        case line
        case polyline
        case polygon
    }
    
    public weak var mapView: MKMapView?
    public var editingType: GeometryEditingType = .point
    
    private var _point: Point?
    public var point: Point? {
        get {
            return _point
        }
        set {
            self._point = newValue
            refresh()
        }
    }
    
    private var _polyline: LineString?
    public var polyline: LineString? {
        get {
            return _polyline
        }
        set {
            self._polyline = newValue
            refresh()
        }
    }
    
    private var _polygon: Polygon?
    public var polygon: Polygon? {
        get {
            return _polygon
        }
        set {
            self._polygon = newValue
            refresh()
        }
    }
    
    private var annotations: [PointAnnotation] = []
    private var overlay: MKOverlay?
    
    public func refresh() {
        if !self.annotations.isEmpty {
            mapView?.removeAnnotations(self.annotations)
            self.annotations = []
        }
        
        if let overlay = self.overlay {
            mapView?.removeOverlay(overlay)
            self.overlay = nil
        }
        
        switch editingType {
        case .point:
            if let point = self._point {
                let annotation = PointAnnotation(coordinate: point.geometry)
                annotations.append(annotation)
                mapView?.addAnnotation(annotation)
            }
        case .line, .polyline:
            if let polyline = self._polyline {
                let annotations = polyline.geometry.map { PointAnnotation(coordinate: $0) }
                self.annotations.append(contentsOf: annotations)
                mapView?.addAnnotations(annotations)
                
                var coordinates = polyline.geometry
                if coordinates.count > 1 {
                    let overlay = MKPolyline(coordinates: &coordinates, count: coordinates.count)
                    self.overlay = overlay
                    mapView?.addOverlay(overlay)
                }
            }
        case .polygon:
            if let geometry = self._polygon?.geometry.first {
                let coordinates = geometry.prefix(geometry.count - 1)
                let annotations = coordinates.map { PointAnnotation(coordinate: $0) }
                self.annotations.append(contentsOf: annotations)
                mapView?.addAnnotations(annotations)
                
                var theCoordinates = Array(coordinates)
                if theCoordinates.count > 2 {
                    let overlay = MKPolygon(coordinates: &theCoordinates, count: theCoordinates.count)
                    self.overlay = overlay
                    mapView?.addOverlay(overlay)
                }
            }
        }
    }
    
    public func add(_ coordinate: CLLocationCoordinate2D) {
        
        if let overlay = self.overlay {
            mapView?.removeOverlay(overlay)
            self.overlay = nil
        }
        
        switch editingType {
        case .point:
            if let point = self._point {
                point.geometry = coordinate
                mapView?.removeAnnotations(annotations)
                annotations.removeAll()
            } else {
                _point = Point(geometry: coordinate)
            }
            
            let annotation = PointAnnotation(coordinate: coordinate)
            annotations.append(annotation)
            mapView?.addAnnotation(annotation)
            
        case .line:
            if let polyline = self._polyline {
                if polyline.geometry.count > 1 {
                    polyline.geometry[1] = coordinate
                    mapView?.removeAnnotation(annotations[1])
                    annotations.remove(at: 1)
                } else {
                    polyline.geometry.append(coordinate)
                }
            } else {
                _polyline = LineString(geometry: [coordinate])
            }
            
            let annotation = PointAnnotation(coordinate: coordinate)
            annotations.append(annotation)
            mapView?.addAnnotation(annotation)
            
            var coordinates = _polyline?.geometry ?? []
            if coordinates.count > 1 {
                let overlay = MKPolyline(coordinates: &coordinates, count: coordinates.count)
                self.overlay = overlay
                mapView?.addOverlay(overlay)
            }
            
        case .polyline:
            if let polyline = self._polyline {
                polyline.geometry.append(coordinate)
            } else {
                _polyline = LineString(geometry: [coordinate])
            }
            
            let annotation = PointAnnotation(coordinate: coordinate)
            annotations.append(annotation)
            mapView?.addAnnotation(annotation)
            
            var coordinates = _polyline?.geometry ?? []
            if coordinates.count > 1 {
                let overlay = MKPolyline(coordinates: &coordinates, count: coordinates.count)
                self.overlay = overlay
                mapView?.addOverlay(overlay)
            }
            
        case .polygon:
            if let polygon = self._polygon, !polygon.geometry.isEmpty {
                if polygon.geometry[0].isEmpty {
                    polygon.geometry[0].append(contentsOf: [coordinate, coordinate])
                } else {
                    let last = polygon.geometry[0].removeLast()
                    polygon.geometry[0].append(contentsOf: [coordinate, last])
                }
            } else {
                _polygon = Polygon(geometry: [[coordinate, coordinate]])
            }
            
            let annotation = PointAnnotation(coordinate: coordinate)
            annotations.append(annotation)
            mapView?.addAnnotation(annotation)
            
            var coordinates = _polygon?.geometry.first ?? []
            if coordinates.count > 2 {
                let overlay = MKPolygon(coordinates: &coordinates, count: coordinates.count)
                self.overlay = overlay
                mapView?.addOverlay(overlay)
            }
        }
    }
    
    public func clear() {
        self._point = nil
        self._polyline = nil
        self._polygon = nil
        
        if !self.annotations.isEmpty {
            mapView?.removeAnnotations(self.annotations)
            self.annotations = []
        }
        
        if let overlay = self.overlay {
            mapView?.removeOverlay(overlay)
            self.overlay = nil
        }
    }
    
    public func remove(_ annotation: MKAnnotation) {
        guard let annotation = annotation as? PointAnnotation else { return }
        guard let index = annotations.index(where: { $0 === annotation }) else { return }
        
        annotations.remove(at: index)
        mapView?.removeAnnotation(annotation)
        
        if let overlay = self.overlay {
            mapView?.removeOverlay(overlay)
            self.overlay = nil
        }
        
        switch editingType {
        case .point:
            self._point = nil
            
        case .line:
            if let polyline = self._polyline {
                polyline.geometry.remove(at: index)
                if polyline.geometry.isEmpty {
                    self._polyline = nil
                }
            }
            
        case .polyline:
            if let polyline = self._polyline {
                polyline.geometry.remove(at: index)
                if polyline.geometry.isEmpty {
                    self._polyline = nil
                }
            }
            
            var coordinates = _polyline?.geometry ?? []
            if coordinates.count > 1 {
                let overlay = MKPolyline(coordinates: &coordinates, count: coordinates.count)
                self.overlay = overlay
                mapView?.addOverlay(overlay)
            }
            
        case .polygon:
            if let polygon = self._polygon, !polygon.geometry.isEmpty {
                polygon.geometry[0].remove(at: index)
                if index == 0 {
                    polygon.geometry[0].removeLast()
                    if let first = polygon.geometry[0].first {
                        polygon.geometry[0].append(first)
                    }
                }
                if polygon.geometry[0].isEmpty {
                    self._polygon = nil
                }
            }
            
            var coordinates = _polygon?.geometry.first ?? []
            if coordinates.count > 2 {
                let overlay = MKPolygon(coordinates: &coordinates, count: coordinates.count)
                self.overlay = overlay
                mapView?.addOverlay(overlay)
            }
        }
    }
    
    public func update(_ annotation: MKAnnotation) {
        guard let annotation = annotation as? PointAnnotation else { return }
        guard let index = annotations.index(where: { $0 === annotation }) else { return }
        
        if let overlay = self.overlay {
            mapView?.removeOverlay(overlay)
            self.overlay = nil
        }
        
        switch editingType {
        case .point:
            if let point = self._point {
                point.geometry = annotation.coordinate
            }
            
        case .line:
            if let polyline = self._polyline {
                polyline.geometry[index] = annotation.coordinate
            }
            
            var coordinates = _polyline?.geometry ?? []
            if coordinates.count > 1 {
                let overlay = MKPolyline(coordinates: &coordinates, count: coordinates.count)
                self.overlay = overlay
                mapView?.addOverlay(overlay)
            }
            
        case .polyline:
            if let polyline = self._polyline {
                polyline.geometry[index] = annotation.coordinate
            }
            
            var coordinates = _polyline?.geometry ?? []
            if coordinates.count > 1 {
                let overlay = MKPolyline(coordinates: &coordinates, count: coordinates.count)
                self.overlay = overlay
                mapView?.addOverlay(overlay)
            }
            
        case .polygon:
            if let polygon = self._polygon, !polygon.geometry.isEmpty {
                polygon.geometry[0][index] = annotation.coordinate
                if index == 0 {
                    polygon.geometry[0].removeLast()
                    polygon.geometry[0].append(annotation.coordinate)
                }
            }
            
            var coordinates = _polygon?.geometry.first ?? []
            if coordinates.count > 2 {
                let overlay = MKPolygon(coordinates: &coordinates, count: coordinates.count)
                self.overlay = overlay
                mapView?.addOverlay(overlay)
            }
        }
    }
}
