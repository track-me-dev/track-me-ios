//
//  RaceVC.swift
//  TrackMe
//
//  Created by 곽진현 on 2023/08/18.
//

import UIKit
import MapKit
import CoreLocation

class RaceVC: UIViewController, CLLocationManagerDelegate {
    
    var pathOfRank1: BreadcrumbPath!
    var breadcrumbPathRenderer: BreadcrumbPathRenderer?
    var showBreadcrumbBounds = UserDefaults.standard.bool(forKey: SettingsKeys.showCrumbsBoundingArea.rawValue) {
        didSet {
            UserDefaults.standard.set(showBreadcrumbBounds, forKey: SettingsKeys.showCrumbsBoundingArea.rawValue)
            if showBreadcrumbBounds {
                updateBreadcrumbBoundsOverlay()
            } else {
                removeBreadcrumbBoundsOverlay()
            }
        }
    }
    var breadcrumbBoundingPolygon: MKPolygon?
    
    var coordinatesOfRank1: [CLLocation]?
    var timestampsOfRank1: [Double]?
    var coordIndex: Int?
    var counter: Int?
    var timeInterval: Double?
    var simulator: Timer?
    
    var recordTimer: Timer?
    var elapsedTime: TimeInterval = 0
    var previousLocation: CLLocation?
    var totalDistance: CLLocationDistance = 0.0
    
    var firstCount = 5
    var counterTimer: Timer?
    
    let locationManager = CLLocationManager()
    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var timeView: UILabel!
    @IBOutlet weak var distanceView: UILabel!
    @IBOutlet weak var counterView: UILabel!
    @IBOutlet weak var mapTrackingButton: UIBarButtonItem!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        mapTrackingButton.customView = MKUserTrackingButton(mapView: mapView)
        mapView.delegate = self
        mapView.userTrackingMode = .follow
        showDestinationMarker()
        
        setupLocationManager()
        
        // Remove the existing path because the app is starting to record a new path.
        if let pathOfRank1 {
            mapView.removeOverlay(pathOfRank1)
            breadcrumbPathRenderer = nil
        }
        
        // Create a fresh path when starting to record the locations.
        pathOfRank1 = BreadcrumbPath()
        mapView.addOverlay(pathOfRank1, level: .aboveRoads)
        
        counterTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { timer in
            guard self.firstCount > 0 else {
                self.counterTimer!.invalidate()
                self.counterView.isHidden = true
                return
            }
            self.counterView.text = String(self.firstCount)
            self.firstCount -= Int(timer.timeInterval)
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
            self.recordTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { timer in
                self.locationManager.startUpdatingLocation()
                self.timeView.text = self.formatElaspsedTime()
                self.elapsedTime += timer.timeInterval
            }
            self.simulateRank1()
        }
        
    }
    
    func showDestinationMarker() {
        let annotation = MKPointAnnotation()
        annotation.coordinate = coordinatesOfRank1!.last!.coordinate
        mapView.addAnnotation(annotation)
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let newLocation = locations.last {
            if let previousLocation = previousLocation {
                let distance = newLocation.distance(from: previousLocation)
                totalDistance += distance
                distanceView.text = String(format: "%.2f km", totalDistance / 1000)
                
                // 목적지 도착
                if coordinatesOfRank1!.last!.distance(from: newLocation)
                    <= newLocation.distance(from: previousLocation) {
                    showSubmitView()
                }
            }
            previousLocation = newLocation
        }
    }
    
    func formatElaspsedTime() -> String {
        let hours = Int(self.elapsedTime) / 3600
        let minutes = (Int(self.elapsedTime) % 3600) / 60
        let seconds = Int(self.elapsedTime) % 60
        return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }
    
    func showSubmitView() {
        let submitView = UIAlertController(title: "완주하셨습니다!",
                                      message: String(format: "나의 기록 : %@", formatElaspsedTime()),
                                      preferredStyle: .alert)
        let submit = UIAlertAction(title: "제출", style: .default)
        let cancel = UIAlertAction(title: "취소", style: .default)
        submitView.addAction(submit)
        submitView.addAction(cancel)
        
        present(submitView, animated: true, completion: nil)
    }
    
    func setupLocationManager() {
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
        locationManager.allowsBackgroundLocationUpdates = true
    }
    
    func simulateRank1() {
        
        var minInterval = (timestampsOfRank1?.last)! - (timestampsOfRank1?.first)!
        for i in 0..<timestampsOfRank1!.count - 1 {
            minInterval = min(minInterval, timestampsOfRank1![i + 1] - timestampsOfRank1![i])
        }
        timeInterval = minInterval / 10
        let activateIndex = timestampsOfRank1?.map { Int(($0 - (timestampsOfRank1?.first)!) / timeInterval!) }
        
        coordIndex = 0
        counter = 0
        simulator = Timer.scheduledTimer(timeInterval: timeInterval!, target: self, selector: #selector(handleTimerExecution), userInfo: activateIndex, repeats: true)
    }
    
    @objc func handleTimerExecution() {
        guard coordIndex! < coordinatesOfRank1!.count else {
            simulator!.invalidate()
            return
        }
    
        let activateIndex = simulator?.userInfo as! [Int]
        if activateIndex[coordIndex!] == counter! {
            displayNewBreadcrumbOnMap(coordinatesOfRank1![coordIndex!])
            coordIndex! += 1
        }
        counter! += 1
    }
    
    func displayNewBreadcrumbOnMap(_ newLocation: CLLocation) {
        /**
         If the `BreadcrumbPath` model object determines that the current location moves far enough from the previous location,
         use the returned updateRect to redraw just the changed area.
         */
        let result = pathOfRank1.addLocation(newLocation, isRecording: false)
        
        /**
         If the `BreadcrumbPath` model object sucessfully adds the location to the path,
         update the rendering of the path to include the new location.
         */
        if result.locationAdded {
            // Compute the currently visible map zoom scale.
            let currentZoomScale = mapView.bounds.size.width / mapView.visibleMapRect.size.width
            
            /**
             Find out the line width at this zoom scale and outset the `pathBounds` by that amount to ensure the full line width draws.
             This covers situations where the new location is right on the edge of the provided `pathBounds`, and only part of the line width
             is within the bounds.
             */
            let lineWidth = MKRoadWidthAtZoomScale(currentZoomScale)
            var areaToRedisplay = pathOfRank1.pathBounds
            areaToRedisplay = areaToRedisplay.insetBy(dx: -lineWidth, dy: -lineWidth)
            
            /**
             Tell the overlay view to update just the changed area, including the area that the line width covers.
             Use `setNeedsDisplay(_:)` to only redraw the changed area of a breadcrumb overlay. For this sample,
             the changed area includes the entire overlay because if the app was recently in the background, the breadcrumb path
             that's visible when the app returns to the foreground might change significantly.
             
             In general, avoid calling `setNeedsDisplay()` on the overlay renderer without a map rectangle, as that may cause a render
             pass for the entire visible map, only some of which may contain updated data in the overlay.
             
             To avoid an expensive operation, call `setNeedsDisplay(_:)` instead of removing the overlay from the map and then immediately
             adding it back to trigger a render pass when the data is changing often. The rendering of an overlay after adding it to the
             map is not instantaneous, so removing and adding an overlay may cause a visual flicker as the system updates the map view
             without the overlay, and then updates it again with the overlay. This is especially true if the map is displaying more than
             one overlay or updating the overlay data often, such as on each location update.
             */
            breadcrumbPathRenderer?.setNeedsDisplay(areaToRedisplay)
        }
        
        if result.boundingRectChanged {
            /**
             When adding a location, the new location sometimes falls outside of the existing bounding area for the path,
             and the `breadcrumbs` object expands the bounding area to include the new location. When this happens, the app
             needs to recreate the bounds overlay.
             */
            updateBreadcrumbBoundsOverlay()
        }
    }
    
    private func removeBreadcrumbBoundsOverlay() {
        if let breadcrumbBoundingPolygon {
            mapView.removeOverlay(breadcrumbBoundingPolygon)
        }
    }
    
    private func updateBreadcrumbBoundsOverlay() {
       removeBreadcrumbBoundsOverlay()
        
        if showBreadcrumbBounds {
            let pathBounds = pathOfRank1.pathBounds
            let boundingPoints = [
                MKMapPoint(x: pathBounds.minX, y: pathBounds.minY),
                MKMapPoint(x: pathBounds.minX, y: pathBounds.maxY),
                MKMapPoint(x: pathBounds.maxX, y: pathBounds.maxY),
                MKMapPoint(x: pathBounds.maxX, y: pathBounds.minY)
            ]
            breadcrumbBoundingPolygon = MKPolygon(points: boundingPoints, count: boundingPoints.count)
            mapView.addOverlay(breadcrumbBoundingPolygon!, level: .aboveRoads)
        }
    }

}

extension RaceVC: MKMapViewDelegate {

    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        if let overlay = overlay as? BreadcrumbPath {
            if breadcrumbPathRenderer == nil {
                breadcrumbPathRenderer = BreadcrumbPathRenderer(crumbPath: overlay)
            }
            return breadcrumbPathRenderer!
        } else if overlay is MKPolygon {
            // The rectangle showing the `pathBounds` of the `breadcrumbs` overlay.
            let pathBoundsRenderer = MKPolygonRenderer(overlay: overlay)
            pathBoundsRenderer.fillColor = .systemBlue.withAlphaComponent(0.25)
            return pathBoundsRenderer
        } else {
            fatalError("Unknown overlay \(overlay) added to the map")
        }
    }
}

