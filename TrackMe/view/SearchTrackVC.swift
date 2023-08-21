//
//  TrackListViewController.swift
//  TrackMe
//
//  Created by 곽진현 on 2023/08/15.
//

import UIKit
import CoreLocation
import MapKit
import Alamofire

class SearchTrackVC: UIViewController {
    
    @IBOutlet weak var tableView: UITableView!
    
    var tracks: [Track] = []
    
    override func viewDidLoad() {
        tableView.delegate = self
        tableView.dataSource = self
        
        AF.request("http://localhost:8080/tracks", method: .get)
            .validate(statusCode: 200..<300)
            .response { response in
                switch response.result {
                case .success(let value):
                    do {
                        let result = try JSONDecoder().decode([Track].self, from: value!)
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
        let cell = tableView.dequeueReusableCell(withIdentifier: "TrackListCell", for: indexPath)
        cell.textLabel?.text = tracks[indexPath.row].title
        return cell
    }
    
}

extension SearchTrackVC: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        performSegue(withIdentifier: "trackDetail", sender: self)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let destination = segue.destination as? TrackDetailVC {
            let track = tracks[(tableView.indexPathForSelectedRow?.row)!]
            destination.track = track
        }
    }
    
}
