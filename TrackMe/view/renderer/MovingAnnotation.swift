//
//  MovingPersonAnnotation.swift
//  TrackMe
//
//  Created by 곽진현 on 2023/08/18.
//

import MapKit

class MovingAnnotation: NSObject, MKAnnotation {
    var coordinate: CLLocationCoordinate2D
    init(coordinate: CLLocationCoordinate2D) {
        self.coordinate = coordinate
    }
}
