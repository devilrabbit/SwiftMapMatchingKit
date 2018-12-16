//
//  PointAnnotation.swift
//  MapMatching
//
//  Created by devilrabbit on 2018/12/01.
//  Copyright (c) 2018 devilrabbit. All rights reserved.
//

import MapKit

public class PointAnnotation : NSObject, MKAnnotation {
    
    public var coordinate: CLLocationCoordinate2D
    public var title: String?
    public var subtitle: String?
    
    public init(coordinate: CLLocationCoordinate2D) {
        self.coordinate = coordinate
        self.title = "\(coordinate.latitude), \(coordinate.longitude)"
        self.subtitle = ""
        super.init()
    }
    
}
