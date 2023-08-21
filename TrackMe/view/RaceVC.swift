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
    
    var breadcrumbs: BreadcrumbPath!
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
    
    var pathCoordinates: [CLLocation] {
        return (TrackUtils.getCoordinates(urlPath: "track-test2")?.map { coordinate in
            let latitude = coordinate["latitude"]
            let longitude = coordinate["longitude"]
            return CLLocation(latitude: latitude!, longitude: longitude!)
        })!
    }
    var pathIndex: Int?
    var timer: Timer?
    var counterInSection: Int?
    
    let locationManager = CLLocationManager()
    
    @IBOutlet weak var mapView: MKMapView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupLocation()
        mapView.delegate = self
        // Remove the existing path because the app is starting to record a new path.
        if let breadcrumbs {
            mapView.removeOverlay(breadcrumbs)
            breadcrumbPathRenderer = nil
        }
        
        // Create a fresh path when starting to record the locations.
        breadcrumbs = BreadcrumbPath()
        mapView.addOverlay(breadcrumbs, level: .aboveRoads)
        
        startMovementSimulation()
    }
    
    func setupLocation() {
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
        mapView.showsUserLocation = true
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.last {
            let region = MKCoordinateRegion(center: location.coordinate, latitudinalMeters: 1000, longitudinalMeters: 1000)
            mapView.setRegion(region, animated: true)
        }
    }
    
    func startMovementSimulation() {
        
        let elapsedTime: Double = 10 // sample data
        let fraction = Double(1) / Double(500)
        let timeInterval = elapsedTime * fraction
        
        pathIndex = 0
        counterInSection = 0
        timer = Timer.scheduledTimer(timeInterval: timeInterval, target: self, selector: #selector(handleTimerExecution), userInfo: fraction, repeats: true)
    }
    
    @objc func handleTimerExecution() {
        guard counterInSection! < 500 else {
            pathIndex! += 1
            counterInSection = 0
            if (pathIndex! >= pathCoordinates.count - 1) {
                timer?.invalidate()
            }
            return
        }
        var f = timer?.userInfo as! Double
        
        let start = pathCoordinates[pathIndex!]
        let end = pathCoordinates[pathIndex! + 1]
        f *= Double(counterInSection!)
    
        let interpolatedLatitude = start.coordinate.latitude + (end.coordinate.latitude - start.coordinate.latitude) * f
        let interpolatedLongitude = start.coordinate.longitude + (end.coordinate.longitude - start.coordinate.longitude) * f
        
        let interpolatedLocation = CLLocation(latitude: interpolatedLatitude, longitude: interpolatedLongitude)
        
        displayNewBreadcrumbOnMap(interpolatedLocation)
        
        counterInSection! += 1
    }
    
    func displayNewBreadcrumbOnMap(_ newLocation: CLLocation) {
        /**
         If the `BreadcrumbPath` model object determines that the current location moves far enough from the previous location,
         use the returned updateRect to redraw just the changed area.
         */
        let result = breadcrumbs.addLocation(newLocation)
        
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
            var areaToRedisplay = breadcrumbs.pathBounds
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
            let pathBounds = breadcrumbs.pathBounds
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

