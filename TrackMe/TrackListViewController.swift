//
//  TrackListViewController.swift
//  TrackMe
//
//  Created by 곽진현 on 2023/08/15.
//

import UIKit
import CoreLocation
import MapKit

class TrackListViewController: UIViewController {
    
    @IBOutlet weak var tableView: UITableView!
    
    var tracks: [Track] = [Track(title: "track1", route: TrackUtils.getCoordinates(urlPath: "track-test")!)]
    
    override func viewDidLoad() {
        tableView.delegate = self
        tableView.dataSource = self
    }
}

extension TrackListViewController: UITableViewDataSource {
  
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return tracks.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "TrackListCell", for: indexPath)
        cell.textLabel?.text = tracks[indexPath.row].title
        return cell
    }
    
}

extension TrackListViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        performSegue(withIdentifier: "trackDetail", sender: self)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let destination = segue.destination as? TrackDetailViewController {
            let track = tracks[(tableView.indexPathForSelectedRow?.row)!]
            destination.trackTitle = track.title
            var locations: [CLLocationCoordinate2D] = []
            track.route.map { (lat, lng) in
                locations.append(CLLocationCoordinate2D(latitude: lat, longitude: lng))
            }
            destination.trackPolyline = MKPolyline(coordinates: locations, count: locations.count)
        }
    }
    
}
