import UIKit
import MapKit
import Alamofire
import KeychainSwift

class TrackDetailVC: UIViewController {
    
    let standardPadding = UIEdgeInsets(top: 100, left: 100, bottom: 100, right: 100)
    
    var trackId: CLong!
    var track: TrackDetailResponse?
    var retrieveTrackUrl: String {
        return "http://localhost:8080/tracks/\(Int(self.trackId))"
    }
    var trackPolyline: MKPolyline!
    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var titleField: UITextField!
    
    @IBOutlet weak var distanceField: UITextField!
    @IBOutlet weak var averageSlopeField: UITextField!
    @IBOutlet weak var lowestAltitudeField: UITextField!
    @IBOutlet weak var highestAltitudeField: UITextField!
    @IBOutlet weak var startRaceButton: UIButton!
    @IBOutlet weak var rank1stField: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        mapView.delegate = self
        initTrack()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        mapView.addOverlay(trackPolyline, level: .aboveRoads)
        mapView.setVisibleMapRect(trackPolyline.boundingMapRect, edgePadding: standardPadding, animated: false)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "startRace" {
            if let raceVC = segue.destination as? RaceVC {
                raceVC.trackId = track!.id
                raceVC.coordinatesOfRank1 = track!.path.map { path in
                    let latitude = path["latitude"]
                    let longitude = path["longitude"]
                    return CLLocation(latitude: latitude!, longitude: longitude!)
                }
                raceVC.elapsedTimesOfRank1 = track!.path.map { $0["elapsedTime"]! }
                raceVC.trackDistance = track!.distance
            }
        } else if segue.identifier == "totalRank" {
            if let rankingVC = segue.destination as? RankingVC {
                rankingVC.trackId = track?.id
            }
        }
    }
    
    private func initTrack() {
        let keychain = KeychainSwift()
        let header : HTTPHeaders = [
            "Content-Type" : "application/json",
            "Authorization" : "Bearer \(keychain.get("trackme_accessToken")!)"
        ]
        AF.request(retrieveTrackUrl, method: .get, headers: header)
            .validate(statusCode: 200..<300)
            .response { response in
                switch response.result {
                case .success(let value):
                    do {
                        let result = try JSONDecoder().decode(TrackDetailResponse.self, from: value!)
                        DispatchQueue.main.async {
                            self.track = result
                            self.initTrackPolyline()
                            self.initField()
                        }
                    } catch {
                        print(error)
                    }
                case .failure(let error):
                    print(error)
                    break;
                }
            }
    }
    
    private func initTrackPolyline() {
        var locations: [CLLocationCoordinate2D] = []
        track!.path.forEach { coord in
            locations.append(CLLocationCoordinate2D(latitude: coord["latitude"]!, longitude: coord["longitude"]!))
        }
        trackPolyline = MKPolyline(coordinates: locations, count: locations.count)
    }
    
    private func initField() {
        if let data = track {
            titleField.text = data.title
            distanceField.text = String(format: "%.2fkm", data.distance / 1000)
            averageSlopeField.text = String(format: "%.1f%%", data.averageSlope! * 100)
            lowestAltitudeField.text = String(format: "%dm", Int(data.lowestAltitude!))
            highestAltitudeField.text = String(format: "%dm", Int(data.highestAltitude!))
            rank1stField.text = String(format: "최고 기록: %@", formatElaspsedTime())
        }
    }
    
    private func formatElaspsedTime() -> String {
        let hours = Int(track!.rank1stTime) / 3600
        let minutes = (Int(track!.rank1stTime) % 3600) / 60
        let seconds = Int(track!.rank1stTime) % 60
        return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }
    
    
}

extension TrackDetailVC: MKMapViewDelegate {
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        let renderer = MKPolylineRenderer(polyline: overlay as! MKPolyline)
        renderer.strokeColor = UIColor(named: "MainColor")
        renderer.lineWidth = 8
        return renderer
    }
}


