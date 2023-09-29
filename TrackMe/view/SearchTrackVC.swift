import UIKit
import CoreLocation
import MapKit
import Alamofire

class SearchTrackVC: UIViewController {
    
    @IBOutlet weak var tableView: UITableView!
    
    var tracks: [SearchTrackResponse] = []
    
    override func viewDidLoad() {
        tableView.delegate = self
        tableView.dataSource = self
        
        AF.request("http://localhost:8080/tracks", method: .get)
            .validate(statusCode: 200..<300)
            .response { response in
                switch response.result {
                case .success(let value):
                    do {
                        let result = try JSONDecoder().decode([SearchTrackResponse].self, from: value!)
                        DispatchQueue.main.async {
                            self.tracks = result
                            self.tableView.reloadData()
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
}

extension SearchTrackVC: UITableViewDataSource {
  
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return tracks.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "trackListCell", for: indexPath)
        let track = tracks[indexPath.row]
        cell.textLabel?.text = track.title
        cell.detailTextLabel?.text = String(format: "주행 거리: %.2fkm, 평균 경사도: %.1f%",
                                            track.distance / 1000,
                                            track.averageSlope!)
        return cell
    }
}

extension SearchTrackVC: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        performSegue(withIdentifier: "trackDetail", sender: self)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let trackDetailVC = segue.destination as? TrackDetailVC {
            let track = tracks[(tableView.indexPathForSelectedRow?.row)!]
            trackDetailVC.trackId = track.id
        }
    }
    
}
