import UIKit
import MapKit
import CoreLocation
import Alamofire
import KeychainSwift

class RaceVC: UIViewController, CLLocationManagerDelegate {
    
    var trackId: CLong!
    
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
    var elapsedTimesOfRank1: [Double]?
    var coordIndex: Int?
    var counter: Int?
    var timeInterval: Double?
    var simulator: Timer?
    
    var recordTimer: Timer?
    var elapsedTime: TimeInterval = 0
    var previousLocation: CLLocation?
    var totalDistance: CLLocationDistance = 0.0
    var trackDistance: CLLocationDistance!
    var currentPath: BreadcrumbPath!
    
    var firstCount = 5
    var counterTimer: Timer?
    
    var modalViewPresented = false
    
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
        
        if let pathOfRank1 {
            mapView.removeOverlay(pathOfRank1)
            breadcrumbPathRenderer = nil
        }
        
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
            self.currentPath = BreadcrumbPath()
            self.locationManager.startUpdatingLocation()
            self.recordTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { timer in
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
        for location in locations {
            currentPath.addLocation(location, isRecording: false)
        }
        if let newLocation = locations.last {
            if let previousLocation = previousLocation {
                let distance = newLocation.distance(from: previousLocation)
                totalDistance += distance
                distanceView.text = String(format: "%.2f km", totalDistance / 1000)
                
                // 목적지 도착 -> 1. 현재 위치가 목적지에 근접해 있는지 확인 / 2. 주행 거리와 트랙 거리의 차이가 {특정 거리} 이내인지 확인
                // TODO: (trackDistance - totalDistance) 값을 검증할 때 오차 범위 정하기
                if coordinatesOfRank1!.last!.distance(from: newLocation)
                    <=  50.0 && trackDistance - totalDistance <= 50.0
                    && !modalViewPresented {
                    locationManager.stopUpdatingLocation()
                    showSubmitView(time: elapsedTime)
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
    
    func showSubmitView(time: Double) {
        DispatchQueue.main.async {
            let submitView = UIAlertController(title: "완주하셨습니다!",
                                               message: String(format: "나의 기록 : %@", self.formatElaspsedTime()),
                                               preferredStyle: .alert)
            let submit = UIAlertAction(title: "제출", style: .default) { submitAction in
                self.transferRecord(time: time)
            }
            let cancel = UIAlertAction(title: "취소", style: .default)
            submitView.addAction(submit)
            submitView.addAction(cancel)
            
            self.present(submitView, animated: true, completion: nil)
            
            self.modalViewPresented = true
        }
    }
    
    func transferRecord(time: Double) {
        // [http 요청 헤더 지정]
        let keychain = KeychainSwift()
        let header : HTTPHeaders = [
            "Content-Type" : "application/json",
            "Authorization" : "Bearer \(keychain.get("trackme_accessToken")!)"
        ]
        
        let referncedTime = currentPath.locations.first!.timestamp
        // [http 요청 파라미터 지정 실시]
        let bodyData : Parameters = [
            "path" : currentPath.locations.map { location in
                let coord = location.coordinate
                let elapsedTime = location.timestamp.timeIntervalSince(referncedTime)
                return ["latitude":coord.latitude, "longitude":coord.longitude, "elapsedTime": elapsedTime]
            },
            "distance" : currentPath.distance,
            "time": time
        ]
        
        AF.request(String(format: "http://localhost:8080/tracks/%d/records", trackId),
                   method: .post,
                   parameters: bodyData, // [전송 데이터]
                   encoding: JSONEncoding.default, // [인코딩 스타일]
                   headers: header // [헤더 지정]
        )
        .validate(statusCode: 200..<300)
        .responseData { response in
            switch response.result {
            case .success(_):
                print("record saved")
            case .failure(let error):
                print(error)
                break;
            }
        }
    }
    
    func setupLocationManager() {
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
    }
    
    func simulateRank1() {
        
        var minInterval = (elapsedTimesOfRank1?.last)! - (elapsedTimesOfRank1?.first)!
        for i in 0..<elapsedTimesOfRank1!.count - 1 {
            minInterval = min(minInterval, elapsedTimesOfRank1![i + 1] - elapsedTimesOfRank1![i])
        }
        timeInterval = minInterval / 10
        let activateIndex = elapsedTimesOfRank1?.map { Int(($0 - (elapsedTimesOfRank1?.first)!) / timeInterval!) }
        
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
        let result = pathOfRank1.addLocation(newLocation, isRecording: false)
        
        if result.locationAdded {
            // Compute the currently visible map zoom scale.
            let currentZoomScale = mapView.bounds.size.width / mapView.visibleMapRect.size.width
            
            let lineWidth = MKRoadWidthAtZoomScale(currentZoomScale)
            var areaToRedisplay = pathOfRank1.pathBounds
            areaToRedisplay = areaToRedisplay.insetBy(dx: -lineWidth, dy: -lineWidth)
            
            breadcrumbPathRenderer?.setNeedsDisplay(areaToRedisplay)
        }
        
        if result.boundingRectChanged {
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

