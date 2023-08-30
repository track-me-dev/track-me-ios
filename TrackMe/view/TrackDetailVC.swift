//
//  TrackDetailViewController.swift
//  TrackMe
//
//  Created by 곽진현 on 2023/08/16.
//

import UIKit
import MapKit

class TrackDetailVC: UIViewController {
    
    let standardPadding = UIEdgeInsets(top: 100, left: 100, bottom: 100, right: 100)
    
    var track: Track? = nil
    var trackPolyline: MKPolyline! {
        var locations: [CLLocationCoordinate2D] = []
        track!.path.forEach { coord in
            locations.append(CLLocationCoordinate2D(latitude: coord["latitude"]!, longitude: coord["longitude"]!))
        }
        return MKPolyline(coordinates: locations, count: locations.count)
    }
    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var titleField: UITextField!
    
    @IBOutlet weak var distanceField: UITextField!
    @IBOutlet weak var averageSlopeField: UITextField!
    @IBOutlet weak var lowestAltitudeField: UITextField!
    @IBOutlet weak var highestAltitudeField: UITextField!
    @IBOutlet weak var startRaceButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        mapView.delegate = self
        if let data = track {
            titleField.text = data.title
            distanceField.text = String(format: "%.2fkm", data.distance / 1000)
            averageSlopeField.text = String(format: "%.1f%%", data.averageSlope!)
            lowestAltitudeField.text = String(format: "%dm", Int(data.lowestAltitude!))
            highestAltitudeField.text = String(format: "%dm", Int(data.highestAltitude!))
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        mapView.addOverlay(trackPolyline, level: .aboveRoads)
        mapView.setVisibleMapRect(trackPolyline.boundingMapRect, edgePadding: standardPadding, animated: false)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "startRace" {
            if let raceVC = segue.destination as? RaceVC {
                raceVC.coordinatesOfRank1 = track!.path.map { path in
                    let latitude = path["latitude"]
                    let longitude = path["longitude"]
                    return CLLocation(latitude: latitude!, longitude: longitude!)
                }
                raceVC.timestampsOfRank1 = track!.path.map { $0["timestamp"]! }
            }
        }
    }
    
}

extension TrackDetailVC: MKMapViewDelegate {
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        let renderer = MKPolylineRenderer(polyline: overlay as! MKPolyline)
        renderer.strokeColor = .systemPink
        renderer.lineWidth = 8
        return renderer
    }
}


