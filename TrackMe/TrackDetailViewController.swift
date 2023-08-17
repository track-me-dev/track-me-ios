//
//  TrackDetailViewController.swift
//  TrackMe
//
//  Created by 곽진현 on 2023/08/16.
//

import UIKit
import MapKit

class TrackDetailViewController: UIViewController {
    
    let standardPadding = UIEdgeInsets(top: 100, left: 100, bottom: 100, right: 100)
    
    var trackTitle: String!
    var trackPolyline: MKPolyline!
    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var titleView: UITextField!
    @IBOutlet weak var infoView: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        mapView.delegate = self
        titleView.text = trackTitle
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        mapView.addOverlay(trackPolyline, level: .aboveRoads)
        mapView.setVisibleMapRect(trackPolyline.boundingMapRect, edgePadding: standardPadding, animated: false)
    }
    
}

extension TrackDetailViewController: MKMapViewDelegate {
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        let renderer = MKPolylineRenderer(polyline: overlay as! MKPolyline)
        renderer.strokeColor = .systemPink
        renderer.lineWidth = 8
        return renderer
    }
}


